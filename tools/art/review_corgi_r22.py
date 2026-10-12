from pathlib import Path
script=Path(__file__).with_name('review_corgi_r19.py')
source=script.read_text(encoding='utf-8-sig').replace("('r6','assets/art_previews/dogs/candidates/r19/corgi_r6.glb')","('r21','assets/art_previews/dogs/candidates/r21/corgi.glb')").replace('r19','r22')
exec(compile(source,str(script),'exec'))
