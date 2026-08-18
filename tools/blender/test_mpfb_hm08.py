"""Smoke-test hm08 via installed MPFB2. Stops on license/import failure."""
import bpy
import importlib
import sys

# Enable extension
for mod in ("bl_ext.user_default.mpfb", "mpfb"):
    try:
        bpy.ops.preferences.addon_enable(module=mod)
        print("enabled", mod)
        break
    except Exception as exc:
        print("enable fail", mod, exc)


def dynamic_import(absolute_package_str, key):
    for amod in sys.modules:
        if amod.endswith(absolute_package_str):
            mpfb_mod = importlib.import_module(amod)
            if hasattr(mpfb_mod, key):
                return getattr(mpfb_mod, key)
    raise ValueError("missing " + absolute_package_str + " " + key)


HumanService = dynamic_import("mpfb.services.humanservice", "HumanService")
TargetService = dynamic_import("mpfb.services.targetservice", "TargetService")
HumanObjectProperties = dynamic_import("mpfb.entities.objectproperties", "HumanObjectProperties")
ExportService = dynamic_import("mpfb.services.exportservice", "ExportService")
ObjectService = dynamic_import("mpfb.services.objectservice", "ObjectService")

human = HumanService.create_human(mask_helpers=True, detailed_helpers=True, extra_vertex_groups=True, feet_on_ground=True, scale=0.1)
mesh = human.data
mesh.calc_loop_triangles()
print("NAME", human.name)
print("VERTS", len(mesh.vertices))
print("FACES", len(mesh.polygons))
print("TRIS", len(mesh.loop_triangles))
print("GROUPS", [g.name for g in human.vertex_groups][:40], "... count", len(human.vertex_groups))
xs = [v.co.x for v in mesh.vertices]
ys = [v.co.y for v in mesh.vertices]
zs = [v.co.z for v in mesh.vertices]
print("BBOX x %.3f:%.3f y %.3f:%.3f z %.3f:%.3f" % (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))
for key in ("gender", "age", "muscle", "weight", "height", "african", "asian", "caucasian"):
    try:
        print("PROP", key, HumanObjectProperties.get_value(key, entity_reference=human))
    except Exception as exc:
        print("PROP fail", key, exc)
print("HM08_OK")
