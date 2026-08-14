"""Author the 1920x1080 /play/ start still from the original battlefield painting.

Live Godot Controls own the menu. Bright baked glyphs are replaced with a
local median so title/buttons are not drawn twice.
"""
from __future__ import annotations

import os
import subprocess
from pathlib import Path

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SOURCE_REV = "0bf8270"
SOURCE_PATH = "game/assets/ui/start_background.jpg"
OUT_GAME = ROOT / "game" / "assets" / "ui" / "start_background.jpg"
OUT_PROV = ROOT / "assets" / "play-start-background.jpg"
TW, TH = 1920, 1080


def _load_original() -> Image.Image:
	data = subprocess.check_output(["git", "show", f"{SOURCE_REV}:{SOURCE_PATH}"], cwd=ROOT)
	tmp = Path(os.environ.get("TEMP", "/tmp")) / "ff_orig_start.jpg"
	tmp.write_bytes(data)
	return Image.open(tmp).convert("RGB")


def _kill_glyphs(im: Image.Image) -> Image.Image:
	med = im.filter(ImageFilter.MedianFilter(9))
	w, h = im.size
	src = im.load()
	ref = med.load()
	out = im.copy()
	dst = out.load()
	x0, x1 = int(w * 0.08), int(w * 0.92)
	for y in range(h):
		for x in range(x0, x1):
			o = src[x, y]
			m = ref[x, y]
			ol = 0.3 * o[0] + 0.59 * o[1] + 0.11 * o[2]
			ml = 0.3 * m[0] + 0.59 * m[1] + 0.11 * m[2]
			if ol > ml + 20:
				dst[x, y] = m
	return out


def _cover_1920(im: Image.Image) -> Image.Image:
	w, h = im.size
	scale = max(TW / w, TH / h)
	nw, nh = int(w * scale + 0.5), int(h * scale + 0.5)
	scaled = im.resize((nw, nh), Image.Resampling.LANCZOS)
	left = max(0, (nw - TW) // 2)
	top = max(0, (nh - TH) // 2)
	return scaled.crop((left, top, left + TW, top + TH))


def main() -> None:
	canvas = _cover_1920(_kill_glyphs(_load_original()))
	OUT_GAME.parent.mkdir(parents=True, exist_ok=True)
	OUT_PROV.parent.mkdir(parents=True, exist_ok=True)
	for dest in (OUT_GAME, OUT_PROV):
		canvas.save(dest, "JPEG", quality=90, optimize=True, subsampling=1)
	print("wrote", canvas.size, OUT_GAME, OUT_GAME.stat().st_size)


if __name__ == "__main__":
	main()
