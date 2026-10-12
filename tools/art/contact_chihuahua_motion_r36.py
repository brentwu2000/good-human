from pathlib import Path
from PIL import Image, ImageDraw
root=Path(__file__).resolve().parents[2]
src=root/'build/dog_polish_r36/captures'
out=root/'docs/06_art/chihuahua_r36_2026-10-12'
for clip in ['Idle','Run','Fetch','Bark','Alert','Sneak','Jump','Howl','Sit']:
 sheet=Image.new('RGB',(1400,600),'white'); draw=ImageDraw.Draw(sheet)
 for row,version in enumerate(['before','after']):
  for col,phase in enumerate([0,25,50,75,99]):
   im=Image.open(src/version/f'chihuahua_M2M_{clip}_{phase}.png')
   sheet.paste(im.resize((280,280)),(col*280,row*300+20))
   draw.text((col*280+3,row*300+3),f'{version} {clip} {phase}%',fill='black')
 sheet.save(out/f'M2M_{clip}.png')
