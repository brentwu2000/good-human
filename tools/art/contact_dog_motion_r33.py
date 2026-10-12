from pathlib import Path
from PIL import Image,ImageDraw
root=Path(__file__).resolve().parents[2];src=root/'build/dog_motion_r33/captures';out=root/'docs/06_art/dog_motion_r33_2026-10-10';out.mkdir(parents=True,exist_ok=True)
breeds=['shiba_01','chihuahua','corgi','frenchie','golden','pomeranian','poodle','shiba'];clips=['Idle','Run','Fetch','Bark','Alert','Sneak','Jump','Howl','Sit'];phases=[0,25,50,75,99]
for clip in clips:
 sheet=Image.new('RGB',(1400,2400),'white');draw=ImageDraw.Draw(sheet)
 for row,breed in enumerate(breeds):
  for col,phase in enumerate(phases):
   im=Image.open(src/'after'/f'{breed}_M2M_{clip}_{phase}.png');x=col*280;y=row*300
   sheet.paste(im.resize((280,280)),(x,y+20));draw.text((x+3,y+3),f'{breed} {clip} {phase}%',fill='black')
 sheet.save(out/f'{clip}_all.png')
for breed,clip in [('chihuahua','Howl'),('chihuahua','Run'),('golden','Run'),('poodle','Run')]:
 sheet=Image.new('RGB',(1200,620),'white');draw=ImageDraw.Draw(sheet)
 for col,version in enumerate(['before','after']):
  im=Image.open(src/version/f'{breed}_M2M_{clip}_50.png');sheet.paste(im.resize((600,600)),(col*600,20));draw.text((col*600+8,4),f'{breed} {clip} / {version}',fill='black')
 sheet.save(out/f'{breed}_{clip}_compare.png')
print('CONTACT_SHEETS_READY')
