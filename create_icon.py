#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw, ImageFont
import subprocess

# Create a simple icon for AI Image Renamer
sizes = [16, 32, 64, 128, 256, 512, 1024]

# Create the base icon at 1024x1024
img = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Background gradient effect
for i in range(512):
    color = int(20 + (235 - 20) * (i / 512))
    blue = int(100 + (200 - 100) * (i / 512))
    draw.ellipse([i, i, 1024-i, 1024-i], 
                 fill=(color, color//2 + 50, blue, 255))

# Draw AI letters
try:
    # Try to use system font
    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 400)
except:
    font = ImageFont.load_default()

# Draw "AI" text
text = "AI"
bbox = draw.textbbox((0, 0), text, font=font)
text_width = bbox[2] - bbox[0]
text_height = bbox[3] - bbox[1]
x = (1024 - text_width) // 2
y = (1024 - text_height) // 2 - 100
draw.text((x, y), text, fill=(255, 255, 255, 255), font=font)

# Draw camera icon outline
camera_size = 200
camera_x = 412
camera_y = 600
# Camera body
draw.rectangle([camera_x, camera_y, camera_x + camera_size, camera_y + 150], 
               fill=(255, 255, 255, 200), outline=(255, 255, 255, 255), width=10)
# Camera lens
draw.ellipse([camera_x + 50, camera_y + 25, camera_x + 150, camera_y + 125], 
             fill=(100, 100, 100, 200), outline=(255, 255, 255, 255), width=8)

# Save icon at different sizes
os.makedirs("icon.iconset", exist_ok=True)

for size in sizes:
    resized = img.resize((size, size), Image.Resampling.LANCZOS)
    if size <= 512:
        resized.save(f"icon.iconset/icon_{size}x{size}.png")
        # Also save @2x versions for Retina displays
        if size <= 256:
            resized_2x = img.resize((size*2, size*2), Image.Resampling.LANCZOS)
            resized_2x.save(f"icon.iconset/icon_{size}x{size}@2x.png")

# Create the icns file
subprocess.run(["iconutil", "-c", "icns", "icon.iconset", "-o", "AI Image Renamer.app/Contents/Resources/AppIcon.icns"])

# Clean up
subprocess.run(["rm", "-rf", "icon.iconset"])

print("Icon created successfully!")