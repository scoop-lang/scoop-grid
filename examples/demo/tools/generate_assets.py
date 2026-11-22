"""Rebuild the original geometric demo artwork; Pillow is needed only here."""

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ASSETS = Path(__file__).resolve().parents[1] / "assets"
FONT = Path("/System/Library/Fonts/Avenir Next.ttc")


def font(size):
    if FONT.exists():
        return ImageFont.truetype(str(FONT), size)
    return ImageFont.load_default(size=size)


def covers():
    palettes = [
        ("#243e42", "#8fbc9b", "#eedbb9"),
        ("#abd9eb", "#3c74ab", "#f7edcf"),
        ("#ed8080", "#782564", "#f8cab4"),
        ("#8a6c4f", "#343943", "#e0cbb0"),
        ("#dc5b65", "#641f45", "#efb7ae"),
        ("#284d87", "#b06139", "#f3c653"),
        ("#dec5a0", "#b87049", "#425d56"),
        ("#e6ad47", "#984c38", "#f5dfa9"),
        ("#322e68", "#a580c7", "#e998bb"),
        ("#233a61", "#668aa0", "#eac994"),
    ]
    titles = [
        "DREAMS / OF YOU",
        "BLUE SKIES",
        "HEAVEN",
        "LIFE MATTERS",
        "LONELY / HEARTS",
        "IMAGINARY / GROOVE",
        "DESERT / BLOOM",
        "GOLDEN DAZE",
        "FRAGMENTS",
        "SOLSTICE CITY",
    ]
    destination = ASSETS / "covers"
    destination.mkdir(parents=True, exist_ok=True)
    for index, (background, accent, light) in enumerate(palettes):
        image = Image.new("RGB", (320, 320), background)
        draw = ImageDraw.Draw(image)
        if index in (0, 3, 6, 7):
            draw.ellipse((176, 56, 278, 158), fill=light)
            for layer in range(3):
                points = [(0, 320), (0, 173 + layer * 35)]
                points += [
                    (x, 169 + layer * 35 + int(28 * math.sin(x / 75 + layer + index)))
                    for x in range(0, 321, 8)
                ]
                points += [(320, 320)]
                draw.polygon(points, fill=[accent, background, light][layer])
        elif index in (1, 2, 4):
            for ring in range(8, 0, -1):
                radius = ring * 24
                draw.ellipse(
                    (160 - radius, 165 - radius, 160 + radius, 165 + radius),
                    fill=[background, accent, light][ring % 3],
                )
            draw.rectangle((0, 239, 320, 320), fill=background)
        elif index == 5:
            for x in range(20, 321, 42):
                draw.rounded_rectangle(
                    (x, 80, x + 21, 260 - x // 3), radius=10, fill=light if x % 3 else accent
                )
        elif index == 8:
            for x in range(0, 320, 64):
                for y in range(70, 320, 55):
                    draw.polygon(
                        [(x, y), (x + 61, y + 11), (x + 24, y + 64)],
                        fill=light if (x + y) % 3 else accent,
                    )
        else:
            draw.ellipse((180, 69, 243, 132), fill=light)
            for x in range(0, 320, 28):
                top = 153 + (x * 13) % 90
                draw.rectangle((x, top, x + 22, 320), fill=accent)
                for y in range(top + 9, 304, 17):
                    draw.rectangle((x + 5, y, x + 8, y + 4), fill=light)
        draw.rectangle((16, 16, 304, 60), fill=background)
        draw.text((22, 23), titles[index], fill=light, font=font(17))
        draw.text(
            (22, 294),
            f"SCOOP RECORDS   /   0{index + 1}",
            fill=accent if index == 1 else light,
            font=font(10),
        )
        image.save(destination / f"{index}.png", optimize=True)


def avatars():
    destination = ASSETS / "avatars"
    destination.mkdir(parents=True, exist_ok=True)
    backgrounds = ["#d6ded2", "#e9d8cf", "#d0dfec", "#dfd3e5"]
    skin = ["#e6b38e", "#b67c57", "#f2c8a6", "#8b553c"]
    shirts = ["#344d70", "#8f5452", "#336259", "#786649"]
    for index in range(12):
        image = Image.new("RGB", (192, 192), backgrounds[index % 4])
        draw = ImageDraw.Draw(image)
        draw.ellipse((29, 128, 165, 262), fill=shirts[index % 4])
        draw.rectangle((81, 109, 112, 147), fill=skin[index % 4])
        hair = ["#3d2922", "#20292d", "#81603d"][index % 3]
        draw.ellipse((49, 29, 145, 136), fill=hair)
        draw.ellipse((60, 48, 133, 128), fill=skin[index % 4])
        draw.pieslice((46, 25, 141, 108), 178, 357, fill=hair)
        if index % 3 == 0:
            draw.rounded_rectangle((51, 65, 66, 145), radius=7, fill=hair)
            draw.rounded_rectangle((130, 65, 145, 145), radius=7, fill=hair)
        for x in (81, 113):
            draw.ellipse((x - 3, 83, x + 2, 88), fill="#3a2a27")
        draw.arc((82, 93, 114, 111), 20, 160, fill="#8e4d46", width=2)
        if index % 4 == 2:
            for x in (68, 100):
                draw.rounded_rectangle((x, 77, x + 29, 95), radius=6, outline=hair, width=2)
            draw.line((96, 84, 101, 84), fill=hair, width=2)
        image.save(destination / f"{index}.png", optimize=True)


def icon():
    image = Image.new("RGBA", (1024, 1024))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((42, 42, 982, 982), radius=216, fill="#162239")
    draw.rounded_rectangle((156, 198, 868, 826), radius=55, fill="#f5f7fb")
    draw.rounded_rectangle((180, 222, 332, 802), radius=28, fill="#263956")
    for y in (294, 390, 486, 582):
        draw.rounded_rectangle(
            (211, y, 301, y + 44), radius=10, fill="#67d8b3" if y == 294 else "#7088a5"
        )
    for column in range(3):
        for row in range(4):
            x, y = 363 + column * 159, 274 + row * 123
            draw.rounded_rectangle(
                (x, y, x + 130, y + 94),
                radius=15,
                fill=["#54b59c", "#71a8d9", "#c8d6e6"][0 if row == 0 else 1 if column == 0 else 2],
            )
    image.save(ASSETS / "icon.png", optimize=True)


if __name__ == "__main__":
    covers()
    avatars()
    icon()
