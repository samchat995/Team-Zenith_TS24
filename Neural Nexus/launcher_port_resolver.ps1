# Neural Nexus Launcher Port Resolver
# Determines port availability, checks for existing active instances (Python or Flutter),
# safely cleans up dead/stale processes, and protects unrelated applications by falling back to alternate ports.

param (
    [int]$PreferredPort = 8080
)

$targetPort = $PreferredPort
$action = "USE_PORT"
$resolvedPort = $PreferredPort

function Test-PortOccupied([int]$port) {
    $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    if ($conn) {
        return $conn[0]
    }
    return $null
}

function Test-NeuralNexusServing([int]$port) {
    $testUrls = @("http://127.0.0.1:$port/", "http://localhost:$port/")
    foreach ($u in $testUrls) {
        try {
            $client = [System.Net.WebClient]::new()
            $client.Headers.Add("User-Agent", "NeuralNexusLauncher")
            $content = $client.DownloadString($u)
            $client.Dispose()
            if ($content -match "NEURAL NEXUS" -or $content -match "Neural Nexus") {
                return $true
            }
        } catch {
            # Try next url
        }
    }
    return $false
}

$listener = Test-PortOccupied $targetPort

if ($listener) {
    $pidNum = $listener.OwningProcess
    $proc = Get-Process -Id $pidNum -ErrorAction SilentlyContinue
    $pname = if ($proc) { $proc.ProcessName } else { "Unknown" }

    # 1. Check if it is ALREADY an active, responding Neural Nexus patient web app
    if (Test-NeuralNexusServing $targetPort) {
        Write-Host "[INFO] Port $targetPort is actively serving the NEURAL NEXUS patient app (PID: $pidNum - $pname)."
        Write-Host "[INFO] Reusing active server instance. Opening browser..."
        try {
            Start-Process "http://localhost:$targetPort"
        } catch {}
        Write-Output "ACTION=REUSE"
        Write-Output "PORT=$targetPort"
        exit 0
    }

    # 2. Check if this process belongs to Flutter or Dart (stale/broken instance)
    $ppath = if ($proc -and $proc.Path) { $proc.Path } else { "" }
    $isDartOrFlutter = ($pname -match "^(dart|dartvm|flutter)$") -or ($ppath -like "*\flutter\*" -or $ppath -like "*\dart*")

    if ($isDartOrFlutter) {
        Write-Host "[WARN] Port $targetPort is held by a stale $pname process (PID: $pidNum). Safely terminating it..."
        try {
            Stop-Process -Id $pidNum -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
        } catch {
            Write-Host "[ERROR] Could not stop process $($pidNum): $($_.Exception.Message)"
        }

        # Verify port is now free
        $recheck = Test-PortOccupied $targetPort
        if (-not $recheck) {
            Write-Host "[OK] Stale process terminated. Port $targetPort is now available."
            Write-Output "ACTION=USE_PORT"
            Write-Output "PORT=$targetPort"
            exit 0
        }
    }

    # 3. Port is occupied by an UNRELATED application (or cannot be freed).
    # DO NOT terminate it! Find the next free port (starting at 8081).
    Write-Host "[WARN] Port $targetPort is occupied by unrelated process '$pname' (PID: $pidNum)."
    Write-Host "[INFO] Preserving unrelated application. Scanning for next available port..."

    $candidate = $PreferredPort + 1
    while ($candidate -le ($PreferredPort + 50)) {
        $check = Test-PortOccupied $candidate
        if (-not $check) {
            $resolvedPort = $candidate
            break
        }
        $candidate++
    }

    Write-Host "[OK] Using available fallback port: $resolvedPort"
    Write-Output "ACTION=USE_PORT"
    Write-Output "PORT=$resolvedPort"
    exit 0
} else {
    Write-Host "[OK] Port $targetPort is free."
    Write-Output "ACTION=USE_PORT"
    Write-Output "PORT=$targetPort"
    exit 0
}
