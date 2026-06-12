"""Render synthetic facility photo cards as 800x600 JPGs.

Output: seed-data/parquet/output/facilities/<facility_id>.jpg

Each card is a deterministic gradient (colored by region) with the facility
monogram, name, region, and bed count overlaid. No real photography is used.
"""
from __future__ import annotations
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from shared._loader import load_ids  # noqa: E402

W, H = 800, 600

# Region -> (top RGB, bottom RGB) gradient palette
REGION_PALETTE = {
    "R-NORTH":   ((28, 56, 110),  (78, 144, 210)),
    "R-LOOP":    ((58, 28, 100),  (148, 84, 200)),
    "R-WEST":    ((96, 52, 18),   (212, 142, 64)),
    "R-SOUTH":   ((18, 88, 90),   (62, 188, 184)),
    "R-AIRPORT": ((40, 40, 48),   (118, 130, 150)),
}


def _font(size: int) -> ImageFont.ImageFont:
    """Try a few common Windows fonts, fall back to PIL default."""
    for name in ("seguisb.ttf", "segoeui.ttf", "arialbd.ttf", "arial.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def _gradient(top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    img = Image.new("RGB", (W, H), top)
    draw = ImageDraw.Draw(img)
    for y in range(H):
        t = y / (H - 1)
        r = int(top[0] + (bottom[0] - top[0]) * t)
        g = int(top[1] + (bottom[1] - top[1]) * t)
        b = int(top[2] + (bottom[2] - top[2]) * t)
        draw.line([(0, y), (W, y)], fill=(r, g, b))
    return img


def _monogram(name: str) -> str:
    parts = [p for p in name.replace("/", " ").split() if p[0].isalpha()]
    if len(parts) >= 2:
        return (parts[0][0] + parts[1][0]).upper()
    return (parts[0][:2] if parts else "??").upper()


def render(h: dict, region_name: str, out: Path) -> None:
    palette = REGION_PALETTE.get(h["regionId"], ((40, 40, 40), (120, 120, 120)))
    img = _gradient(*palette)
    draw = ImageDraw.Draw(img)

    # Translucent panel for legibility
    panel = Image.new("RGBA", (W - 80, H - 120), (0, 0, 0, 90))
    img.paste(panel, (40, 60), panel)

    # Monogram circle
    mono_size = 220
    mono_xy = (W // 2 - mono_size // 2, 110)
    draw.ellipse(
        [mono_xy, (mono_xy[0] + mono_size, mono_xy[1] + mono_size)],
        fill=(255, 255, 255, 230),
    )
    mono_font = _font(120)
    mono = _monogram(h["name"])
    bbox = draw.textbbox((0, 0), mono, font=mono_font)
    mw, mh = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text(
        (mono_xy[0] + (mono_size - mw) // 2 - bbox[0],
         mono_xy[1] + (mono_size - mh) // 2 - bbox[1]),
        mono, fill=palette[0], font=mono_font,
    )

    # Facility name
    name_font = _font(40)
    bbox = draw.textbbox((0, 0), h["name"], font=name_font)
    nw = bbox[2] - bbox[0]
    draw.text(((W - nw) // 2, 360), h["name"], fill="white", font=name_font)

    # Subtitle: region + type
    sub_font = _font(26)
    sub = f"{region_name}  •  {h['type']}  •  {h['beds']} beds"
    bbox = draw.textbbox((0, 0), sub, font=sub_font)
    sw = bbox[2] - bbox[0]
    draw.text(((W - sw) // 2, 420), sub, fill=(220, 220, 230), font=sub_font)

    # Footer ID badge
    id_font = _font(22)
    badge_text = f"Facility ID: {h['hospitalId']}  •  UrbanPulse"
    bbox = draw.textbbox((0, 0), badge_text, font=id_font)
    iw = bbox[2] - bbox[0]
    draw.text(((W - iw) // 2, 510), badge_text, fill=(180, 180, 200), font=id_font)

    out.parent.mkdir(parents=True, exist_ok=True)
    img.convert("RGB").save(out, "JPEG", quality=85, optimize=True)


def main() -> None:
    ids = load_ids()
    region_lookup = {r["regionId"]: r["name"] for r in ids["regions"]}

    out_dir = Path(__file__).resolve().parent / "output" / "facilities"
    out_dir.mkdir(parents=True, exist_ok=True)

    for h in ids["hospitals"]:
        out_path = out_dir / f"{h['hospitalId']}.jpg"
        render(h, region_lookup[h["regionId"]], out_path)
        print(f"  -> {out_path.relative_to(out_dir.parents[1])}  ({out_path.stat().st_size:,} bytes)")

    print(f"\nWrote {len(ids['hospitals'])} JPGs to {out_dir}")


if __name__ == "__main__":
    main()
