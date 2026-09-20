# ChromeDocker

Spin up a **throwaway Chrome inside a Docker container** and use it in your
Mac's own browser over noVNC. Nothing touches your host Chrome, Keychain, or
profile — stop the container and every trace of the session is gone.

It's a single self-contained Bash script — nothing to build or install.

![Throwaway Chrome running in a Docker container, viewed in the browser](./readme_images/02-chrome.png)

---

## What This Tool Does

The World Wide Web promises a lot of things, but your privacy is not one of
them — your data is **not** secure. Every site you touch is quietly building a
picture of you: browser fingerprinting stitches together your screen size,
fonts, timezone, GPU, and dozens of other signals into an identifier that
follows you even with cookies cleared and a VPN on. Cookies, trackers, cached
logins, and leftover extensions all bleed state between sessions and hand it
straight to advertisers, data brokers, and anyone snooping in between. Your
normal browser remembers everything, and so does everyone watching it.

ChromeDocker flips that on its head. It's a brand-new, sandboxed Chrome that
leaves **zero footprint** on your real machine — a throwaway session with no
history to mine and nothing to leak back to your daily profile. That's useful
for a lot more than it first sounds:

- **Private / clean browsing** — a genuinely fresh profile with no cookies,
  history, extensions, or saved logins bleeding in from your daily browser.
  Close it and it's gone.
- **Crypto & MetaMask** — keep wallet extensions and dApp sessions fully
  isolated from your everyday browsing, so a compromised site or extension on
  your main profile can't reach them (and vice-versa). Destroy the container to
  wipe the session cleanly.
- **Security / SecOps work** — open suspicious links, phishing pages, or
  untrusted downloads inside a disposable container instead of on your host.
  Blast radius is the container, not your Mac.
- **Account isolation** — run a separate work, client, or throwaway Google
  account without profile-juggling or signing in and out.
- **Gaming & web apps** — a clean, dedicated session for browser games or
  web apps that you don't want tangled up with your main profile's cookies.
- **Shared / public machines** — spin up a private session on a library,
  lab, or shared computer and leave nothing behind when you stop it.
- **Testing & development** — a pristine browser for reproducing bugs,
  testing extensions, or checking a site with none of your own state cached.

---

## Quick start

```bash
bash chromedocker.sh          # start (or reattach if already running)
bash chromedocker.sh stop     # kill the container — everything inside is destroyed
bash chromedocker.sh restart  # stop + fresh start
bash chromedocker.sh status   # is it running?
bash chromedocker.sh down     # stop container AND shut down the Colima VM
```

Once it's up, the container's Chrome opens at **https://localhost:6901**
(self-signed cert — click through the browser warning).

Login: user `kasm_user`, password `password`.

### In action

```console
$ bash chromedocker.sh
==> Pulling kasmweb/chrome:1.16.0 (skips if cached)...
==> Starting throwaway Chrome container...
==> Waiting for Chrome UI on https://localhost:6901.
================================================================
  Throwaway Chrome is up:  https://localhost:6901
  Login:  kasm_user  /  password
  (Self-signed cert: click through the browser warning.)

  Stop & destroy:  bash chromedocker.sh stop
================================================================
```

---

## How it works

- Runs the [`kasmweb/chrome`](https://hub.docker.com/r/kasmweb/chrome) image,
  which packages Chrome + a noVNC server.
- Binds the noVNC UI to **`127.0.0.1:6901` only** — not exposed to your network.
- Starts the container with `--rm`, so stopping it destroys the container and
  everything inside (profile, cookies, history, downloads).
- Auto-starts a Docker daemon if one isn't running — preferring
  [Colima](https://github.com/abiosoft/colima), falling back to Docker Desktop.

---

## Configuration

Edit the variables at the top of the script:

| Variable | Default | Meaning |
| --- | --- | --- |
| `IMAGE` | `kasmweb/chrome:1.16.0` | Container image / Chrome version |
| `PORT` | `6901` | Local port the noVNC UI is bound to (127.0.0.1 only) |
| `VNC_PW` | `password` | noVNC login password |
| `SHM` | `512m` | Shared-memory size for Chrome |
| `COLIMA_CPU` / `COLIMA_MEM` | `4` / `6` | Colima VM sizing (only if Colima isn't already running) |

> **Tip:** if Chrome's page renderer crashes with `Aw, Snap! (SIGSEGV)`, bump
> `SHM` to `1g` or `2g` — Chrome needs more shared memory than the default under
> some virtualised setups.

---

## Requirements

- macOS
- Docker, via **Colima** (`brew install colima docker`) **or** Docker Desktop

The first run pulls the `kasmweb/chrome` image (~2 GB), so give it a minute.
Subsequent starts are fast.

---

## Notes

- The self-signed TLS cert on `localhost:6901` is expected — click through the
  warning once.
- `down` also stops the Colima VM, freeing the CPU/RAM it reserved. Use it when
  you're done for the day; use `stop` if you'll spin Chrome up again shortly.

<br />
<br />

<div align="center">
  <a href="https://techangelx.com" target="_blank">
    <img src="./readme_images/logo.png" alt="Tech Angel X Logo" width="70" height="70" style="vertical-align: middle; border-radius: 50%; border: 4px solid #ffffff; box-shadow: 0 4px 10px rgba(0,0,0,0.2);">
  </a>
  <br /><br />
  <span style="font-size: 1.4em; font-weight: 300;">
    Built by Ricki Angel • <a href="https://techangelx.com" target="_blank" style="text-decoration: none;">Tech Angel X</a>
  </span>
</div>
