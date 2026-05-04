// @ts-nocheck
// This file runs on Deno (Supabase Edge). Workspace TypeScript is Node-oriented and
// cannot resolve jsr:/https: imports or the Deno global; use @ts-nocheck or the Deno VS Code extension.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { SignJWT, importPKCS8 } from "https://esm.sh/jose@5.9.6?target=deno";

type QueueRow = {
  id: string;
  user_id: string;
  title: string;
  body: string;
  data: Record<string, unknown>;
  processed_at: string | null;
};

type ServiceAccount = {
  type: string;
  project_id: string;
  private_key: string;
  client_email: string;
};

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-push-process-secret",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** Service role for admin client: legacy env or new SUPABASE_SECRET_KEYS JSON. */
function getServiceRoleKey(): string {
  const legacy = (Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "").trim();
  if (legacy.length > 0) return legacy;
  const raw = Deno.env.get("SUPABASE_SECRET_KEYS") ?? "";
  if (!raw.trim()) return "";
  try {
    const o = JSON.parse(raw) as Record<string, string>;
    const d = o["default"];
    if (typeof d === "string" && d.trim()) return d.trim();
    const first = Object.values(o).find((v) => typeof v === "string" && v.trim());
    return typeof first === "string" ? first.trim() : "";
  } catch {
    return "";
  }
}

function authorize(req: Request): { ok: true } | { ok: false; debug: Record<string, unknown> } {
  const sr = getServiceRoleKey();
  const auth = (req.headers.get("Authorization") ?? "").trim();
  const apikey = (req.headers.get("apikey") ?? "").trim();

  if (sr && auth === `Bearer ${sr}`) return { ok: true };
  if (sr && apikey === sr) return { ok: true };

  const secret = (Deno.env.get("PUSH_PROCESS_SECRET") ?? "").replace(/^\uFEFF/, "").trim();
  if (secret.length > 0) {
    const headerSecret = (req.headers.get("x-push-process-secret") ?? "").replace(/^\uFEFF/, "")
      .trim();
    if (headerSecret === secret) return { ok: true };

    const bearer = auth.match(/^Bearer\s+(.+)$/is)?.[1]?.replace(/^\uFEFF/, "").trim() ?? "";
    if (bearer === secret) return { ok: true };
    if (apikey.replace(/^\uFEFF/, "").trim() === secret) return { ok: true };

    // Database Webhook → Edge URL: Supabase often strips custom auth headers before the worker.
    // Query string is still forwarded — use same value as PUSH_PROCESS_SECRET:
    //   .../process-push-queue?push_token=<secret>
    let pushToken = "";
    try {
      pushToken = (new URL(req.url).searchParams.get("push_token") ?? "").trim();
    } catch {
      pushToken = "";
    }
    if (pushToken === secret) return { ok: true };

    const headerKeys: string[] = [];
    req.headers.forEach((_, k) => headerKeys.push(k));
    headerKeys.sort();

    return {
      ok: false,
      debug: {
        push_secret_configured: true,
        has_authorization: auth.length > 0,
        has_apikey: apikey.length > 0,
        has_x_push_header: headerSecret.length > 0,
        has_push_token_query: pushToken.length > 0,
        bearer_length: bearer.length,
        secret_env_length: secret.length,
        lengths_match_bearer: bearer.length === secret.length && bearer.length > 0,
        lengths_match_query: pushToken.length === secret.length && pushToken.length > 0,
        header_keys: headerKeys,
        fix:
          "Append ?push_token=<same value as PUSH_PROCESS_SECRET> to the webhook URL (headers are stripped on this path).",
      },
    };
  }

  return {
    ok: false,
    debug: {
      push_secret_configured: false,
      has_service_role_env: sr.length > 0,
      has_authorization: auth.length > 0,
      has_apikey: apikey.length > 0,
      hint: "Add Edge secret PUSH_PROCESS_SECRET (same value as webhook), redeploy function, then retry.",
    },
  };
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const pk = sa.private_key.replace(/\\n/g, "\n");
  const key = await importPKCS8(pk, "RS256");
  const now = Math.floor(Date.now() / 1000);
  const assertion = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!tokenRes.ok) {
    const t = await tokenRes.text();
    throw new Error(`oauth2 token failed: ${tokenRes.status} ${t}`);
  }
  const json = (await tokenRes.json()) as { access_token?: string };
  if (!json.access_token) throw new Error("oauth2: no access_token");
  return json.access_token;
}

function fcmDataStrings(
  data: Record<string, unknown>,
): Record<string, string> {
  const out: Record<string, string> = {};
  for (const [k, v] of Object.entries(data ?? {})) {
    if (v == null) continue;
    out[k] = typeof v === "string" ? v : JSON.stringify(v);
  }
  return out;
}

async function sendFcm(
  projectId: string,
  accessToken: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<{ ok: boolean; status: number; text: string }> {
  const url =
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: {
        token,
        notification: { title, body },
        data,
      },
    }),
  });
  const text = await res.text();
  return { ok: res.ok, status: res.status, text };
}

async function processRow(
  supabase: ReturnType<typeof createClient>,
  sa: ServiceAccount,
  row: QueueRow,
): Promise<{ sent: boolean; detail: string }> {
  if (row.processed_at) {
    return { sent: false, detail: "already_processed" };
  }

  const { data: prof, error: pe } = await supabase
    .from("profiles")
    .select("fcm_token")
    .eq("id", row.user_id)
    .maybeSingle();

  if (pe) {
    return { sent: false, detail: `profile_error:${pe.message}` };
  }

  const fcmToken = (prof as { fcm_token?: string } | null)?.fcm_token?.trim();
  if (!fcmToken) {
    await supabase
      .from("push_notification_queue")
      .update({ processed_at: new Date().toISOString() })
      .eq("id", row.id);
    return { sent: false, detail: "no_token" };
  }

  const access = await getAccessToken(sa);
  const dataStr = fcmDataStrings(row.data ?? {});
  const r = await sendFcm(
    sa.project_id,
    access,
    fcmToken,
    row.title,
    row.body,
    dataStr,
  );

  if (r.ok) {
    await supabase
      .from("push_notification_queue")
      .update({ processed_at: new Date().toISOString() })
      .eq("id", row.id);
    return { sent: true, detail: "ok" };
  }

  const unregistered =
    r.text.includes("UNREGISTERED") ||
    r.text.includes("registration-token-not-registered");
  if (unregistered) {
    await supabase.from("profiles").update({ fcm_token: null }).eq(
      "id",
      row.user_id,
    );
  }

  await supabase
    .from("push_notification_queue")
    .update({ processed_at: new Date().toISOString() })
    .eq("id", row.id);

  return { sent: false, detail: `fcm_${r.status}:${r.text.slice(0, 200)}` };
}

/** Some webhook→Edge paths omit JSON; drain pending rows (same as process_batch). */
async function runProcessBatch(
  supabase: ReturnType<typeof createClient>,
  sa: ServiceAccount,
): Promise<Array<{ id: string; sent: boolean; detail: string }>> {
  const out: Array<{ id: string; sent: boolean; detail: string }> = [];
  const { data: rows, error } = await supabase
    .from("push_notification_queue")
    .select("*")
    .is("processed_at", null)
    .order("created_at", { ascending: true })
    .limit(50);
  if (error) throw new Error(error.message);
  for (const row of rows ?? []) {
    const r = await processRow(supabase, sa, row as QueueRow);
    out.push({ id: (row as QueueRow).id, sent: r.sent, detail: r.detail });
  }
  return out;
}

function unwrapWebhookPayload(b: Record<string, unknown>): Record<string, unknown> {
  const p = b["payload"];
  if (p && typeof p === "object" && !Array.isArray(p)) {
    return p as Record<string, unknown>;
  }
  return b;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const authz = authorize(req);
  if (!authz.ok) {
    return jsonResponse(
      {
        error: "unauthorized",
        hint:
          "If Database Webhook strips headers, set webhook URL to .../process-push-queue?push_token=<same as PUSH_PROCESS_SECRET>. " +
          "Also try Authorization Bearer / apikey / x-push-process-secret. Service role works if headers arrive. verify_jwt=false in config.toml.",
        debug: authz.debug,
      },
      401,
    );
  }

  const saJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!saJson) {
    return jsonResponse({ error: "missing FIREBASE_SERVICE_ACCOUNT_JSON" }, 500);
  }

  let sa: ServiceAccount;
  try {
    sa = JSON.parse(saJson) as ServiceAccount;
  } catch {
    return jsonResponse({ error: "invalid FIREBASE_SERVICE_ACCOUNT_JSON" }, 500);
  }

  if (!sa.project_id || !sa.private_key || !sa.client_email) {
    return jsonResponse({ error: "incomplete service account json" }, 500);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseKey = getServiceRoleKey();
  if (!supabaseKey) {
    return jsonResponse(
      {
        error: "missing_service_role",
        hint:
          "No SUPABASE_SERVICE_ROLE_KEY or SUPABASE_SECRET_KEYS in function env. Redeploy or check project API keys.",
      },
      500,
    );
  }
  const supabase = createClient(supabaseUrl, supabaseKey);

  let body: Record<string, unknown> = {};
  try {
    if (req.method === "POST" || req.method === "PUT") {
      const text = await req.text();
      if (text.trim()) {
        body = JSON.parse(text) as Record<string, unknown>;
      }
    }
  } catch {
    return jsonResponse({ error: "invalid json" }, 400);
  }

  body = unwrapWebhookPayload(body);

  const results: Array<{ id: string; sent: boolean; detail: string }> = [];

  // Supabase Database Webhook: { type, table, record, ... }
  const evtType = String(body["type"] ?? "");
  const table = String(body["table"] ?? "");
  if (
    evtType.toUpperCase() === "INSERT" &&
    table === "push_notification_queue"
  ) {
    const rec = body["record"] as QueueRow | undefined;
    if (rec?.id) {
      const r = await processRow(supabase, sa, rec);
      results.push({ id: rec.id, sent: r.sent, detail: r.detail });
      return jsonResponse({ ok: true, results });
    }
  }

  const processBatch = body["process_batch"] === true;
  const singleId = typeof body["queue_id"] === "string"
    ? body["queue_id"] as string
    : null;

  if (singleId) {
    const { data: row, error } = await supabase
      .from("push_notification_queue")
      .select("*")
      .eq("id", singleId)
      .maybeSingle();
    if (error || !row) {
      return jsonResponse(
        { error: error?.message ?? "row not found", id: singleId },
        404,
      );
    }
    const r = await processRow(supabase, sa, row as QueueRow);
    results.push({ id: singleId, sent: r.sent, detail: r.detail });
    return jsonResponse({ ok: true, results });
  }

  if (processBatch) {
    try {
      const batchResults = await runProcessBatch(supabase, sa);
      return jsonResponse({ ok: true, results: batchResults });
    } catch (e) {
      return jsonResponse({ error: String(e) }, 500);
    }
  }

  // No JSON payload: drain pending rows (same as process_batch). Covers:
  // - POST with empty body (some Database Webhook → Edge paths omit JSON)
  // - GET with ?push_token=… (browser / uptime checks / misconfigured webhook as GET)
  const noPayload = Object.keys(body).length === 0;
  if (noPayload && (req.method === "POST" || req.method === "GET")) {
    try {
      const batchResults = await runProcessBatch(supabase, sa);
      return jsonResponse({
        ok: true,
        results: batchResults,
        note:
          req.method === "GET"
            ? "get_batch_fallback"
            : "empty_body_batch_fallback",
      });
    } catch (e) {
      return jsonResponse({ error: String(e) }, 500);
    }
  }

  return jsonResponse(
    {
      error: "expected webhook INSERT payload, queue_id, or process_batch",
      got: {
        type: body["type"],
        table: body["table"],
        keys: Object.keys(body),
        method: req.method,
        content_type: req.headers.get("content-type"),
      },
    },
    400,
  );
});
