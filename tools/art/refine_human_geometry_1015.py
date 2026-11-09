"""Local CX-10 changes, appending geometry without re-exporting bones or clips."""
import os,json,struct,numpy as np
ROOT=r'C:/Users/b/Documents/good-human';BASE=ROOT+'/assets/art_previews/humans/refine_2026_10_15';OUT=ROOT+'/build/human_refine_2026_10_15'
def read(p):
 d=open(p,'rb').read();n=struct.unpack_from('<I',d,12)[0];j=json.loads(d[20:20+n]);off=20+n;return j,bytearray(d[off+8:off+8+struct.unpack_from('<I',d,off)[0]])
def arr(j,b,i):
 a=j['accessors'][i];v=j['bufferViews'][a['bufferView']];dt={5126:'<f4',5123:'<u2',5125:'<u4',5121:'u1'}[a['componentType']];k={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']];return np.frombuffer(b,dtype=dt,count=a['count']*k,offset=v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(-1,k).copy()
def add(j,b,a,typ,component=5126):
 a=np.asarray(a,dtype={5126:'<f4',5123:'<u2',5125:'<u4'}[component]);
 while len(b)%4:b.append(0)
 v=len(j['bufferViews']);j['bufferViews'].append({'buffer':0,'byteOffset':len(b),'byteLength':a.nbytes});b.extend(a.tobytes());i=len(j['accessors']);j['accessors'].append({'bufferView':v,'componentType':component,'count':len(a),'type':typ})
 if typ=='VEC3':j['accessors'][-1].update(min=a.min(0).tolist(),max=a.max(0).tolist())
 return i
def save(p,j,b):
 while len(b)%4:b.append(0)
 j['buffers'][0]['byteLength']=len(b);s=json.dumps(j,separators=(',',':')).encode();s+=b' '*((-len(s))%4);open(p,'wb').write(struct.pack('<III',0x46546c67,2,28+len(s)+len(b))+struct.pack('<II',len(s),0x4e4f534a)+s+struct.pack('<II',len(b),0x004e4942)+b)
# Shoulder drape, with a folded edge and two woven red bands.
p=BASE+'/market_auntie.glb';j,b=read(p);pr=j['meshes'][0]['primitives'][0];positions=arr(j,b,pr['attributes']['POSITION'])
path=np.array([[-.285,.72],[-.267,.80],[-.237,.90],[-.18,.99],[-.09,1.035],[.01,1.043],[.105,1.005],[.18,.94],[.19,.87]]) # Blender Y,Z
points=[];cols=[];rows=41;wide=9
for r in range(rows):
 t=r/(rows-1)*(len(path)-1);k=min(int(t),len(path)-2);f=t-k;a=path[max(0,k-1)];c=path[k];d=path[k+1];e=path[min(len(path)-1,k+2)]
 yz=.5*((2*c)+(-a+d)*f+(2*a-5*c+4*d-e)*f*f+(-a+3*c-3*d+e)*f*f*f)
 for h in range(wide):
  u=h/(wide-1);xx=-.165+(u-.5)*.105;wave=.004*np.cos(u*np.pi*6)*(1-.25*np.sin(r/(rows-1)*np.pi))
  points.append([xx,float(yz[1]+wave),float(-yz[0]+.002*np.sin(u*np.pi*4))]);red=r in (2,3,6,7,34,35)
  col=[.59,.075,.06,1] if red else [.88,.86,.79,1]
  cols.append(col)
points=np.array(points,np.float32);tri=[]
for r in range(rows-1):
 for h in range(wide-1):
  a=r*wide+h;tri.extend([[a,a+1,a+wide],[a+1,a+wide+1,a+wide]])
tri=np.array(tri,np.uint32);norm=np.zeros_like(points)
for a,c,d in tri:
 n=np.cross(points[c]-points[a],points[d]-points[a]);norm[[a,c,d]]+=n
norm/=np.maximum(np.linalg.norm(norm,axis=1,keepdims=True),1e-12)
jointnames=[j['nodes'][n]['name'] for n in j['skins'][0]['joints']];ji=jointnames.index('spine_03');joint=np.zeros((len(points),4),np.uint16);joint[:,0]=ji;weights=np.zeros((len(points),4),np.float32);weights[:,0]=1
mi=len(j['materials']);j['materials'].append({'name':'auntie_woven_towel','pbrMetallicRoughness':{'baseColorFactor':[1,1,1,1],'metallicFactor':0,'roughnessFactor':.93},'doubleSided':True})
attrs={'POSITION':add(j,b,points,'VEC3'),'NORMAL':add(j,b,norm,'VEC3'),'COLOR_0':add(j,b,cols,'VEC4'),'JOINTS_0':add(j,b,joint,'VEC4',5123),'WEIGHTS_0':add(j,b,weights,'VEC4')}
j['meshes'][0]['primitives'].append({'attributes':attrs,'indices':add(j,b,tri.reshape(-1,1),'SCALAR',5125),'material':mi});save(p,j,b)
json.dump({'added_towel_triangles':len(tri),'bone':'spine_03','source_body_unchanged':True},open(OUT+'/market_auntie/geometry.json','w'),indent=2)
# Bounded shoulder/neck shelf reduction: keep head and central throat fixed.
p=BASE+'/gym_coach.glb';j,b=read(p);pr=j['meshes'][0]['primitives'][0];old=arr(j,b,pr['attributes']['POSITION']);new=old.copy();x,h,d=old.T
w=np.exp(-((np.abs(x)-.18)/.065)**2-((h-1.425)/.055)**2-((d-.02)/.30)**2);w[(h>1.53)|(h<1.31)|(np.abs(x)<.075)]=0
new[:,1]-=.018*w;new[:,0]-=np.sign(x)*.008*w
pr['attributes']['POSITION']=add(j,b,new,'VEC3')
# Normals share across duplicate seam positions, no UV/weight edits.
idx=arr(j,b,pr['indices']).reshape(-1,3);normal=np.zeros_like(new)
for a,c,d in idx:
 n=np.cross(new[c]-new[a],new[d]-new[a]);normal[[a,c,d]]+=n
keys,inv=np.unique(np.round(new,6),axis=0,return_inverse=True);sums=np.zeros_like(keys);np.add.at(sums,inv,normal);normal=sums[inv];normal/=np.maximum(np.linalg.norm(normal,axis=1,keepdims=True),1e-12)
pr['attributes']['NORMAL']=add(j,b,normal,'VEC3');save(p,j,b)
json.dump({'moved_vertices':int((w>1e-5).sum()),'max_displacement_m':float(np.linalg.norm(new-old,axis=1).max()),'head_above_1_53m_fixed':bool(np.array_equal(new[h>1.53],old[h>1.53]))},open(OUT+'/gym_coach/geometry.json','w'),indent=2)
print('CX10_GEOMETRY_COMPLETE')
