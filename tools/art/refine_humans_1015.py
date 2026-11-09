"""Authored surface-space garment details on reviewed v5 masks. No face/rig edits."""
import bpy, numpy as np, os, sys, json, struct, hashlib
ROOT=r'C:/Users/b/Documents/good-human'
os.chdir(ROOT);sys.path.insert(0,ROOT+'/art_pipeline/scripts')
import paint_regions as pr
import inspect_asset as ia
NAMES=['office_worker','market_auntie','retired_fisher','delivery_rider','gym_coach','xiaomi']
OUT=ROOT+'/build/human_refine_2026_10_15'
CAND=ROOT+'/assets/art_previews/humans/refine_2026_10_15'
os.makedirs(CAND,exist_ok=True)
def patch_image(src,dst,png):
 data=open(src,'rb').read();jl=struct.unpack_from('<I',data,12)[0];j=json.loads(data[20:20+jl]);off=20+jl;bl=struct.unpack_from('<I',data,off)[0];blob=bytearray(data[off+8:off+8+bl])
 tex=j['materials'][0]['pbrMetallicRoughness']['baseColorTexture']['index'];ii=j['textures'][tex]['source'];im=j['images'][ii]
 while len(blob)%4:blob.append(0)
 p=open(png,'rb').read();idx=len(j['bufferViews']);j['bufferViews'].append({'buffer':0,'byteOffset':len(blob),'byteLength':len(p)});blob.extend(p);im.clear();im.update({'name':os.path.basename(dst)[:-4]+'_refined_basecolor','bufferView':idx,'mimeType':'image/png'})
 while len(blob)%4:blob.append(0)
 j['buffers'][0]['byteLength']=len(blob);js=json.dumps(j,separators=(',',':')).encode();js+=b' '*((-len(js))%4)
 result=struct.pack('<III',0x46546c67,2,12+8+len(js)+8+len(blob))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(blob),0x004e4942)+blob
 open(dst,'wb').write(result)
 return {'original_binary_prefix_unchanged':bytes(blob[:bl])==data[off+8:off+8+bl],'bones':len(j['skins'][0]['joints']),'clips':len(j.get('animations',[]))}
def raster(o,T):
 m=o.data;m.calc_loop_triangles();uv=np.array([d.uv[:] for d in m.uv_layers.active.data])*T
 pos=np.array([o.matrix_world@v.co for v in m.vertices]);rr=np.array([d.value for d in m.attributes['region_id'].data])
 pp=np.zeros((T,T,3),np.float32);rid=np.zeros((T,T),np.int16);norm=np.zeros((T,T,3),np.float32)
 for tri in m.loop_triangles:
  uv3=uv[list(tri.loops)];ys,xs=pr.tri_texels(uv3,T)
  if ys is None:continue
  a,b,c=uv3;det=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
  if abs(det)<1e-12:continue
  xx=xs+.5;yy=ys+.5;l1=((b[1]-c[1])*(xx-c[0])+(c[0]-b[0])*(yy-c[1]))/det;l2=((c[1]-a[1])*(xx-c[0])+(a[0]-c[0])*(yy-c[1]))/det
  pp[ys,xs]=np.stack([l1,l2,1-l1-l2],axis=1)@pos[list(tri.vertices)]
  rid[ys,xs]=rr[tri.polygon_index];norm[ys,xs]=o.matrix_world.to_3x3()@tri.normal
 return pp,rid,norm

def process(name):
 bpy.ops.wm.open_mainfile(filepath=ROOT+'/art_pipeline/assets/work/'+name+'_E_baked.blend')
 cfg=json.load(open('art_pipeline/config/characters/'+name+'.json'));o=bpy.data.objects['Character']
 outdir=OUT+'/'+name;os.makedirs(outdir,exist_ok=True)
 source=next(n.image for n in o.active_material.node_tree.nodes if n.type=='TEX_IMAGE' and 'basecolor' in n.image.name)
 T=source.size[0];old=np.array(source.pixels[:],np.float32).reshape(T,T,4)[...,:3];out=old.copy()
 pp,rid,nn=raster(o,T);x,y,z=pp.transpose(2,0,1);front=nn[:,:,1]<-.20
 regions={r['name']:r for r in cfg['regions']}
 masks={n:rid==r['id'] for n,r in regions.items()}
 valid=rid>0
 # Hand-authored garment contours, constrained to the inspected body surface.
 # These replace fragmented projection edges; this is not automatic Z segmentation.
 def domain(d,n):
  d=d&valid
  for key in masks:masks[key][d]=False
  masks[n][d]=True
 if name=='office_worker':
  domain((z>.755)&(z<1.145)&(np.abs(x)<.20)&(y<.135),'top')
  domain((z>.70)&(z<.96)&(np.abs(x)>.20)&(y<.12),'top')
  domain((z>.12)&(z<.755)&(np.abs(x)<.215)&(y<.15),'bottom')
  domain((z<.73)&(z>.48)&(np.abs(x)>.17),'skin')
 elif name=='market_auntie':
  domain((z>.43)&(z<1.01)&(np.abs(x)<.29)&(y<.19),'top')
  apron=(z>.44)&(z<.92)&(y<-.075)&(np.abs(x)<(.21+.05*np.clip((.85-z)/.4,0,1)))
  domain(apron,'apron')
  domain((z>.75)&(z<.94)&(np.abs(x)>.26),'top')
  domain((z>.40)&(z<.75)&(np.abs(x)>.29),'skin')
  domain((z>.91)&(z<1.025)&(np.abs(x)<.13)&(y<-.04),'skin')
 elif name=='retired_fisher':
  domain((z>.55)&(z<1.015)&(np.abs(x)<.21)&(y<.18),'vest')
  domain((z>.55)&(z<1.04)&(np.abs(x)<.043)&(y<-.04),'top')
  domain((z>.78)&(z<.99)&(np.abs(x)>.20),'top')
  domain((z>.33)&(z<.55)&(np.abs(x)<.22),'bottom')
  domain((z>.12)&(z<.33)&(np.abs(x)<.26),'skin')
  domain((z>.41)&(z<.78)&(np.abs(x)>.23),'skin')
  domain((z>1.32),'accessories')
 elif name=='delivery_rider':
  domain((z>.82)&(z<1.22)&(np.abs(x)<.23),'top')
  domain((z>.70)&(z<1.10)&(np.abs(x)>.23),'top')
  domain((z>.52)&(z<.70)&(np.abs(x)>.25),'top')
  domain((z>.14)&(z<.82)&(np.abs(x)<.25),'bottom')
 elif name=='gym_coach':
  domain((z>.90)&(z<1.405)&(np.abs(x)<.265)&(y<.28),'top')
  domain((z>1.32)&(z<1.45)&(y<-.10)&((x/.14)**2+((z-1.46)/.14)**2<1),'skin')
  domain((z>.43)&(z<.90)&(np.abs(x)<.35),'bottom')
  domain((z>.17)&(z<.43)&(np.abs(x)<.37),'skin')
  domain((z>.62)&(z<1.12)&(np.abs(x)>.35),'skin')
 elif name=='xiaomi':
  domain((z>.57)&(z<.84)&(y<.10)&(np.abs(x)<.20),'top')
  domain((z>.54)&(z<.75)&(np.abs(x)>.155)&(y<.15),'top')
  domain((z>.38)&(z<.54)&(np.abs(x)>.19)&(y<.10),'skin')
  domain((z>.39)&(z<.65)&(np.abs(x)<.19)&(y<.18),'bottom')
  domain((z>.63)&(z<.76)&(np.abs(x)<.09)&(y<-.10),'bottom')
  domain((z>.65)&(z<.82)&(np.abs(np.abs(x)-.077)<.014)&(y<-.10),'bottom')
  domain((z>.12)&(z<.39)&(np.abs(x)<.20),'skin')
  domain((z>.13)&(z<.22)&(np.abs(x)<.20),'shoes')
 # Clean the shoe collar on the inspected feet, including former skin fragments.
 shoe_top={'office_worker':.105,'market_auntie':.22,'retired_fisher':.115,'delivery_rider':.145,'gym_coach':.155,'xiaomi':.13}[name]
 domain((z<shoe_top),'shoes')
 def mask(n):return masks.get(n,np.zeros((T,T),bool))
 def color(m,c):out[m]=c
 def ellipse(cx,cz,rx,rz):return ((x-cx)/rx)**2+((z-cz)/rz)**2<1
 def border(cx,cz,w,h,t=.003):return (np.abs(x-cx)<w)&(np.abs(z-cz)<h)&((np.abs(x-cx)>w-t)|(np.abs(z-cz)>h-t))
 # Deliberate base colours: remove accidental baked shadows/confetti, retain head/skin exactly.
 for rn in ('top','bottom','shoes','vest','apron','skin'):
  if rn in regions:color(mask(rn),regions[rn]['colour'])
 if name=='office_worker':
  m=mask('top');color(m,[.88,.87,.84]);color(m&front&(np.abs(x)<.004),[.70,.70,.68])
  tie=m&front&(z>.77)&(z<1.11)&(np.abs(x)<(.025-.012*np.clip((z-.92)/.19,0,1)))
  color(tie,[.20,.27,.46]);color(tie&((z+x*.7)% .055<.006),[.43,.52,.69])
  color(m&front&ellipse(0,1.105,.022,.018),[.16,.23,.40])
  color(m&front&border(-.09,.997,.033,.042),[.67,.69,.70])
  for zz in [.82,.85,.94]:color(m&front&ellipse(.012,zz,.0035,.0035),[.37,.39,.41])
  color(mask('accessories'),[.13,.12,.12])
  color(mask('accessories')&(np.abs(x)>.125)&(z>.62)&(z<.67),[.24,.19,.14])
 elif name=='market_auntie':
  m=mask('apron');color(m,[.78,.34,.30])
  # Coherent floral print measured on surface, rather than fragmented camera projection.
  u=(x+.9)% .095-.0475;v=(z+.02)% .105-.0525
  flower=(u*u+v*v)<(.023+.007*np.cos(5*np.arctan2(v,u)))**2
  color(m&flower,[.94,.79,.55]);color(m&(u*u+v*v<.008**2),[.39,.44,.59])
  color(m&(((u-.026)**2/.012**2+(v+.027)**2/.020**2)<1),[.40,.48,.39])
  color(m&front&border(.07,.57,.064,.058,.004),[.96,.82,.60])
  m=mask('top');color(m,[.46,.44,.62]);color(m&((x*1.1+z)% .095<.004),[.56,.53,.69])
  color(mask('towel'),[.95,.94,.90]);color(mask('towel')&(z<.88),[.78,.31,.28])
  # Retain hair bow above head, clean satchel and buckle only below shoulder.
  m=mask('accessories')&(z<1.02);color(m,[.32,.22,.16]);color(m&(z>.59)&(z<.62),[.58,.42,.22])
 elif name=='retired_fisher':
  m=mask('vest');color(m,[.46,.45,.30]);color(m&front&(np.abs(x)<.009),[.25,.26,.19])
  for cx in [-.105,.105]:
   color(m&front&border(cx,.77,.060,.060,.004),[.29,.30,.20]);color(m&front&(np.abs(x-cx)<.06)&(np.abs(z-.80)<.006),[.64,.60,.42])
   color(m&front&ellipse(cx,.785,.004,.004),[.76,.71,.49])
  m=mask('accessories');color(m&(z>1.18),[.72,.63,.47]);color(m&(z>1.31)&(z<1.35),[.34,.29,.20])
 elif name=='delivery_rider':
  m=mask('top');color(m,[.92,.46,.17])
  torso=front&(np.abs(x)<.19)&(z>.83)&(z<1.23)
  color(m&torso&(np.abs(x)<.065),[.89,.87,.82]);color(m&torso&(np.abs(np.abs(x)-.073)<.009),[.19,.17,.16])
  color(m&torso&(np.abs(np.abs(x)-.13)<.020),[.19,.17,.16])
  color(m&torso&(np.abs(np.abs(x)-.13)<.013)&(np.abs(z-1.06)<.020),[.65,.61,.51])
  color(m&(z>.92)&(z<.932)&(np.abs(x)>.19),[.92,.88,.76])
  # Gloves are already merged into the jacket region in the source mask.
  color(m&(z<.76)&(np.abs(x)>.255),[.16,.15,.15])
  back=(y>.17)&(z>.83)&(z<1.22);color(m&back,[.91,.44,.16]);color(m&back&((np.abs(x)>.165)|(z<.86)|(z>1.19)),[.19,.17,.16])
  # Keep existing dog emblem within its compact central panel.
  keep=back&(np.abs(x)<.10)&(z>.94)&(z<1.12);out[keep]=old[keep]
 elif name=='gym_coach':
  m=mask('top');color(m,[.94,.93,.89])
  # Preserve the drawn chest emblem, but remove adjacent accidental dark fragments.
  keep=m&front&(np.abs(x)<.115)&(z>1.02)&(z<1.27);out[keep]=old[keep]
  color(m&front&(np.abs(np.abs(x)-.20)<.004),[.76,.75,.72])
  color(mask('bottom'),[.13,.12,.12]);color(mask('bottom')&(np.abs(x)>.22)&(z>.53)&(z<.88),[.76,.23,.21])
  color(mask('accessories'),[.14,.13,.13])
 elif name=='xiaomi':
  m=mask('bottom');color(m,[.33,.46,.58])
  color(m&front&border(0,.635,.07,.049,.003),[.75,.69,.48])
  color(m&front&(np.abs(np.abs(x)-.077)<.003)&(z>.52)&(z<.76),[.73,.68,.49])
  for cx in [-.073,.073]:color(m&front&ellipse(cx,.765,.007,.007),[.90,.69,.28])
  color(mask('accessories'),[.25,.45,.49]);color(mask('accessories')&((np.abs(x)>.16)|(z>.79)),[.84,.52,.58])
  color(mask('accessories')&(y>.20)&border(0,.64,.11,.09,.004),[.91,.74,.49])
 # All shoes: authored sole separation and laces follow each shoe surface; no projected crumbs.
 m=mask('shoes');validz=z[m];zlo=float(np.min(validz));zhi=float(np.percentile(validz,95));sole=zlo+min(.025,(zhi-zlo)*.16)
 color(m&(z<sole),[.24,.23,.22] if name=='market_auntie' else [.80,.78,.71])
 if name!='market_auntie':
  for side in [-1,1]:
   xx=float(np.median(x[m&(x*side>0)]));lace=m&front&(np.abs(x-xx)<.035)&(z>sole+.015)&(z<sole+.08)&((z-sole)%.016<.003)
   color(lace,[.93,.91,.85])
 # Visual QA rollback: do not accept garment masks that cross fused side bags or hands.
 # Retain those original patches instead of another automatic segmentation retry.
 rollback=np.zeros((T,T),bool)
 if name=='office_worker':rollback=(y>.13)&(z<1.18)
 elif name=='market_auntie':rollback=(y>.02)&(np.abs(x)>.25)&(z<.72)
 elif name=='gym_coach':rollback=(z<.91)&(z>.155)
 elif name=='xiaomi':rollback=(y>.02)&(z>.36)&(z<.86)
 out[rollback]=old[rollback]
 # Keep the drawn face footprint byte-for-byte in Blender's image values.
 face_floor={'office_worker':1.18,'market_auntie':1.035,'retired_fisher':1.07,'delivery_rider':1.23,'gym_coach':1.46,'xiaomi':.86}[name]
 protected=((rid==regions['skin']['id'])|(rid==regions['eyes']['id']))&(z>face_floor)
 if name=='retired_fisher':protected&=(z<1.32)
 out[protected]=old[protected]
 changed=np.max(np.abs(out-old),axis=2)>1/255
 protected_delta=float(np.max(np.abs(out[protected]-old[protected])))
 pr.dilate(out,rid>0,16)
 image=pr.save_image(name+'_refined',out,outdir+'/basecolor.png','sRGB')
 for node in o.active_material.node_tree.nodes:
  if node.type=='TEX_IMAGE' and node.image==source:node.image=image
 bpy.ops.wm.save_as_mainfile(filepath=outdir+'/refined.blend')
 checks=patch_image(OUT+'/before/'+name+'/'+name+'.glb',CAND+'/'+name+'.glb',outdir+'/basecolor.png')
 checks.update({'protected_skin_eye_max_delta':protected_delta,'changed_texels':int(changed.sum()),'texture_size':T})
 json.dump(checks,open(outdir+'/verification.json','w'),indent=2)
 # View actual new texture on the unchanged model, using the same view rig as stage A.
 for a in bpy.data.objects:
  if a.type=='ARMATURE':a.data.pose_position='REST'
 ia.render_views(outdir,640,'after')
 print('REFINED',name,checks,flush=True)
for name in (sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else NAMES):process(name)
