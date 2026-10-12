"""Archive 405x720 umbrella review evidence and make comparison sheets."""
from pathlib import Path
from PIL import Image, ImageDraw
import hashlib, json, shutil
ROOT=Path(__file__).resolve().parents[2]
stage=ROOT/'build/umbrella_cx01'
out=ROOT/'docs/06_art/umbrella_cx01_2026-10-12'
out.mkdir(parents=True,exist_ok=True)
for kind in ['showcase','fight']:
    files=sorted((stage/'after'/kind).glob('*.png'))
    cols=5 if kind=='showcase' else 4
    sheet=Image.new('RGB',(cols*203,((len(files)+cols-1)//cols)*380),'white')
    draw=ImageDraw.Draw(sheet)
    for i,p in enumerate(files):
        im=Image.open(p)
        assert im.size==(405,720), (p,im.size)
        x=(i%cols)*203;y=(i//cols)*380
        sheet.paste(im.resize((203,360)),(x,y+20))
        draw.text((x+4,y+4),f'{kind} frame {p.stem}',fill='black')
    sheet.save(out/(kind+'_all.png'))
sheet=Image.new('RGB',(810,2220),'white');draw=ImageDraw.Draw(sheet)
for row,frame in enumerate([90,210,420]):
    for col,version in enumerate(['before','after']):
        im=Image.open(stage/version/'showcase'/f'{frame:04d}.png')
        x=405*col;y=740*row
        sheet.paste(im,(x,y+20));draw.text((x+5,y+4),f'{version} / frame {frame}',fill='black')
sheet.save(out/'before_after.png')
shutil.copy2(stage/'after/showcase/0210.png',out/'guard_405x720.png')
shutil.copy2(stage/'after/fight/0210.png',out/'fight_405x720.png')
for p in ['preservation.json','regression_final.json']:
    shutil.copy2(stage/p,out/p)
for version in ['before','after']:
    for kind in ['showcase','fight']:
        shutil.copy2(stage/version/(kind+'.log'),out/(version+'_'+kind+'.log'))
        shutil.copy2(stage/version/(kind+'.err'),out/(version+'_'+kind+'.err'))
manifest=json.loads((stage/'preservation.json').read_text())
actual=hashlib.sha256((ROOT/'assets/props/weapons/umbrella.glb').read_bytes()).hexdigest()
assert actual==manifest['after']['sha256']
tests=json.loads((stage/'regression_final.json').read_text(encoding='utf-8-sig'))
assert len(tests)==7 and all(t['passed'] for t in tests)
print('UMBRELLA_CX01_EVIDENCE_OK',actual)
