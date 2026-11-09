from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
R=Path(r'C:/Users/b/Documents/good-human');D=R/'build/human_refine_2026_10_15';O=R/'assets/art_previews/humans/refine_2026_10_15';F=ImageFont.truetype('C:/Windows/Fonts/msjh.ttc',23);S=ImageFont.truetype('C:/Windows/Fonts/msjh.ttc',17)
names=[('office_worker','上班族'),('market_auntie','市場阿姨'),('retired_fisher','釣魚阿伯'),('delivery_rider','外送員'),('gym_coach','健身教練'),('xiaomi','小米')]
canvas=Image.new('RGB',(1536,1160),'#f3f1ec');draw=ImageDraw.Draw(canvas)
for i,(n,label) in enumerate(names):
 x=(i%3)*512;y=(i//3)*580
 draw.text((x+16,y+10),label,font=F,fill='#252c32')
 for j,(p,txt) in enumerate([('before','精修前'),('after','精修後')]):
  im=Image.open(D/n/('godot_'+p+'_front.png')).convert('RGB').resize((256,480)) if False else Image.open(D/n/('godot_'+p+'_front.png')).convert('RGB')
  # Equal square views, identical framing and light. Keep proportions.
  im=im.resize((256,256),Image.Resampling.LANCZOS);canvas.paste(im,(x+j*256,y+65))
  draw.text((x+j*256+18,y+40),txt,font=S,fill='#41464b')
  detail=Image.open(D/n/('godot_'+p+'_three_quarter.png')).convert('RGB').resize((256,256),Image.Resampling.LANCZOS);canvas.paste(detail,(x+j*256,y+324))
canvas.save(O/'comparison.jpg',quality=95)
for n,label in names:
 c=Image.new('RGB',(1280,1390),'#f3f1ec');d=ImageDraw.Draw(c);d.text((25,10),label+'｜左：精修前　右：精修後',font=F,fill='#252c32')
 for row,v in enumerate(['front','three_quarter']):
  for col,p in enumerate(['before','after']):c.paste(Image.open(D/n/('godot_'+p+'_'+v+'.png')).convert('RGB'),(col*640,55+row*650))
 c.save(O/(n+'_comparison.jpg'),quality=94)
print(O/'comparison.jpg')

views=Image.new('RGB',(1280,1680),'#f3f1ec');dv=ImageDraw.Draw(views)
for row,(n,label) in enumerate(names):
 dv.text((8,row*280),label,font=S,fill='#252c32')
 for col,v in enumerate(['front','back','left','right','three_quarter']):
  views.paste(Image.open(D/n/('godot_after_'+v+'.png')).convert('RGB').resize((256,256)),(col*256,row*280+24))
views.save(O/'all_views.jpg',quality=94)
motion=Image.new('RGB',(1536,560),'#f3f1ec');dm=ImageDraw.Draw(motion)
for col,(n,label) in enumerate(names):
 dm.text((col*256+8,0),label,font=S,fill='#252c32')
 for row,clip in enumerate(['Idle','Walk']):
  pp=D/n/('motion_'+clip+'.png')
  if pp.exists():motion.paste(Image.open(pp).convert('RGB').resize((256,256)),(col*256,row*280+24))
motion.save(O/'motion_review.jpg',quality=94)
