# Cloud RDP from GitHub Actions

Full Windows Server 2022 desktop with real internet, running on GitHub's runners, reached through a Cloudflare tunnel. Free tier: 2000 minutes/month, 6 hours per session.

Specs per session: 4 vCPU, 16 GB RAM, 14 GB SSD, Windows Server 2022 Datacenter, full outbound internet.

## Deploy (3 minutes)

1. Create a new **private** repo on github.com — name it anything, e.g. `cloud-rdp`
2. Upload the contents of this folder so the workflow lands at:
   `.github/workflows/windows-rdp.yml`
3. Repo → **Actions** → select **WINDOWS RDP - CLOUDFLARE** → **Run workflow**
4. Optional: set your own password in the prompt (default `CloudRdp2026!`)
5. Wait 1–2 minutes. Open the run, the **Print connection details** step shows:

```
Tunnel URL : https://xxxx-xxxx.trycloudflare.com
Username   : runneradmin
Password   : <yours>
```

The same info is on the run's **Summary** page.

## Connect

From the PC you're sitting at:

```bat
connect-rdp.bat
```

Paste the tunnel hostname when asked. It downloads cloudflared if missing, opens the local bridge, then launches `mstsc`.

Manual version:

```bat
cloudflared access tcp --hostname xxxx-xxxx.trycloudflare.com --url localhost:13389
mstsc /v:localhost:13389
```

Login: `runneradmin` / your password.

Keep the cloudflared window open for the whole session — kill it and the bridge drops.

## Phone

1. Run `connect-rdp.bat` on a PC in your LAN, but change `localhost:13389` to `0.0.0.0:13389`
2. Allow the port: `New-NetFirewallRule -DisplayName "cf-rdp" -Direction Inbound -LocalPort 13389 -Protocol TCP -Action Allow`
3. On the phone: Microsoft Remote Desktop → PC name `192.168.x.x:13389` → same credentials

## Session rules

| Thing | Limit |
|---|---|
| Max session | 6 hours (360 min), set via `session_minutes` input |
| Monthly quota | 2000 Actions minutes on free tier — that's ~5 full sessions |
| Data | wiped when the run ends, nothing persists |
| Concurrency | one run at a time is polite; free tier allows 20 |

To end early: Actions → open the run → **Cancel**.

## Notes

- Tunnel URL is random per session and dies with the run — it changes every time you start a new one.
- Don't push secrets into this repo; the password goes through the workflow input, not a file.
- Free GitHub accounts get 2000 minutes/month. Windows minutes burn at 2x, so realistically ~1000 minutes of Windows time = roughly 2–3 six-hour sessions per month before you'd want a second account or a paid plan.
- Runner bandwidth on GitHub's network is genuinely fast — several hundred Mbps to low Gbps in most regions. Browsing and downloads feel like a datacenter box because it is one.
