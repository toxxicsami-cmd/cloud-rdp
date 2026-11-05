# keep-session.ps1 - local session keeper
# Polls the repo's session file; when the tunnel hostname changes (new box
# fired by the relay, or a watchdog restart), swaps the local cloudflared
# bridge underneath the running mstsc. Local port never changes, so the
# RDP client just reconnects to the same address.
param(
    [string]$Repo = "toxxicsami-cmd/cloud-rdp",
    [string]$BridgePort = "13389",
    [int]$PollSeconds = 60
)

$cf = Join-Path $env:LOCALAPPDATA "cloudflared.exe"
$log = Join-Path $env:TEMP "rdp-keeper.log"
$curHost = $null

function Log([string]$m) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m" | Add-Content -Path $log
}

if (-not (Test-Path $cf)) { Log "FATAL: cloudflared missing at $cf"; exit 1 }

Log "keeper started (repo=$Repo port=$BridgePort poll=${PollSeconds}s)"

while ($true) {
    try {
        $raw = (gh api "/repos/$Repo/contents/session/tunnel-url.txt" --jq ".content" 2>$null) -join ""
        if ($raw) {
            $txt = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(($raw -replace "`n", "")))
            $kv = @{}
            foreach ($line in ($txt -split "`n")) {
                if ($line -match '^([^=]+)=(.*)$') { $kv[$Matches[1]] = $Matches[2] }
            }
            $h = $kv['HOSTNAME']
            $status = $kv['TUNNEL_STATUS']

            if ($h -and $h -ne $curHost) {
                Log "hostname changed: '$curHost' -> '$h' (status=$status) - swapping bridge"
                Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                Start-Process -FilePath $cf `
                    -ArgumentList "access", "tcp", "--hostname", $h, "--url", "localhost:$BridgePort" `
                    -WindowStyle Hidden
                $curHost = $h
                Log "bridge now -> $h (localhost:$BridgePort)"
            } elseif ($status -eq "SESSION_ENDED" -and $curHost) {
                # session over, successor not published yet - keep old bridge,
                # it will die with the box; keeper swaps when the new URL lands
                Log "session ended, waiting for successor URL"
            }
        }
    } catch {
        Log "poll error: $($_.Exception.Message)"
    }
    Start-Sleep -Seconds $PollSeconds
}
