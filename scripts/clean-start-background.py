"""Author the 1920x1080 /play/ start still from clean cinematic art.

Do not use the user battlefield mockup at runtime — that JPEG has menu
chrome baked into the pixels and already ghosts. This plate is
`assets/rear_over_elite_squad.webp` (operators advancing on the breach).
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "rear_over_elite_squad.webp"
OUT_GAME = ROOT / "game" / "assets" / "ui" / "start_background.jpg"
OUT_PROV = ROOT / "assets" / "play-start-background.jpg"
TW, TH = 1920, 1080


def cover(im: Image.Image) -> Image.Image:
	w, h = im.size
	scale = max(TW / w, TH / h)
	nw, nh = int(w * scale + 0.5), int(h * scale + 0.5)
	scaled = im.convert("RGB").resize((nw, nh), Image.Resampling.LANCZOS)
	left = max(0, (nw - TW) // 2)
	top = max(0, (nh - TH) // 2)
	return scaled.crop((left, top, left + TW, top + TH))


def main() -> None:
	if not SRC.exists():
		raise SystemExit(f"missing {SRC}")
	canvas = cover(Image.open(SRC))
	OUT_GAME.parent.mkdir(parents=True, exist_ok=True)
	for dest in (OUT_GAME, OUT_PROV):
		canvas.save(dest, "JPEG", quality=90, optimize=True, subsampling=1)
	print("wrote", canvas.size, OUT_GAME, OUT_GAME.stat().st_size)


if __name__ == "__main__":
	main()
