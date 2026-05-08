// @ts-nocheck
// This Edge Function runs on Supabase Edge Runtime (Deno).
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** Service role for admin client: legacy env or new SUPABASE_SECRET_KEYS JSON. */
function getServiceRoleKey() {
  const legacy = (Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "").trim();
  if (legacy.length > 0) return legacy;
  const raw = Deno.env.get("SUPABASE_SECRET_KEYS") ?? "";
  if (!raw.trim()) return "";
  try {
    const o = JSON.parse(raw);
    const d = o["default"];
    if (typeof d === "string" && d.trim()) return d.trim();
    const first = Object.values(o).find(
      (v) => typeof v === "string" && v.trim(),
    );
    return typeof first === "string" ? first.trim() : "";
  } catch {
    return "";
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  const authHeader = (req.headers.get("Authorization") ?? "").trim();
  const accessToken = authHeader.replace(/^Bearer\s+/i, "");
  if (!accessToken) {
    return jsonResponse({ error: "missing_bearer_token" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  if (!supabaseUrl) {
    return jsonResponse({ error: "missing_SUPABASE_URL" }, 500);
  }

  const serviceRoleKey = getServiceRoleKey();
  if (!serviceRoleKey) {
    return jsonResponse(
      {
        error: "missing_service_role",
        hint:
          "Set SUPABASE_SERVICE_ROLE_KEY (or SUPABASE_SECRET_KEYS) as an Edge Function secret, then redeploy.",
      },
      500,
    );
  }

  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

  // Validate caller token and derive the user id from it (so attacker cannot delete arbitrary users).
  const { data: userData, error: userErr } =
    await supabaseAdmin.auth.getUser(accessToken);

  if (userErr || !userData?.user?.id) {
    return jsonResponse({ error: "unauthorized", detail: userErr?.message }, 401);
  }

  const userId = userData.user.id;

  const { error: delErr } = await supabaseAdmin.auth.admin.deleteUser(userId);
  if (delErr) {
    return jsonResponse(
      { error: "delete_failed", detail: delErr.message },
      500,
    );
  }

  return jsonResponse({ ok: true, user_id: userId });
});

