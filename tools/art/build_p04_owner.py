"""Blender stage 2: adapt installed CC0 MPFB base into modular clothed owner.
Run inside Blender after owner_01_base.blend. Source base remains in milestone.
"""
import bpy, math, os
from mathutils import Vector, Matrix

WORK = r'C:\Users\b\Documents\good-human-3d-pipeline\blender\human\p04_owner'
h = bpy.data.objects['OwnerBody']
rig = bpy.data.objects['OwnerBody.rig']
rig.name = 'OwnerSkeleton'
for mod in h.modifiers: mod.show_viewport = False
dg = bpy.context.evaluated_depsgraph_get(); dg.update()
evaluated = bpy.data.meshes.new_from_object(h.evaluated_get(dg), depsgraph=dg)
groups = {g.name:g.index for g in h.vertex_groups}
members = {name:{v.index for v in h.data.vertices if any(g.group==idx for g in v.groups)} for name,idx in groups.items()}
weights = {v.index:{h.vertex_groups[g.group].name:g.weight for g in v.groups if h.vertex_groups[g.group].name in rig.data.bones} for v in h.data.vertices}
zmax = max(evaluated.vertices[i].co.z for i in members['body'])
factor = 1.76 / zmax
for v in evaluated.vertices: v.co *= factor
for b in rig.data.bones: pass
bpy.ops.object.select_all(action='DESELECT'); rig.select_set(True); bpy.context.view_layer.objects.active=rig
rig.data.transform(Matrix.Scale(factor,4));rig.scale=(1,1,1)

def mat(name, color, rough=.75):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough
    return m
skin=mat('GH_Skin',(0.52,.30,.19),.56)
jacket=mat('GH_Jacket',(.32,.265,.19))
denim=mat('GH_Denim',(.042,.072,.105),.86)
cream=mat('GH_Cotton',(.57,.54,.46),.9)
hair=mat('GH_Hair',(.025,.017,.013),.72)
shoe=mat('GH_Shoe',(.055,.058,.053),.75)
sole=mat('GH_Rubber',(.39,.37,.31),.88)
eye=mat('GH_EyeWhite',(.68,.66,.57),.32)
iris=mat('GH_Iris',(.047,.028,.015),.28)

def subset(name, group, predicate, material, offset=0):
    ids=members[group]
    faces=[p for p in evaluated.polygons if all(i in ids for i in p.vertices) and predicate(sum((evaluated.vertices[i].co for i in p.vertices),Vector())/len(p.vertices))]
    used=sorted({i for p in faces for i in p.vertices}); remap={old:i for i,old in enumerate(used)}
    me=bpy.data.meshes.new(name);me.from_pydata([evaluated.vertices[i].co+evaluated.vertices[i].normal*offset for i in used],[],[[remap[i] for i in p.vertices] for p in faces]);me.update()
    o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);o.data.materials.append(material)
    for n in rig.data.bones.keys():o.vertex_groups.new(name=n)
    for new,old in enumerate(used):
        for n,w in weights[old].items():o.vertex_groups[n].add([new],w,'REPLACE')
    a=o.modifiers.new('Skin','ARMATURE');a.object=rig;o.parent=rig
    for p in me.polygons:p.use_smooth=True
    if evaluated.uv_layers.active:
        uv=me.uv_layers.new(name='UVMap')
        for np,op in zip(me.polygons,faces):
            for ni,oi in zip(np.loop_indices,op.loop_indices):uv.data[ni].uv=evaluated.uv_layers.active.data[oi].uv
    return o

# Visible anatomical head/neck and hands only. Covered body retained in base milestone.
body=subset('Body_HeadHands','body',lambda p:p.z>1.43 or (abs(p.x)>.445 and p.z>.75),skin)
top=subset('Top_Jacket','helper-tights',lambda p:.93<p.z<1.51 and abs(p.x)<.46,jacket,.018)
bottom=subset('Bottom_Jeans','helper-tights',lambda p:.13<p.z<1.04,denim,.012)
# Relax silhouette and add restrained fabric creasing without breaking weight topology.
for o in [top,bottom]:
    for v in o.data.vertices:
        x,y,z=v.co
        if o==top:
            if abs(x)<.23: v.co.y += .015 if y>0 else -.012
        else:
            side=1 if x>0 else -1; center=side*(.12+.035*(1-z))
            v.co.x=center+(x-center)*1.13
        wave=.0025*math.sin(z*93+x*35)*math.sin(y*37+z*19)
        v.co += v.normal*wave
    s=o.modifiers.new('Hem thickness','SOLIDIFY');s.thickness=.003;s.offset=0

# A fitted cotton chest insert sits inside the jacket opening.
insert=subset('Top_Undershirt','helper-tights',lambda p:.98<p.z<1.47 and abs(p.x)<.085 and p.y<-.015,cream,.021)
scalp=subset('Hair_Short','body',lambda p:p.z>1.645 and (p.y>-.075 or p.z>1.719),hair,.006)
for side in ['l','r']:
    subset('Eye_'+side,'helper-'+side+'-eye',lambda p:True,eye,0)

def rigid_mesh(name, verts, faces, material, bone):
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);me.materials.append(material)
    vg=o.vertex_groups.new(name=bone);vg.add(list(range(len(verts))),1,'REPLACE')
    a=o.modifiers.new('Skin','ARMATURE');a.object=rig;o.parent=rig
    for p in me.polygons:p.use_smooth=True
    return o

def shoe_mesh(side):
    b=rig.data.bones['foot_'+side];x=b.head_local.x
    # Elliptical toe/heel sections form a shoe, not an enclosing box.
    verts=[];faces=[]; n=16
    for y,w,z,hgt in [( .055,.047,.065,.036),(.02,.064,.09,.06),(-.07,.067,.082,.057),(-.16,.066,.052,.03),(-.215,.04,.045,.018)]:
        for j in range(n):
            a=math.tau*j/n;verts.append((x+w*math.cos(a),y,z+hgt*math.sin(a)))
    for k in range(4):
        for j in range(n):faces.append((k*n+j,k*n+(j+1)%n,(k+1)*n+(j+1)%n,(k+1)*n+j))
    faces.extend([tuple(reversed(range(n))),tuple(4*n+j for j in range(n))])
    o=rigid_mesh('Shoes_'+side,verts,faces,shoe,'foot_'+side)
    verts2=[(a,b,max(.009,min(.038,c))) for a,b,c in verts]
    rigid_mesh('Soles_'+side,verts2,faces,sole,'foot_'+side)
shoe_mesh('l');shoe_mesh('r')

h.hide_render=True;h.hide_set(True);h.name='SOURCE_HIDDEN_DO_NOT_EXPORT'
bpy.context.scene['art_stage']='P04 owner modular construction; review not final'
bpy.ops.wm.save_as_mainfile(filepath=WORK+'/owner_02_clothed.blend')
print('CREATED',[(o.name,len(o.data.polygons)) for o in bpy.context.scene.objects if o.type=='MESH' and not o.hide_render])
