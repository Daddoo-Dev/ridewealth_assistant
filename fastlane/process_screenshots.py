#!/usr/bin/env python3
"""Flatten PNG alpha and size tablet copies for Play Store."""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
PHONE = ROOT / "metadata/android/en-US/images/phoneScreenshots"
SEVEN = ROOT / "metadata/android/en-US/images/sevenInchScreenshots"
TEN = ROOT / "metadata/android/en-US/images/tenInchScreenshots"


def flatten(im: Image.Image) -> Image.Image:
    if im.mode == "RGB":
        return im
    bg = Image.new("RGB", im.size, (255, 255, 255))
    if im.mode == "RGBA":
        bg.paste(im, mask=im.split()[-1])
        return bg
    return im.convert("RGB")


def contain(im: Image.Image, size: tuple[int, int]) -> Image.Image:
    tw, th = size
    scale = min(tw / im.width, th / im.height)
    resized = im.resize(
        (max(1, round(im.width * scale)), max(1, round(im.height * scale))),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGB", size, (255, 255, 255))
    left = (tw - resized.width) // 2
    top = (th - resized.height) // 2
    canvas.paste(resized, (left, top))
    return canvas


def main() -> None:
    sources = sorted(PHONE.glob("*.png"))
    if not sources:
        raise SystemExit(f"No screenshots in {PHONE}")

    SEVEN.mkdir(parents=True, exist_ok=True)
    TEN.mkdir(parents=True, exist_ok=True)

    for src in sources:
        rgb = flatten(Image.open(src))
        rgb.save(src, "PNG")
        contain(rgb, (1200, 1920)).save(SEVEN / src.name, "PNG")
        contain(rgb, (1600, 2560)).save(TEN / src.name, "PNG")
        print(src.name)

    print(f"Processed {len(sources)} screenshot(s)")


if __name__ == "__main__":
    main()
