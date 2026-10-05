import bpy, collections
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r"C:\Users\b\Documents\good-human\assets\characters\human\models\ai_grandma_research\grandma.glb")
o=bpy.data.objects['Character']
for lo,hi in [(1.26,1.46),(1.3,1.46),(1.46,1.55)]:
    ps=[p for p in o.data.polygons if lo <= p.center.z < hi]
    print('BIN',lo,hi,'count',len(ps),'yrange',round(min((p.center.y for p in ps),default=0),3),round(max((p.center.y for p in ps),default=0),3),'xrange',round(min((p.center.x for p in ps),default=0),3),round(max((p.center.x for p in ps),default=0),3))
for i,m in enumerate(o.data.materials):
    zs=[p.center.z for p in o.data.polygons if p.material_index==i]
    print(i,m.name,len(zs),round(min(zs),3) if zs else None,round(max(zs),3) if zs else None)
