param([int]$Port = 8766, [int]$AiPort = 8765, [string]$Model = 'gpt-4.1')
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) { throw "Stop the existing ResiDry backend on port $Port first." }
if (Get-NetTCPConnection -LocalPort $AiPort -State Listen -ErrorAction SilentlyContinue) { throw "Port $AiPort is already in use." }
if (-not $env:OPENAI_API_KEY) {
    $aiSecret = Read-Host 'New OpenAI API key (hidden)' -AsSecureString
    $env:OPENAI_API_KEY = [System.Net.NetworkCredential]::new('', $aiSecret).Password
    Remove-Variable aiSecret
}
if (-not $env:OPENAI_API_KEY) { throw 'An API key is required.' }
$env:OPENAI_VISION_MODEL = $Model
$env:REGISTRATION_DEV_TOKEN = [guid]::NewGuid().ToString('N')
$env:PORT = [string]$AiPort
$env:RESIDRY_AI_DOSSIER_URL = "http://127.0.0.1:$AiPort/verify-dossier"
$pythonExe = (Get-Command python).Source
$serviceScript = Join-Path (Split-Path $PSScriptRoot -Parent) 'server\registration_service.py'
$aiProcess = Start-Process -FilePath $pythonExe -ArgumentList @('"' + $serviceScript + '"') -WindowStyle Hidden -PassThru
try {
    & "$PSScriptRoot\start-local.ps1" -Port $Port
} finally {
    if (-not $aiProcess.HasExited) { Stop-Process -Id $aiProcess.Id }
    Remove-Item Env:OPENAI_API_KEY -ErrorAction SilentlyContinue
    Remove-Item Env:REGISTRATION_DEV_TOKEN -ErrorAction SilentlyContinue
}
