"""Shared whole-face repair engine. Each breed supplies measured proportions.

Based on owner-accepted pomeranian r10. Immutable originals and skeleton/clip
values are retained; per-breed geometry and projection callbacks are required.
"""
import pathlib,sys,json,struct,copy,hashlib,io
import numpy as np
from PIL import Image
sys.path.insert(0,str(pathlib.Path(__file__).parent))
from reshape_pomeranian_r9 import unpack,accessor,smooth
ROOT=pathlib.Path(__file__).resolve().parents[2]
def main(config):
    OUT=pathlib.Path(config['output_dir']);SOURCE=pathlib.Path(config['source']);REF=pathlib.Path(config['reference'])
    breed=config['breed'];CX,CZ=config['center'];RX,RZ=config['radius']
    cut_depth=config['cut_depth'];face_y=config['surface'];project=config['project']
    xmin,xmax,zmin,zmax=config['chart'];chart_width=xmax-xmin;chart_height=zmax-zmin
    OUT.mkdir(parents=True,exist_ok=True)
    doc,data=unpack(SOURCE);original_doc=copy.deepcopy(doc);original_data=bytes(data)
    prim=max((p for m in doc['meshes'] for p in m['primitives']),key=lambda p:doc['accessors'][p['attributes']['POSITION']]['count'])
    pos=accessor(doc,data,prim['attributes']['POSITION']).copy();normal=accessor(doc,data,prim['attributes']['NORMAL']).copy()
    tri=accessor(doc,data,prim['indices']).copy().reshape(-1,3)
    p=pos[:,[0,2,1]].astype(float);p[:,1]*=-1;H=np.ptp(p[:,2]);p/=H
    q=p[tri].mean(1)
    cut=(((q[:,0]-CX)/RX)**2+((q[:,2]-CZ)/RZ)**2<.90)&(q[:,1]<cut_depth)
    _,first,inv=np.unique(np.round(p,6),axis=0,return_index=True,return_inverse=True)
    logical=inv[tri]
    # A small separate cheek tuft can intersect the ellipse. Retain it rather
    # than creating a second cut with no connection to the anterior face.
    parent=np.arange(len(first))
    def find(v):
        while parent[v]!=v:
            parent[v]=parent[parent[v]];v=parent[v]
        return v
    for a,b,c in logical[cut]:
        ra=find(a);parent[find(b)]=ra;parent[find(c)]=ra
    ids=np.flatnonzero(cut);roots=np.array([find(t[0]) for t in logical[cut]])
    values,counts=np.unique(roots,return_counts=True)
    cut[ids[roots!=values[np.argmax(counts)]]]=False
    for iteration in range(12):
        et=logical[cut]
        edges=np.sort(np.concatenate([et[:,[0,1]],et[:,[1,2]],et[:,[2,0]]]),axis=1)
        u,count=np.unique(edges,axis=0,return_counts=True);boundary=u[count==1]
        verts,degree=np.unique(boundary,return_counts=True)
        bad=verts[degree!=2]
        if not len(bad):break
        cut|=np.isin(logical,bad).any(1)
    assert not len(bad),'Boundary has branches'
    graph={int(v):[] for v in verts}
    for a,b in boundary:graph[int(a)].append(int(b));graph[int(b)].append(int(a))
    loops=[];unseen=set(graph)
    while unseen:
        start=min(unseen);loop=[start];previous=None;cur=start
        while True:
            nxt=next(v for v in graph[cur] if v!=previous)
            if nxt==start:break
            assert nxt not in loop
            loop.append(nxt);previous,cur=cur,nxt
        unseen-=set(loop);loops.append(loop)
    if len(loops)!=1:
        print('BOUNDARIES',[(len(loop),p[first[np.array(loop)]].mean(0).tolist()) for loop in loops])
    assert len(loops)==1,[len(a) for a in loops]
    indices=first[np.array(loops[0])];rim=p[indices].copy()
    area=np.sum(rim[:,0]*np.roll(rim[:,2],-1)-rim[:,2]*np.roll(rim[:,0],-1))
    if area<0:indices=indices[::-1];rim=rim[::-1]
    angles=np.unwrap(np.arctan2((rim[:,2]-CZ)/RZ,(rim[:,0]-CX)/RX))
    da=np.diff(np.r_[angles,angles[0]+2*np.pi])
    # The AI mesh boundary doubles back in projection. Regularize its angular
    # spacing before filling; a radial fan over that uncorrected rim folds.
    for _ in range(5):da=(np.roll(da,1)+2*da+np.roll(da,-1))/4
    da=np.maximum(da,.003);da*=2*np.pi/da.sum()
    theta=angles[0]+np.r_[0,np.cumsum(da[:-1])]
    theta+=np.mean(angles-theta)
    desired=rim.copy();desired[:,0]=CX+RX*np.sqrt(.90)*np.cos(theta);desired[:,2]=CZ+RZ*np.sqrt(.90)*np.sin(theta)
    rim_y=rim[:,1].copy()
    for _ in range(10):rim_y=(np.roll(rim_y,1)+2*rim_y+np.roll(rim_y,-1))/4
    desired[:,1]=rim_y
    # Spread the rim correction over six neighboring body loops, keeping all
    # more distant vertices fixed. No deformation is applied to the body/legs.
    adj=[set() for _ in first]
    for a,b,c in logical:
        adj[a].update([b,c]);adj[b].update([a,c]);adj[c].update([a,b])
    rim_ids=inv[indices];dist=np.full(len(first),99);dist[rim_ids]=0
    for depth in range(1,7):
        for v in np.flatnonzero(dist==depth-1):
            for neighbor in adj[v]:
                if dist[neighbor]>depth:dist[neighbor]=depth
    delta=np.zeros((len(first),3));delta[rim_ids]=desired-rim
    active=np.flatnonzero((dist>0)&(dist<6))
    for _ in range(48):
        updated=delta.copy()
        for v in active:updated[v]=delta[list(adj[v])].mean(0)*.94
        delta=updated
    adjusted_unique=p[first]+delta
    adjusted=adjusted_unique[inv];rim=adjusted[indices]
    N=len(rim);rings=config.get('rings',20)
    center=np.array([CX,face_y(CX,CZ),CZ])
    new=[center];radii=[0.0]
    for j in range(1,rings+1):
        radius=j/rings
        for bound in rim:
            x=CX+(bound[0]-CX)*radius;z=CZ+(bound[2]-CZ)*radius
            y=face_y(x,z)
            # Match the original rim exactly; transition outside facial features.
            y+=(bound[1]-face_y(bound[0],bound[2]))*smooth(.70,1.,np.array(radius))
            new.append([x,y,z]);radii.append(radius)
    new=np.array(new);radii=np.array(radii)
    tris=[]
    for k in range(N):tris.append([0,1+k,1+(k+1)%N])
    for j in range(rings-1):
        inner=1+j*N;outer=inner+N
        for k in range(N):
            n=(k+1)%N;tris.extend([[inner+k,outer+k,outer+n],[inner+k,outer+n,inner+n]])
    tris=np.array(tris,np.uint32)
    normals=np.zeros_like(new)
    fn=np.cross(new[tris[:,1]]-new[tris[:,0]],new[tris[:,2]]-new[tris[:,0]])
    for j in range(3):np.add.at(normals,tris[:,j],fn)
    normals/=np.maximum(np.linalg.norm(normals,axis=1,keepdims=True),1e-12)
    # One shared normal field across the retained body and reconstructed rim.
    kept=tri[~cut];fn_old=np.cross(adjusted[kept[:,1]]-adjusted[kept[:,0]],adjusted[kept[:,2]]-adjusted[kept[:,0]])
    sums=np.zeros((len(first),3))
    for j in range(3):np.add.at(sums,inv[kept[:,j]],fn_old)
    for i,t in enumerate(tris):
        for v in t:
            if v>=len(new)-N:sums[rim_ids[v-(len(new)-N)]]+=fn[i]
    sums/=np.maximum(np.linalg.norm(sums,axis=1,keepdims=True),1e-12)
    normals[-N:]=sums[rim_ids]
    oldn=normal[:,[0,2,1]].copy();oldn[:,1]*=-1
    changed=(dist[inv]<7);oldn[changed]=sums[inv[changed]]
    # Texture chart covers the whole patch, with an explicit boundary blend.
    uv=np.stack([(new[:,0]-xmin)/chart_width,(zmax-new[:,2])/chart_height],1)
    node_head=next(i for i,n in enumerate(doc['nodes']) if n.get('name')=='head')
    joint=doc['skins'][0]['joints'].index(node_head)
    joints=np.zeros((len(new),4),np.uint16);weights=np.zeros((len(new),4),np.float32)
    joints[:,0]=joint;weights[:,0]=1
    rim_joints=accessor(doc,data,prim['attributes']['JOINTS_0'])[indices].copy()
    rim_weights=accessor(doc,data,prim['attributes']['WEIGHTS_0'])[indices].copy()
    for j in range(1,rings+1):
        blend=float(smooth(.65,1.,np.array(j/rings)))
        if blend==0:continue
        for k in range(N):
            values={joint:1-blend}
            for bone,weight in zip(rim_joints[k],rim_weights[k]):values[int(bone)]=values.get(int(bone),0)+float(weight)*blend
            best=sorted(values.items(),key=lambda pair:pair[1],reverse=True)[:4]
            v=1+(j-1)*N+k;joints[v]=0;weights[v]=0
            for slot,(bone,weight) in enumerate(best):joints[v,slot]=bone;weights[v,slot]=weight
            weights[v]/=weights[v].sum()
    def append_blob(blob):
        data.extend(b'\0'*(-len(data)%4));offset=len(data);data.extend(blob)
        doc['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':len(blob)})
        return len(doc['bufferViews'])-1
    def add_array(array,typ,component,bounds=False):
        view=append_blob(array.tobytes());a={'bufferView':view,'componentType':component,'count':len(array),'type':typ}
        if bounds:a.update(min=array.min(0).tolist(),max=array.max(0).tolist())
        doc['accessors'].append(a);return len(doc['accessors'])-1
    prim['indices']=add_array(tri[~cut].astype('<u4').reshape(-1),'SCALAR',5125)
    body_xyz=(adjusted*H)[:,[0,2,1]];body_xyz[:,2]*=-1
    body_nn=oldn[:,[0,2,1]];body_nn[:,2]*=-1
    prim['attributes']['POSITION']=add_array(body_xyz.astype('<f4'),'VEC3',5126,True)
    prim['attributes']['NORMAL']=add_array(body_nn.astype('<f4'),'VEC3',5126)
    xyz=(new*H)[:,[0,2,1]];xyz[:,2]*=-1
    nn=normals[:,[0,2,1]];nn[:,2]*=-1
    attrs={'POSITION':add_array(xyz.astype('<f4'),'VEC3',5126,True),
           'NORMAL':add_array(nn.astype('<f4'),'VEC3',5126),
           'TEXCOORD_0':add_array(uv.astype('<f4'),'VEC2',5126),
           'JOINTS_0':add_array(joints.astype('<u2'),'VEC4',5123),
           'WEIGHTS_0':add_array(weights.astype('<f4'),'VEC4',5126)}
    ind=add_array(tris.reshape(-1).astype('<u4'),'SCALAR',5125)
    def sample(img,u,v):
        u=np.clip(u,0,img.shape[1]-1.001);v=np.clip(v,0,img.shape[0]-1.001)
        ix=u.astype(int);iy=v.astype(int);fx=(u-ix)[...,None];fy=(v-iy)[...,None]
        return (img[iy,ix]*(1-fx)+img[iy,ix+1]*fx)*(1-fy)+(img[iy+1,ix]*(1-fx)+img[iy+1,ix+1]*fx)*fy
    ref=np.array(Image.open(REF).convert('RGB'),float)/255
    yy,xx=np.mgrid[0:1024,0:1024];x=(xx+.5)/1024*chart_width+xmin;z=zmax-(yy+.5)/1024*chart_height
    su,sv=project(x,z)
    col=sample(ref,su,sv)
    imv=original_doc['bufferViews'][original_doc['images'][0]['bufferView']]
    atlas=np.array(Image.open(io.BytesIO(original_data[imv.get('byteOffset',0):imv.get('byteOffset',0)+imv['byteLength']])).convert('RGB'),float)/255
    old_uv=accessor(original_doc,bytearray(original_data),original_doc['meshes'][0]['primitives'][0]['attributes']['TEXCOORD_0'])[indices]
    rim_color=sample(atlas,old_uv[:,0]*atlas.shape[1]-.5,old_uv[:,1]*atlas.shape[0]-.5)
    for _ in range(5):rim_color=(np.roll(rim_color,1,axis=0)+2*rim_color+np.roll(rim_color,-1,axis=0))/4
    angle=np.arctan2((z-CZ)/RZ,(x-CX)/RX);angle=np.mod(angle-theta[0],2*np.pi)+theta[0]
    edge=np.stack([np.interp(angle,np.r_[theta,theta[0]+2*np.pi],np.r_[rim_color[:,i],rim_color[0,i]]) for i in range(3)],-1)
    radius=np.sqrt(((x-CX)/RX)**2+((z-CZ)/RZ)**2)
    blend=smooth(config.get('blend_start',.72),.945,radius)
    col=col*(1-blend[...,None])+edge*blend[...,None]
    face_image=Image.fromarray(np.uint8(np.clip(col,0,1)*255));face_image.save(OUT/'face_atlas.png')
    buf=io.BytesIO();face_image.save(buf,format='JPEG',quality=95)
    vi=append_blob(buf.getvalue());doc['images'].append({'bufferView':vi,'mimeType':'image/jpeg','name':f'Owner_{breed}_Face'})
    doc['textures'].append({'source':len(doc['images'])-1,'sampler':doc['textures'][0].get('sampler',0)})
    mat=copy.deepcopy(doc['materials'][prim['material']]);mat['name']=f'{breed}_anatomical_face'
    mat['pbrMetallicRoughness']['baseColorTexture']={'index':len(doc['textures'])-1}
    doc['materials'].append(mat)
    mesh=next(m for m in doc['meshes'] if any(p is prim for p in m['primitives']))
    mesh['primitives'].append({'attributes':attrs,'indices':ind,'material':len(doc['materials'])-1,'mode':4})
    data.extend(b'\0'*(-len(data)%4));doc['buffers'][0]['byteLength']=len(data)
    assert bytes(data[:len(original_data)])==original_data
    for key in ['skins','nodes','animations','scenes']:assert doc[key]==original_doc[key]
    # Remove orphaned original position/index buffers, retaining the immutable
    # r6 file as the source rather than shipping dead geometry in this candidate.
    used=set()
    for m in doc['meshes']:
        for pr in m['primitives']:
            used.update(pr['attributes'].values())
            if 'indices' in pr:used.add(pr['indices'])
            for target in pr.get('targets',[]):used.update(target.values())
    for skin in doc['skins']:
        if 'inverseBindMatrices' in skin:used.add(skin['inverseBindMatrices'])
    for animation in doc['animations']:
        for sampler in animation['samplers']:used.update([sampler['input'],sampler['output']])
    amap={old:new for new,old in enumerate(sorted(used))}
    for m in doc['meshes']:
        for pr in m['primitives']:
            pr['attributes']={key:amap[value] for key,value in pr['attributes'].items()}
            if 'indices' in pr:pr['indices']=amap[pr['indices']]
            for target in pr.get('targets',[]):
                for key in target:target[key]=amap[target[key]]
    for skin in doc['skins']:
        if 'inverseBindMatrices' in skin:skin['inverseBindMatrices']=amap[skin['inverseBindMatrices']]
    for animation in doc['animations']:
        for sampler in animation['samplers']:
            sampler['input']=amap[sampler['input']];sampler['output']=amap[sampler['output']]
    doc['accessors']=[doc['accessors'][i] for i in sorted(used)]
    views={a['bufferView'] for a in doc['accessors']}|{im['bufferView'] for im in doc['images']}
    vmap={old:new for new,old in enumerate(sorted(views))};packed=bytearray();newviews=[]
    for old in sorted(views):
        v=copy.deepcopy(doc['bufferViews'][old]);offset=v.get('byteOffset',0)
        packed.extend(b'\0'*(-len(packed)%4));v['byteOffset']=len(packed);packed.extend(data[offset:offset+v['byteLength']]);newviews.append(v)
    for a in doc['accessors']:a['bufferView']=vmap[a['bufferView']]
    for im in doc['images']:im['bufferView']=vmap[im['bufferView']]
    packed.extend(b'\0'*(-len(packed)%4));data=packed;doc['bufferViews']=newviews;doc['buffers'][0]['byteLength']=len(data)
    enc=json.dumps(doc,separators=(',',':')).encode();enc+=b' '*(-len(enc)%4)
    raw=struct.pack('<III',0x46546c67,2,28+len(enc)+len(data))+struct.pack('<II',len(enc),0x4e4f534a)+enc+struct.pack('<II',len(data),0x004e4942)+data
    (OUT/f'{breed}.glb').write_bytes(raw)
    report={'removed_faces':int(cut.sum()),'boundary_vertices':N,'new_face_vertices':len(new),'new_face_triangles':len(tris),'total_triangles':int((~cut).sum()+len(tris)),
      'unused_original_buffers_removed':True,'body_seam_vertices_adjusted':int((np.linalg.norm(delta[inv],axis=1)>1e-7).sum()),'skeleton_animation_data_preserved_accessor_ids_remapped':True,'clips':[a['name'] for a in doc['animations']],
      'source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'result_sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}
    (OUT/'verification.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))

if __name__=='__main__':raise SystemExit('Use a breed-specific recipe, e.g. rebuild_frenchie_face_r11.py')
