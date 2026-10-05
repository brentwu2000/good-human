"""R7 staged socket/eyelid modelling and coherent face UV material work.

All operations begin from immutable r6 backups; previews are not published here.
"""
import bpy,bmesh,pathlib,sys,json,math
import numpy as np
from mathutils import Vector
from mathutils.geometry import barycentric_transform
ROOT=pathlib.Path(r'C:\Users\b\Documents\good-human')
OUT=ROOT/'build/dogs_face_r7'
sys.path.insert(0,str(ROOT/'tools/art'))
import repair_breed_dog_textures as tex
from repair_dog_faces import EYES

def mat(name,color,rough=.5):
    m=bpy.data.materials.new(name);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough
    return m

def mesh(name,verts,faces,material,arm,colors=None):
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob);me.materials.append(material)
    for p in me.polygons:p.use_smooth=True
    if colors is not None:
        ca=me.color_attributes.new(name='Coat',type='FLOAT_COLOR',domain='POINT')
        for entry,col in zip(ca.data,colors):entry.color=(*col,1)
    world=ob.matrix_world.copy();ob.parent=arm;ob.matrix_world=world
    group=ob.vertex_groups.new(name='head');group.add(list(range(len(verts))),1,'REPLACE')
    mod=ob.modifiers.new('Head skin','ARMATURE');mod.object=arm
    return ob

def clean_atlas(breed,dest):
    a=np.load(ROOT/'build/dogs_face_repair_r5/candidate'/breed/'face_surface.npz')
    code=(ROOT/'tools/art/repair_dog_faces.py').read_text(encoding='utf-8-sig').replace('alpha=(1-smooth(.82,1.52,disk))*clear','alpha=np.zeros(len(x))')
    code=code.replace("clear_z=.090 if breed=='frenchie' else .070", "clear_z=.100 if breed=='frenchie' else .100")
    ns={};exec(code,ns)
    c=ns['rebuild_face'](breed,*[a[k] for k in ['c','p','n','co','tris','fur','pale']],tex.read_image,tex.sample,tex.smooth,tex.mix,tex.F)
    if breed=='pomeranian':
        x,y,z=a['p'].T
        bridge=(1-tex.smooth(.065,.115,np.abs(x)))*tex.smooth(.66,.705,z)*(1-tex.smooth(.82,.88,z))*(1-tex.smooth(-.22,-.12,y))
        c=tex.mix(c,a['fur'],bridge)
    if breed=='frenchie':
        # One continuous cylindrical face map replaces the competing planar
        # front/side mouth and nose images. Features now share the same surface.
        x,y,z=a['p'].T
        ref=tex.read_image(tex.F/'references/dogs/frenchie_front.png')
        arc=np.arctan2(x,-(y+.17))*np.sqrt(x*x+(y+.17)**2)
        sy=np.interp(z,[.40,.46,.52,.60,.635,.710,.83,.90],[438,396,349,298,251,233,138,88])
        coords=np.stack([326+arc*600,sy],1)
        mapped=tex.sample(ref,coords)
        # Source-eye occlusion is never baked into the skin; sockets receive
        # their own real geometry below.
        source_eye=np.maximum(1-tex.smooth(.8,1.8,((coords[:,0]-238)/43)**2+((coords[:,1]-233)/40)**2),1-tex.smooth(.8,1.8,((coords[:,0]-414)/43)**2+((coords[:,1]-233)/40)**2))
        mapped=tex.mix(mapped,c,source_eye)
        head=tex.smooth(.43,.47,z)*(1-tex.smooth(.60,.63,z))*(1-tex.smooth(-.18,-.08,y))
        valid=tex.sample(tex.figure_mask(ref).astype(float)[...,None].repeat(3,axis=2),coords)[:,0]
        front=1-tex.smooth(.20,.31,np.abs(arc))
        clean_muzzle=tex.mix(a['pale'],mapped,valid*front)
        c=tex.mix(c,clean_muzzle,head)
    ar=tex.read_image(ROOT/'build/dogs_face_repair_r5/candidate'/breed/'basecolor_codex.png')
    changed=np.max(np.abs(c-a['c']),axis=1)>1e-7
    surf=ar[a['have']];surf[changed]=c[changed];ar[a['have']]=surf
    filled=a['have'].copy()
    for _ in range(12):
        acc=np.zeros_like(ar);count=np.zeros(filled.shape,np.float32)
        for delta in [(1,0),(-1,0),(0,1),(0,-1)]:
            f=np.roll(filled,delta,(0,1));acc+=np.roll(ar,delta,(0,1))*f[...,None];count+=f
        grow=~filled&(count>0);ar[grow]=acc[grow]/count[grow,None];filled|=grow
    im=bpy.data.images.new(breed+'_r7_face',1024,1024,alpha=False)
    im.pixels=np.concatenate([ar[::-1],np.ones((1024,1024,1))],-1).astype(np.float32).ravel()
    im.file_format='PNG';im.filepath_raw=str(dest/'face_atlas.png');im.save();im.pack()
    return im,ar

def main(breed):
    dest=OUT/breed;dest.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(OUT/'previous'/f'{breed}.glb'))
    arm=next(o for o in bpy.data.objects if o.type=='ARMATURE');arm.data.pose_position='REST'
    body=max((o for o in bpy.data.objects if o.type=='MESH'),key=lambda o:len(o.data.vertices))
    for ob in list(bpy.data.objects):
        if ob.type=='MESH' and ob!=body:bpy.data.objects.remove(ob,do_unlink=True)
    if not (dest/'00_before.blend').exists():bpy.ops.wm.save_as_mainfile(filepath=str(dest/'00_before.blend'))
    H=float(np.ptp(np.array([body.matrix_world@v.co for v in body.data.vertices])[:,2]))
    image,atlas=clean_atlas(breed,dest)
    for m in body.data.materials:
        for node in m.node_tree.nodes:
            if node.type=='TEX_IMAGE':node.image=image
    bpy.context.view_layer.objects.active=body;body.select_set(True)
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    # Weld positional duplicates across UV seams before local smoothing; loop
    # UVs and deform weights remain on the welded mesh.
    bm=bmesh.new();bm.from_mesh(body.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=H*1e-6);bm.to_mesh(body.data);bm.free()
    me=body.data
    points=np.array([v.co for v in me.vertices])/H
    if breed=='pomeranian':
        # Pull the erroneous brow shelf back into a continuous nasal bridge.
        x,y,z=points.T
        bridge=(1-tex.smooth(.065,.115,np.abs(x)))*tex.smooth(.66,.705,z)*(1-tex.smooth(.82,.88,z))*(1-tex.smooth(-.25,-.15,y))
        target=np.interp(z,[.66,.705,.78,.86],[-.43,-.39,-.33,-.28])
        points[:,1]+=bridge*np.maximum(0,target-y)
    placements=json.loads((ROOT/'build/dogs_eye_r6/texture_candidate'/breed/'eye_placement.json').read_text())
    centers=np.array([p['center'] for p in placements]);cx=np.mean(np.abs(centers[:,0]));cy=np.mean(centers[:,1]);cz=np.mean(centers[:,2])
    radius=EYES[breed][2]*1.00
    if breed=='poodle':radius=.048
    anchors=[np.array([side*cx,cy,cz]) for side in [-1,1]]
    # Smooth folds in the socket neighbourhood, with a zero-displacement border.
    adj=[[] for _ in me.vertices]
    for e in me.edges:a,b=e.vertices;adj[a].append(b);adj[b].append(a)
    weight=np.zeros(len(points))
    for c in anchors:
        d=((points[:,0]-c[0])/(radius*2.0))**2+((points[:,2]-c[2])/(radius*1.9))**2
        weight=np.maximum(weight,(1-tex.smooth(.45,1,d))*(1-tex.smooth(.06,.11,np.abs(points[:,1]-c[1]))))
    for _ in range(10):
        new=points.copy()
        for i in np.flatnonzero(weight>.001):
            if adj[i]:new[i]+=weight[i]*.40*(points[adj[i]].mean(0)-points[i])
        points=new
    for v,p in zip(me.vertices,points):v.co=p*H
    me.update();bpy.context.view_layer.update()
    # Sample the newly smoothed body for outer socket continuity and UV colour.
    sampler=body.copy();sampler.data=body.data.copy();bpy.context.collection.objects.link(sampler);sampler.hide_render=True
    sample_me=sampler.data
    inv=body.matrix_world.inverted()
    def ray(point,normal):
        hit,where,no,index=sampler.ray_cast(inv@(Vector(point)+Vector(normal)*H),inv.to_3x3()@Vector(-np.array(normal)))
        if not hit:return Vector(point),np.array([.3,.2,.12])
        poly=sample_me.polygons[index];vs=[sample_me.vertices[i].co for i in poly.vertices[:3]]
        uv=[Vector((*sample_me.uv_layers.active.data[i].uv,0)) for i in list(poly.loop_indices)[:3]]
        st=barycentric_transform(where,*vs,*uv)
        col=tex.sample(atlas,np.array([[st.x*1024,(1-st.y)*1024]]))[0]
        col=np.where(col<=.04045,col/12.92,((col+.055)/1.055)**2.4)
        world=body.matrix_world@where
        delta=world-Vector(point)
        if delta.length>H*.045:
            world=Vector(point)+Vector(normal)*max(-H*.045,min(H*.045,delta.dot(Vector(normal))))
        return world,col
    # Cache all samples before opening the socket holes.
    eye_records=[]
    for side,c in zip([-1,1],anchors):
        outward={'frenchie':.60,'poodle':.25,'chihuahua':.40,'pomeranian':.45,'corgi':.50,'shiba':.50,'golden':.50}[breed]
        forward=math.sqrt(1-outward*outward)
        n=np.array([side*outward,-forward,0]);t=np.array([forward,side*outward,0]);up=np.array([0,0,1])
        hit,_=ray(c*H,n);anchor=np.array(hit)
        samples=[]
        for k in range(64):
            th=2*math.pi*k/64
            p=anchor+t*(math.cos(th)*radius*H*1.30)+up*(math.sin(th)*radius*H*1.30)
            samples.append(ray(p,n))
        eye_records.append((side,anchor,n,t,up,samples))
    # Replace the folded surface inside each eye aperture with real eyeball and
    # concentric eyelid loops. The annulus covers the cut boundary completely.
    bm=bmesh.new();bm.from_mesh(me);remove=[]
    for face in bm.faces:
        p=np.array(face.calc_center_median())
        for side,a,n,t,up,samples in eye_records:
            q=(p-a)/H;u=q@t;v=q[2]
            if (u/radius)**2+(v/(radius*.94))**2<1.05 and abs(q@n)<.10:
                remove.append(face);break
    bmesh.ops.delete(bm,geom=remove,context='FACES')
    boundary={}
    uv_layer=bm.loops.layers.uv.active
    for side,a,n,t,up,samples in eye_records:
        candidates=[]
        for v in bm.verts:
            if not any(e.is_boundary for e in v.link_edges):continue
            q=(np.array(v.co)-a)/H
            if abs(q@n)>.13 or (q@t)**2+q[2]**2>(radius*1.6)**2:continue
            candidates.append(v)
        allowed=set(candidates)
        start=min(candidates,key=lambda v:math.atan2((np.array(v.co)-a)[2],(np.array(v.co)-a)@t))
        ordered=[start];previous=None;current=start
        while True:
            options=[e.other_vert(current) for e in current.link_edges if e.is_boundary and e.other_vert(current) in allowed and e.other_vert(current)!=previous]
            assert options,'Open socket boundary'
            nxt=options[0]
            if nxt==start:break
            assert nxt not in ordered,'Branching socket boundary'
            ordered.append(nxt);previous,current=current,nxt
        assert len(ordered)==len(candidates),(side,len(ordered),len(candidates))
        flat=np.array([[(np.array(v.co)-a)@t,(np.array(v.co)-a)[2]] for v in ordered])
        if np.sum(flat[:,0]*np.roll(flat[:,1],-1)-flat[:,1]*np.roll(flat[:,0],-1))<0:ordered=[ordered[0]]+ordered[:0:-1]
        theta0=math.atan2((np.array(ordered[0].co)-a)[2],(np.array(ordered[0].co)-a)@t)
        depth=np.array([(np.array(v.co)-a)@n for v in ordered])
        for _ in range(8):depth=(np.roll(depth,1)+depth*2+np.roll(depth,-1))/4
        depth=np.clip(depth,-H*.035,H*.015)
        entries=[]
        for k,v in enumerate(ordered):
            theta=theta0+k*math.tau/len(ordered)
            uv=v.link_loops[0][uv_layer].uv
            col=tex.sample(atlas,np.array([[uv.x*1024,(1-uv.y)*1024]]))[0]
            col=np.where(col<=.04045,col/12.92,((col+.055)/1.055)**2.4)
            position=a+t*(math.cos(theta)*radius*H*1.03)+up*(math.sin(theta)*radius*H*.98)+n*depth[k]
            v.co=position
            entries.append((theta,position,col))
        assert len(entries)>16,(side,len(entries))
        boundary[side]=entries
    bm.to_mesh(me);bm.free();me.update()
    black=mat('Eye sclera dark brown',(.008,.004,.002),.18)
    en=black.node_tree.nodes.new('ShaderNodeVertexColor');en.layer_name='Coat';black.node_tree.links.new(en.outputs['Color'],black.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
    iris=mat('Iris amber',(.10,.035,.008),.24)
    pupil=mat('Pupil',(.0015,.0008,.0004),.16)
    lid=mat('Lid coat',(.2,.12,.08),.66)
    node=lid.node_tree.nodes.new('ShaderNodeVertexColor');node.layer_name='Coat';lid.node_tree.links.new(node.outputs['Color'],lid.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
    for side,a,n,t,up,samples in eye_records:
        rx=radius*H;rz=rx*1.04;depth=rx*.68;center=a-n*(rx*.47)
        # Ring topology sphere whose forward surface has a large dark pupil.
        verts=[];faces=[];eye_colors=[];segments=40;rings=24
        for j in range(rings+1):
            phi=math.pi*j/rings
            for k in range(segments):
                th=k*math.tau/segments
                verts.append(center+t*(rx*math.sin(phi)*math.cos(th))+up*(rz*math.sin(phi)*math.sin(th))+n*(depth*math.cos(phi)))
                rr=math.sin(phi)
                band=float(tex.smooth(.72,.79,np.array(rr))*(1-tex.smooth(.89,.95,np.array(rr)))) if phi<math.pi/2 else 0
                variation=.80+.20*math.sin(th*13+phi*15)
                brown=np.array([.095,.028,.006])*(.45+.55*max(0,-math.sin(th)))*variation
                eye_colors.append(np.array([.0025,.0015,.0008])*(1-band)+brown*band)
        for j in range(rings):
            for k in range(segments):
                aa=j*segments+k;bb=j*segments+(k+1)%segments;faces.append((aa,aa+segments,bb+segments,bb))
        eye=mesh(f'Eye_{side:+d}',verts,faces,black,arm,eye_colors)
        # Iris and pupil are curved patches on the eye, not flat decals.
        for name,rad,material,offset in []:
            vv=[];ff=[]
            for j in range(9):
                rr=rad*j/8
                for k in range(segments):
                    th=k*math.tau/segments
                    vv.append(center+t*(rx*rr*math.cos(th))+up*(rz*rr*math.sin(th))+n*(depth*math.sqrt(1-rr*rr)+offset))
            for j in range(8):
                for k in range(segments):
                    aa=j*segments+k;bb=j*segments+(k+1)%segments;ff.append((aa,aa+segments,bb+segments,bb))
            mesh(f'{name}_{side:+d}',vv,ff,material,arm)
        vv=[];cc=[];ff=[];steps=8
        entries=boundary[side];segments=len(entries)
        mean_coat=np.median(np.array([entry[2] for entry in entries]),axis=0)
        for j in range(steps+1):
            s=j/steps;f=s*s*(3-2*s)
            for k in range(segments):
                th,outer,coat=entries[k]
                # Slightly hooded upper lid; lower rim follows the globe.
                ux=math.cos(th)*.88;uz=math.sin(th)*(.78 if math.sin(th)>0 else .80)
                inner=center+t*(rx*ux)+up*(rz*uz)+n*(depth*math.sqrt(max(0,1-ux*ux-uz*uz))+.0001)
                point=inner*(1-f)+outer*f+n*(math.sin(math.pi*s)*rx*.04)
                vv.append(point)
                dark=np.array([.017,.008,.004])
                blend=float(tex.smooth(.03,.32,np.array(s)))
                local_coat=mean_coat*(1-f)+coat*f
                cc.append(dark*(1-blend)+local_coat*blend)
        for j in range(steps):
            for k in range(segments):
                aa=j*segments+k;bb=j*segments+(k+1)%segments;ff.append((aa,aa+segments,bb+segments,bb))
        mesh(f'Eyelids_{side:+d}',vv,ff,lid,arm,cc)
    bpy.data.objects.remove(sampler,do_unlink=True)
    # Weld the eyelid outer loops to the actual body boundary, so the surface
    # shares positions, normals and skinning instead of overlapping a decal.
    ca=body.data.color_attributes.new(name='Coat',type='FLOAT_COLOR',domain='POINT')
    vu=np.zeros((len(body.data.vertices),2))
    for loop in body.data.loops:vu[loop.vertex_index]=body.data.uv_layers.active.data[loop.index].uv
    col=tex.sample(atlas,np.stack([vu[:,0]*1024,(1-vu[:,1])*1024],1));col=np.where(col<=.04045,col/12.92,((col+.055)/1.055)**2.4)
    ca.data.foreach_set('color',np.concatenate([col,np.ones((len(col),1))],1).astype(np.float32).ravel())
    bpy.ops.object.select_all(action='DESELECT');body.select_set(True)
    for o in bpy.data.objects:
        if o.name.startswith('Eyelids_'):o.select_set(True)
    bpy.context.view_layer.objects.active=body;bpy.ops.object.join()
    bm=bmesh.new();bm.from_mesh(body.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=H*1e-6);bm.to_mesh(body.data);bm.free()
    bpy.ops.wm.save_as_mainfile(filepath=str(dest/'01_sockets.blend'))
    arm.data.pose_position='POSE'
    bpy.ops.object.select_all(action='DESELECT')
    for o in bpy.data.objects:
        if o==arm or (o.type=='MESH' and o.parent==arm):o.select_set(True)
    bpy.context.view_layer.objects.active=arm
    bpy.ops.export_scene.gltf(filepath=str(dest/f'{breed}_game_codex.glb'),use_selection=True,export_format='GLB',export_image_format='JPEG',export_jpeg_quality=92,export_animations=True)
    print('R7_SOCKET_STAGE',breed,'removed',len(remove),'radius',radius)

if __name__=='__main__':
    for breed in sys.argv[sys.argv.index('--')+1:]:main(breed)
