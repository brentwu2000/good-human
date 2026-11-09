"""Create side-by-side evidence sheets without modifying source captures."""
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/poodle_refine_r40';DOC=ROOT/'docs/06_art/poodle_refine_r40_2026-10-14';DOC.mkdir(parents=True,exist_ok=True)
def sheet(paths,cols,target,name):
    w,h=target;im=Image.new('RGB',(cols*w,((len(paths)+cols-1)//cols)*h),'#dddddd')
    for i,p in enumerate(paths):
        src=Image.open(p).convert('RGB');src=ImageOps.contain(src,(w,h));im.paste(src,((i%cols)*w,(i//cols)*h))
    im.save(DOC/name)
for clip in ['Idle','Run','Fetch','Bark','Alert','Sneak','Jump','Howl','Sit']:
    paths=[OUT/'motion'/v/f'poodle_M2M_{clip}_{f}.png' for v in ['before','after'] for f in [0,25,50,75,99]]
    sheet(paths,5,(203,360),f'motion_{clip}.jpg')
paths=[OUT/'godot'/f'{v}_false_{a}.png' for v in ['r39','r40'] for a in [-90,-45,0,45,90]]
sheet(paths,5,(203,360),'faces.jpg')
paths=[OUT/'godot'/f'{v}_true_{a}.png' for v in ['runtime','r39'] for a in [-90,-45,0,45,90]]
sheet(paths,5,(203,360),'faces_toon.jpg')
sheet([OUT/'godot'/f'clip_{c}_{f}.png' for c in ['Idle','Walk','Sit'] for f in [25,50,75]],3,(203,360),'original_clips.jpg')
sheet([OUT/'diagnose_front_texture.png',OUT/'candidate.png'],2,(480,480),'blender_comparison.jpg')
print('13 contact sheets saved to',DOC)



from PIL import ImageFont
def comparison(left,right,name,title):
    images=[Image.open(p).convert('RGB') for p in [left,right]]
    assert images[0].size==images[1].size
    images=[ImageOps.contain(im,(640,640)) for im in images]
    w,h=images[0].size;canvas=Image.new('RGB',(w*2+16,h+148),'#f4f3ef');d=ImageDraw.Draw(canvas)
    ft=ImageFont.truetype('C:/Windows/Fonts/msjh.ttc',28);fl=ImageFont.truetype('C:/Windows/Fonts/msjh.ttc',23);fs=ImageFont.truetype('C:/Windows/Fonts/msjh.ttc',19)
    d.text((24,14),title,font=ft,fill='#202b33')
    for i,(im,label) in enumerate(zip(images,['精修前 r39｜14,712 面','精修後 r40｜14,558 面'])):
        x=i*(w+16);d.text((x+24,62),label,font=fl,fill='#202b33');canvas.paste(im,(x,104))
    d.text((24,h+113),'相同相機與燈光；原圖並排，未修圖。',font=fs,fill='#202b33');canvas.save(DOC/name)
comparison(OUT/'diagnose_front_texture.png',OUT/'candidate.png','before_after_front.png','貴賓犬精修前後：額頭、臉頰與耳根')
comparison(OUT/'godot/r39_false_0.png',OUT/'godot/r40_false_0.png','before_after_godot.png','Godot 正面近照：精修前後')
