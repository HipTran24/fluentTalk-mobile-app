$ErrorActionPreference = "Continue"
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  Dang khoi dong FluentTalk Backend Server..." -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# Tu dong giai phong cong 8080 neu co tien trinh cu treo
try {
    $connections = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
    foreach ($conn in $connections) {
        if ($conn.OwningProcess -gt 0) {
            Write-Host "Giai phong cong 8080 (PID: $($conn.OwningProcess))..." -ForegroundColor Yellow
            Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
        }
    }
} catch {
    # Netstat fallback
    $netstat = netstat -aon | Select-String ":8080\s+LISTENING"
    foreach ($line in $netstat) {
        $parts = $line.ToString().Trim() -split '\s+'
        $pidToKill = $parts[-1]
        if ($pidToKill -and $pidToKill -as [int]) {
            Stop-Process -Id ([int]$pidToKill) -Force -ErrorAction SilentlyContinue
        }
    }
}

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$envPath = Join-Path $root "config\backend.private.env"

if (-not (Test-Path $envPath)) {
    Write-Host "[LOI] Khong tim thay file $envPath" -ForegroundColor Red
    Read-Host "Nhan Enter de thoat..."
    exit 1
}

# Load environment variables from backend.private.env
Get-Content $envPath | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#") -and ($line -match '^([^=]+)=(.*)$')) {
        $key = $matches[1].Trim()
        $val = $matches[2].Trim()
        if ($val.StartsWith('"') -and $val.EndsWith('"')) {
            $val = $val.Substring(1, $val.Length - 2)
        }
        if ($val.StartsWith("'") -and $val.EndsWith("'")) {
            $val = $val.Substring(1, $val.Length - 2)
        }
        [System.Environment]::SetEnvironmentVariable($key, $val, "Process")
    }
}

# Determine Java binary
$javaPath = "java"
if (Test-Path "C:\Program Files\Java\jdk-22\bin\java.exe") {
    $javaPath = "C:\Program Files\Java\jdk-22\bin\java.exe"
} elseif ($env:JAVA_HOME -and (Test-Path "$env:JAVA_HOME\bin\java.exe")) {
    $javaPath = "$env:JAVA_HOME\bin\java.exe"
}

$jarPath = Join-Path $root "backend\target\backend-0.1.0-SNAPSHOT.jar"
if (-not (Test-Path $jarPath)) {
    Write-Host "[THONG BAO] Chua co file jar, dang build backend..." -ForegroundColor Yellow
    Push-Location (Join-Path $root "backend")
    & ".\mvnw.cmd" package -DskipTests
    Pop-Location
}

Write-Host "Chay Backend voi: $javaPath" -ForegroundColor Green
Set-Location $root
& $javaPath -Xmx512m -jar $jarPath
