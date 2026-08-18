"""Debug hm08 bbox and region counts after male macros."""
import importlib
import sys
import bpy

for mod in ("bl_ext.user_default.mpfb", "mpfb"):
    try:
        bpy.ops.preferences.addon_enable(module=mod)
        break
    except Exception as exc:
        print("enable fail", mod, exc)


def dynamic_import(absolute_package_str, key):
    for amod in sys.modules:
        if amod.endswith(absolute_package_str):
            m = importlib.import_module(amod)
            if hasattr(m, key):
                return getattr(m, key)
    raise ValueError(absolute_package_str)


HumanService = dynamic_import("mpfb.services.humanservice", "HumanService")
TargetService = dynamic_import("mpfb.services.targetservice", "TargetService")
HumanObjectProperties = dynamic_import("mpfb.entities.objectproperties", "HumanObjectProperties")
ExportService = dynamic_import("mpfb.services.exportservice", "ExportService")

human = HumanService.create_human(mask_helpers=True, detailed_helpers=True, extra_vertex_groups=True, feet_on_ground=True, scale=0.1)
for k, v in (("gender", 1.0), ("age", 0.52), ("muscle", 0.78), ("weight", 0.62), ("height", 0.64), ("proportions", 0.58)):
    HumanObjectProperties.set_value(k, v, entity_reference=human)
TargetService.reapply_macro_details(human)
TargetService.bake_targets(human)
ExportService.bake_modifiers_remove_helpers(human, bake_masks=True, bake_subdiv=False, remove_helpers=True)

xs = [v.co.x for v in human.data.vertices]
ys = [v.co.y for v in human.data.vertices]
zs = [v.co.z for v in human.data.vertices]
print("VERTS", len(human.data.vertices))
print("BBOX x %.3f:%.3f y %.3f:%.3f z %.3f:%.3f" % (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))
h = max(zs) - min(zs)
z0 = min(zs)
cy = 0.5 * (min(ys) + max(ys))
print("h", h, "cy", cy, "groups", [g.name for g in human.vertex_groups])

# z histogram of torso-ish verts |x|<0.2
bands = {}
for v in human.data.vertices:
    if abs(v.co.x) > 0.2:
        continue
    b = int((v.co.z - z0) / h * 20)
    bands.setdefault(b, []).append(v.co)
print("TORSO_BANDS")
for b in sorted(bands):
    pts = bands[b]
    print(" ", b, "n", len(pts), "y", min(p.y for p in pts), max(p.y for p in pts), "x", min(p.x for p in pts), max(p.x for p in pts), "z", min(p.z for p in pts), max(p.z for p in pts))

chest_z0, chest_z1 = z0 + h * 0.54, z0 + h * 0.76
c1 = sum(1 for v in human.data.vertices if chest_z0 <= v.co.z <= chest_z1)
c2 = sum(1 for v in human.data.vertices if chest_z0 <= v.co.z <= chest_z1 and abs(v.co.x) < 0.17)
c3 = sum(1 for v in human.data.vertices if chest_z0 <= v.co.z <= chest_z1 and abs(v.co.x) < 0.17 and v.co.y < cy - 0.01)
c4 = sum(1 for v in human.data.vertices if chest_z0 <= v.co.z <= chest_z1 and abs(v.co.x) < 0.17 and v.co.y < cy)
print("chest z-only", c1, "z+|x|", c2, "z+|x|+y<cy-0.01", c3, "z+|x|+y<cy", c4)

# gender-ish: torso only |x|<0.22
def width_at(t0, t1, xmax=0.22):
    w = 0.0
    n = 0
    for v in human.data.vertices:
        if abs(v.co.x) > xmax:
            continue
        t = (v.co.z - z0) / h
        if t0 <= t <= t1:
            w = max(w, abs(v.co.x))
            n += 1
    return w, n
print("torso_shoulder", width_at(0.78, 0.86))
print("torso_chest", width_at(0.62, 0.72))
print("torso_hip", width_at(0.48, 0.56))
print("DEBUG_OK")
