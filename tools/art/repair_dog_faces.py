"""Local tangent-plane eye painting. One source eye per anatomical side."""
import numpy as np

# target tangent coordinate, height, radius; source left/right eye centres/radius.
EYES={
 'chihuahua':(-.115,.690,.044, (326,463),267,38),
 'pomeranian':(-.198,.703,.040, (296,441),268,32),
 'poodle':(-.035,.712,.049, (320,449),235,34),
 'frenchie':(-.175,.710,.052, (238,414),233,34),
 'corgi':(-.178,.741,.043, (338,464),228,32),
 'shiba':(-.165,.780,.036, (277,390),192,26),
 'golden':(-.205,.900,.035, (249,354),112,25),
}

def rebuild_face(breed,c,p,n,co,tris,fur,pale,read_image,sample,smooth,mix,factory):
    x,y,z=p.T
    ref=read_image(factory/'references/dogs'/f'{breed}_front.png')
    uc,zc,r,centres,sy,sr=EYES[breed]
    u=(np.abs(x)+y)*.70710678
    if breed=='poodle':u=np.abs(x)*.9396926+y*.3420201
    du=u-uc;dv=z-zc
    if breed=='poodle':
        # The lower right 'socket' is the sloping muzzle. Place both eyes on
        # the actual forward-facing head above it, not on that muzzle shelf.
        du=(np.abs(x)-.105)*.9396926+(y+.313)*.3420201
        dv=z-.767
        r=.044
    # Full-opacity core erases BOTH prior front and side projections.
    clear_u=.13 if breed=='frenchie' else (.10 if breed in ['chihuahua','poodle'] else .085)
    clear_z=.090 if breed=='frenchie' else .070
    dist=(du/clear_u)**2+(dv/clear_z)**2
    clear=1-smooth(.66,1.35,dist)
    if breed=='poodle':
        clear=(1-smooth(.075,.105,np.abs(z-.731)))*(1-smooth(.17,.205,np.abs(x)))
    if breed=='frenchie':clear=1-smooth(.075,.105,np.abs(z-.715))
    clear*=1-smooth(-.15,-.08,y)
    if breed!='frenchie':clear*=smooth(.035,.065,np.abs(x))
    sx=np.where(x<0,centres[0],centres[1])
    # Fur-only swatch immediately above the eye, excluding the brow.
    donor=sample(ref,np.stack([sx+np.where(x<0,-1,1)*45,np.full(len(x),sy-35)],1))
    if breed=='frenchie':donor[:]=np.median(ref[175:200,225:250].reshape(-1,3),axis=0)
    base=mix(fur,donor,np.full(len(x),.75))
    if breed=='frenchie':
        stripe=(1-smooth(.045,.085,np.abs(x)))*smooth(.62,.67,z)
        base=mix(base,pale,stripe)
    result=mix(c,base,clear)
    coords=np.stack([sx+np.where(x<0,-1,1)*du/r*sr,sy-dv/r*sr],1)
    eye=sample(ref,coords)
    disk=(du/r)**2+(dv/r)**2
    alpha=(1-smooth(.82,1.52,disk))*clear
    result=mix(result,eye,alpha)
    if breed=='frenchie':
        # Register the nose separately: the sheet's face centre is offset from
        # its full-body bounding box, which caused the old forehead nostrils.
        nv=(y+.53)*.5+(z-.635)*.8660254
        disk=(x/.070)**2+(nv/.035)**2
        nose_alpha=(1-smooth(.75,1.30,disk))*(1-smooth(-.47,-.43,y))
        nose=sample(ref,np.stack([329+x/.070*43,245-nv/.035*24],1))
        result=mix(result,nose,nose_alpha)
    return result
