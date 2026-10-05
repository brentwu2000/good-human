"""Local surface-space nose repair over r6; preserve mesh and eye texels."""
import bpy, pathlib, sys, numpy as np, json
ROOT=pathlib.Path(r'C:\Users\b\Documents\good-human')
sys.path.insert(0,str(ROOT/'tools/art'))
import repair_breed_dog_textures as tex
OUT=ROOT/'build/dogs_muzzle_r8/pomeranian'

def main():
    a=np.load(ROOT/'build/dogs_face_repair_r5/candidate/pomeranian/face_surface.npz')
    original=tex.read_image(ROOT/'build/dogs_eye_r6/texture_candidate/pomeranian/basecolor_codex.png')
    p=a['p']; x,y,z=p.T
    c=original[a['have']].copy()
    # Coat bridge: remove white cut and duplicated nose projection above the snout.
    bridge=(1-tex.smooth(.070,.103,np.abs(x)))*tex.smooth(.645,.680,z)*(1-tex.smooth(.79,.82,z))*(1-tex.smooth(-.41,-.36,y))
    warm=np.array([.82,.51,.25])+(.012*np.sin(z*160+x*100))[:,None]
    c=tex.mix(c,warm,bridge)
    # Cream wrap on the actual muzzle, independent of UV island/view seams.
    muzzle=(1-tex.smooth(.085,.13,np.abs(x)))*tex.smooth(.568,.596,z)*(1-tex.smooth(.650,.677,z))*(1-tex.smooth(-.405,-.37,y))
    cream=np.array([.88,.81,.69])+(.006*np.sin(x*210+z*170))[:,None]
    c=tex.mix(c,cream,muzzle)
    # A single nose over the protruding lower bulb; surface coordinates ensure
    # the same colour wraps around its sides instead of duplicating a photo.
    d=(x/.068)**2+((z-.615)/.048)**2
    nose=(1-tex.smooth(.84,1.12,d))*(1-tex.smooth(-.458,-.430,y))
    v=.006*np.sin(x*900)*np.sin(z*1100)
    nose_col=np.tile([.105,.083,.076],(len(x),1))+v[:,None]
    # Retain the owner's nostrils and leathery nose detail on the forward cap.
    ref=tex.read_image(tex.F/'references/dogs/pomeranian_front.png')
    uv=np.stack([372+x/.055*25,287-(z-.620)/.034*19],1)
    detail=tex.sample(ref,uv)
    dark=1-tex.smooth(.30,.48,detail.mean(1))
    cap=(1-tex.smooth(.65,1.0,(x/.055)**2+((z-.620)/.034)**2))
    nose_col=tex.mix(nose_col,detail,dark*cap)
    c=tex.mix(c,nose_col,nose)
    changed=np.maximum.reduce([bridge,muzzle,nose])
    result=original.copy();result[a['have']]=np.clip(c,0,1)
    filled=a['have'].copy()
    for _ in range(12):
        acc=np.zeros_like(result);count=np.zeros(filled.shape,np.float32)
        for delta in [(1,0),(-1,0),(0,1),(0,-1)]:
            f=np.roll(filled,delta,(0,1));acc+=np.roll(result,delta,(0,1))*f[...,None];count+=f
        grow=~filled&(count>0);result[grow]=acc[grow]/count[grow,None];filled|=grow
    im=bpy.data.images.new('pomeranian_muzzle_r8',1024,1024,alpha=False)
    im.pixels=np.concatenate([result[::-1],np.ones((1024,1024,1))],-1).astype(np.float32).ravel()
    for fmt,ext in [('PNG','png'),('JPEG','jpg')]:
        im.file_format=fmt;im.filepath_raw=str(OUT/f'basecolor_codex.{ext}');im.save()
    body=bpy.data.objects['DogBody']
    for mat in body.data.materials:
        for node in mat.node_tree.nodes:
            if node.type=='TEX_IMAGE':node.image=im
    (OUT/'repair.json').write_text(json.dumps({'base':'r6','changed_surface_texels':int((changed>.001).sum()),'geometry_changed':False},indent=2))
    print('MUZZLE_R8_BAKED')

if __name__=='__main__':main()
