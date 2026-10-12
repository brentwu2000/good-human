"""Give retained-body triangles a nonoverlapping bake chart; preserve face UV."""
import bpy,pathlib,numpy as np,sys
ROOT=pathlib.Path(r'C:\Users\b\Documents\good-human')
sys.path.insert(0,str(ROOT/'tools/art'))
from reshape_pomeranian_r9 import unpack,accessor
dog=bpy.data.objects['DogBody']
original_uv=dog.data.uv_layers.active
if 'R14Bake' not in dog.data.uv_layers:
    baked_uv=dog.data.uv_layers.new(name='R14Bake',do_init=True)
    dog.data.uv_layers.active=baked_uv
    for mat in dog.data.materials:
        nt=mat.node_tree;node=nt.nodes.new('ShaderNodeUVMap');node.uv_map=original_uv.name
        original=nt.nodes['R14_SIDE_COLOR'].inputs[1].links[0].from_node
        nt.links.new(node.outputs['UV'],original.inputs['Vector'])
bpy.ops.object.select_all(action='DESELECT');dog.select_set(True);bpy.context.view_layer.objects.active=dog
bpy.context.tool_settings.mesh_select_mode=(False,False,True)
for poly in dog.data.polygons:poly.select=poly.material_index==0
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.uv.smart_project(angle_limit=1.151917,island_margin=.012,correct_aspect=True)
bpy.ops.object.mode_set(mode='OBJECT')
def key(p):return tuple(np.rint(np.asarray(p,dtype=float)*1e5).astype(int))
from mathutils.kdtree import KDTree
polys=[poly for poly in dog.data.polygons if poly.material_index==0]
tree=KDTree(len(polys))
for i,poly in enumerate(polys):tree.insert(poly.center,i)
tree.balance()
mapping=[]
uv=dog.data.uv_layers.active.data
for poly in dog.data.polygons:
    if poly.material_index!=0:continue
    coords=[key(dog.data.vertices[dog.data.loops[i].vertex_index].co) for i in poly.loop_indices]
    mapping.append((np.array([dog.data.vertices[dog.data.loops[i].vertex_index].co[:] for i in poly.loop_indices]),np.array([uv[i].uv[:] for i in poly.loop_indices])))
doc,data=unpack(ROOT/'build/frenchie_face_r13/frenchie.glb')
pr=doc['meshes'][0]['primitives'][0]
p=accessor(doc,data,pr['attributes']['POSITION']);p=p[:,[0,2,1]].copy();p[:,1]*=-1
t=accessor(doc,data,pr['indices']).reshape(-1,3)
result=[]
for tri in t:
    center,index,distance=tree.find(p[tri].mean(0))
    assert distance<1e-5,distance
    coords,chart=mapping[index]
    corner=np.linalg.norm(p[tri,None,:]-coords[None,:,:],axis=2).argmin(1)
    assert np.max(np.linalg.norm(p[tri]-coords[corner],axis=1))<1e-5
    result.append([[chart[v][0],1-chart[v][1]] for v in corner])
np.save(ROOT/'build/frenchie_face_r14/body_corner_uv.npy',np.array(result,np.float32))
print('BODY_UNWRAP_MATCHED',len(t))
