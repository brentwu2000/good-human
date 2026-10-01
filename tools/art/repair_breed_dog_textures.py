"""Blender surface-aware material repair on each dog's existing UV atlas.

Owner-sheet colours and source projection only; no generated/research-only art.
Outputs are staged under build/dogs_texture_codex, never factory originals.
"""
import bpy, numpy as np, pathlib, sys, json, hashlib

F=pathlib.Path(r'C:\Users\b\Documents\good_human_stylized_factory')
OUT=pathlib.Path(r'C:\Users\b\Documents\good-human\build\dogs_texture_codex')
sys.path.insert(0,str(F/'scripts'))
from rig_full import barycentric
from dog_project import figure_mask, fit, VIEWS

BREEDS=['chihuahua','pomeranian','poodle','frenchie','corgi','shiba','golden']
COAT={'chihuahua':[.88,.59,.32],'pomeranian':[.93,.61,.31],'poodle':[.91,.60,.36],
      'frenchie':[.33,.255,.23],'corgi':[.91,.55,.25],'shiba':[.90,.55,.24],'golden':[.93,.65,.34]}
CREAM={'poodle':[.85,.61,.40],'golden':[.86,.66,.43]}

def smooth(a,b,x):
    t=np.clip((x-a)/(b-a),0,1);return t*t*(3-2*t)
def mix(a,b,w):
    return a*(1-w[...,None])+b*w[...,None]
def read_image(path):
    im=bpy.data.images.load(str(path),check_existing=False)
    w,h=im.size
    ar=np.array(im.pixels[:],dtype=np.float32).reshape(h,w,4)[::-1,:,:3].copy()
    bpy.data.images.remove(im)
    return ar
def sample(img,coords):
    h,w=img.shape[:2];x=np.clip(coords[:,0],0,w-1.001);y=np.clip(coords[:,1],0,h-1.001)
    ix=x.astype(int);iy=y.astype(int);fx=(x-ix)[:,None];fy=(y-iy)[:,None]
    return (img[iy,ix]*(1-fx)+img[iy,ix+1]*fx)*(1-fy)+(img[iy+1,ix]*(1-fx)+img[iy+1,ix+1]*fx)*fy

def main(breed):
    dest=OUT/breed;dest.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(F/'export/dogs'/f'{breed}_game.glb'))
    arm=next(o for o in bpy.data.objects if o.type=='ARMATURE');arm.data.pose_position='REST'
    body=max((o for o in bpy.data.objects if o.type=='MESH'),key=lambda o:len(o.data.vertices))
    me=body.data;me.calc_loop_triangles()
    co=np.array([body.matrix_world@v.co for v in me.vertices])
    vn=np.array([(body.matrix_world.to_3x3()@v.normal).normalized() for v in me.vertices])
    tris=np.array([t.vertices[:] for t in me.loop_triangles]);loops=np.array([t.loops[:] for t in me.loop_triangles])
    uv=np.array([u.uv[:] for u in me.uv_layers.active.data]);T=1024
    pos=np.zeros((T,T,3),np.float32);norm=np.zeros_like(pos);have=np.zeros((T,T),bool)
    for ti in range(len(tris)):
        u=uv[loops[ti]]*T
        x0,y0=np.maximum(np.floor(u.min(0)).astype(int),0);x1,y1=np.minimum(np.ceil(u.max(0)).astype(int),T-1)
        if x1<x0 or y1<y0:continue
        xx,yy=np.meshgrid(np.arange(x0,x1+1)+.5,np.arange(y0,y1+1)+.5)
        bc=barycentric(u,xx,yy)
        if bc is None:continue
        inside=(bc>=-0.00001).all(-1)
        iy,ix=np.where(inside);ty=T-1-(iy+y0);tx=ix+x0
        pos[ty,tx]=bc[inside]@co[tris[ti]];norm[ty,tx]=bc[inside]@vn[tris[ti]];have[ty,tx]=True
    p=pos[have];n=norm[have];n/=np.linalg.norm(n,axis=1,keepdims=True)+1e-9
    H=np.ptp(co[:,2]);p=p/H
    x,y,z=p.T;nx,ny,nz=n.T;ax=np.abs(x)
    original=read_image(F/'texture_work/dogs'/breed/'projection/basecolor.png')
    old=original[have].copy();c=old.copy()
    coat=np.array(COAT[breed]);cream=np.array(CREAM.get(breed,[.83,.77,.66]))
    # Reliable side-coat samples keep the new fill within the original palette.
    donor=(np.abs(nx)>.55)&(np.abs(y)<.16)&(z>.35)&(z<.64)&(old[:,0]>old[:,2]+.15)&(old[:,0]<.97)
    if donor.sum()>50 and breed!='frenchie':
        coat=.55*np.median(old[donor],axis=0)+.45*coat
    # Quiet variation in new fur regions; no baked hard key-light or shadows.
    variation=(np.sin(x*153+y*101+z*97)+np.sin(x*79-y*211+z*135))*.006
    fur=np.clip(coat+variation[:,None],0,1)
    pale=np.clip(cream+variation[:,None]*.45,0,1)
    if breed=='poodle':
        # Owner's curled-fur detail swatch, used in surface space (not arbitrary UV fill).
        sheet=read_image(F/'references/dogs/poodle_front.png')
        tile=sheet[240:305,170:235]
        mirror=lambda a:1-np.abs(np.mod(a,2)-1)
        weights=np.abs(n)**4;weights/=weights.sum(1,keepdims=True)+1e-9
        t=np.zeros_like(old)
        for axis,(u,vv) in enumerate([(y,z),(x,z),(x,y)]):
            st=np.stack([mirror(u*14)*(tile.shape[1]-1.01),mirror(vv*14)*(tile.shape[0]-1.01)],1)
            t+=sample(tile,st)*weights[:,axis:axis+1]
        v=np.clip(t.mean(1)-np.median(tile.mean(-1)),-.10,.10)*.30
        fur=np.clip(coat+v[:,None],0,1);pale=np.clip(cream+v[:,None]*.55,0,1)
    head=smooth(.53,.62,z)*(1-smooth(-.06,.04,y))
    if breed=='poodle':head=smooth(.44,.50,z)*(1-smooth(-.06,.04,y))
    tail=smooth(.16,.27,y)*smooth(.43,.56,z)
    if breed=='golden':tail=smooth(.32,.43,y)
    # One side view across the torso avoids the old front/side/back takeover line.
    side_ref=read_image(F/'references/dogs'/f'{breed}_side.png')
    side_mask=figure_mask(side_ref)
    side_uv=fit(co,VIEWS['left'][0],side_mask)(pos[have])
    side_col=sample(side_ref,side_uv)
    ix=np.clip(side_uv[:,0].astype(int),0,side_ref.shape[1]-1)
    iy=np.clip(side_uv[:,1].astype(int),0,side_ref.shape[0]-1)
    torso=(1-head)*(1-tail)*smooth(.10,.24,z)
    side_col=mix(fur,side_col,side_mask[iy,ix].astype(float))
    c=mix(c,side_col,torso*.92)
    # Coat on unseen ear backs/crown, keeping the forward ear's pink leather.
    ear=smooth(.76,.84,z)*head
    ear_back=ear*smooth(-.28,.15,ny)
    crown=head*smooth(.89,.95,z)*smooth(-.35,.05,nz)
    if breed=='golden':crown*=.35;ear_back*=.35
    c=mix(c,fur,np.maximum(ear_back,crown))
    # Tail cannot inherit a front-view collar, eyes, harness or ear patch.
    tail_color=fur.copy()
    if breed in ['shiba','chihuahua','pomeranian','corgi']:
        tail_white=smooth(.67,.82,z)*(.80 if breed=='pomeranian' else .60)
        tail_color=mix(fur,pale,tail_white)
    if breed=='frenchie':tail_color=pale
    c=mix(c,tail_color,tail)
    # Belly and inner leg colours are surface-space fields, not UV-neighbour fill.
    belly=(1-smooth(.30,.47,z))*(1-smooth(.09,.20,ax))*smooth(-.28,-.12,y)*(1-smooth(.26,.40,y))
    under=smooth(.10,.48,-nz)*(1-smooth(.52,.61,z))*smooth(-.24,-.14,y)
    lower=1-smooth(.10,.22,z)
    inner=(1-smooth(.03,.10,ax))*smooth(.05,.14,z)*(1-smooth(.36,.49,z))
    repair=np.maximum.reduce([belly,under,lower,inner])
    if breed=='golden':repair*=.85
    c=mix(c,pale,repair)
    # Repair colour mismatches on non-feature body surfaces, with soft spatial seams.
    body_zone=(1-head)*(1-tail)
    chroma=old.max(1)-old.min(1)
    if breed!='frenchie':
        bad=(old[:,2]>old[:,0]-.03)|(old[:,0]<.35)|((old[:,0]>old[:,1]+.22)&(old[:,1]<old[:,2]+.03))
        safe_body=body_zone*smooth(-.04,.08,y)*smooth(.12,.28,z)
        c=mix(c,fur,bad.astype(float)*safe_body)
    # Back/top projection boundaries: replace the abrupt view seam with a stable coat.
    backstrip=smooth(.25,.7,nz)*smooth(-.12,.03,y)*smooth(.45,.58,z)*(1-tail)
    c=mix(c,fur,backstrip*(.85 if breed in ['chihuahua','corgi','frenchie'] else .5))
    if breed in ['chihuahua','corgi','shiba','pomeranian']:
        # Broad rear-head coat avoids normal-dependent islands and pale crown shards.
        rearhead=head*smooth(-.26,-.12,y)*smooth(.60,.69,z)*(1-smooth(.74,.82,z))*smooth(-.15,.10,ny)
        c=mix(c,fur,rearhead)
    if breed=='frenchie':
        # Clean cream underside / brown saddle. Keep the front collar and pendant.
        rear=smooth(-.08,.04,y)*(1-head)
        saddle=smooth(.43,.56,z)
        saddle*=1-smooth(.19,.35,y)
        bodycol=mix(pale,fur,saddle)
        c=mix(c,bodycol,rear)
        # One chest girth band, safely in front of the rump and tail.
        band=(1-smooth(.022,.040,np.abs(y+.018)))*smooth(.22,.35,z)*(1-head)*(1-tail)
        c=mix(c,np.array([.18,.155,.145]),band)
        # Remove strap fragments on the rear of the head, keeping dark ears.
        rearhead=head*smooth(-.14,.15,ny)*(1-smooth(.72,.83,z))
        c=mix(c,pale,rearhead)
    if breed in ['poodle']:
        # Remove all competing facial projections before applying one front view.
        head_base=mix(fur,pale,1-smooth(.64,.76,z))
        c=mix(c,head_base,head)
        if breed=='poodle':
            back_ref=read_image(F/'references/dogs/poodle_back.png')
            buv=fit(co,VIEWS['back'][0],figure_mask(back_ref))(pos[have])
            bcol=sample(back_ref,buv)
            bm=figure_mask(back_ref);bix=np.clip(buv[:,0].astype(int),0,back_ref.shape[1]-1);biy=np.clip(buv[:,1].astype(int),0,back_ref.shape[0]-1)
            # The back crop contains ear gaps; keep an even curl field here instead.
            c=mix(c,fur,head*smooth(-.25,-.16,y))
        ref=read_image(F/'references/dogs'/f'{breed}_front.png')
        projection=fit(co,VIEWS['front'][0],figure_mask(ref))
        face_pos=pos[have].copy()
        face_pos[:,0]=H*.18*np.arctan2(x,-(y+.14))
        front=sample(ref,projection(face_pos))
        face=head*(1-smooth(-.235,-.165,y))
        # Non-dog pixels cannot be projected onto crown/ear gaps.
        fuv=projection(face_pos);fm=figure_mask(ref)
        fix=np.clip(fuv[:,0].astype(int),0,ref.shape[1]-1);fiy=np.clip(fuv[:,1].astype(int),0,ref.shape[0]-1)
        face*=fm[fiy,fix]
        c=mix(c,front,face)
    # Preserve the approved front collar and pendant (a side image cannot replace them).
    front_chest=smooth(.18,.55,-ny)*(1-smooth(-.17,-.07,y))*smooth(.20,.30,z)*(1-smooth(.49,.57,z))
    c=mix(c,old,front_chest)
    if breed!='poodle':
        # Tongues and noses can sit below the generic head bound on short breeds.
        muzzle=(1-smooth(-.32,-.22,y))*smooth(.32,.44,z)
        c=mix(c,old,muzzle)
    # Paint four warm paw-pad groups on downward-facing soles only.
    lowco=co[co[:,2]<co[:,2].min()+H*.045]/H
    cy=np.median(lowco[:,1]);pad=np.zeros(len(p))
    for sx in [-1,1]:
        for front in [True,False]:
            cluster=lowco[(lowco[:,0]*sx>0)&((lowco[:,1]<cy)==front)]
            if len(cluster)<3:continue
            center=np.median(cluster,axis=0);rx=max(np.ptp(cluster[:,0])*.30,.015);ry=max(np.ptp(cluster[:,1])*.26,.02)
            d=((x-center[0])/rx)**2+((y-center[1])/ry)**2
            shape=1-smooth(.7,1.0,d)
            for offset in [-.65,0,.65]:
                toe=((x-center[0]-offset*rx)/(rx*.32))**2+((y-center[1]+ry*.92)/(ry*.35))**2
                shape=np.maximum(shape,1-smooth(.65,1,toe))
            pad=np.maximum(pad,shape)
    pad*=smooth(.25,.7,-nz)*(1-smooth(.025,.065,z))
    c=mix(c,np.array([.28,.18,.13]),pad)
    result=original.copy();result[have]=np.clip(c,0,1)
    # Fill the gutters from actual adjacent surface texels, never alter original files.
    filled=have.copy()
    for _ in range(12):
        acc=np.zeros_like(result);count=np.zeros((T,T),np.float32)
        for delta in [(1,0),(-1,0),(0,1),(0,-1)]:
            f=np.roll(filled,delta,(0,1));acc+=np.roll(result,delta,(0,1))*f[...,None];count+=f
        grow=~filled&(count>0);result[grow]=acc[grow]/count[grow,None];filled|=grow
    im=bpy.data.images.new(f'{breed}_basecolor_codex',T,T,alpha=False)
    im.pixels=np.concatenate([result[::-1],np.ones((T,T,1))],-1).astype(np.float32).ravel()
    im.file_format='PNG';im.filepath_raw=str(dest/'basecolor_codex.png');im.save()
    bpy.context.scene.render.image_settings.file_format='JPEG';bpy.context.scene.render.image_settings.quality=90
    # image.save keeps the atlas colour convention used by the factory.
    im.file_format='JPEG';im.filepath_raw=str(dest/'basecolor_codex.jpg');im.save()
    report={'breed':breed,'covered_texels':int(have.sum()),'changed_texels_over_2_percent':int((np.abs(c-old).max(1)>.02).sum()),
       'source_sha256':hashlib.sha256((F/'texture_work/dogs'/breed/'projection/basecolor.png').read_bytes()).hexdigest(),
       'coat':coat.tolist(),'texture':[1024,1024]}
    (dest/'material_repair.json').write_text(json.dumps(report,indent=2))
    print('DOG_MATERIAL_REPAIR',json.dumps(report),flush=True)

if __name__=='__main__':
    argv=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else BREEDS
    for breed in argv:main(breed)
