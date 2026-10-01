"""Arrange untouched QA screenshots into before/after review sheets."""
from PIL import Image,ImageDraw
import pathlib,sys
F=pathlib.Path(r'C:\Users\b\Documents\good_human_stylized_factory')
OUT=pathlib.Path(r'C:\Users\b\Documents\good-human\build\dogs_texture_codex')
for breed in sys.argv[1:]:
    dest=OUT/breed/'renders'
    sheet=Image.new('RGB',(1600,854),'white');draw=ImageDraw.Draw(sheet)
    for row,label in enumerate(['BEFORE — FACTORY ORIGINAL','AFTER — CODEX TEXTURE REPAIR']):
        draw.text((8,row*427+5),f'{breed} / {label}',fill='black')
        for col,view in enumerate(['34','side','back','low']):
            path=F/'renders/dog_qa/handoff'/f'{breed}_{view}.png' if row==0 else dest/f'{breed}_{view}.png'
            im=Image.open(path).convert('RGB').resize((400,400),Image.Resampling.LANCZOS)
            sheet.paste(im,(col*400,row*427+27))
    sheet.save(dest/f'{breed}_before_after.png')
    clips=Image.new('RGB',(1200,427),'white');d=ImageDraw.Draw(clips)
    for i,clip in enumerate(['Idle','Walk','Sit']):
        d.text((i*400+8,6),f'{breed} / {clip}',fill='black')
        im=Image.open(dest/f'{breed}_{clip}.png').convert('RGB').resize((400,400),Image.Resampling.LANCZOS)
        clips.paste(im,(i*400,27))
    clips.save(dest/f'{breed}_clips.png')
    print(breed,'SHEETS_READY')
