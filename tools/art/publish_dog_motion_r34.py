"""Publish verified r34 candidates with unchanged-input guards and r33 backups."""
import argparse, hashlib, json, shutil
from pathlib import Path
import numpy as np
from reshape_pomeranian_r9 import unpack,accessor
ROOT=Path(__file__).resolve().parents[2]
BREEDS=['shiba_01','chihuahua','corgi','frenchie','golden','pomeranian','poodle','shiba']
OUT=ROOT/'build/dog_motion_r34'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def check_library(old,new):
 d,b=unpack(old);e,c=unpack(new)
 assert {n.get('name') for n in d['nodes']}=={n.get('name') for n in e['nodes']}
 assert {a['name'] for a in d['animations']}=={a['name'] for a in e['animations']}
 lengths={a['name']:max(float(accessor(d,b,s['input']).max()) for s in a['samplers']) for a in d['animations']}
 for a in e['animations']:
  duration=max(float(accessor(e,c,s['input']).max()) for s in a['samplers'])
  assert abs(duration-lengths[a['name']])<1e-5,(a['name'],duration,lengths[a['name']])
  for s in a['samplers']:
   assert np.isfinite(accessor(e,c,s['output'])).all()
 run=next(a for a in e['animations'] if a['name']=='M2M_Run')
 assert max(e['accessors'][s['input']]['count'] for s in run['samplers'])>=53
parser=argparse.ArgumentParser();parser.add_argument('--publish',action='store_true');args=parser.parse_args()
pairs=[]
for breed in BREEDS:
 old=ROOT/f'assets/art_previews/dogs/candidates/r33/m2m/{breed}.glb'
 new=ROOT/f'assets/art_previews/dogs/candidates/r34/m2m/{breed}.glb'
 runtime=ROOT/f'assets/characters/dog/animations/m2m/{breed}.glb'
 check_library(old,new)
 pairs.append((old,new,runtime,OUT/f'before_m2m/{breed}.glb'))
old=ROOT/'assets/art_previews/dogs/candidates/r33/models/chihuahua.glb'
new=ROOT/'assets/art_previews/dogs/candidates/r34/models/chihuahua.glb'
d,b=unpack(old);e,c=unpack(new)
assert bytes(c[:len(b)])==bytes(b)
for key in ['accessors','meshes','nodes','skins','animations','materials','textures','samplers','scenes','scene']:
 assert d.get(key)==e.get(key),key
pairs.append((old,new,ROOT/'assets/characters/dog/models/breeds/chihuahua.glb',OUT/'before_models/chihuahua.glb'))
report=[]
for old,new,runtime,backup in pairs:
 assert sha(runtime) in (sha(old),sha(new)),f'Concurrent asset change: {runtime}'
 if backup.exists():assert sha(backup)==sha(old)
 report.append({'runtime':str(runtime.relative_to(ROOT)),'before_sha256':sha(old),'after_sha256':sha(new)})
OUT.mkdir(exist_ok=True)
(OUT/'preservation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
if args.publish:
 for old,new,runtime,backup in pairs:
  backup.parent.mkdir(parents=True,exist_ok=True)
  if not backup.exists():shutil.copy2(old,backup)
  shutil.copy2(new,runtime)
  if '/animations/' in runtime.as_posix():
   imp=Path(str(runtime)+'.import')
   text=imp.read_text(encoding='utf-8')
   assert 'animation/fps=30' in text or 'animation/fps=120' in text
   imp.write_text(text.replace('animation/fps=30','animation/fps=120'),encoding='utf-8')
 print('R34_PUBLISHED',len(pairs))
else:print('R34_VERIFIED',len(pairs))
