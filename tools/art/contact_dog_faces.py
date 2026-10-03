"""Contact sheets of unchanged rendered head screenshots for ART inspection."""
import pathlib,sys
from PIL import Image,ImageDraw
ROOT=pathlib.Path(__file__).resolve().parents[2]/'build/dogs_face_repair_r5'
for breed in sys.argv[1:]:
    sheet=Image.new('RGB',(1800,1220),'white');draw=ImageDraw.Draw(sheet)
    for row,label in enumerate(['previous','candidate']):
        for col,angle in enumerate([-60,-45,0,45,60]):
            p=ROOT/label/breed/'renders'/f'{breed}_head_{angle:+03d}.png'
            if not p.exists():continue
            im=Image.open(p).convert('RGB').resize((360,360),Image.Resampling.LANCZOS)
            sheet.paste(im,(col*360,row*400+30))
            draw.text((col*360+8,row*400+8),f'{breed} {label} {angle:+d}',fill='black')
    sheet=sheet.crop((0,0,1800,800))
    sheet.save(ROOT/f'{breed}_heads.png')
