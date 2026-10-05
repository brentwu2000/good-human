"""Arrange unretouched runtime screenshots for art review."""
from PIL import Image,ImageDraw
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
src=ROOT/'build/dogs_face_r9/godot'
out=ROOT/'docs/06_art/pomeranian_r9_2026-10-04'
out.mkdir(parents=True,exist_ok=True)
for toon in ['false','true']:
    sheet=Image.new('RGB',(2000,848),'white');d=ImageDraw.Draw(sheet)
    for row,version in enumerate(['r6','r9']):
        for col,angle in enumerate([-90,-45,0,45,90]):
            sheet.paste(Image.open(src/f'{version}_{toon}_{angle}.png').resize((400,400)),(col*400,row*424+24))
            d.text((col*400+8,row*424+6),f'{version} / toon={toon} / {angle}',fill='black')
    sheet.save(out/f'comparison_{toon}.png')
sheet=Image.new('RGB',(1200,1272),'white');d=ImageDraw.Draw(sheet)
for row,clip in enumerate(['Idle','Walk','Sit']):
    for col,percent in enumerate([25,50,75]):
        sheet.paste(Image.open(src/f'clip_{clip}_{percent}.png').resize((400,400)),(col*400,row*424+24))
        d.text((col*400+8,row*424+6),f'r9 / {clip} / {percent}%',fill='black')
sheet.save(out/'animations.png')
