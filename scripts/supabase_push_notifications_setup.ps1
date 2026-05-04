#Requires -Version 5.1
<#
  Link project, push migrations, deploy process-push-queue, set Edge secrets.

  Prerequisites:
  - Install Supabase CLI (recommended: https://supabase.com/docs/guides/cli/getting-started )
    or:  winget install Supabase.CLI
  - Log in:  supabase login
  - Create supabase/.env.secrets from supabase/.env.secrets.example (minify JSON to one line).

  Usage (from repo root):
    .\scripts\supabase_push_notifications_setup.ps1
    .\scripts\supabase_push_notifications_setup.ps1 -ProjectRef "tucjzlcvrcxvovfaxsuk" -SkipSecrets
#>
param(
  [string] $ProjectRef = "tucjzlcvrcxvovfaxsuk",
  [switch] $SkipSecrets
)

$ErrorActionPreference = "Stop"
# scripts\ → repo root
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

$supabase = Get-Command supabase -ErrorAction SilentlyContinue
if (-not $supabase) {
  Write-Error "Supabase CLI not found on PATH. Install it, then re-run this script."
}

Write-Host "Linking project $ProjectRef (use DB password from Supabase Dashboard → Settings → Database)..."
supabase link --project-ref $ProjectRef

Write-Host "Pushing migrations..."
supabase db push

Write-Host "Deploying Edge Function process-push-queue..."
supabase functions deploy process-push-queue --project-ref $ProjectRef

if (-not $SkipSecrets) {
  $envFile = Join-Path $Root "supabase\.env.secrets"
  if (-not (Test-Path $envFile)) {
    Write-Warning "Missing $envFile — copy from supabase\.env.secrets.example, then run:"
    Write-Host "  supabase secrets set --env-file supabase\.env.secrets --project-ref $ProjectRef"
  }
  else {
    Write-Host "Setting Edge secrets from supabase\.env.secrets..."
    supabase secrets set --env-file $envFile --project-ref $ProjectRef
  }
}

Write-Host @"

--- Webhook (Dashboard) ---
1. Open: https://supabase.com/dashboard/project/$ProjectRef/integrations/hooks
   (or: Database → Webhooks, depending on UI version)
2. Create webhook: table public.push_notification_queue, event INSERT
3. HTTP POST URL:
   https://$ProjectRef.supabase.co/functions/v1/process-push-queue
4. HTTP Headers:  x-push-process-secret  =  (same value as PUSH_PROCESS_SECRET in .env.secrets)
5. Save.

Optional: drain backlog: POST with Authorization Bearer (service_role) and JSON body { `"process_batch`": true }.

"@
