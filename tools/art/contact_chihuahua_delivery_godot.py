from pathlib import Path
from PIL import Image,ImageDraw
import sys
ROOT=Path(__file__).resolve().parents[2];folder=ROOT/'build/dog_delivery'/('godot_runtime' if '--runtime' in sys.argv else 'godot')
clips=['Idle','Walk','Sit','M2M_Run','M2M_Sneak','M2M_Fetch','M2M_Bark','M2M_Alert','M2M_Jump','M2M_Howl','M2M_Sit','M2M_Idle']
def sheet(files,cols,name):
 w,h=260,282;im=Image.new('RGB',(cols*w,((len(files)+cols-1)//cols)*h),(35,35,35));d=ImageDraw.Draw(im)
 for i,f in enumerate(files):
  tile=Image.open(folder/f).convert('RGB').resize((260,260));x=i%cols*w;y=i//cols*h;im.paste(tile,(x,y));d.text((x+4,y+261),f,fill='white')
 im.save(folder/name)
sheet(['view_%03d.png'%a for a in range(0,360,45)],4,'contact_views.png')
for group in range(3):sheet([f'{clip}_{p:02d}.png' for clip in clips[group*4:group*4+4] for p in [0,25,50,75,99]],5,f'contact_motion_{group}.png')
print('DELIVERY_CONTACT_SHEETS_READY')
