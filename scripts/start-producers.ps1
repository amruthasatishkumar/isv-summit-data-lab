<#
.SYNOPSIS
    Starts the three Event Hub simulators for the UrbanPulse Data Lab.

.DESCRIPTION
    Loads connection strings from .env.local in the repo root, then opens
    three new PowerShell windows - one per simulator - so you can monitor
    them and stop any of them independently.

    Run this once at the start of the lab session. Each simulator runs
    for SIM_DURATION_SECONDS (default 8h). Re-run to relaunch.

.EXAMPLE
    .\scripts\start-producers.ps1

.EXAMPLE
    # Short burst for a smoke test (60 seconds):
    $env:SIM_DURATION_SECONDS = 60
    .\scripts\start-producers.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# --- Locate repo root (parent of scripts/) ---
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $repoRoot

# --- Load .env.local ---
$envFile = Join-Path $repoRoot '.env.local'
if (-not (Test-Path $envFile)) {
    throw ".env.local not found at $envFile. Create it from the README before running."
}

Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if (-not $line -or $line.StartsWith('#')) { return }
    $eq = $line.IndexOf('=')
    if ($eq -lt 1) { return }
    $name  = $line.Substring(0, $eq).Trim()
    $value = $line.Substring($eq + 1).Trim()
    Set-Item -Path "env:$name" -Value $value
}

# --- Sanity check ---
$required = @(
    'EVENTHUB_VITALS_CONN_STR',
    'EVENTHUB_MOVEMENT_CONN_STR',
    'EVENTHUB_TRAIN_CONN_STR'
)
foreach ($v in $required) {
    if (-not (Get-Item "env:$v" -ErrorAction SilentlyContinue).Value) {
        throw "Missing $v in .env.local"
    }
}

if (-not $env:SIM_DURATION_SECONDS) {
    $env:SIM_DURATION_SECONDS = '28800'   # 8h default
}

Write-Host ""
Write-Host "Launching 3 simulators against rtidemo Event Hubs..." -ForegroundColor Cyan
Write-Host "  Duration per simulator: $($env:SIM_DURATION_SECONDS) seconds"
Write-Host "  Repo root            : $repoRoot"
Write-Host ""

# --- Spawn 3 windows, one per simulator ---
$pythonExe = (Get-Command python).Source

$jobs = @(
    @{ Title='SIM · medicalvitals';   Script='seed-data\eventhub\simulate_medicalvitals.py';   ConnVar='EVENTHUB_VITALS_CONN_STR'   },
    @{ Title='SIM · medicalmovement'; Script='seed-data\eventhub\simulate_medicalmovement.py'; ConnVar='EVENTHUB_MOVEMENT_CONN_STR' },
    @{ Title='SIM · metrotrain';      Script='seed-data\eventhub\simulate_metrotrain.py';      ConnVar='EVENTHUB_TRAIN_CONN_STR'    }
)

foreach ($j in $jobs) {
    $connValue = (Get-Item "env:$($j.ConnVar)").Value
    $cmd = @"
`$Host.UI.RawUI.WindowTitle = '$($j.Title)';
`$env:$($j.ConnVar) = '$connValue';
`$env:SIM_DURATION_SECONDS = '$($env:SIM_DURATION_SECONDS)';
Set-Location '$repoRoot';
& '$pythonExe' '$($j.Script)';
Write-Host '';
Write-Host 'Simulator exited. Press any key to close...' -ForegroundColor Yellow;
[void][System.Console]::ReadKey(`$true);
"@

    Start-Process powershell -ArgumentList @(
        '-NoExit',
        '-NoProfile',
        '-Command', $cmd
    ) | Out-Null

    Write-Host "  -> launched $($j.Title)" -ForegroundColor Green
    Start-Sleep -Milliseconds 400   # stagger so output is readable
}

Write-Host ""
Write-Host "All three simulators launched in their own windows." -ForegroundColor Cyan
Write-Host "Close any window to stop that one simulator. Ctrl+C inside the window also works."
