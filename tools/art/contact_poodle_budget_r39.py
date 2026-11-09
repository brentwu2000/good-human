"""Create side-by-side evidence sheets without modifying source captures."""
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/poodle_budget_r39';DOC=ROOT/'docs/06_art/poodle_budget_r39_2026-10-14';DOC.mkdir(parents=True,exist_ok=True)
def sheet(paths,cols,target,name):
    w,h=target;im=Image.new('RGB',(cols*w,((len(paths)+cols-1)//cols)*h),'#dddddd')
    for i,p in enumerate(paths):
        src=Image.open(p).convert('RGB');src=ImageOps.contain(src,(w,h));im.paste(src,((i%cols)*w,(i//cols)*h))
    im.save(DOC/name)
for clip in ['Idle','Run','Fetch','Bark','Alert','Sneak','Jump','Howl','Sit']:
    paths=[OUT/'motion'/v/f'poodle_M2M_{clip}_{f}.png' for v in ['before','after'] for f in [0,25,50,75,99]]
    sheet(paths,5,(203,360),f'motion_{clip}.jpg')
paths=[OUT/'godot'/f'{v}_false_{a}.png' for v in ['runtime','r39'] for a in [-90,-45,0,45,90]]
sheet(paths,5,(203,360),'faces.jpg')
paths=[OUT/'godot'/f'{v}_true_{a}.png' for v in ['runtime','r39'] for a in [-90,-45,0,45,90]]
sheet(paths,5,(203,360),'faces_toon.jpg')
sheet([OUT/'godot'/f'clip_{c}_{f}.png' for c in ['Idle','Walk','Sit'] for f in [25,50,75]],3,(203,360),'original_clips.jpg')
sheet([OUT/'baseline.png',OUT/'candidate.png'],2,(480,480),'blender_comparison.jpg')
print('13 contact sheets saved to',DOC)


# Owner-facing comparison: keep both source images at identical scale.
from PIL import ImageFont
def labelled_pair(left, right, name, title, subtitle):
    images=[Image.open(p).convert('RGB') for p in [left,right]]
    assert images[0].size==images[1].size
    w,h=images[0].size
    font_path='C:/Windows/Fonts/msjh.ttc'
    title_font=ImageFont.truetype(font_path,28)
    label_font=ImageFont.truetype(font_path,24)
    small=ImageFont.truetype(font_path,19)
    top=140;bottom=58
    canvas=Image.new('RGB',(w*2+16,h+top+bottom),'#f4f3ef')
    d=ImageDraw.Draw(canvas)
    d.text((24,16),title,font=title_font,fill='#202b33')
    d.text((24,56),subtitle,font=small,fill='#4a5960')
    for i,(im,label,count) in enumerate(zip(images,['原版','減面後 r39'],['50,736 三角面','14,712 三角面'])):
        x=i*(w+16)
        d.text((x+24,91),label+'  |  '+count,font=label_font,fill='#202b33')
        canvas.paste(im,(x,top))
    d.text((24,top+h+16),'面數減少 71.0% ｜ 候選版，尚未替換遊戲模型',font=small,fill='#202b33')
    canvas.save(DOC/name)
labelled_pair(OUT/'baseline.png',OUT/'candidate.png','before_after_body.png','貴賓犬減面前後：全身對照','同一 Blender 相機、尺寸與燈光；左原版，右候選。')
labelled_pair(OUT/'godot/runtime_false_0.png',OUT/'godot/r39_false_0.png','before_after_face.png','貴賓犬減面前後：正面近照','同一 Godot 相機與標準材質；左原版，右候選。')
print('Labelled comparison PNGs saved')
