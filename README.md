# nouveau-va-browser

GPU video decoding in Firefox and Chromium-based browsers (Brave, Chromium) on older NVIDIA cards running the **nouveau** driver.

Out of the box, nouveau's VA-API driver decodes video fine in mpv, but browsers fall back to CPU decoding:

- **Firefox** can't import the decoded frames. nouveau keeps them as interlaced (field-split) surfaces, and VA-API export refuses those.
- **Chromium** also needs an ARGB output surface for its video converter, which nouveau doesn't offer.

On an old CPU that's the difference between smooth 1080p and a slideshow.

## What the patches do

All three are small changes to Mesa's VA-API frontend (`src/gallium/frontends/va`). The distro's Mesa is left alone.

| Patch | Change |
|---|---|
| 0001 | When an interlaced surface is exported, give the caller a progressive copy (the two fields woven together) and keep it current after each decode. Firefox works with this alone. |
| 0002 | If the driver lacks A8R8G8B8 for video processing, use B8G8R8A8 and export it with the ARGB fourcc. Lets Chromium's VA-API ImageProcessor start. |
| 0003 | Video processing reads the interlaced source directly and only weaves when Chromium re-imports a surface (removes an extra copy per frame). Also outputs limited-range for Chromium's ARGB path so highlights don't clip. The range part is a Chromium-specific workaround. |

## Tested on

- Quadro 600 (GF108, Fermi), Core 2 Quad Q9550, Linux Mint 22.1, kernel 7.0, Mesa 25.2.8, X11
- Firefox (VA-API, 1080p60 H.264, 0 dropped frames) and Brave 1.100 with h264ify (1080p, a few dropped frames)

Other nouveau cards with video decode (VP3+/VP4+ era) use the same code path, but I haven't tried them. Reports welcome.

You also need the video firmware for your card in `/lib/firmware/nouveau` (extracted from the NVIDIA blob, see the [nouveau VideoAcceleration page](https://nouveau.freedesktop.org/VideoAcceleration.html)). Most browsers only get H.264 from these cards, so use h264ify / enhanced-h264ify on YouTube.

## Build

Install the build dependencies (Debian/Ubuntu/Mint):

```
sudo apt install build-essential meson ninja-build pkg-config python3-mako python3-yaml \
  libdrm-dev libva-dev libx11-dev libx11-xcb-dev libxcb1-dev libxcb-dri3-dev libxcb-present-dev \
  libxcb-randr0-dev libxcb-shm0-dev libxcb-xfixes0-dev libxshmfence-dev libxext-dev libxfixes-dev \
  libxrandr-dev libxxf86vm-dev libexpat1-dev zlib1g-dev bison flex glslang-tools
```

Then:

```
./build.sh            # builds for the installed mesa-va-drivers version
sudo ./install.sh     # installs as nouveaupatched_drv_video.so next to the system driver
```

`build.sh 25.2.8` picks a version explicitly. Rebuild after every Mesa upgrade. If a patch stops applying, `build.sh` stops and says so.

## Use

The patched driver only loads when asked for by name, so nothing else on the system changes:

- **Firefox:** start it with `wrappers/firefox-gpu`, and in `about:config` set `media.hardware-video-decoding.force-enabled` and `media.ffmpeg.vaapi.enabled` to `true`.
- **Brave / Chromium:** `BROWSER=/usr/bin/brave-browser-stable wrappers/chromium-gpu`.

Check with `about:support` (Firefox, "HARDWARE_VIDEO_DECODING") or `brave://media-internals` (look for `VaapiVideoDecoder`).

To have every launcher use it, copy the wrapper to `~/.local/bin` and point the `Exec=` line of a copy of the browser's `.desktop` file in `~/.local/share/applications` at it.

Undo: `sudo ./install.sh --remove`.

## Credits

Made with Claude (Anthropic's AI model, via Claude Code), which wrote the patches and scripts; I tested them on the hardware. The aim is to get 0001 (and maybe 0002) into Mesa itself. Until then, this repo is the place for it.

Licensed MIT, like Mesa.
