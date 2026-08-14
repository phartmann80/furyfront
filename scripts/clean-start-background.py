"""Author a sharp 1920x1080 play-start plate from the generated battlefield.

No baked menu. Smoke in the menu zone is the painting itself, darkened and
softened, so live Controls sit in atmosphere instead of on a second layer.
"""
from __future__ import annotations

import random
import shutil
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SRC_CURSOR = Path(r"C:\Users\hartm\.cursor\projects\c-Users-hartm-furyfront\assets\play-start-battlefield.png")
SRC_REPO = ROOT / "assets" / "play-start-battlefield.png"
OUT_GAME = ROOT / "game" / "assets" / "ui" / "start_background.jpg"
OUT_PROV = ROOT / "assets" / "play-start-background.jpg"
TW, TH = 1920, 1080


def _cover(im: Image.Image) -> Image.Image:
	w, h = im.size
	scale = max(TW / w, TH / h)
	nw, nh = int(w * scale + 0.5), int(h * scale + 0.5)
	scaled = im.convert("RGB").resize((nw, nh), Image.Resampling.LANCZOS)
	left = max(0, (nw - TW) // 2)
	extra = max(0, nh - TH)
	top = int(extra * 0.28)  # keep sandbags / soldier
	return scaled.crop((left, top, left + TW, top + TH))


def _menu_haze(canvas: Image.Image) -> Image.Image:
	"""Thicken the existing smoke where the centered menu lives."""
	smoky = ImageEnhance.Brightness(canvas.filter(ImageFilter.GaussianBlur(18))).enhance(0.62)
	smoky = ImageEnhance.Color(smoky).enhance(0.75)
	mask = Image.new("L", (TW, TH), 0)
	d = ImageDraw.Draw(mask)
	d.ellipse((int(TW * 0.16), int(TH * 0.08), int(TW * 0.84), int(TH * 0.78)), fill=255)
	mask = mask.filter(ImageFilter.GaussianBlur(90))
	mask = ImageEnhance.Brightness(mask).enhance(0.72)
	return Image.composite(smoky, canvas, mask)


def _vignette(canvas: Image.Image) -> Image.Image:
	v = Image.new("L", (TW, TH), 0)
	ImageDraw.Draw(v).ellipse((-int(TW * 0.08), -int(TH * 0.12), int(TW * 1.08), int(TH * 1.18)), fill=255)
	v = ImageChops.invert(v.filter(ImageFilter.GaussianBlur(150)))
	v = ImageEnhance.Brightness(v).enhance(0.22)
	edge = ImageEnhance.Brightness(canvas).enhance(0.55)
	return Image.composite(edge, canvas, v)


def _grain(canvas: Image.Image) -> Image.Image:
	rnd = random.Random(17)
	gw, gh = TW // 2, TH // 2
	g = Image.new("L", (gw, gh))
	px = g.load()
	for y in range(gh):
		for x in range(gw):
			px[x, y] = rnd.randint(118, 138)
	g = g.resize((TW, TH), Image.Resampling.BILINEAR)
	return Image.blend(canvas, Image.merge("RGB", (g, g, g)), 0.045)


def main() -> None:
	src = SRC_REPO if SRC_REPO.exists() else SRC_CURSOR
	if not src.exists():
		raise SystemExit(f"missing generated still: {src}")
	if src != SRC_REPO:
		SRC_REPO.parent.mkdir(parents=True, exist_ok=True)
		shutil.copy2(src, SRC_REPO)
	canvas = _grain(_vignette(_menu_haze(_cover(Image.open(src)))))
	OUT_GAME.parent.mkdir(parents=True, exist_ok=True)
	for dest in (OUT_GAME, OUT_PROV):
		canvas.save(dest, "JPEG", quality=92, optimize=True, subsampling=1)
	print("wrote", canvas.size, OUT_GAME, OUT_GAME.stat().st_size)


if __name__ == "__main__":
	main()
