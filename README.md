# COD Tower Defense

A Call of Duty Zombies-inspired tower defense game that runs on Android, Linux, and in any browser.

## What's in this release

| File | Platform | Description |
|---|---|---|
| `codboz-td.apk` | Android | Installable app for phones/tablets (touch joysticks, tap-to-build) |
| `codboz-td-linux.zip` | Linux | Full game + launcher (keyboard + mouse controls) |
| `linux/` | Linux | Launcher, installer, and desktop-entry scripts |

## Android install

1. Download `codboz-td.apk` and open it on your phone.
2. Allow "install unknown apps" for your browser/file manager when prompted.
3. Launch **COD Tower Defense** from your app drawer.

## Linux install

```bash
unzip codboz-td-linux.zip
cd codboz-td
./linux/install.sh          # optional: adds it to your app menu
codboz-td                   # launch (starts a local server + opens your browser)
```

Quick launch without installing:

```bash
unzip codboz-td-linux.zip
cd codboz-td
./linux/codboz-td --port 8080
```

Options: `--native` opens a pywebview window instead of a browser; `CODBOZ_NO_OPEN=1` skips opening a browser.

## Controls (auto-detected)

- **Desktop:** WASD/arrow keys to move, mouse to aim, hold left-click to shoot, 1-9 to select build cards, Enter/Space to start a round, Esc to cancel/pause, G to cycle weapons, right-click to cancel a build.
- **Mobile:** virtual joysticks, tap to build, hold to shoot.

## Notes

- Fan-made project inspired by Call of Duty Zombies. Not affiliated with or endorsed by Activision.
- The game is a single-file web app; `index.html` inside the Linux zip can also be opened in any browser served over HTTP.
