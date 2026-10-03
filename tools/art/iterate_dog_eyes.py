"""Fast Blender texture iteration using cached UV surface samples."""
import pathlib,sys,os
sys.path.insert(0,str(pathlib.Path(__file__).parent))
from repair_breed_dog_textures import *
for breed in sys.argv[sys.argv.index('--')+1:]:
    dest=OUT/breed
    a=np.load(dest/'face_surface.npz')
    c=rebuild_face(breed,*[a[k] for k in ['c','p','n','co','tris','fur','pale']],read_image,sample,smooth,mix,F)
    previous=OUT.parent/'previous'/breed/'basecolor_codex.png'
    result=read_image(previous)
    changed=np.max(np.abs(c-a['c']),axis=1)>1e-7
    surface=result[a['have']];surface[changed]=c[changed];result[a['have']]=surface
    filled=a['have'].copy()
    for _ in range(12):
        acc=np.zeros_like(result);count=np.zeros(filled.shape,np.float32)
        for delta in [(1,0),(-1,0),(0,1),(0,-1)]:
            f=np.roll(filled,delta,(0,1));acc+=np.roll(result,delta,(0,1))*f[...,None];count+=f
        grow=~filled&(count>0);result[grow]=acc[grow]/count[grow,None];filled|=grow
    im=bpy.data.images.new(breed,1024,1024,alpha=False)
    im.pixels=np.concatenate([result[::-1],np.ones((1024,1024,1))],-1).astype(np.float32).ravel()
    im.file_format='PNG';im.filepath_raw=str(dest/'basecolor_codex.png');im.save()
    bpy.context.scene.render.image_settings.quality=90
    im.file_format='JPEG';im.filepath_raw=str(dest/'basecolor_codex.jpg');im.save()
    print('EYE_BAKE',breed,int(changed.sum()),flush=True)
