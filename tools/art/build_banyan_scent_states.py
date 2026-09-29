import bpy, math, os

WORK=r'C:\Users\b\Documents\good-human-3d-pipeline\blender\environment\banyan_01'
OUT=r'C:\Users\b\Documents\good-human\assets\environment\territory\models\banyan_01'
bpy.ops.wm.save_as_mainfile(filepath=WORK+'/banyan_06_before_scent.blend')

def material(name, color, emission=0.0):
    m=bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.diffuse_color=(*color,1);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=.72
    p.inputs['Emission Color'].default_value=(*color,1);p.inputs['Emission Strength'].default_value=emission
    return m

teal=material('Scent_Player_Teal',(.055,.42,.36),.08)
coral=material('Scent_Rival_Coral',(.62,.18,.13),.06)
violet=material('Scent_Discovered_Violet',(.38,.24,.48),.05)
amber=material('Scent_Recognize_Amber',(.8,.4,.08),.25)
cream=material('Scent_Reward_Cream',(.85,.72,.36),.12)
states={'UNKNOWN':[],'DISCOVERED':[violet],'CONTESTED':[coral,teal,coral],'CLAIMING':[teal,coral,teal,teal],'OWNED':[teal,teal,teal,teal]}
for state,mats in states.items():
    root=bpy.data.collections.new('ScentState_'+state);bpy.context.scene.collection.children.link(root)
    for i,m in enumerate(mats):
        a=-1.0+i*.62;x=math.sin(a)*1.15;z=-.72+math.cos(a)*.35
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=.105,location=(x,.12,z))
        bead=bpy.context.object;bead.name='Scent_%s_Bead_%02d'%(state,i);bead.data.materials.append(m)
        for c in list(bead.users_collection):c.objects.unlink(bead)
        root.objects.link(bead)
        bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=.025,depth=.42,location=(x+.1,.13,z))
        stroke=bpy.context.object;stroke.name='Scent_%s_Stroke_%02d'%(state,i);stroke.rotation_euler[1]=math.pi/2;stroke.data.materials.append(m)
        for c in list(stroke.users_collection):c.objects.unlink(stroke)
        root.objects.link(stroke)
    root['territory_state']=state;root.hide_render=(state!='DISCOVERED');root.hide_viewport=(state!='DISCOVERED')

reward=bpy.data.collections.new('OwnershipReward');bpy.context.scene.collection.children.link(reward)
for i in range(9):
    a=math.tau*i/9;r=.45+.12*(i%3);p=(math.cos(a)*r,.14,-.65+math.sin(a)*r)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.055,location=p)
    o=bpy.context.object;o.name='Reward_Leaf_%02d'%i;o.scale=(1.6,.35,.7);o.rotation_euler=(0,a,.28*math.sin(a));o.data.materials.append(teal if i%2==0 else cream)
    for c in list(o.users_collection):c.objects.unlink(o)
    reward.objects.link(o)
reward.hide_viewport=True;reward.hide_render=True

for c in bpy.context.scene.collection.children:
    if c.name.startswith('ScentState_') or c.name=='OwnershipReward':
        for o in c.objects:o.select_set(True)
bpy.ops.wm.save_as_mainfile(filepath=WORK+'/banyan_07_scent_states.blend')
bpy.ops.export_scene.gltf(filepath=OUT+'/banyan_scent_states.glb',export_format='GLB',use_selection=True,export_yup=True)
print('STATES',[(c.name,len(c.objects),c.hide_viewport) for c in bpy.context.scene.collection.children if c.name.startswith('ScentState_') or c.name=='OwnershipReward'])
