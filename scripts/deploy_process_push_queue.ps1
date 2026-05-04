#Requires -Version 5.1
<#
  Deploy Edge Function process-push-queue without needing supabase on PATH.

  Ways to get the CLI:
    A) This script downloads the latest Windows build into .tools/supabase/ (first run only).
    B) winget install Supabase.CLI, then supabase is on PATH.
    C) Supabase Dashboard → Edge Functions → create/deploy from editor (no CLI):
       https://supabase.com/docs/guides/functions/quickstart-dashboard

  One-time auth (any method):
    supabase login
    # or set env: $env:SUPABASE_ACCESS_TOKEN = "sbp_..." from https://supabase.com/dashboard/account/tokens

  Usage:
    cd E:\improve\new_proj\new_project
    .\scripts\deploy_process_push_queue.ps1
    .\scripts\deploy_process_push_queue.ps1 -ProjectRef "tucjzlcvrcxvovfaxsuk"
#>
param(
  [string] $ProjectRef = "tucjzlcvrcxvovfaxsuk"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

function Get-SupabaseExecutable {
  $cmd = Get-Command supabase -ErrorAction SilentlyContinue
  if ($cmd) {
    return $cmd.Source
  }

  $cached = Join-Path $Root ".tools\supabase\supabase.exe"
  if (Test-Path $cached) {
    return $cached
  }

  Write-Host ""
  Write-Host "Supabase CLI not found. Downloading latest Windows amd64 build to .tools\supabase\ ..." -ForegroundColor Cyan
  Write-Host "(GitHub: supabase/cli releases, asset supabase_windows_amd64.tar.gz)" -ForegroundColor Gray
  Write-Host ""

  $dir = Split-Path $cached -Parent
  New-Item -ItemType Directory -Force -Path $dir | Out-Null

  $url = "https://github.com/supabase/cli/releases/latest/download/supabase_windows_amd64.tar.gz"
  $gz = Join-Path $dir "supabase_windows_amd64.tar.gz"
  Invoke-WebRequest -Uri $url -OutFile $gz -UseBasicParsing

  $extract = Join-Path $dir "_extract"
  if (Test-Path $extract) {
    Remove-Item $extract -Recurse -Force
  }
  New-Item -ItemType Directory -Force -Path $extract | Out-Null
  tar -xzf $gz -C $extract
  Remove-Item $gz -Force

  $exeFound = Get-ChildItem -Path $extract -Filter "supabase.exe" -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1
  if (-not $exeFound) {
    throw "Could not find supabase.exe inside the downloaded archive."
  }
  Move-Item -Force $exeFound.FullName $cached
  Remove-Item $extract -Recurse -Force

  Write-Host "Installed CLI at: $cached" -ForegroundColor Green
  return $cached
}

$supabase = Get-SupabaseExecutable

Write-Host "Deploying process-push-queue (project $ProjectRef) from $Root ..." -ForegroundColor Cyan
& $supabase functions deploy process-push-queue --project-ref $ProjectRef
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "If deploy failed with auth errors, run once:" -ForegroundColor Yellow
  Write-Host ('  Login once: "' + $supabase + '" login') -ForegroundColor White
  Write-Host "or set SUPABASE_ACCESS_TOKEN (sbp_...) then re-run this script." -ForegroundColor White
  exit $LASTEXITCODE
}

Write-Host "Done." -ForegroundColor Green
