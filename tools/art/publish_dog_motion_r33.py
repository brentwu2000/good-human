"""Verify and publish CX-04 assets only if their recorded baselines still match."""
from pathlib import Path
import json,hashlib,shutil,copy
import numpy as np
from reshape_pomeranian_r9 import unpack,accessor
ROOT=Path(__file__).resolve().parents[2]
REVS={'chihuahua':29,'corgi':21,'frenchie':18,'golden':25,'pomeranian':10,'poodle':28,'shiba':23}
STAGE=ROOT/'build/dog_motion_r33'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify():
 report={'models':{},'animations':{}}
 for breed,revision in REVS.items():
  source=ROOT/f'assets/art_previews/dogs/candidates/r{revision}/{breed}.glb';dest=ROOT/f'assets/characters/dog/models/breeds/{breed}.glb';candidate=ROOT/f'assets/art_previews/dogs/candidates/r33/models/{breed}.glb'
  assert sha(dest) in {sha(source),sha(candidate)},f'Runtime model changed concurrently: {breed}'
  old,ob=unpack(source);new,nb=unpack(candidate)
  assert nb[:len(ob)]==ob
  for key in ['nodes','skins','animations','materials','textures','images','samplers','scenes','scene']:assert old.get(key)==new.get(key),(breed,key)
  for om,nm in zip(old['meshes'],new['meshes']):
   for op,np_ in zip(om['primitives'],nm['primitives']):
    expected=copy.deepcopy(np_)
    for key in ['JOINTS_0','WEIGHTS_0']:expected['attributes'][key]=op['attributes'][key]
    for key in ['JOINTS_1','WEIGHTS_1']:expected['attributes'].pop(key)
    assert expected==op
    a=np_['attributes'];weights=np.c_[accessor(new,nb,a['WEIGHTS_0']),accessor(new,nb,a['WEIGHTS_1'])]
    assert np.all(np.isfinite(weights)) and np.all(weights>=0) and np.max(abs(weights.sum(1)-1))<1e-5
  report['models'][breed]={'before_sha256':sha(source),'after_sha256':sha(candidate),'rest_geometry_uvs_textures_rig_original_clips_preserved':True,'influences_per_vertex':8}
 for breed in ['shiba_01']+list(REVS):
  dest=ROOT/f'assets/characters/dog/animations/m2m/{breed}.glb';candidate=ROOT/f'assets/art_previews/dogs/candidates/r33/m2m/{breed}.glb';backup=STAGE/f'before/{breed}.glb'
  assert sha(dest) in {sha(backup),sha(candidate)},f'Runtime motion changed concurrently: {breed}'
  old,ob=unpack(dest);new,nb=unpack(candidate)
  old_names=sorted(a['name'] for a in old['animations']);assert old_names==sorted(a['name'] for a in new['animations']) and len(old_names)==9
  assert [old['nodes'][i]['name'] for i in old['skins'][0]['joints']]==[new['nodes'][i]['name'] for i in new['skins'][0]['joints']]
  report['animations'][breed]={'before_sha256':sha(backup),'after_sha256':sha(candidate),'clips':old_names}
 return report
if __name__=='__main__':
 import argparse
 parser=argparse.ArgumentParser();parser.add_argument('--publish',action='store_true');args=parser.parse_args();report=verify()
 (STAGE/'preservation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
 if args.publish:
  (STAGE/'before_models').mkdir(exist_ok=True)
  for breed in REVS:
   dest=ROOT/f'assets/characters/dog/models/breeds/{breed}.glb'
   backup=STAGE/f'before_models/{breed}.glb'
   if not backup.exists():shutil.copy2(ROOT/f'assets/art_previews/dogs/candidates/r{REVS[breed]}/{breed}.glb',backup)
   assert sha(backup)==report['models'][breed]['before_sha256']
   shutil.copy2(ROOT/f'assets/art_previews/dogs/candidates/r33/models/{breed}.glb',dest)
  for breed in report['animations']:shutil.copy2(ROOT/f'assets/art_previews/dogs/candidates/r33/m2m/{breed}.glb',ROOT/f'assets/characters/dog/animations/m2m/{breed}.glb')
 print('R33_PUBLISHED' if args.publish else 'R33_PRESERVATION_VERIFIED')
