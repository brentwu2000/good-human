"""Actual runtime frames only: rejected r9 above, new candidate r10 below."""
from PIL import Image,ImageDraw
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
src=ROOT/'build/golden_face_r25/godot';out=ROOT/'docs/06_art/golden_r25_2026-10-07'
out.mkdir(parents=True,exist_ok=True)
for toon in ['false','true']:
    for angles,name in [([-90,-45,0,45,90],'all'),([-45,0,45],'face'),([-90,90],'sides')]:
        sheet=Image.new('RGB',(400*len(angles),848),'white');d=ImageDraw.Draw(sheet)
        for row,version in enumerate(['r24','r25']):
            for col,angle in enumerate(angles):
                sheet.paste(Image.open(src/f'{version}_{toon}_{angle}.png').resize((400,400)),(col*400,row*424+24))
                d.text((col*400+8,row*424+6),f'{version} / toon={toon} / {angle}',fill='black')
        sheet.save(out/f'{name}_{toon}.png')
sheet=Image.new('RGB',(1200,1272),'white');d=ImageDraw.Draw(sheet)
for row,clip in enumerate(['Idle','Walk','Sit']):
    for col,percent in enumerate([25,50,75]):
        sheet.paste(Image.open(src/f'clip_{clip}_{percent}.png').resize((400,400)),(col*400,row*424+24))
        d.text((col*400+8,row*424+6),f'r25 / {clip} / {percent}%',fill='black')
sheet.save(out/'animations.png')













