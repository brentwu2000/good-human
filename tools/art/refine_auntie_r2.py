import bpy, numpy as np, os, sys, bmesh,json
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=r'C:/Users/b/Documents/good-human';OUT=ROOT+'/build/market_auntie_refine_r2';os.chdir(ROOT);sys.path.insert(0,ROOT+'/art_pipeline/scripts');import paint_regions as pr
bpy.ops.wm.open_mainfile(filepath=OUT+'/00_before.blend')
o=bpy.data.objects['Character'];me=o.data;me.calc_loop_triangles();T=2048
node=next(n for n in me.materials[0].node_tree.nodes if n.type=='TEX_IMAGE' and 'basecolor' in n.image.name)
old=np.array(node.image.pixels[:],np.float32).reshape(T,T,4)[:,:,:3];out=old.copy();xyz=np.zeros((T,T,3),np.float32);valid=np.zeros((T,T),bool)
uv=np.array([u.uv[:] for u in me.uv_layers.active.data])*T;coords=np.array([v.co[:] for v in me.vertices])
for tri in me.loop_triangles:
 if tri.material_index!=0:continue
 a,b,c=uv[list(tri.loops)];ys,xs=pr.tri_texels(np.array([a,b,c]),T)
 if ys is None:continue
 det=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
 if abs(det)<1e-10:continue
 xx=xs+.5;yy=ys+.5;u=((b[1]-c[1])*(xx-c[0])+(c[0]-b[0])*(yy-c[1]))/det;v=((c[1]-a[1])*(xx-c[0])+(a[0]-c[0])*(yy-c[1]))/det
 xyz[ys,xs]=np.stack([u,v,1-u-v],1)@coords[list(tri.vertices)];valid[ys,xs]=True
x,y,z=xyz.transpose(2,0,1)
# Explicitly protected expression landmarks, independent of the broken region classification.
face=(y<-.105)&((x/.237)**2+((z-1.193)/.199)**2<1)&(z<1.368)
expression=face&(((z>1.218)&(z<1.344)&(np.abs(x)<.16))|((z>1.108)&(z<1.16)&(np.abs(x)<.115)))
hair=(z>1.015)&valid&((~face&(old.max(-1)<.50))|(y>.025))
bow=(z>(1.398+.20*(x+.08)**2))&(x>-.13)&(y<.085)&valid
hair&=~bow
strand=.012*np.sin(130*x+18*np.sin(z*9)+y*35)+.006*np.sin(x*550+z*190)
base=np.stack([.115+strand,.075+strand*.7,.059+strand*.5],-1);out[hair]=base[hair]
# Remove projection flecks from skin without repainting expression landmarks.
skin=np.array([.97,.78,.63]);dark=old.max(-1)<.40
clean=face&(z<1.09)&(np.abs(x)<.18)&dark;out[clean]=skin
# Forehead curl belongs to hair: it is raised geometry, not a skin blemish.
curl=((x+.186)/.055)**2+((z-1.294)/.049)**2<1
out[curl&(y<-.12)&valid]=base[curl&(y<-.12)&valid]
# The isolated upper nose outline is a projection artefact; keep lower smiling mouth.
clean=face&(z>1.17)&(z<1.227)&(np.abs(x)<.085)&dark;out[clean]=skin
out[bow]=[.70,.24,.21]
dots=bow&(((x%.037-.0185)/.004)**2+((z%.034-.017)/.004)**2<1)
out[dots]=[.91,.72,.49]
# Subtle woven variation, below the footprint of expression/head painting.
cloth=valid&(z>.42)&(z<1.015)&(old[:,:,2]>.19)&(y<.20)
weave=1+.012*np.sin(x*1550)*np.sin(z*1700)+.008*np.sin(x*430+z*260)
out[cloth]*=weave[cloth,None]
# Retire the old flat hanging side panels below the hands into the trouser silhouette.
panel=(np.abs(x)>.29)&(z>.375)&(z<.505)&(y<.05)&valid
out[panel]=[.24,.24,.26]
 # Slight boot material variation retains form and avoids plastic-flat fills.
boots=valid&(z<.24);out[boots]*=(.98+.018*np.sin(x[boots]*430+y[boots]*180))[:,None]
protected_delta=float(np.abs(out[expression&~curl]-old[expression&~curl]).max())
pr.dilate(out,valid,16);img=pr.save_image('auntie_r2_basecolor',out,OUT+'/basecolor.png','sRGB');node.image=img
# Fit the towel to the actual shoulder surface; preserve independent cloth geometry.
bodytris=[tuple(t.vertices) for t in me.loop_triangles if t.material_index==0];bvh=BVHTree.FromPolygons([v.co.copy() for v in me.vertices],bodytris,all_triangles=True)
towel=set(v for p in me.polygons if p.material_index==1 for v in p.vertices)
maxmove=0
for vi in towel:
 v=me.vertices[vi];v0=v.co.copy();back=v.co.y>0
 start=Vector((v.co.x,1 if back else -1,v.co.z));direction=Vector((0,-1 if back else 1,0))
 p,n,ti,dist=bvh.ray_cast(start,direction)
 if p is not None and v.co.z<1.015:
  target=p.y+(.008 if back else -.008)
  v.co.y+=max(-.035,min(.035,target-v.co.y))
  maxmove=max(maxmove,(v.co-v0).length)
# Cloth continuity: smooth only depth across the regular drape grid.
ids=sorted(towel)
if len(ids)==369:
 yy=np.array([me.vertices[i].co.y for i in ids]).reshape(41,9)
 for _ in range(6):
  tmp=yy.copy();tmp[1:-1,1:-1]=.5*yy[1:-1,1:-1]+.125*(yy[:-2,1:-1]+yy[2:,1:-1]+yy[1:-1,:-2]+yy[1:-1,2:]);yy=tmp
 for i,value in zip(ids,yy.ravel()):me.vertices[i].co.y=float(value)
# Mild welded-neighbour relaxation on outer hair only; protect face and bow.
bm=bmesh.new();bm.from_mesh(me);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6);bm.verts.ensure_lookup_table()
# Topology stays unchanged in the game mesh: transfer only bounded coordinates by rounded original position.
orig={tuple(round(c,6) for c in v.co):v.co.copy() for v in bm.verts};deltas={}
for v in bm.verts:
 px,py,pz=v.co
 if 1.04<pz<1.425 and (py>.015 or abs(px)>.235):
  ns=[e.other_vert(v).co for e in v.link_edges]
  if ns:
   delta=(sum(ns,Vector())/len(ns)-v.co)*.28
   if delta.length>.003:delta=delta.normalized()*.003
   deltas[tuple(round(c,6) for c in v.co)]=delta
for v in me.vertices:
 key=tuple(round(c,6) for c in v.co)
 if key in deltas:v.co+=deltas[key]
bm.free()
for v in me.vertices:
 px,py,pz=v.co
 if abs(px)>.29 and .375<pz<.505 and py<.05:
  fade=min(1,(.505-pz)/.025)*min(1,(pz-.375)/.025)
  v.co.x-=np.sign(px)*min(.035,abs(px)-.29)*fade
me.update()
bpy.ops.wm.save_as_mainfile(filepath=OUT+'/01_head_and_towel.blend')
json.dump({'expression_max_delta':protected_delta,'hair_smoothed_positions':len(deltas),'max_hair_move_m':.003,'max_towel_fit_m':maxmove},open(OUT+'/head_towel.json','w'),indent=2)
print('AUNTIE_HEAD_TOWEL',protected_delta,len(deltas),maxmove)
