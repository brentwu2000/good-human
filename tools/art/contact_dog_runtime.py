"""Arrange unmodified Godot screenshots for visual review."""
from PIL import Image,ImageDraw
from pathlib import Path
root=Path(__file__).resolve().parents[2]/'build/dogs_face_repair_r5'
breeds=['chihuahua','pomeranian','poodle','frenchie','corgi','shiba','golden']
for b in breeds:
    out=Image.new('RGB',(1200,850),'white');draw=ImageDraw.Draw(out)
    for row,mode in enumerate(['standard','toon']):
        for col,angle in enumerate([-45,0,45]):
            src=root/'godot'/f'{b}_{mode}_{angle}.png'
            im=Image.open(src).convert('RGB').resize((400,400))
            out.paste(im,(col*400,row*425+25))
            draw.text((col*400+8,row*425+6),f'{b} {mode} {angle:+d}',fill='black')
    out.save(root/f'{b}_godot.png')
