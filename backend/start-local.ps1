param([int]$Port = 8766)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
if (-not $env:JAVA_HOME) {
    $jdkPath = Join-Path $env:USERPROFILE '.jdks\jbr-17.0.14'
    if (Test-Path -LiteralPath (Join-Path $jdkPath 'bin\java.exe')) { $env:JAVA_HOME = $jdkPath }
    else { throw 'Set JAVA_HOME to your Java 17 or later JDK.' }
}
if (-not $env:RESIDRY_ADMIN_EMAIL) { $env:RESIDRY_ADMIN_EMAIL = Read-Host 'Administrator email' }
if (-not $env:RESIDRY_ADMIN_PASSWORD) {
    $adminSecret = Read-Host 'Administrator password (at least 12 characters)' -AsSecureString
    $env:RESIDRY_ADMIN_PASSWORD = [System.Net.NetworkCredential]::new('', $adminSecret).Password
    Remove-Variable adminSecret
}
$env:RESIDRY_PORT = [string]$Port
& .\mvnw.cmd -q -DskipTests package
if ($LASTEXITCODE -ne 0) { throw 'Backend compilation failed.' }
& (Join-Path $env:JAVA_HOME 'bin\java.exe') -jar target\residry-backend-0.1.0.jar
