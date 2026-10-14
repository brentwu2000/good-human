import bpy
from pathlib import Path
OUT=Path(r'C:/Users/b/Documents/good-human/build/dog_delivery')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'before_delivery_budget.blend'))
bpy.ops.object.select_all(action='DESELECT')
for name,ratio in [('ChihuahuaHead',.60),('ChihuahuaBodyTopology',.80)]:
 ob=bpy.data.objects[name];ob.select_set(True);bpy.context.view_layer.objects.active=ob;m=ob.modifiers.new('DeliveryBudget','DECIMATE');m.ratio=ratio;bpy.ops.object.modifier_move_up(modifier=m.name);bpy.ops.object.modifier_apply(modifier=m.name);ob.select_set(False)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_budget_refined.blend'))
