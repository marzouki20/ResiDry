param(
    [int]$Port=8766,
    [int]$AiPort=8765,
    [string]$Model='gemma3:4b',
    [ValidateSet('127.0.0.1','0.0.0.0')][string]$Bind='127.0.0.1'
)
$ErrorActionPreference='Stop'
Set-Location -LiteralPath $PSScriptRoot
if (Get-NetTCPConnection -LocalPort $Port,$AiPort -State Listen -ErrorAction SilentlyContinue) { throw 'Stop the existing ResiDry services before starting this configuration.' }
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) { throw 'Install Ollama from https://ollama.com/download/windows first, then download the vision model using: ollama pull gemma3:4b' }
& ollama show $Model *> $null
if ($LASTEXITCODE -ne 0) { throw "Start Ollama and download the model first: ollama pull $Model" }
$env:AI_PROVIDER='ollama'
$env:OLLAMA_URL='http://127.0.0.1:11434'
$env:OLLAMA_VISION_MODEL=$Model
$env:REGISTRATION_DEV_TOKEN=[guid]::NewGuid().ToString('N')
$env:PORT=[string]$AiPort
$env:VERIFICATION_BIND='127.0.0.1'
$env:RESIDRY_BIND=$Bind
$env:RESIDRY_AI_DOSSIER_URL="http://127.0.0.1:$AiPort/verify-dossier"
$serviceScript=Join-Path (Split-Path $PSScriptRoot -Parent) 'server\registration_service.py'
$aiProcess=Start-Process -FilePath (Get-Command python).Source -ArgumentList @('"'+$serviceScript+'"') -WindowStyle Hidden -PassThru
try { & "$PSScriptRoot\start-local.ps1" -Port $Port }
finally { if (-not $aiProcess.HasExited) { Stop-Process -Id $aiProcess.Id }; Remove-Item Env:REGISTRATION_DEV_TOKEN -ErrorAction SilentlyContinue }
