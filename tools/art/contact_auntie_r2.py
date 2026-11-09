from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
R=Path(r'C:/Users/b/Documents/good-human');D=R/'build/market_auntie_refine_r2';O=R/'assets/art_previews/humans/market_auntie_r2';F=ImageFont.truetype('C:/Windows/Fonts/msjh.ttc',26);S=ImageFont.truetype('C:/Windows/Fonts/msjh.ttc',20)
c=Image.new('RGB',(1280,1410),'#f3f1ec');d=ImageDraw.Draw(c)
d.text((25,10),'市場阿姨｜左：上一輪候選　右：本輪精修',font=F,fill='#283039')
for row,v in enumerate(['three_quarter','left']):
 for col,p in enumerate(['before','after']):c.paste(Image.open(D/('godot_'+p+'_'+v+'.png')).convert('RGB'),(col*640,70+row*660))
c.save(O/'comparison.jpg',quality=95)
c=Image.new('RGB',(1280,720),'#f3f1ec');d=ImageDraw.Draw(c);d.text((20,10),'頭部近景｜左：上一輪　右：本輪（同光線）',font=F,fill='#283039')
for i,p in enumerate(['before_head.png','accepted_head.png']):c.paste(Image.open(D/p).convert('RGB').resize((640,640)),(i*640,65))
c.save(O/'head_comparison.jpg',quality=95)
clips=['Idle','Walk','Jab','HeavyHook','Kick','Block','Dodge','Down','HitHeavy','Stumble']
c=Image.new('RGB',(1600,1700),'#f3f1ec');d=ImageDraw.Draw(c)
for i,clip in enumerate(clips):
 x=(i%2)*800;y=(i//2)*340;d.text((x+10,y),clip+' | before / after',font=S,fill='#283039')
 for k,p in enumerate(['before','after']):
  path=D/('motion_'+p+'_'+clip+'.png')
  if path.exists():c.paste(Image.open(path).convert('RGB').resize((320,320)),(x+k*360,y+22))
c.save(O/'motion_comparison.jpg',quality=93)
print(O/'comparison.jpg')
