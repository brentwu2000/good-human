"""Arrange actual, unchanged render captures for review; no retouching."""
from PIL import Image,ImageDraw
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'docs/06_art/dog_eye_review_r6_2026-10-03'
OUT.mkdir(exist_ok=True)
(OUT/'.gdignore').touch()
BREEDS=['chihuahua','pomeranian','poodle','frenchie','corgi','shiba','golden']
for breed in BREEDS:
    im=Image.new('RGB',(1200,850),'white');d=ImageDraw.Draw(im)
    for row,version in enumerate(['r5','r6']):
        for col,a in enumerate([-45,0,45]):
            base=ROOT/'build/dogs_face_repair_r5/candidate' if version=='r5' else ROOT/'build/dogs_eye_r6/texture_candidate'
            p=base/breed/'renders'/f'{breed}_head_{a:+03d}.png'
            im.paste(Image.open(p).convert('RGB').resize((400,400),Image.Resampling.LANCZOS),(col*400,row*425+25))
            d.text((col*400+8,row*425+5),f'{breed} {version} {a:+d}',fill='black')
    im.save(OUT/f'{breed}_before_after.png')
    if (ROOT/'build/dogs_eye_r6/godot_final'/f'{breed}_standard_0.png').exists():
        im=Image.new('RGB',(1200,850),'white');d=ImageDraw.Draw(im)
        for row,mode in enumerate(['standard','toon']):
            for col,a in enumerate([-45,0,45]):
                p=ROOT/'build/dogs_eye_r6/godot_final'/f'{breed}_{mode}_{a}.png'
                im.paste(Image.open(p).convert('RGB').resize((400,400),Image.Resampling.LANCZOS),(col*400,row*425+25))
                d.text((col*400+8,row*425+5),f'{breed} r6 {mode} {a:+d}',fill='black')
        im.save(OUT/f'{breed}_godot.png')
