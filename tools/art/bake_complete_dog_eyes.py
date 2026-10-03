"""Bake an unoccluded eye source onto measured local head surfaces, r6."""
import bpy,pathlib,sys,numpy as np,math,json
from mathutils import Vector
ROOT=pathlib.Path(r'C:\Users\b\Documents\good-human')
sys.path.insert(0,str(ROOT/'tools/art'))
import repair_breed_dog_textures as tex
from repair_dog_faces import EYES
OUT=ROOT/'build/dogs_eye_r6/texture_candidate'

def main(breed):
    dest=OUT/breed;dest.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/art_previews/dogs/models'/f'{breed}.glb'))
    body=max((o for o in bpy.data.objects if o.type=='MESH'),key=lambda o:len(o.data.vertices))
    H=float(np.ptp(np.array([body.matrix_world@v.co for v in body.data.vertices])[:,2]))
    a=np.load(ROOT/'build/dogs_face_repair_r5/candidate'/breed/'face_surface.npz')
    code=(ROOT/'tools/art/repair_dog_faces.py').read_text(encoding='utf-8-sig').replace('alpha=(1-smooth(.82,1.52,disk))*clear','alpha=np.zeros(len(x))')
    code=code.replace("clear_z=.090 if breed=='frenchie' else .070", "clear_z=.090 if breed=='frenchie' else .095")
    ns={};exec(code,ns)
    c=ns['rebuild_face'](breed,*[a[k] for k in ['c','p','n','co','tris','fur','pale']],tex.read_image,tex.sample,tex.smooth,tex.mix,tex.F)
    image=bpy.data.images.load(str(ROOT/'assets/_source/generated/dog_eyes_r6/puppy_eye_rgba.png'))
    rgba=np.array(image.pixels[:],np.float32).reshape(image.size[1],image.size[0],4)[::-1].copy()
    eye=rgba[:,:,:3];alpha=rgba[:,:,3:4].repeat(3,axis=2)
    uc,zc,r,*_=EYES[breed]
    if breed=='poodle':uc=.105*.9396926-.313*.3420201;zc=.767;r=.044
    p=a['p'];records=[]
    for side in [-1,1]:
        angle=math.radians(20 if breed=='poodle' else 45)
        n=Vector((side*math.sin(angle),-math.cos(angle),0));t=Vector((side*math.cos(angle),math.sin(angle),0))
        origin=(t*uc+Vector((0,0,zc))+n*2)*H
        inv=body.matrix_world.inverted();hit,loc,sn,idx=body.ray_cast(inv@origin,inv.to_3x3()@(-n));assert hit
        center=np.array(body.matrix_world@loc)/H
        # More frontal local tangent prevents the 45-degree projection stretching
        # on the forward head. Depth + facing limits prevent back-surface ghosts.
        angle=math.radians(20)
        tangent=np.array([math.cos(angle),side*math.sin(angle),0])
        normal=np.array([side*math.sin(angle),-math.cos(angle),0])
        q=p-center;du=q@tangent;dv=q[:,2]
        radius=r*.90
        disk=(du/radius)**2+(dv/(radius*1.04))**2
        mask=(p[:,0]*side>0)*(1-tex.smooth(.045,.08,np.abs(q@normal)))
        coords=np.stack([628+du/radius*523,617-dv/(radius*1.04)*462],1)
        # Supersample the material source at the small eye's atlas footprint;
        # premultiplied filtering avoids dark transparent-edge fringes.
        coverage=np.zeros(len(p),np.float32);color=np.zeros_like(c)
        for dx in [-12,-4,4,12]:
            for dy in [-12,-4,4,12]:
                st=coords+np.array([dx,dy])
                aa=tex.sample(alpha,st)[:,0]
                coverage+=aa/16
                color+=tex.sample(eye,st)*aa[:,None]/16
        color/=np.maximum(coverage[:,None],1e-8)
        mask*=coverage
        # Test actual geometric visibility along the projector direction. A
        # depth slab alone also painted hidden folded surfaces near the nose.
        for index in np.flatnonzero(mask>.001):
            point=Vector(p[index]*H)
            ray_origin=point+Vector(normal)*H
            hit,where,_,_=body.ray_cast(inv@ray_origin,inv.to_3x3()@Vector(-normal))
            if not hit or ((body.matrix_world@where)-point).length>H*.003:
                mask[index]=0
        c=tex.mix(c,color,mask)
        records.append({'side':side,'center':center.tolist(),'radius':radius})
    result=tex.read_image(ROOT/'build/dogs_face_repair_r5/candidate'/breed/'basecolor_codex.png')
    changed=np.max(np.abs(c-a['c']),axis=1)>1e-7
    surface=result[a['have']];surface[changed]=c[changed];result[a['have']]=surface
    filled=a['have'].copy()
    for _ in range(12):
        acc=np.zeros_like(result);count=np.zeros(filled.shape,np.float32)
        for delta in [(1,0),(-1,0),(0,1),(0,-1)]:
            f=np.roll(filled,delta,(0,1));acc+=np.roll(result,delta,(0,1))*f[...,None];count+=f
        grow=~filled&(count>0);result[grow]=acc[grow]/count[grow,None];filled|=grow
    im=bpy.data.images.new(breed+'_complete_eyes',1024,1024,alpha=False)
    im.pixels=np.concatenate([result[::-1],np.ones((1024,1024,1))],-1).astype(np.float32).ravel()
    im.file_format='PNG';im.filepath_raw=str(dest/'basecolor_codex.png');im.save()
    bpy.context.scene.render.image_settings.quality=90
    im.file_format='JPEG';im.filepath_raw=str(dest/'basecolor_codex.jpg');im.save()
    (dest/'eye_placement.json').write_text(json.dumps(records,indent=2))
    print('EYE_BAKE_R6',breed)

if __name__=='__main__':
    for breed in sys.argv[sys.argv.index('--')+1:]:main(breed)
