from PIL import Image,ImageDraw
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];src=ROOT/'build/chihuahua_motion_r31/godot_final';out=ROOT/'docs/06_art/chihuahua_r31_2026-10-09';out.mkdir(parents=True,exist_ok=True)
fractions=[int(i*100/16) for i in range(17)]
for clip,duration in [('HeadLook',3),('Sniff',2)]:
 frames=[Image.open(src/f'clip_{clip}_{f}.png').convert('RGB') for f in fractions]
 sheet=Image.new('RGB',(1250,1100),'white');draw=ImageDraw.Draw(sheet)
 for i,(frame,f) in enumerate(zip(frames,fractions)):
  x=(i%5)*250;y=(i//5)*275;sheet.paste(frame.resize((250,250)),(x,y+25));draw.text((x+5,y+6),f'{clip} {f}%',fill='black')
 sheet.save(out/f'{clip}_frames.png')
 anim=[im.resize((600,600)) for im in frames[:-1]]
 anim[0].save(out/f'{clip}.gif',save_all=True,append_images=anim[1:],duration=round(duration*1000/16),loop=0)
print('CONTACT_AND_GIFS_READY')
