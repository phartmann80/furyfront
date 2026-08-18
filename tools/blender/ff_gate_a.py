#!/usr/bin/env python3
"""Fury Front Gate A — clay forms from MakeHuman hm08 via MPFB2.

Portable Blender 4.5 only. No Meshy. No textures. No production rig.
Do not factory-reset Blender (that unloads MPFB).

  blender --background --python tools/blender/ff_gate_a.py -- --root <repo>
"""
from __future__ import annotations

import importlib
import json
import math
import os
import sys
from datetime import datetime, timezone

import bpy
import bmesh
from mathutils import Euler, Matrix, Vector
from mathutils.bvhtree import BVHTree

# Gameplay camera / weapon placement (Godot camera space).
# Blender FPS space uses Y-forward / Z-up so glTF Y-up export lands on these Godot values.
GODOT_HIP = Vector((0.22, -0.19, -0.40))
GODOT_ADS = Vector((0.0, -0.135, -0.36))
GODOT_FOV = 75.0
MUZZLE_GODOT = Vector((0.0, 0.028, -0.58))
SHELL_GODOT = Vector((0.04, 0.04, -0.04))


def argv_after_dash() -> list[str]:
    if "--" in sys.argv:
        return sys.argv[sys.argv.index("--") + 1 :]
    return []


def parse_root() -> str:
    args = argv_after_dash()
    if "--root" in args:
        return args[args.index("--root") + 1]
    return os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def dynamic_import(absolute_package_str, key):
    for amod in sys.modules:
        if amod.endswith(absolute_package_str):
            mpfb_mod = importlib.import_module(amod)
            if hasattr(mpfb_mod, key):
                return getattr(mpfb_mod, key)
    raise ValueError("missing " + absolute_package_str + " " + key)


def enable_mpfb() -> None:
    last = None
    for mod in ("bl_ext.user_default.mpfb", "mpfb"):
        try:
            bpy.ops.preferences.addon_enable(module=mod)
            print("MPFB enabled", mod, flush=True)
            return
        except Exception as exc:
            last = exc
            print("MPFB enable fail", mod, exc, flush=True)
    raise RuntimeError("MPFB2 is not installed in this Blender. Stop; do not switch base meshes.") from last


def mpfb_services():
    enable_mpfb()
    return {
        "HumanService": dynamic_import("mpfb.services.humanservice", "HumanService"),
        "TargetService": dynamic_import("mpfb.services.targetservice", "TargetService"),
        "HumanObjectProperties": dynamic_import("mpfb.entities.objectproperties", "HumanObjectProperties"),
        "ExportService": dynamic_import("mpfb.services.exportservice", "ExportService"),
        "ObjectService": dynamic_import("mpfb.services.objectservice", "ObjectService"),
    }


def clear_scene() -> None:
    """Delete objects without factory-reset (factory-reset would unload MPFB)."""
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.images, bpy.data.cameras, bpy.data.lights):
        for block in list(coll):
            if block.users == 0:
                coll.remove(block)


def link(obj) -> None:
    col = bpy.context.scene.collection
    if obj.name not in col.objects:
        col.objects.link(obj)


def active(obj) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def apply_mods(obj) -> None:
    active(obj)
    bpy.ops.object.make_single_user(object=True, obdata=True)
    for m in list(obj.modifiers):
        try:
            bpy.ops.object.modifier_apply(modifier=m.name)
        except Exception:
            obj.modifiers.remove(m)


def shade_auto(obj) -> None:
    active(obj)
    bpy.ops.object.shade_smooth()
    mesh = obj.data
    if hasattr(mesh, "use_auto_smooth"):
        mesh.use_auto_smooth = True
        mesh.auto_smooth_angle = math.radians(55)
    for p in mesh.polygons:
        p.use_smooth = True


def tris(obj) -> int:
    mesh = obj.data
    mesh.calc_loop_triangles()
    return len(mesh.loop_triangles)


def kit_meta(parts, body) -> dict:
    live = [p for p in parts if p is not None]
    kit_parts = [p for p in live if p != body]
    return {
        "kit_pieces": len(kit_parts),
        "kit_tris": sum(tris(p) for p in kit_parts),
        "body_tris": tris(body) if body is not None else 0,
    }


def print_mesh_bounds(obj, tag="") -> None:
    pts = [obj.matrix_world @ v.co for v in obj.data.vertices]
    xs, ys, zs = [p.x for p in pts], [p.y for p in pts], [p.z for p in pts]
    print(
        f"BBOX {tag or obj.name} x {min(xs):.3f}:{max(xs):.3f} "
        f"y {min(ys):.3f}:{max(ys):.3f} z {min(zs):.3f}:{max(zs):.3f} n={len(pts)}",
        flush=True,
    )


def clay(name, color, metallic=0.08, roughness=0.62, emission=None):
    if name in bpy.data.materials:
        return bpy.data.materials[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    p = nt.nodes.get("Principled BSDF")
    p.inputs["Base Color"].default_value = (*color, 1.0)
    p.inputs["Metallic"].default_value = metallic
    p.inputs["Roughness"].default_value = roughness
    m.diffuse_color = (*color, 1.0)
    if emission:
        if "Emission Color" in p.inputs:
            p.inputs["Emission Color"].default_value = (*emission, 1.0)
            p.inputs["Emission Strength"].default_value = 0.18
    return m


def assign_mat(obj, material) -> None:
    obj.data.materials.clear()
    obj.data.materials.append(material)


def empty(name, loc) -> bpy.types.Object:
    e = bpy.data.objects.new(name, None)
    e.empty_display_size = 0.02
    e.empty_display_type = "PLAIN_AXES"
    e.location = loc
    link(e)
    return e


def group_indices(obj, name) -> set[int]:
    vg = obj.vertex_groups.get(name)
    if vg is None:
        return set()
    gi = vg.index
    return {v.index for v in obj.data.vertices if any(g.group == gi and g.weight > 0.15 for g in v.groups)}


def bbox(obj):
    xs = [v.co.x for v in obj.data.vertices]
    ys = [v.co.y for v in obj.data.vertices]
    zs = [v.co.z for v in obj.data.vertices]
    return min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)


def metrics(obj) -> dict:
    xmin, xmax, ymin, ymax, zmin, zmax = bbox(obj)
    return {
        "xmin": xmin, "xmax": xmax, "ymin": ymin, "ymax": ymax, "zmin": zmin, "zmax": zmax,
        "h": zmax - zmin, "w": xmax - xmin, "d": ymax - ymin,
        "cx": 0.5 * (xmin + xmax), "cy": 0.5 * (ymin + ymax), "cz": 0.5 * (zmin + zmax),
        "front": ymin, "back": ymax,
    }


def duplicate_mesh(obj, name) -> bpy.types.Object:
    mesh = obj.data.copy()
    dup = bpy.data.objects.new(name, mesh)
    dup.location = obj.location.copy()
    dup.rotation_euler = obj.rotation_euler.copy()
    dup.scale = obj.scale.copy()
    link(dup)
    return dup


def bmesh_of(obj) -> bmesh.types.BMesh:
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.verts.ensure_lookup_table()
    bm.faces.ensure_lookup_table()
    bm.edges.ensure_lookup_table()
    return bm


def commit_bm(bm, obj) -> None:
    bm.to_mesh(obj.data)
    obj.data.update()
    bm.free()


def grow_indices(obj, keep: set[int], rings: int) -> set[int]:
    if rings <= 0:
        return set(keep)
    bm = bmesh_of(obj)
    selected = set(keep)
    for _ in range(rings):
        extra = set()
        for v in bm.verts:
            if v.index in selected:
                for e in v.link_edges:
                    extra.add(e.other_vert(v).index)
        selected |= extra
    bm.free()
    return selected


def keep_only(obj, keep: set[int]) -> None:
    bm = bmesh_of(obj)
    dead = [v for v in bm.verts if v.index not in keep]
    bmesh.ops.delete(bm, geom=dead, context="VERTS")
    commit_bm(bm, obj)


def delete_indices(obj, drop: set[int], protect: set[int] | None = None) -> int:
    protect = protect or set()
    kill = drop - protect
    bm = bmesh_of(obj)
    dead = [v for v in bm.verts if v.index in kill]
    n = len(dead)
    if dead:
        bmesh.ops.delete(bm, geom=dead, context="VERTS")
    commit_bm(bm, obj)
    return n


def inflate(obj, amount: float) -> None:
    bm = bmesh_of(obj)
    bm.normal_update()
    for v in bm.verts:
        v.co += v.normal * amount
    commit_bm(bm, obj)


def solidify_bevel(obj, thickness=0.008, offset=1.0, bevel=0.0024, segs=2) -> None:
    sol = obj.modifiers.new("Sol", "SOLIDIFY")
    sol.thickness = thickness
    sol.offset = offset
    sol.use_even_offset = True
    bev = obj.modifiers.new("Bev", "BEVEL")
    bev.width = bevel
    bev.segments = segs
    bev.limit_method = "ANGLE"
    bev.angle_limit = math.radians(30)
    bev.harden_normals = True
    apply_mods(obj)
    shade_auto(obj)


def cleanup_mesh(obj) -> None:
    bm = bmesh_of(obj)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=0.00035)
    loose = [v for v in bm.verts if not v.link_faces]
    if loose:
        bmesh.ops.delete(bm, geom=loose, context="VERTS")
    degenerate = [f for f in bm.faces if f.calc_area() < 1e-10]
    if degenerate:
        bmesh.ops.delete(bm, geom=degenerate, context="FACES")
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    commit_bm(bm, obj)


def strip_to_plain_mesh(obj) -> None:
    """Drop shapekeys / MH custom layers that spike after vertex deletion."""
    if obj.data.shape_keys:
        obj.shape_key_clear()
    bm = bmesh_of(obj)
    me = bpy.data.meshes.new(obj.name + "_plain")
    bm.to_mesh(me)
    bm.free()
    old = obj.data
    obj.data = me
    if old.users == 0:
        bpy.data.meshes.remove(old)
    cleanup_mesh(obj)


def inflate_interior(obj, amount: float) -> None:
    bm = bmesh_of(obj)
    bm.normal_update()
    for v in bm.verts:
        if v.is_boundary:
            continue
        v.co += v.normal * amount
    commit_bm(bm, obj)
    bm = bmesh_of(obj)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=0.00035)
    loose = [v for v in bm.verts if not v.link_faces]
    if loose:
        bmesh.ops.delete(bm, geom=loose, context="VERTS")
    degenerate = [f for f in bm.faces if f.calc_area() < 1e-10]
    if degenerate:
        bmesh.ops.delete(bm, geom=degenerate, context="FACES")
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    commit_bm(bm, obj)


def extract_shell(src, name, keep: set[int], *, rings=1, inflate_amt=0.010, thickness=0.008, bevel=0.0022) -> bpy.types.Object:
    keep = grow_indices(src, keep, rings)
    if len(keep) < 12:
        keep = grow_indices(src, keep, rings + 2)
    if len(keep) < 12:
        raise RuntimeError(f"{name}: too few verts ({len(keep)})")
    ob = duplicate_mesh(src, name)
    keep_only(ob, keep)
    strip_to_plain_mesh(ob)
    inflate_interior(ob, inflate_amt * 0.25)
    solidify_bevel(ob, thickness, 1.0, bevel, 2)
    cleanup_mesh(ob)
    return ob


def select_by(obj, pred) -> set[int]:
    return {v.index for v in obj.data.vertices if pred(v.co)}


def join_objects(name, objects, material=None) -> bpy.types.Object:
    objects = [o for o in objects if o is not None and o.name in bpy.data.objects]
    if not objects:
        raise RuntimeError("join empty " + name)
    active(objects[0])
    for o in objects:
        o.select_set(True)
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    if material:
        assign_mat(obj, material)
    return obj


def add_box(name, loc, scale, rot=(0.0, 0.0, 0.0)) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc, rotation=rot)
    ob = bpy.context.object
    ob.name = name
    ob.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return ob


def add_cyl(name, loc, radius, depth, rot=(math.pi / 2, 0.0, 0.0), verts=16) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth, location=loc, rotation=rot)
    ob = bpy.context.object
    ob.name = name
    return ob


def boolean_cut(obj, cutter, solver="EXACT") -> None:
    active(obj)
    n0 = len(obj.data.vertices)
    m = obj.modifiers.new("Cut", "BOOLEAN")
    m.operation = "DIFFERENCE"
    m.object = cutter
    # Blender 4.5.10 enum: FAST, EXACT, MANIFOLD.
    m.solver = solver
    try:
        apply_mods(obj)
        print(f"BOOL {cutter.name} solver={solver} verts {n0}->{len(obj.data.vertices)}", flush=True)
    except Exception as exc:
        print("boolean skip", cutter.name, exc, flush=True)
        if "Cut" in obj.modifiers:
            obj.modifiers.remove(obj.modifiers["Cut"])
    if cutter.name in bpy.data.objects:
        bpy.data.objects.remove(cutter, do_unlink=True)


def finish_hard(obj, bevel=0.0018, segs=3) -> None:
    bev = obj.modifiers.new("Bev", "BEVEL")
    bev.width = bevel
    bev.segments = segs
    bev.limit_method = "ANGLE"
    bev.angle_limit = math.radians(28)
    bev.harden_normals = True
    bev.miter_outer = "MITER_ARC"
    wn = obj.modifiers.new("WN", "WEIGHTED_NORMAL")
    wn.keep_sharp = True
    apply_mods(obj)
    shade_auto(obj)


def cap_mesh(obj, cap: int) -> None:
    if obj.type != "MESH":
        return
    n = tris(obj)
    if n <= cap:
        return
    d = obj.modifiers.new("Dec", "DECIMATE")
    d.ratio = max(0.08, cap / float(n))
    apply_mods(obj)


def triangulate(obj) -> None:
    if obj.type != "MESH":
        return
    t = obj.modifiers.new("Tri", "TRIANGULATE")
    t.quad_method = "FIXED"
    apply_mods(obj)


def count_tree(obj) -> tuple[int, int]:
    t = v = 0

    def walk(o):
        nonlocal t, v
        if o.type == "MESH":
            t += tris(o)
            v += len(o.data.vertices)
        for c in o.children:
            walk(c)

    walk(obj)
    return t, v


def export_glb(path, objects) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    to_sel = []
    for o in objects:
        to_sel.append(o)
        to_sel.extend(list(o.children_recursive))
    for o in to_sel:
        if o.type == "MESH":
            triangulate(o)
    bpy.ops.object.select_all(action="DESELECT")
    for o in to_sel:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_texcoords=True,
        export_normals=True,
        export_tangents=False,
        export_materials="EXPORT",
        export_skins=False,
        export_animations=False,
        export_extras=True,
        export_yup=True,
        export_cameras=False,
        export_lights=False,
    )


def hide_for_render(hidden) -> dict:
    state = {}
    for o in bpy.context.scene.objects:
        state[o.name] = (o.hide_render, o.hide_viewport)
        o.hide_render = True
        o.hide_viewport = True
    for o in hidden:
        if o is None:
            continue
        stack = [o] + list(o.children_recursive)
        for s in stack:
            s.hide_render = False
            s.hide_viewport = False
    return state


def restore_hide(state) -> None:
    for o in bpy.context.scene.objects:
        if o.name in state:
            o.hide_render, o.hide_viewport = state[o.name]


def render_previews(out_dir, name, camera_loc, look, subjects, wire=False, lens=50) -> None:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 1200
    scene.render.film_transparent = False
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.show_shadows = True
    scene.display.shading.show_cavity = True
    world = bpy.data.worlds.get("W") or bpy.data.worlds.new("W")
    scene.world = world
    world.color = (0.10, 0.11, 0.12)
    cam = bpy.data.cameras.new("C_" + name)
    cam.lens = lens
    cob = bpy.data.objects.new("C_" + name, cam)
    cob.location = camera_loc
    link(cob)
    scene.camera = cob
    direction = Vector(look) - Vector(camera_loc)
    cob.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    st = hide_for_render(subjects)
    if wire:
        for o in bpy.context.scene.objects:
            if o.type == "MESH" and not o.hide_render:
                o.display_type = "WIRE"
        scene.display.shading.light = "FLAT"
        scene.display.shading.color_type = "SINGLE"
        scene.display.shading.show_cavity = False
    os.makedirs(out_dir, exist_ok=True)
    scene.render.filepath = os.path.join(out_dir, name)
    bpy.ops.render.render(write_still=True)
    if wire:
        for o in bpy.context.scene.objects:
            if o.type == "MESH":
                o.display_type = "TEXTURED"
    restore_hide(st)
    bpy.data.objects.remove(cob, do_unlink=True)
    bpy.data.cameras.remove(cam)


def godot_to_blender(g: Vector) -> Vector:
    """Godot camera-local (Y-up, -Z forward) -> Blender Z-up for glTF export_yup.

    Blender (x, y, z) exports as glTF/Godot (x, z, -y). Inverse: (gx, -gz, gy).
    """
    return Vector((g.x, -g.z, g.y))


def blender_to_godot(b: Vector) -> Vector:
    return Vector((b.x, b.z, -b.y))


def apply_macros(svc, human, **kwargs) -> None:
    hop = svc["HumanObjectProperties"]
    ts = svc["TargetService"]
    race = kwargs.pop("race", None)
    for k, v in kwargs.items():
        hop.set_value(k, float(v), entity_reference=human)
    if race:
        for k, v in race.items():
            hop.set_value(k, float(v), entity_reference=human)
    ts.reapply_macro_details(human)


def torso_width_at(human, t0: float, t1: float, xmax: float = 0.22) -> float:
    m = metrics(human)
    w = 0.0
    for v in human.data.vertices:
        if abs(v.co.x) > xmax:
            continue
        t = (v.co.z - m["zmin"]) / m["h"] if m["h"] else 0.0
        if t0 <= t <= t1:
            w = max(w, abs(v.co.x))
    return w


def shoulder_hip(human) -> tuple[float, float, float]:
    """Torso-only widths so T-pose hands are not mistaken for hips."""
    shoulder = torso_width_at(human, 0.76, 0.84)
    hip = torso_width_at(human, 0.48, 0.56)
    return shoulder, hip, (shoulder / hip if hip else 0.0)


def chest_front(human) -> float:
    m = metrics(human)
    ys = []
    for v in human.data.vertices:
        if abs(v.co.x) > 0.10:
            continue
        t = (v.co.z - m["zmin"]) / m["h"] if m["h"] else 0.0
        if 0.62 <= t <= 0.74:
            ys.append(v.co.y)
    return min(ys) if ys else 0.0


def verify_gender_polarity(svc) -> float:
    """macro.json: 0=female, 1=male. Abort only if live mesh clearly contradicts that."""
    hop = svc["HumanObjectProperties"]
    ts = svc["TargetService"]
    hs = svc["HumanService"]
    es = svc["ExportService"]
    results = {}
    for g in (0.0, 1.0):
        human = hs.create_human(mask_helpers=True, detailed_helpers=False, extra_vertex_groups=True, feet_on_ground=True, scale=0.1)
        hop.set_value("gender", g, entity_reference=human)
        hop.set_value("age", 0.5, entity_reference=human)
        hop.set_value("muscle", 0.7, entity_reference=human)
        hop.set_value("weight", 0.5, entity_reference=human)
        hop.set_value("cupsize", 0.85, entity_reference=human)
        ts.reapply_macro_details(human)
        ts.bake_targets(human)
        es.bake_modifiers_remove_helpers(human, bake_masks=True, bake_subdiv=False, remove_helpers=True)
        sh, hip, ratio = shoulder_hip(human)
        front = chest_front(human)
        results[g] = (sh, hip, ratio, front)
        print(f"GENDER_PROBE {g} shoulder={sh:.3f} hip={hip:.3f} ratio={ratio:.3f} chest_front_y={front:.3f}", flush=True)
        bpy.data.objects.remove(human, do_unlink=True)
    # Female chest is more -Y (forward). Male should not have the more-negative chest.
    if results[0.0][3] >= results[1.0][3] - 0.005:
        raise RuntimeError(
            f"hm08 gender polarity unexpected (chest_front gender0={results[0.0][3]:.3f} gender1={results[1.0][3]:.3f}). "
            "Stop; do not switch base meshes."
        )
    print("GENDER_OK male=1.0 (macro.json + chest-front probe)", flush=True)
    return 1.0


def create_shaped_human(svc, name: str, macros: dict) -> tuple[bpy.types.Object, dict]:
    hs = svc["HumanService"]
    ts = svc["TargetService"]
    es = svc["ExportService"]
    human = hs.create_human(
        mask_helpers=True,
        detailed_helpers=True,
        extra_vertex_groups=True,
        feet_on_ground=True,
        scale=0.1,
    )
    apply_macros(svc, human, **macros)
    ts.bake_targets(human)
    es.bake_modifiers_remove_helpers(human, bake_masks=True, bake_subdiv=False, remove_helpers=True)
    strip_to_plain_mesh(human)
    human.name = name
    m = metrics(human)
    nverts = len(human.data.vertices)
    ntris = tris(human)
    print(
        f"HUMAN {name} verts={nverts} tris={ntris} h={m['h']:.3f} w={m['w']:.3f} "
        f"z={m['zmin']:.3f}:{m['zmax']:.3f}",
        flush=True,
    )
    if nverts < 8000:
        raise RuntimeError(f"{name}: hm08 body unexpectedly small ({nverts} verts). Stop.")
    return human, {"source_verts": nverts, "source_tris": ntris, "height": m["h"], **{k: m[k] for k in ("xmin", "xmax", "ymin", "ymax", "zmin", "zmax")}}


def torso_center_y(body, m) -> float:
    """Front/back split from the ribcage, ignoring T-pose arms that dominate the full bbox."""
    z0, h = m["zmin"], m["h"]
    ys = [
        v.co.y
        for v in body.data.vertices
        if abs(v.co.x) < 0.16 and z0 + h * 0.55 < v.co.z < z0 + h * 0.78
    ]
    if not ys:
        return m["cy"]
    return sum(ys) / len(ys)


def region_sets(body) -> dict:
    m = metrics(body)
    h, z0 = m["h"], m["zmin"]
    tcy = torso_center_y(body, m)

    def tz(p, a, b):
        t = (p.z - z0) / h if h else 0.0
        return a <= t <= b

    chest = select_by(body, lambda p: tz(p, 0.60, 0.78) and abs(p.x) < 0.17 and p.y <= tcy)
    back = select_by(body, lambda p: tz(p, 0.60, 0.78) and abs(p.x) < 0.16 and p.y >= tcy)
    belt = select_by(body, lambda p: tz(p, 0.54, 0.61) and abs(p.x) < 0.16)
    l_knee = select_by(body, lambda p: tz(p, 0.28, 0.40) and -0.20 < p.x < -0.04 and p.y <= tcy + 0.03)
    r_knee = select_by(body, lambda p: tz(p, 0.28, 0.40) and 0.04 < p.x < 0.20 and p.y <= tcy + 0.03)
    l_boot = select_by(body, lambda p: tz(p, 0.00, 0.13) and p.x < -0.02)
    r_boot = select_by(body, lambda p: tz(p, 0.00, 0.13) and p.x > 0.02)
    helm = select_by(body, lambda p: tz(p, 0.93, 1.01) and abs(p.x) < 0.11)
    visor = select_by(body, lambda p: tz(p, 0.88, 0.92) and p.y <= tcy and abs(p.x) < 0.08)
    headset = select_by(body, lambda p: tz(p, 0.88, 0.93) and 0.07 < abs(p.x) < 0.13)
    l_glove = select_by(body, lambda p: p.x < -0.50)
    r_glove = select_by(body, lambda p: p.x > 0.50)
    l_pad = select_by(body, lambda p: tz(p, 0.74, 0.84) and -0.28 < p.x < -0.10)
    r_pad = select_by(body, lambda p: tz(p, 0.74, 0.84) and 0.10 < p.x < 0.28)
    uniform = select_by(body, lambda p: tz(p, 0.12, 0.86) and abs(p.x) < 0.20)
    l_arm = select_by(body, lambda p: p.x < -0.16 and tz(p, 0.50, 0.90))
    r_arm = select_by(body, lambda p: p.x > 0.16 and tz(p, 0.50, 0.90))
    face = select_by(body, lambda p: tz(p, 0.86, 0.96) and p.y <= tcy and abs(p.x) < 0.09)
    neck = select_by(body, lambda p: tz(p, 0.82, 0.88) and abs(p.x) < 0.10)
    elbows = select_by(body, lambda p: 0.22 < abs(p.x) < 0.42 and tz(p, 0.68, 0.82))
    knees = l_knee | r_knee
    hands = l_glove | r_glove
    feet = l_boot | r_boot
    torso_hide = select_by(body, lambda p: tz(p, 0.52, 0.80) and abs(p.x) < 0.16)
    thigh_pouch_l = select_by(body, lambda p: tz(p, 0.40, 0.52) and -0.18 < p.x < -0.05 and p.y <= tcy)
    thigh_pouch_r = select_by(body, lambda p: tz(p, 0.40, 0.52) and 0.05 < p.x < 0.18 and p.y <= tcy)
    collar = select_by(body, lambda p: tz(p, 0.78, 0.85) and abs(p.x) < 0.12)
    return {
        "chest": chest, "back": back, "belt": belt, "l_knee": l_knee, "r_knee": r_knee,
        "l_boot": l_boot, "r_boot": r_boot, "helm": helm, "visor": visor, "headset": headset,
        "l_glove": l_glove, "r_glove": r_glove, "l_pad": l_pad, "r_pad": r_pad,
        "uniform": uniform, "l_arm": l_arm, "r_arm": r_arm, "face": face, "neck": neck,
        "elbows": elbows, "knees": knees, "hands": hands, "feet": feet, "torso_hide": torso_hide,
        "thigh_pouch_l": thigh_pouch_l, "thigh_pouch_r": thigh_pouch_r, "collar": collar,
        "scalp": helm, "lips": face,
    }


def centroid_of(body, indices: set[int]) -> Vector:
    if not indices:
        return Vector((0.0, 0.0, 0.0))
    acc = Vector((0.0, 0.0, 0.0))
    for i in indices:
        acc += body.data.vertices[i].co
    return acc / len(indices)


def region_size(body, indices: set[int]) -> Vector:
    pts = [body.data.vertices[i].co for i in indices]
    if not pts:
        return Vector((0.08, 0.08, 0.08))
    xs, ys, zs = [p.x for p in pts], [p.y for p in pts], [p.z for p in pts]
    return Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))


def make_wrap_cage(body) -> bpy.types.Object:
    """Torso/head/legs only. T-pose arms must not be a shrinkwrap target or plates spike into the hands."""
    cage = duplicate_mesh(body, "WrapCage")
    drop = select_by(cage, lambda p: abs(p.x) > 0.23)
    delete_indices(cage, drop)
    strip_to_plain_mesh(cage)
    bm = bmesh_of(cage)
    boundary = [e for e in bm.edges if e.is_boundary]
    if boundary:
        bmesh.ops.holes_fill(bm, edges=boundary, sides=0)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    commit_bm(bm, cage)
    return cage


def fitted_panel(target, name, center, width, height, normal, *, offset=0.012, thickness=0.010, cuts=6, material=None):
    """Closed-after-solidify clothing panel. Shrinkwraps a regular grid onto anatomy — not extracted hm08 faces."""
    n = Vector(normal)
    if n.length < 1e-6:
        n = Vector((0.0, -1.0, 0.0))
    n.normalize()
    rot = Vector((0.0, 0.0, 1.0)).rotation_difference(n)
    bpy.ops.mesh.primitive_grid_add(
        x_subdivisions=max(3, cuts),
        y_subdivisions=max(3, cuts),
        size=1.0,
        location=center,
    )
    ob = bpy.context.object
    ob.name = name
    ob.scale = (width, height, 1.0)
    ob.rotation_euler = rot.to_euler()
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    sw = ob.modifiers.new("SW", "SHRINKWRAP")
    sw.target = target
    sw.wrap_method = "NEAREST_SURFACEPOINT"
    sw.wrap_mode = "ABOVE_SURFACE"
    sw.offset = offset
    sol = ob.modifiers.new("Sol", "SOLIDIFY")
    sol.thickness = thickness
    sol.offset = 1.0
    sol.use_even_offset = True
    apply_mods(ob)
    cleanup_mesh(ob)
    if material:
        assign_mat(ob, material)
    shade_auto(ob)
    return ob


def fitted_volume(target, name, loc, size, *, offset=0.008, thickness=0.008, cuts=2, material=None):
    """Closed cube, subdivided, shrinkwrapped onto a body region (pads, pack)."""
    ob = add_box(name, loc, size)
    bm = bmesh_of(ob)
    bmesh.ops.subdivide_edges(bm, edges=list(bm.edges), cuts=cuts)
    commit_bm(bm, ob)
    sw = ob.modifiers.new("SW", "SHRINKWRAP")
    sw.target = target
    sw.wrap_method = "NEAREST_SURFACEPOINT"
    sw.wrap_mode = "ABOVE_SURFACE"
    sw.offset = offset
    sol = ob.modifiers.new("Sol", "SOLIDIFY")
    sol.thickness = thickness
    sol.offset = 1.0
    sol.use_even_offset = True
    apply_mods(ob)
    cleanup_mesh(ob)
    if material:
        assign_mat(ob, material)
    shade_auto(ob)
    return ob


def simple_boot(body, name, keep: set[int], material):
    """Closed combat boot sized to the foot bbox. No shrinkwrap."""
    pts = [body.data.vertices[i].co for i in keep]
    if len(pts) < 8:
        return None
    xs, ys, zs = [p.x for p in pts], [p.y for p in pts], [p.z for p in pts]
    loc = Vector(((min(xs) + max(xs)) * 0.5, (min(ys) + max(ys)) * 0.5, min(zs)))
    sole = add_box(name + "Sole", (loc.x, loc.y - 0.035, loc.z + 0.012), (0.085, 0.22, 0.026))
    heel = add_box(name + "Heel", (loc.x, loc.y + 0.055, loc.z + 0.008), (0.080, 0.06, 0.022))
    shaft = add_cyl(name + "Shaft", (loc.x, loc.y + 0.02, loc.z + 0.10), 0.046, 0.16, (0.0, 0.0, 0.0), 14)
    toe = add_box(name + "Toe", (loc.x, loc.y - 0.08, loc.z + 0.032), (0.078, 0.08, 0.040))
    ob = join_objects(name, [sole, heel, shaft, toe], material)
    finish_hard(ob, 0.0024, 2)
    return ob


def glove_overlay(body, keep: set[int], name, material, inflate_amt=0.0045):
    """Thin glove surface from hand topology. Inflate only — never solidify open hand patches."""
    keep = grow_indices(body, keep, 1)
    if len(keep) < 20:
        return None
    ob = duplicate_mesh(body, name)
    keep_only(ob, keep)
    strip_to_plain_mesh(ob)
    inflate(ob, inflate_amt)
    cleanup_mesh(ob)
    assign_mat(ob, material)
    shade_auto(ob)
    return ob


def waist_torus(body, name, material, *, major_extra=0.018, minor=0.016):
    r = region_sets(body)
    belt = r["belt"]
    c = centroid_of(body, belt)
    pts = [body.data.vertices[i].co for i in belt]
    if not pts:
        return None
    major = max(math.hypot(p.x - c.x, p.y - c.y) for p in pts) + major_extra
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major,
        minor_radius=minor,
        major_segments=28,
        minor_segments=8,
        location=(c.x, c.y, c.z),
    )
    ob = bpy.context.object
    ob.name = name
    assign_mat(ob, material)
    shade_auto(ob)
    finish_hard(ob, 0.0016, 2)
    return ob


def fitted_belt(target, body, name, material, *, depth=0.05, extra=0.006, thickness=0.010):
    """Waist band from an open cylinder tube shrinkwrapped to the armless cage — not a floating torus."""
    r = region_sets(body)
    c = centroid_of(body, r["belt"])
    pts = [body.data.vertices[i].co for i in r["belt"]]
    if not pts:
        return None
    rad = max(math.hypot(p.x - c.x, p.y - c.y) for p in pts) + extra
    bpy.ops.mesh.primitive_cylinder_add(vertices=22, radius=rad, depth=depth, location=c)
    ob = bpy.context.object
    ob.name = name
    bm = bmesh_of(ob)
    caps = [f for f in bm.faces if abs(f.normal.z) > 0.85]
    if caps:
        bmesh.ops.delete(bm, geom=caps, context="FACES")
    commit_bm(bm, ob)
    sw = ob.modifiers.new("SW", "SHRINKWRAP")
    sw.target = target
    sw.wrap_method = "NEAREST_SURFACEPOINT"
    sw.wrap_mode = "ABOVE_SURFACE"
    sw.offset = 0.006
    sol = ob.modifiers.new("Sol", "SOLIDIFY")
    sol.thickness = thickness
    sol.offset = 1.0
    sol.use_even_offset = True
    apply_mods(ob)
    cleanup_mesh(ob)
    assign_mat(ob, material)
    shade_auto(ob)
    return ob


def mag_pouch(name, loc, material):
    pouch = add_box(name + "B", loc, (0.040, 0.034, 0.088))
    active(pouch)
    bpy.ops.object.mode_set(mode="EDIT")
    bm = bmesh.from_edit_mesh(pouch.data)
    for v in bm.verts:
        if v.co.z < -0.02:
            v.co.x *= 0.86
            v.co.y *= 0.88
    bmesh.update_edit_mesh(pouch.data)
    bpy.ops.object.mode_set(mode="OBJECT")
    flap = add_box(name + "F", (loc[0], loc[1] - 0.004, loc[2] + 0.038), (0.038, 0.028, 0.014))
    # Vertical webbing that reads as a sewn attachment, not a floating box.
    tab = add_box(name + "T", (loc[0], loc[1] + 0.016, loc[2] + 0.012), (0.012, 0.018, 0.036))
    buckle = add_box(name + "K", (loc[0], loc[1] - 0.012, loc[2] + 0.042), (0.016, 0.010, 0.008))
    ob = join_objects(name, [pouch, flap, tab, buckle], material)
    finish_hard(ob, 0.0022, 2)
    return ob


def molle_field(name, origin, material, *, rows=3, cols=5, pitch=(0.022, 0.018), width=0.13):
    """Horizontal webbing + short verticals so the carrier reads as sewn MOLLE, not a bump grid."""
    bits = []
    ox, oy, oz = origin
    px, pz = pitch
    for r in range(rows):
        z = oz + (r - (rows - 1) * 0.5) * pz
        bits.append(add_box(f"{name}_h{r}", (ox, oy, z), (width, 0.008, 0.007)))
        for c in range(cols):
            x = ox + (c - (cols - 1) * 0.5) * px
            bits.append(add_box(f"{name}_v{r}{c}", (x, oy, z), (0.007, 0.007, 0.014)))
    ob = join_objects(name, bits, material)
    shade_auto(ob)
    return ob


def drop_leg(target, body, name, keep: set[int], material, side: float):
    """Thigh platform + holster brick + two wrap straps. Volume wrap, not a grid panel (those spike)."""
    if len(keep) < 8:
        return None
    c = centroid_of(body, keep)
    plat = fitted_volume(
        target, name + "Plat",
        (c.x + side * 0.016, c.y - 0.020, c.z),
        (0.068, 0.018, 0.12),
        offset=0.009, thickness=0.006, cuts=2, material=material,
    )
    hol = kit_box(
        name + "Hol",
        (c.x + side * 0.018, c.y - 0.048, c.z - 0.008),
        (0.040, 0.028, 0.090),
        material,
        0.0020,
    )
    straps = []
    for i, dz in enumerate((0.038, -0.038)):
        s = add_cyl(name + f"St{i}", (c.x, c.y + 0.004, c.z + dz), 0.058, 0.012, (0.0, 0.0, 0.0), 12)
        sw = s.modifiers.new("SW", "SHRINKWRAP")
        sw.target = target
        sw.wrap_method = "NEAREST_SURFACEPOINT"
        sw.wrap_mode = "ABOVE_SURFACE"
        sw.offset = 0.006
        apply_mods(s)
        assign_mat(s, material)
        shade_auto(s)
        straps.append(s)
    return join_objects(name, [plat, hol] + straps, material)


def slim_thigh(target, body, name, keep: set[int], material, side: float, size=(0.038, 0.024, 0.078)):
    """Seated thigh pouch + two wrap straps. Boxes, not grid panels."""
    if len(keep) < 8:
        return None
    c = centroid_of(body, keep)
    pouch = kit_box(
        name + "P",
        (c.x + side * 0.018, c.y - 0.030, c.z),
        size,
        material,
        0.0018,
    )
    straps = []
    for i, dz in enumerate((0.028, -0.028)):
        s = add_cyl(name + f"St{i}", (c.x, c.y + 0.004, c.z + dz), 0.052, 0.010, (0.0, 0.0, 0.0), 12)
        sw = s.modifiers.new("SW", "SHRINKWRAP")
        sw.target = target
        sw.wrap_method = "NEAREST_SURFACEPOINT"
        sw.wrap_mode = "ABOVE_SURFACE"
        sw.offset = 0.005
        apply_mods(s)
        assign_mat(s, material)
        shade_auto(s)
        straps.append(s)
    return join_objects(name, [pouch] + straps, material)


def elbow_pad(target, body, name, keep: set[int], material, side: float):
    """Wraps the elbow on the full body — the armless cage has no elbow surface."""
    if len(keep) < 6:
        return None
    c = centroid_of(body, keep)
    return fitted_panel(
        target, name, c + Vector((side * 0.02, -0.01, 0.0)),
        0.055, 0.070, (side * 0.85, -0.4, 0.1), offset=0.010, thickness=0.008, cuts=3, material=material,
    )


def flap_pouch(name, loc, size, material):
    """Admin / dump / lumbar: body + flap + sewn tab so it is not a blank brick."""
    pouch = add_box(name + "B", loc, size)
    flap = add_box(
        name + "F",
        (loc[0], loc[1] - size[1] * 0.12, loc[2] + size[2] * 0.42),
        (size[0] * 0.92, size[1] * 0.82, size[2] * 0.16),
    )
    tab = add_box(
        name + "T",
        (loc[0], loc[1] + size[1] * 0.38, loc[2] + size[2] * 0.05),
        (size[0] * 0.28, size[1] * 0.28, size[2] * 0.42),
    )
    ob = join_objects(name, [pouch, flap, tab], material)
    finish_hard(ob, 0.0020, 2)
    return ob


def knee_mount(target, body, name, keep: set[int], material):
    """Hard cap + two wrap straps so the pad reads as mounted, not a floating tile."""
    c = centroid_of(body, keep)
    pad = fitted_panel(
        target, name + "Pad", c + Vector((0.0, -0.01, 0.0)),
        0.078, 0.088, (0.0, -1.0, 0.12), offset=0.011, thickness=0.011, cuts=3, material=material,
    )
    cap = kit_box(name + "Cap", (c.x, c.y - 0.028, c.z + 0.004), (0.055, 0.016, 0.048), material, 0.0020)
    straps = []
    for i, dz in enumerate((-0.018, -0.040)):
        s = add_cyl(name + f"St{i}", (c.x, c.y + 0.008, c.z + dz), 0.052 if i == 0 else 0.048, 0.013, (0.0, 0.0, 0.0), 14)
        sw = s.modifiers.new("SW", "SHRINKWRAP")
        sw.target = target
        sw.wrap_method = "NEAREST_SURFACEPOINT"
        sw.wrap_mode = "ABOVE_SURFACE"
        sw.offset = 0.006
        apply_mods(s)
        assign_mat(s, material)
        shade_auto(s)
        straps.append(s)
    return join_objects(name, [pad, cap] + straps, material)


def boot_with_cuff(target, body, name, keep: set[int], material):
    """Combat boot + gaiter cuff + tongue so the pant tuck reads as a transition, not a cylinder cap."""
    boot = simple_boot(body, name, keep, material)
    if boot is None:
        return None
    pts = [body.data.vertices[i].co for i in keep]
    loc = Vector((
        sum(p.x for p in pts) / len(pts),
        sum(p.y for p in pts) / len(pts),
        min(p.z for p in pts) + 0.162,
    ))
    cuff = add_cyl(name + "Cuff", tuple(loc), 0.052, 0.055, (0.0, 0.0, 0.0), 14)
    sw = cuff.modifiers.new("SW", "SHRINKWRAP")
    sw.target = target
    sw.wrap_method = "NEAREST_SURFACEPOINT"
    sw.wrap_mode = "ABOVE_SURFACE"
    sw.offset = 0.007
    sol = cuff.modifiers.new("Sol", "SOLIDIFY")
    sol.thickness = 0.007
    sol.offset = 1.0
    apply_mods(cuff)
    assign_mat(cuff, material)
    shade_auto(cuff)
    tongue = kit_box(
        name + "Tongue",
        (loc.x, loc.y - 0.048, loc.z - 0.012),
        (0.030, 0.016, 0.088),
        material,
        0.0016,
    )
    return join_objects(name, [boot, cuff, tongue], material)


def kit_box(name, loc, size, material, bevel=0.0024):
    ob = add_box(name, loc, size)
    finish_hard(ob, bevel, 2)
    assign_mat(ob, material)
    return ob


def reduce_hidden_body(body, hide: set[int], protect: set[int], ratio=0.14) -> int:
    """Collapse covered torso only. Face/hands/shoulders/elbows/knees stay dense for later deform."""
    idx = list(hide - protect)
    if len(idx) < 80:
        return 0
    vg = body.vertex_groups.new(name="ff_hidden")
    vg.add(idx, 1.0, "REPLACE")
    d = body.modifiers.new("DecHidden", "DECIMATE")
    d.decimate_type = "COLLAPSE"
    d.ratio = ratio
    d.vertex_group = "ff_hidden"
    apply_mods(body)
    cleanup_mesh(body)
    shade_auto(body)
    return len(idx)


def closed_helmet(body, armor_mat, visor_mat, stealth=False) -> list:
    m = metrics(body)
    loc = Vector((0.0, torso_center_y(body, m), m["zmin"] + m["h"] * 0.938))
    rad = 0.110 if stealth else 0.118
    bpy.ops.mesh.primitive_uv_sphere_add(segments=22, ring_count=14, radius=rad, location=loc)
    helm = bpy.context.object
    helm.name = "Helmet"
    # Ballistic shell: slightly longer front-to-back, not a pancake brim.
    helm.scale = (1.02, 1.12, 0.96) if not stealth else (1.00, 1.08, 0.94)
    bpy.ops.object.transform_apply(scale=True)
    sw = helm.modifiers.new("SW", "SHRINKWRAP")
    sw.target = body
    sw.wrap_method = "NEAREST_SURFACEPOINT"
    sw.wrap_mode = "ABOVE_SURFACE"
    sw.offset = 0.011 if stealth else 0.015
    sol = helm.modifiers.new("Sol", "SOLIDIFY")
    sol.thickness = 0.011 if stealth else 0.015
    apply_mods(helm)
    face_cut_h = 0.052 if stealth else 0.044
    boolean_cut(
        helm,
        add_box("FaceCut", (loc.x, loc.y - rad * 0.52, loc.z - 0.032), (rad * 1.05, rad * 0.62, face_cut_h)),
    )
    boolean_cut(
        helm,
        add_box("ChinCut", (loc.x, loc.y, loc.z - rad * 0.72), (rad * 2.0, rad * 2.0, rad * 0.48)),
    )
    assign_mat(helm, armor_mat)
    shade_auto(helm)
    vis_h = 0.040 if stealth else 0.026
    vis = add_box("Visor", (loc.x, loc.y - rad * 0.40, loc.z - 0.012), (rad * 0.72, 0.014, vis_h))
    sw2 = vis.modifiers.new("SW", "SHRINKWRAP")
    sw2.target = body
    sw2.wrap_method = "NEAREST_SURFACEPOINT"
    sw2.wrap_mode = "ABOVE_SURFACE"
    sw2.offset = 0.018
    apply_mods(vis)
    assign_mat(vis, visor_mat)
    shade_auto(vis)
    cups = []
    for s in (-1.0, 1.0):
        cup = add_cyl("Cup", (loc.x + s * rad * 0.68, loc.y + 0.008, loc.z - 0.004), 0.024, 0.034, (0.0, math.pi / 2, 0.0), 12)
        assign_mat(cup, armor_mat)
        shade_auto(cup)
        cups.append(cup)
    brow = add_box("Brow", (loc.x, loc.y - rad * 0.38, loc.z + 0.018), (rad * 0.70, 0.018, 0.012))
    nape = add_box("Nape", (loc.x, loc.y + rad * 0.38, loc.z - 0.018), (rad * 0.62, 0.032, 0.040))
    assign_mat(brow, armor_mat)
    assign_mat(nape, armor_mat)
    shade_auto(brow)
    shade_auto(nape)
    return [helm, vis, brow, nape] + cups


def kit_assault(body, mats) -> tuple[list, dict]:
    r = region_sets(body)
    print("REGIONS assault", {k: len(v) for k, v in r.items() if isinstance(v, set)}, flush=True)
    armor, visor_m, glove_m, fabric = mats["armor"], mats["visor"], mats["glove"], mats["fabric"]
    assign_mat(body, fabric)
    shade_auto(body)
    cage = make_wrap_cage(body)

    chest_c = centroid_of(body, r["chest"])
    back_c = centroid_of(body, r["back"])
    chest_s = region_size(body, r["chest"])
    back_s = region_size(body, r["back"])

    front = fitted_panel(
        cage, "Plate", chest_c + Vector((0.0, -0.028, 0.0)),
        min(0.23, chest_s.x * 1.08), min(0.28, chest_s.z * 1.08),
        (0.0, -1.0, 0.08), offset=0.016, thickness=0.018, cuts=6, material=armor,
    )
    plate_insert = kit_box(
        "PlateInsert",
        (chest_c.x, chest_c.y - 0.078, chest_c.z + 0.01),
        (0.168, 0.028, 0.205),
        armor,
        0.0030,
    )
    back = fitted_panel(
        cage, "BackPlate", back_c + Vector((0.0, 0.028, 0.0)),
        min(0.21, back_s.x * 1.02), min(0.26, back_s.z * 1.04),
        (0.0, 1.0, 0.08), offset=0.014, thickness=0.014, cuts=5, material=armor,
    )
    l_side = fitted_panel(
        cage, "LSide", chest_c + Vector((-0.11, 0.0, -0.01)),
        0.085, 0.15, (-1.0, -0.1, 0.0), offset=0.012, thickness=0.009, cuts=4, material=armor,
    )
    r_side = fitted_panel(
        cage, "RSide", chest_c + Vector((0.11, 0.0, -0.01)),
        0.085, 0.15, (1.0, -0.1, 0.0), offset=0.012, thickness=0.009, cuts=4, material=armor,
    )
    l_pad = fitted_panel(
        cage, "LPad", centroid_of(body, r["l_pad"]) + Vector((-0.02, 0.0, 0.02)),
        0.09, 0.07, (-0.4, -0.15, 0.8), offset=0.013, thickness=0.010, cuts=3, material=armor,
    )
    r_pad = fitted_panel(
        cage, "RPad", centroid_of(body, r["r_pad"]) + Vector((0.02, 0.0, 0.02)),
        0.09, 0.07, (0.4, -0.15, 0.8), offset=0.013, thickness=0.010, cuts=3, material=armor,
    )
    collar = fitted_panel(
        cage, "Collar", centroid_of(body, r["collar"]) + Vector((0.0, -0.02, 0.01)),
        0.12, 0.055, (0.0, -0.35, 0.75), offset=0.010, thickness=0.007, cuts=3, material=armor,
    )
    l_strap = fitted_panel(
        cage, "LStrap", chest_c + Vector((-0.075, -0.01, 0.12)),
        0.030, 0.16, (-0.2, -0.65, 0.55), offset=0.015, thickness=0.006, cuts=3, material=armor,
    )
    r_strap = fitted_panel(
        cage, "RStrap", chest_c + Vector((0.075, -0.01, 0.12)),
        0.030, 0.16, (0.2, -0.65, 0.55), offset=0.015, thickness=0.006, cuts=3, material=armor,
    )
    belt = fitted_belt(cage, body, "Belt", armor, depth=0.050, extra=0.005, thickness=0.012)
    lk = knee_mount(cage, body, "LKnee", r["l_knee"], armor)
    rk = knee_mount(cage, body, "RKnee", r["r_knee"], armor)

    fm = metrics(front)
    pouch_y = fm["ymin"] - 0.020
    pouches = [
        mag_pouch("Mag0", (chest_c.x - 0.052, pouch_y, chest_c.z - 0.045), armor),
        mag_pouch("Mag1", (chest_c.x + 0.000, pouch_y - 0.004, chest_c.z - 0.045), armor),
        mag_pouch("Mag2", (chest_c.x + 0.052, pouch_y, chest_c.z - 0.045), armor),
    ]
    webbing = kit_box(
        "MagWeb",
        (chest_c.x, pouch_y + 0.018, chest_c.z - 0.045),
        (0.155, 0.010, 0.072),
        armor,
        0.0014,
    )
    molle_f = molle_field(
        "MolleF",
        (chest_c.x, chest_c.y - 0.102, chest_c.z + 0.058),
        armor,
        rows=3,
        cols=6,
        pitch=(0.022, 0.018),
        width=0.14,
    )
    molle_b = molle_field(
        "MolleB",
        (back_c.x, back_c.y + 0.062, back_c.z + 0.02),
        armor,
        rows=3,
        cols=5,
        pitch=(0.022, 0.018),
        width=0.12,
    )
    admin = flap_pouch(
        "Admin",
        (chest_c.x, pouch_y + 0.006, chest_c.z + 0.062),
        (0.100, 0.028, 0.042),
        armor,
    )
    belt_c = centroid_of(body, r["belt"])
    dump = flap_pouch(
        "Dump",
        (belt_c.x - 0.13, belt_c.y - 0.052, belt_c.z - 0.012),
        (0.078, 0.048, 0.070),
        armor,
    )
    lumbar = flap_pouch(
        "Lumbar",
        (back_c.x, back_c.y + 0.055, belt_c.z + 0.008),
        (0.12, 0.040, 0.055),
        armor,
    )
    util = kit_box("Util", (chest_c.x - 0.12, pouch_y + 0.04, chest_c.z - 0.14), (0.05, 0.032, 0.055), armor, 0.0022)
    radio = kit_box("Radio", tuple(chest_c + Vector((-0.13, -0.02, 0.10))), (0.038, 0.048, 0.062), armor, 0.0020)
    ant = add_cyl("Ant", tuple(Vector(radio.location) + Vector((0.0, 0.0, 0.052))), 0.004, 0.065, (0.0, 0.0, 0.0), 8)
    assign_mat(ant, armor)
    shade_auto(ant)
    l_buckle = kit_box("LBuckle", tuple(chest_c + Vector((-0.075, -0.055, 0.10))), (0.024, 0.016, 0.018), armor, 0.0012)
    r_buckle = kit_box("RBuckle", tuple(chest_c + Vector((0.075, -0.055, 0.10))), (0.024, 0.016, 0.018), armor, 0.0012)

    l_elbow_idx = {i for i in r["elbows"] if body.data.vertices[i].co.x < 0}
    r_elbow_idx = {i for i in r["elbows"] if body.data.vertices[i].co.x > 0}
    l_elb = elbow_pad(body, body, "LElbow", l_elbow_idx, armor, -1.0)
    r_elb = elbow_pad(body, body, "RElbow", r_elbow_idx, armor, 1.0)
    drop = drop_leg(cage, body, "DropLeg", r["thigh_pouch_r"], armor, 1.0)
    cargo = fitted_volume(
        cage, "CargoL", centroid_of(body, r["thigh_pouch_l"]) + Vector((-0.01, -0.02, 0.0)),
        (0.055, 0.028, 0.085), offset=0.010, thickness=0.007, cuts=2, material=armor,
    )

    l_boot = boot_with_cuff(cage, body, "LBoot", r["l_boot"], armor)
    r_boot = boot_with_cuff(cage, body, "RBoot", r["r_boot"], armor)
    l_glove = glove_overlay(body, r["l_glove"], "LGlove", glove_m)
    r_glove = glove_overlay(body, r["r_glove"], "RGlove", glove_m)

    helm_bits = closed_helmet(body, armor, visor_m, stealth=False)
    visor_obj = helm_bits[1]
    cups = helm_bits[4:]
    hloc = helm_bits[0].location
    rad = 0.118
    shroud = kit_box("NvgShroud", (hloc.x, hloc.y - rad * 0.38, hloc.z + 0.042), (0.042, 0.028, 0.022), armor, 0.0014)
    nvg = kit_box("NvgMount", (hloc.x, hloc.y - rad * 0.52, hloc.z + 0.036), (0.020, 0.018, 0.014), armor, 0.0008)
    rails = []
    for i, cup in enumerate(cups[:2]):
        sx = 1.0 if cup.location.x >= 0 else -1.0
        rails.append(
            kit_box(
                f"ArcRail{i}",
                (cup.location.x + sx * 0.012, cup.location.y, cup.location.z + 0.004),
                (0.012, 0.070, 0.024),
                armor,
                0.0010,
            )
        )
    gaiter = kit_box(
        "Gaiter",
        (hloc.x, hloc.y - rad * 0.28, hloc.z - 0.058),
        (rad * 0.78, 0.032, 0.052),
        visor_m,
        0.0020,
    )
    boom = add_cyl(
        "Boom",
        (cups[0].location.x * 0.25, helm_bits[0].location.y - 0.07, helm_bits[0].location.z - 0.022),
        0.004,
        0.072,
        (math.pi / 2.4, 0.0, 0.0),
        8,
    )
    assign_mat(boom, armor)
    shade_auto(boom)
    helm_kit = join_objects(
        "HelmetKit",
        [helm_bits[0], helm_bits[2], helm_bits[3], boom, shroud, nvg] + cups + rails,
        armor,
    )

    bpy.data.objects.remove(cage, do_unlink=True)

    parts = [
        body, front, plate_insert, back, l_side, r_side, l_pad, r_pad, collar,
        l_strap, r_strap, l_buckle, r_buckle, belt, lk, rk, webbing, molle_f, molle_b,
        admin, dump, lumbar, util, radio, ant, drop, cargo, l_elb, r_elb,
        l_boot, r_boot, helm_kit, visor_obj, gaiter, l_glove, r_glove,
    ] + pouches
    parts = [p for p in parts if p is not None]
    meta = kit_meta(parts, body)
    return parts, {
        "hidden_verts_decimated": 0,
        "protect_kept": "full hm08 kept for Gate A2 form — hidden-torso collapse planned after approval",
        "kit_method": "MOLLE carrier, mag/admin/dump/lumbar pouches, drop-leg, NVG shroud + ARC rails, gaiter cuff boots, dual knee straps",
        "kit_pieces": meta["kit_pieces"],
        "kit_tris": meta["kit_tris"],
        "body_tris": meta["body_tris"],
    }


def kit_phantom(body, mats) -> tuple[list, dict]:
    r = region_sets(body)
    print("REGIONS phantom", {k: len(v) for k, v in r.items() if isinstance(v, set)}, flush=True)
    armor, visor_m, glove_m, fabric = mats["armor"], mats["visor"], mats["glove"], mats["fabric"]
    assign_mat(body, fabric)
    shade_auto(body)
    cage = make_wrap_cage(body)

    chest_c = centroid_of(body, r["chest"])
    back_c = centroid_of(body, r["back"])
    chest_s = region_size(body, r["chest"])
    belt_c = centroid_of(body, r["belt"])

    # Crossing X-harness (not a plate carrier). Strap width stays narrow.
    harness_a = fitted_panel(
        cage, "HarnessA", chest_c + Vector((-0.02, -0.016, 0.02)),
        0.030, 0.26, (-0.55, -1.0, 0.05), offset=0.009, thickness=0.006, cuts=4, material=armor,
    )
    harness_b = fitted_panel(
        cage, "HarnessB", chest_c + Vector((0.02, -0.016, 0.02)),
        0.030, 0.26, (0.55, -1.0, 0.05), offset=0.009, thickness=0.006, cuts=4, material=armor,
    )
    sternum = kit_box("Sternum", tuple(chest_c + Vector((0.0, -0.058, 0.015))), (0.048, 0.018, 0.032), armor, 0.0014)
    light_plate = fitted_panel(
        cage, "LightPlate", chest_c + Vector((0.0, -0.020, -0.02)),
        min(0.11, chest_s.x * 0.55), 0.090, (0.0, -1.0, 0.04),
        offset=0.010, thickness=0.006, cuts=4, material=armor,
    )
    slim = flap_pouch(
        "SlimPouch",
        tuple(chest_c + Vector((0.055, -0.058, -0.04))),
        (0.034, 0.024, 0.058),
        armor,
    )
    waist_tap_l = kit_box("TapL", (chest_c.x - 0.055, chest_c.y - 0.040, belt_c.z + 0.035), (0.022, 0.014, 0.055), armor, 0.0012)
    waist_tap_r = kit_box("TapR", (chest_c.x + 0.055, chest_c.y - 0.040, belt_c.z + 0.035), (0.022, 0.014, 0.055), armor, 0.0012)

    pack = kit_box(
        "Pack",
        (back_c.x, back_c.y + 0.062, back_c.z + 0.015),
        (0.088, 0.044, 0.125),
        armor,
        0.0024,
    )
    pack_lid = kit_box(
        "PackLid",
        (back_c.x, back_c.y + 0.078, back_c.z + 0.062),
        (0.080, 0.016, 0.036),
        armor,
        0.0016,
    )
    pack_straps = [
        kit_box("PackComp0", (back_c.x, back_c.y + 0.086, back_c.z + 0.01), (0.072, 0.008, 0.010), armor, 0.0008),
        kit_box("PackComp1", (back_c.x, back_c.y + 0.086, back_c.z - 0.028), (0.072, 0.008, 0.010), armor, 0.0008),
    ]
    pack_strap_l = fitted_panel(
        cage, "PackSL", back_c + Vector((-0.055, 0.018, 0.07)),
        0.020, 0.11, (-0.15, 0.85, 0.30), offset=0.009, thickness=0.004, cuts=3, material=armor,
    )
    pack_strap_r = fitted_panel(
        cage, "PackSR", back_c + Vector((0.055, 0.018, 0.07)),
        0.020, 0.11, (0.15, 0.85, 0.30), offset=0.009, thickness=0.004, cuts=3, material=armor,
    )
    node = kit_box("SBNode", (back_c.x, back_c.y + 0.088, back_c.z + 0.04), (0.036, 0.020, 0.028), visor_m, 0.0016)
    tube = add_cyl("Hydra", (back_c.x - 0.038, back_c.y + 0.055, back_c.z + 0.08), 0.004, 0.12, (0.55, 0.0, 0.0), 8)
    assign_mat(tube, armor)
    shade_auto(tube)

    belt = fitted_belt(cage, body, "PBelt", armor, depth=0.040, extra=0.004, thickness=0.009)
    buckle = kit_box("PBuckle", (belt_c.x, belt_c.y - 0.072, belt_c.z), (0.038, 0.016, 0.028), armor, 0.0014)
    hip = flap_pouch("HipPouch", (belt_c.x + 0.11, belt_c.y - 0.028, belt_c.z), (0.045, 0.032, 0.050), armor)

    collar = fitted_panel(
        cage, "PCollar", centroid_of(body, r["collar"]) + Vector((0.0, -0.012, 0.0)),
        0.10, 0.048, (0.0, -0.35, 0.80), offset=0.009, thickness=0.006, cuts=3, material=armor,
    )

    l_thigh = slim_thigh(cage, body, "PThighL", r["thigh_pouch_l"], armor, -1.0, size=(0.042, 0.026, 0.085))
    r_thigh = slim_thigh(cage, body, "PThighR", r["thigh_pouch_r"], armor, 1.0, size=(0.036, 0.022, 0.070))
    lk = knee_mount(cage, body, "PLKnee", r["l_knee"], armor)
    rk = knee_mount(cage, body, "PRKnee", r["r_knee"], armor)

    l_boot = boot_with_cuff(cage, body, "PLBoot", r["l_boot"], armor)
    r_boot = boot_with_cuff(cage, body, "PRBoot", r["r_boot"], armor)
    l_glove = glove_overlay(body, r["l_glove"], "PLGlove", glove_m, 0.0035)
    r_glove = glove_overlay(body, r["r_glove"], "PRGlove", glove_m, 0.0035)

    helm_bits = closed_helmet(body, armor, visor_m, stealth=True)
    visor_obj = helm_bits[1]
    active(visor_obj)
    visor_obj.scale = (1.18, 1.45, 1.35)
    bpy.ops.object.transform_apply(scale=True)
    vm = metrics(visor_obj)
    sensor = add_cyl("Sensor", (vm["xmax"] + 0.01, vm["ymin"] - 0.01, vm["cz"]), 0.008, 0.018, (math.pi / 2, 0.0, 0.0), 10)
    sensor2 = add_cyl("Sensor2", (vm["xmin"] - 0.01, vm["ymin"] - 0.01, vm["cz"] + 0.01), 0.006, 0.014, (math.pi / 2, 0.0, 0.0), 8)
    assign_mat(sensor, visor_m)
    assign_mat(sensor2, visor_m)
    shade_auto(sensor)
    shade_auto(sensor2)
    helm_kit = join_objects("PHelmet", [helm_bits[0]] + helm_bits[2:], armor)

    bpy.data.objects.remove(cage, do_unlink=True)

    parts = [
        body, harness_a, harness_b, sternum, light_plate, slim, waist_tap_l, waist_tap_r,
        pack, pack_lid, pack_strap_l, pack_strap_r, node, tube, belt, buckle, hip, collar,
        l_thigh, r_thigh, lk, rk, l_boot, r_boot, helm_kit, visor_obj, sensor, sensor2,
        l_glove, r_glove,
    ] + pack_straps
    parts = [p for p in parts if p is not None]
    meta = kit_meta(parts, body)
    return parts, {
        "hidden_verts_decimated": 0,
        "protect_kept": "full hm08 kept for Gate A2 form — hidden-torso collapse planned after approval",
        "kit_method": "X-harness + sternum, compact pack with lid/node, dual thigh pouches, stealth visor, waist taps",
        "kit_pieces": meta["kit_pieces"],
        "kit_tris": meta["kit_tris"],
        "body_tris": meta["body_tris"],
    }


def profile_mesh(name, pts_yz, half_x, segs=1) -> bpy.types.Object:
    """Side-view YZ profile extruded in X — hard-surface receiver language, not stacked cubes."""
    mesh = bpy.data.meshes.new(name)
    ob = bpy.data.objects.new(name, mesh)
    link(ob)
    bm = bmesh.new()
    ring_l = [bm.verts.new(Vector((-half_x, p[0], p[1]))) for p in pts_yz]
    ring_r = [bm.verts.new(Vector((half_x, p[0], p[1]))) for p in pts_yz]
    n = len(pts_yz)
    bm.faces.new(ring_l[::-1])
    bm.faces.new(ring_r)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((ring_l[i], ring_l[j], ring_r[j], ring_r[i]))
    bm.normal_update()
    bm.to_mesh(mesh)
    bm.free()
    return ob


def relieve_handguard_for_support(body) -> None:
    """Rail-profile top chamfer (both sides) plus extra left-edge bite at the wrap.

    Symmetric chamfer reads as a manufactured rail in hero/left/right. Extra
    left-top inset is the occluded strip under the support fingers.
    """
    bm = bmesh_of(body)
    for v in bm.verts:
        y, z, x = v.co.y, v.co.z, v.co.x
        if not (0.14 < y < 0.40):
            continue
        if z > 0.018:
            t = min(1.0, (z - 0.018) / 0.032)
            v.co.x *= 1.0 - 0.50 * t
        if x < 0.0 and 0.165 < y < 0.300 and z > 0.022:
            t = min(1.0, (z - 0.022) / 0.028)
            wy = 1.0 - abs(y - 0.218) / 0.070
            w = max(0.0, wy) * t
            v.co.x += 0.008 * w
    commit_bm(bm, body)


def _probe_open_span(bvh, sign, origin, axis, limit=0.08, step=0.001) -> float:
    """Distance from origin along ±axis until signed distance goes negative (hits metal)."""
    axis = Vector(axis).normalized()
    hit = limit
    for sgn in (1.0, -1.0):
        for i in range(1, int(limit / step) + 1):
            p = origin + axis * (sgn * i * step)
            if nearest(bvh, p, sign)[2] < 0.0:
                hit = min(hit, i * step)
                break
    return 2.0 * hit


def report_kf16_receiving(metal) -> None:
    """Print well / corner extents after boolean + bevel (checkpoint evidence)."""
    bvh = bvh_of(metal)
    sign = bvh_sign(bvh)
    origin = Vector((0.0, 0.024, -0.032))
    fwd = Vector((0.0, 0.032, -0.034))
    sd0 = nearest(bvh, origin, sign)[2]
    sdf = nearest(bvh, fwd, sign)[2]
    span_x = _probe_open_span(bvh, sign, fwd, (1.0, 0.0, 0.0))
    span_y = _probe_open_span(bvh, sign, fwd, (0.0, 1.0, 0.0), limit=0.04)
    span_z = _probe_open_span(bvh, sign, fwd, (0.0, 0.0, 1.0), limit=0.04)
    side = Vector((0.022, 0.032, -0.034))
    print(
        f"RECV well_center sd={sd0:.4f} fwd_sd={sdf:.4f} open_x={span_x:.4f} "
        f"open_y={span_y:.4f} open_z={span_z:.4f} outboard_sd={nearest(bvh, side, sign)[2]:.4f} "
        f"(before 0.007 / 0.022 / 0.016)",
        flush=True,
    )
    pts = [v.co.copy() for v in metal.data.vertices]
    corner = [p for p in pts if -0.050 <= p.x <= 0.012 and 0.16 <= p.y <= 0.32 and 0.018 <= p.z <= 0.062]
    if corner:
        left = [p for p in corner if p.x < 0.0]
        top_left = [p for p in left if p.z > 0.030]
        lx = min(p.x for p in left) if left else 0.0
        tlx = min(p.x for p in top_left) if top_left else lx
        tz = max(p.z for p in top_left) if top_left else 0.0
        print(
            f"RECV corner left_face_x={lx:.4f} top_left_x={tlx:.4f} top_left_z={tz:.4f} "
            f"(before left_face~-0.017 top unchamfered)",
            flush=True,
        )
    print(
        "RECV authored tg_cut FAST on body (0.055, 0.036, 0.038) at (0, 0.038, -0.036) — forward of grip",
        flush=True,
    )


def report_kf16_nodes(root) -> None:
    bpy.context.view_layer.update()
    wanted = ("MuzzleFlash", "ShellEject", "Magazine", "AdsAlign")
    print("KF16 NODES (Blender local / Godot)", flush=True)
    for name in wanted:
        ob = next((o for o in [root] + list(root.children_recursive) if o.name == name), None)
        if ob is None:
            print(f"  {name} MISSING", flush=True)
            continue
        loc = Vector(ob.location)
        g = blender_to_godot(loc)
        print(
            f"  {name} blender={tuple(round(c, 4) for c in loc)} "
            f"godot={tuple(round(c, 4) for c in g)}",
            flush=True,
        )


def kf16_build(metal_mat, poly_mat) -> tuple[bpy.types.Object, dict]:
    """Original KF-16 as one readable service-rifle silhouette.

    Barrel along Blender +Y so glTF export_yup points Godot -Z (camera forward).
    Stock / receiver / magwell / handguard are one profile, not stacked primitives.
    """
    # Closed YZ loop: handguard front → rail → stock → grip → magwell → handguard belly.
    # One YZ loop: handguard → upper receiver → stock → grip → magwell → belly.
    # Order is clockwise and non-crossing so the rifle reads as one forging.
    body_pts = [
        (0.38, 0.040), (0.26, 0.044), (0.16, 0.050), (0.10, 0.056),
        (0.00, 0.058), (-0.10, 0.052), (-0.20, 0.046), (-0.28, 0.038),
        (-0.33, 0.026), (-0.348, 0.008), (-0.348, -0.018), (-0.30, -0.010),
        (-0.20, 0.002), (-0.10, 0.000), (-0.062, -0.008),
        (-0.060, -0.040), (-0.050, -0.078), (-0.028, -0.104),
        (0.008, -0.100), (0.024, -0.068), (0.022, -0.028), (0.016, -0.012),
        (0.028, -0.014), (0.034, -0.048), (0.048, -0.078), (0.078, -0.080),
        (0.092, -0.048), (0.090, -0.010), (0.20, 0.012), (0.38, 0.016),
    ]
    body = profile_mesh("kf16_body", body_pts, 0.018)
    # Continuous taper on the handguard so it does not read as a bolted tube.
    bm = bmesh_of(body)
    for v in bm.verts:
        if v.co.y > 0.14:
            t = min(1.0, (v.co.y - 0.14) / 0.26)
            v.co.x *= 1.0 - 0.12 * t
    commit_bm(bm, body)
    relieve_handguard_for_support(body)
    # Widen the existing grip/magwell gap on the body alone (manifold extrusion).
    boolean_cut(body, add_box("tg_cut", (0.0, 0.038, -0.036), (0.055, 0.036, 0.038)), solver="FAST")
    # Barrel continues the handguard; overlaps the front so the seam reads as a joint.
    barrel = add_cyl("bar", (0.0, 0.44, 0.026), 0.0088, 0.36, (math.pi / 2, 0.0, 0.0), 18)
    chamber = add_cyl("chm", (0.0, 0.30, 0.026), 0.0115, 0.08, (math.pi / 2, 0.0, 0.0), 16)
    muzzle = add_cyl("mz", (0.0, 0.655, 0.026), 0.0135, 0.042, (math.pi / 2, 0.0, 0.0), 16)
    optic = add_cyl("optic", (0.0, 0.00, 0.072), 0.013, 0.062, (math.pi / 2, 0.0, 0.0), 14)
    hood = add_cyl("hood", (0.0, -0.028, 0.072), 0.015, 0.014, (math.pi / 2, 0.0, 0.0), 14)
    rail = add_box("rail", (0.0, 0.06, 0.058), (0.013, 0.22, 0.005))
    teeth = [add_box("tooth", (0.0, -0.02 + i * 0.032, 0.062), (0.011, 0.012, 0.003)) for i in range(6)]
    ch = add_box("ch", (0.0, -0.10, 0.050), (0.007, 0.048, 0.007))
    cht = add_box("cht", (0.024, -0.122, 0.050), (0.040, 0.010, 0.007))
    sel = add_cyl("sel", (0.019, -0.04, 0.004), 0.006, 0.009, (0.0, math.pi / 2, 0.0), 10)
    metal = join_objects(
        "kf16_metal",
        [body, barrel, chamber, muzzle, optic, hood, rail, ch, cht, sel] + teeth,
    )
    boolean_cut(metal, add_box("eject_cut", (0.020, 0.03, 0.030), (0.016, 0.048, 0.018)))
    boolean_cut(metal, add_box("well_cut", (0.0, 0.055, -0.038), (0.020, 0.024, 0.046)))
    finish_hard(metal, 0.0048, 3)
    tg_bot = add_box("tg_bot", (0.0, 0.038, -0.058), (0.016, 0.036, 0.008))
    trig = add_box("trig", (0.0, 0.028, -0.026), (0.004, 0.007, 0.014), (math.radians(8), 0.0, 0.0))
    assign_mat(tg_bot, metal_mat)
    assign_mat(trig, metal_mat)
    metal = join_objects("kf16_metal", [metal, tg_bot, trig])
    assign_mat(metal, metal_mat)
    shade_auto(metal)

    mag = add_box("Magazine", (0.0, 0.055, -0.068), (0.018, 0.026, 0.092))
    active(mag)
    bpy.ops.object.mode_set(mode="EDIT")
    bm = bmesh.from_edit_mesh(mag.data)
    for v in bm.verts:
        if v.co.z < -0.02:
            v.co.x *= 0.84
            v.co.y *= 0.88
            v.co.y += 0.008
    bmesh.update_edit_mesh(mag.data)
    bpy.ops.object.mode_set(mode="OBJECT")
    finish_hard(mag, 0.0020, 3)
    assign_mat(mag, poly_mat)

    root = bpy.data.objects.new("ff_wpn_kf16", None)
    link(root)
    metal.parent = root
    mag.name = "Magazine"
    mag.parent = root
    mz = empty("MuzzleFlash", tuple(godot_to_blender(MUZZLE_GODOT)))
    se = empty("ShellEject", tuple(godot_to_blender(SHELL_GODOT)))
    ads = empty("AdsAlign", tuple(godot_to_blender(Vector((0.0, 0.078, -0.02)))))
    for e in (mz, se, ads):
        e.parent = root
    bpy.context.view_layer.update()
    report_kf16_receiving(metal)
    report_kf16_nodes(root)
    t, v = count_tree(root)
    print(f"KF-16 tris={t} verts={v} budget<=8000 {'OK' if t <= 8000 else 'OVER'}", flush=True)
    return root, {
        "tris": t,
        "verts": v,
        "nodes": ["MuzzleFlash", "ShellEject", "Magazine", "AdsAlign"],
        "grip_local": (0.030, -0.012, -0.058),
        "handguard_local": (-0.026, 0.22, 0.016),
        "budget_ok": t <= 8000,
    }


def _reject(v: Vector, axis: Vector) -> Vector:
    r = v - axis * v.dot(axis)
    return r if r.length > 1e-6 else Vector((1.0, 0.0, 0.0))


def _basis(axis: Vector) -> tuple[Vector, Vector, Vector]:
    axis = Vector(axis).normalized()
    ref = Vector((1.0, 0.0, 0.0)) if abs(axis.x) < 0.85 else Vector((0.0, 1.0, 0.0))
    u = _reject(ref, axis).normalized()
    v = axis.cross(u).normalized()
    return axis, u, v


def _frames(points: list[Vector]) -> list[tuple[Vector, Vector, Vector]]:
    """Parallel-transport frames so lofted fingers do not twist."""
    pts = [Vector(p) for p in points]
    frames = []
    prev_u = None
    for i, _p in enumerate(pts):
        if i == 0:
            axis = (pts[1] - pts[0]).normalized()
        elif i == len(pts) - 1:
            axis = (pts[i] - pts[i - 1]).normalized()
        else:
            axis = (pts[i + 1] - pts[i - 1]).normalized()
        if prev_u is None:
            _ax, u, v = _basis(axis)
        else:
            u = prev_u - axis * prev_u.dot(axis)
            if u.length < 1e-6:
                _ax, u, v = _basis(axis)
            else:
                u = u.normalized()
                v = axis.cross(u).normalized()
        prev_u = u
        frames.append((axis, u, v))
    return frames


def _add_box_bm(bm, center, ax, ay, az, size) -> None:
    geom = bmesh.ops.create_cube(bm, size=1.0)
    ax, ay, az = Vector(ax).normalized(), Vector(ay).normalized(), Vector(az).normalized()
    center = Vector(center)
    for vert in geom["verts"]:
        local = Vector((vert.co.x * size[0] * 0.5, vert.co.y * size[1] * 0.5, vert.co.z * size[2] * 0.5))
        vert.co = center + ax * local.x + ay * local.y + az * local.z


def _add_tube_bm(bm, points, radii, segs=8, flatten=0.78) -> None:
    """Loft a flattened finger/forearm tube. First point sits inside the palm so the glove is one mass."""
    pts = [Vector(p) for p in points]
    frames = _frames(pts)
    rings = []
    for (p, r, (_ax, u, v)) in zip(pts, radii, frames):
        ring = []
        for k in range(segs):
            ang = 2.0 * math.pi * k / segs
            ring.append(bm.verts.new(p + u * math.cos(ang) * r + v * math.sin(ang) * r * flatten))
        rings.append(ring)
    for i in range(len(rings) - 1):
        a, b = rings[i], rings[i + 1]
        for k in range(segs):
            k2 = (k + 1) % segs
            try:
                bm.faces.new((a[k], a[k2], b[k2], b[k]))
            except ValueError:
                pass
    try:
        bm.faces.new(list(reversed(rings[0])))
    except ValueError:
        pass
    try:
        bm.faces.new(rings[-1])
    except ValueError:
        pass


def _finger_radii(root: float, tip: float, n: int) -> list[float]:
    """Taper with slight knuckle swell so digits read as fingers, not a hose."""
    out = []
    for i in range(n):
        t = i / max(1, n - 1)
        r = root * (1.0 - t) + tip * t
        if 0 < i < n - 1 and i % 2 == 0:
            r *= 1.08
        out.append(r)
    return out


def _hand_axes(out, along_hint, index_forward) -> tuple[Vector, Vector, Vector]:
    """Orthonormal hand frame. `out` is the back of the hand (must face the gameplay camera)."""
    out = Vector(out).normalized()
    along = (Vector(along_hint) - out * Vector(along_hint).dot(out)).normalized()
    across = out.cross(along).normalized()
    if across.dot(Vector(index_forward)) < 0.0:
        across = -across
        along = across.cross(out).normalized()
    return across, along, out


def make_glove_hand(name, palm_c, across, along, out, palm_size, fingers, thumb, wrist, glove_mat):
    """One connected viewmodel glove: palm mass + knuckle plate + digits + wrist cuff."""
    palm_c = Vector(palm_c)
    across, along, out = Vector(across).normalized(), Vector(along).normalized(), Vector(out).normalized()
    mesh = bpy.data.meshes.new(name)
    ob = bpy.data.objects.new(name, mesh)
    link(ob)
    bm = bmesh.new()
    _add_box_bm(bm, palm_c, across, along, out, palm_size)
    knuckle_c = palm_c + along * (palm_size[1] * 0.36) + out * (palm_size[2] * 0.10)
    _add_box_bm(bm, knuckle_c, across, along, out, (palm_size[0] * 0.90, palm_size[1] * 0.32, palm_size[2] * 0.62))
    thenar = palm_c - along * (palm_size[1] * 0.08) + across * (palm_size[0] * 0.30) + out * (palm_size[2] * 0.06)
    _add_box_bm(bm, thenar, across, along, out, (palm_size[0] * 0.38, palm_size[1] * 0.48, palm_size[2] * 0.70))
    for path, root, tip in fingers:
        _add_tube_bm(bm, path, _finger_radii(root, tip, len(path)), segs=8, flatten=0.74)
    _add_tube_bm(bm, thumb[0], _finger_radii(thumb[1], thumb[2], len(thumb[0])), segs=8, flatten=0.80)
    cuff = palm_c - along * (palm_size[1] * 0.46) + out * (palm_size[2] * 0.02)
    _add_box_bm(bm, cuff, across, along, out, (palm_size[0] * 0.68, palm_size[1] * 0.26, palm_size[2] * 0.82))
    _add_tube_bm(bm, [cuff, wrist], [0.017, 0.016], segs=8, flatten=0.88)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=0.0008)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(mesh)
    bm.free()
    sub = ob.modifiers.new("Sub", "SUBSURF")
    sub.levels = 1
    sub.render_levels = 1
    apply_mods(ob)
    assign_mat(ob, glove_mat)
    shade_auto(ob)
    return ob


def make_sleeve(name, wrist, elbow, rw, re, material):
    mesh = bpy.data.meshes.new(name)
    ob = bpy.data.objects.new(name, mesh)
    link(ob)
    bm = bmesh.new()
    mid = (Vector(wrist) + Vector(elbow)) * 0.5
    _add_tube_bm(bm, [wrist, mid, elbow], [rw, (rw + re) * 0.55, re], segs=10, flatten=0.90)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(mesh)
    bm.free()
    sub = ob.modifiers.new("Sub", "SUBSURF")
    sub.levels = 1
    sub.render_levels = 1
    apply_mods(ob)
    assign_mat(ob, material)
    shade_auto(ob)
    return ob


def extract_viewmodel_arm(body, side: float) -> bpy.types.Object:
    """Wrist cuff through fingertips. No mid-forearm — FOV 75 does not read that mass."""
    keep = select_by(body, lambda p: p.x * side > 0.505)
    keep = grow_indices(body, keep, 1)
    if len(keep) < 80:
        keep = select_by(body, lambda p: p.x * side > 0.48)
        keep = grow_indices(body, keep, 1)
    if len(keep) < 80:
        raise RuntimeError(f"arm extract too small ({len(keep)}) side={side}")
    ob = duplicate_mesh(body, "RArm" if side > 0 else "LArm")
    keep_only(ob, keep)
    strip_to_plain_mesh(ob)
    bm = bmesh_of(ob)
    boundary = [e for e in bm.edges if e.is_boundary]
    if boundary:
        bmesh.ops.holes_fill(bm, edges=boundary, sides=0)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    xs = [v.co.x for v in bm.verts]
    cut = min(xs) if side > 0 else max(xs)
    cuff = [v for v in bm.verts if abs(v.co.x - cut) < 0.028]
    if cuff:
        for _ in range(4):
            bmesh.ops.smooth_vert(
                bm, verts=cuff, factor=0.55,
                use_axis_x=True, use_axis_y=True, use_axis_z=True,
            )
    commit_bm(bm, ob)
    print(f"EXTRACT {ob.name} verts={len(ob.data.vertices)} tris={tris(ob)}", flush=True)
    return ob


def measure_tpose_hand(ob, side: float) -> dict:
    """Source frame from the extracted hand. across = along × out so index sits toward -Y."""
    pts = [v.co.copy() for v in ob.data.vertices]
    outward = [p.x * side for p in pts]
    lo, hi = min(outward), max(outward)
    wrist_pts = [p for p, s in zip(pts, outward) if s < lo + 0.018]
    tip_pts = [p for p, s in zip(pts, outward) if s > hi - 0.014]
    palm_pts = [p for p, s in zip(pts, outward) if lo + 0.014 < s < hi - 0.028]
    if not palm_pts:
        palm_pts = pts
    wrist = sum(wrist_pts, Vector()) / len(wrist_pts)
    tips = sum(tip_pts, Vector()) / len(tip_pts)
    palm = sum(palm_pts, Vector()) / len(palm_pts)
    along = (tips - wrist).normalized()
    out = Vector((0.0, 0.0, 1.0))
    out = (out - along * out.dot(along)).normalized()
    if out.z < 0.0:
        out = -out
    across = along.cross(out).normalized()
    print(
        f"TPOSE {ob.name} palm={tuple(round(c, 3) for c in palm)} "
        f"along={tuple(round(c, 2) for c in along)} out={tuple(round(c, 2) for c in out)} "
        f"across={tuple(round(c, 2) for c in across)} n={len(pts)}",
        flush=True,
    )
    return {"palm": palm, "wrist": wrist, "along": along, "out": out, "across": across}


def _apply_basis(ob, src: dict, palm_target, across, along, out) -> None:
    src_m = Matrix((src["across"], src["along"], src["out"])).transposed()
    dst_m = Matrix((Vector(across), Vector(along), Vector(out))).transposed()
    rot = dst_m @ src_m.inverted()
    origin = src["palm"]
    target = Vector(palm_target)
    for v in ob.data.vertices:
        v.co = target + rot @ (v.co - origin)
    ob.data.update()


def gun_metal(gun_root) -> bpy.types.Object:
    meshes = [o for o in gun_root.children_recursive if o.type == "MESH"]
    for ob in meshes:
        if "metal" in ob.name.lower():
            return ob
    if not meshes:
        raise RuntimeError("kf16 has no mesh for contact BVH")
    return meshes[0]


def bvh_of(ob) -> BVHTree:
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bm.transform(ob.matrix_world)
    tree = BVHTree.FromBMesh(bm)
    bm.free()
    return tree


def nearest(bvh: BVHTree, point: Vector, sign: float):
    loc, nrm, _idx, dist = bvh.find_nearest(point)
    if loc is None:
        return None, None, 1e9
    nrm = Vector(nrm).normalized()
    sd = (Vector(point) - Vector(loc)).dot(nrm) * sign
    return Vector(loc), nrm * sign, sd


def bvh_sign(bvh: BVHTree) -> float:
    probe = Vector((0.12, 0.0, 0.02))
    loc, nrm, _idx, _d = bvh.find_nearest(probe)
    if loc is None:
        return 1.0
    sd = (probe - Vector(loc)).dot(Vector(nrm).normalized())
    return 1.0 if sd >= 0.0 else -1.0


def palm_pad_verts(ob, palm, along, across, out):
    palm = Vector(palm)
    pad = []
    for v in ob.data.vertices:
        rel = v.co - palm
        if -0.010 <= rel.dot(along) <= 0.028 and -0.022 <= rel.dot(across) <= 0.030 and rel.dot(out) < 0.006:
            pad.append(v.index)
    return pad


def snap_palm(ob, palm, along, across, out, bvh, sign, plane_pt, plane_n, clearance=0.0020) -> Vector:
    """Seat the inner palm on a known gun face. Translate only — no finger motion."""
    plane_pt, plane_n = Vector(plane_pt), Vector(plane_n).normalized()
    pad = palm_pad_verts(ob, palm, along, across, out)
    if len(pad) < 6:
        pad = [
            v.index
            for v in ob.data.vertices
            if abs((v.co - palm).dot(across)) < 0.03 and -0.01 <= (v.co - palm).dot(along) <= 0.04
        ]
    if not pad:
        print("PALM snap skipped — no pad verts", flush=True)
        return Vector(palm)
    delta_total = Vector((0.0, 0.0, 0.0))
    min_sd = 0.0
    mean_plane = 0.0
    for _ in range(5):
        scored = []
        for idx in pad:
            p = ob.data.vertices[idx].co
            scored.append(((p - plane_pt).dot(plane_n), idx))
        scored.sort()
        inner = scored[: max(4, len(scored) * 2 // 5)]
        mean_plane = sum(d for d, _i in inner) / len(inner)
        step = plane_n * (clearance - mean_plane)
        if step.length < 0.00035:
            break
        for v in ob.data.vertices:
            v.co += step
        delta_total += step
        ob.data.update()
    sds = [nearest(bvh, ob.data.vertices[idx].co, sign)[2] for idx in pad]
    min_sd = min(sds) if sds else 0.0
    if min_sd < clearance:
        push = plane_n * (clearance - min_sd)
        for v in ob.data.vertices:
            v.co += push
        delta_total += push
        ob.data.update()
        sds = [nearest(bvh, ob.data.vertices[idx].co, sign)[2] for idx in pad]
        min_sd = min(sds) if sds else 0.0
    print(
        f"PALM snap n={len(pad)} delta={tuple(round(c, 4) for c in delta_total)} "
        f"plane={mean_plane:.4f} min_sd={min_sd:.4f}",
        flush=True,
    )
    return Vector(palm) + delta_total


def digit_groups(ob, palm, along, across):
    """Split extended verts into thumb + four fingers by across. Index is the +across band."""
    palm = Vector(palm)
    along, across = Vector(along), Vector(across)
    fingerish = []
    thumb = []
    for v in ob.data.vertices:
        rel = v.co - palm
        d_along = rel.dot(along)
        d_across = rel.dot(across)
        if d_along < 0.006 and d_across > 0.010:
            thumb.append(v.index)
        elif d_along > 0.018:
            fingerish.append((d_across, v.index))
    fingerish.sort()
    if len(fingerish) < 16:
        return {"thumb": thumb, "pinky": [], "ring": [], "middle": [], "index": []}
    n = len(fingerish)
    def band(a, b):
        return [idx for _s, idx in fingerish[int(a * n) : int(b * n)]]
    return {
        "thumb": thumb,
        "pinky": band(0.00, 0.22),
        "ring": band(0.22, 0.44),
        "middle": band(0.44, 0.68),
        "index": band(0.68, 1.00),
    }


def distal_indices(ob, indices, palm, along, frac=0.45) -> list:
    """Contact tests use fingertips, not the palm-adjacent root that already sits on the gun."""
    palm, along = Vector(palm), Vector(along)
    scored = [((ob.data.vertices[i].co - palm).dot(along), i) for i in indices]
    scored.sort()
    cut = scored[int(len(scored) * (1.0 - frac)) :]
    return [i for _d, i in cut] or list(indices)


def curl_until_contact(ob, indices, pivot, axis, bvh, sign, palm, along, clearance=0.0018, max_ang=1.05, min_ang=0.0, prefer=None, label=""):
    """Hinge one digit from rest until the fingertips kiss the gun, then stop."""
    if len(indices) < 4:
        print(f"CURL {label} skipped n={len(indices)}", flush=True)
        return 0.0
    rest = {i: ob.data.vertices[i].co.copy() for i in indices}
    pivot, axis = Vector(pivot), Vector(axis).normalized()
    tips = distal_indices(ob, indices, palm, along)
    rest_tip = sum((rest[i] for i in tips), Vector()) / len(tips)
    prefer_v = Vector(prefer).normalized() if prefer is not None else None

    def apply(ang):
        rot = Matrix.Rotation(-ang, 3, axis)
        for i, p0 in rest.items():
            ob.data.vertices[i].co = pivot + rot @ (p0 - pivot)
        ob.data.update()

    def min_sd(idxs=None):
        best = 1e9
        for i in (idxs or tips):
            _loc, _n, sd = nearest(bvh, ob.data.vertices[i].co, sign)
            best = min(best, sd)
        return best

    def tip_mean():
        return sum((ob.data.vertices[i].co for i in tips), Vector()) / len(tips)

    apply(0.15)
    sd_pos = min_sd()
    pos_dot = (tip_mean() - rest_tip).dot(prefer_v) if prefer_v is not None else 0.0
    apply(-0.15)
    sd_neg = min_sd()
    neg_dot = (tip_mean() - rest_tip).dot(prefer_v) if prefer_v is not None else 0.0
    apply(0.0)
    sd0 = min_sd()
    if prefer_v is not None:
        rot_sign = 1.0 if pos_dot >= neg_dot else -1.0
    else:
        rot_sign = 1.0 if sd_pos < sd_neg else -1.0
    if sd0 < -0.0008:
        print(f"CURL {label} CLIP at rest sd={sd0:.4f} — not seated", flush=True)
        apply(0.0)
        return 0.0
    if prefer_v is None:
        if min(sd_pos, sd_neg) >= sd0 - 0.0004 and min_ang <= 0.0:
            print(f"CURL {label} ang=0.00 no approaching direction sd={sd0:.4f}", flush=True)
            return 0.0
        if 0.0 <= sd0 <= clearance and min_ang <= 0.0:
            print(f"CURL {label} ang=0.00 already seated sd={sd0:.4f}", flush=True)
            return 0.0
    lo, hi = 0.0, max_ang
    best_ang = 0.0
    for _ in range(14):
        mid = (lo + hi) * 0.5
        apply(rot_sign * mid)
        sd = min_sd()
        if sd < clearance:
            hi = mid
        else:
            best_ang = mid
            lo = mid
    best_ang = max(best_ang, min_ang)
    apply(rot_sign * best_ang)
    sd_f = min_sd()
    if sd_f > sd0 - 0.001:
        apply(0.0)
        print(f"CURL {label} revert sd0={sd0:.4f} sdf={sd_f:.4f}", flush=True)
        return 0.0
    print(f"CURL {label} ang={rot_sign * best_ang:.3f} sd={sd_f:.4f} n_tip={len(tips)}", flush=True)
    return rot_sign * best_ang


def _rotate_verts(ob, idxs, pivot, axis, ang) -> None:
    pivot, axis = Vector(pivot), Vector(axis).normalized()
    rot = Matrix.Rotation(ang, 3, axis)
    for i in idxs:
        ob.data.vertices[i].co = pivot + rot @ (ob.data.vertices[i].co - pivot)
    ob.data.update()


def _tip_index(ob, idxs, palm, along):
    palm, along = Vector(palm), Vector(along)
    return max(idxs, key=lambda i: (ob.data.vertices[i].co - palm).dot(along))


def pose_digit_to_target(ob, idxs, pivot, target, label, t=0.90):
    """Authored digit: short-arc rotate onto an explicit hold point. No clip back-off."""
    if len(idxs) < 4:
        print(f"{label} skipped", flush=True)
        return
    pivot, target = Vector(pivot), Vector(target)
    tip_i = max(idxs, key=lambda i: (ob.data.vertices[i].co - pivot).length)
    a = ob.data.vertices[tip_i].co - pivot
    b = target - pivot
    if a.length < 1e-6 or b.length < 1e-6:
        return
    q = a.rotation_difference(b)
    rot = Matrix.Rotation(q.angle * t, 3, q.axis)
    for i in idxs:
        ob.data.vertices[i].co = pivot + rot @ (ob.data.vertices[i].co - pivot)
    ob.data.update()
    tip = ob.data.vertices[tip_i].co
    print(
        f"{label} t={t:.2f} tip={tuple(round(c, 3) for c in tip)} "
        f"dist={(tip - target).length:.4f}",
        flush=True,
    )


def web_indices(ob, palm, along, across, out):
    """Thumb web / thenar pad — the region that was burying into the receiver."""
    palm = Vector(palm)
    along, across, out = Vector(along), Vector(across), Vector(out)
    web = []
    for v in ob.data.vertices:
        rel = v.co - palm
        if -0.030 <= rel.dot(along) <= -0.002 and 0.002 <= rel.dot(across) <= 0.028 and rel.dot(out) < 0.010:
            web.append(v.index)
    return web


def push_hand_clearance(ob, idxs, bvh, sign, direction, min_clear=0.0022, max_push=0.008, label=""):
    """Whole-hand translate along `direction` until listed verts clear. Bias clearance over penetration."""
    if not idxs:
        return
    direction = Vector(direction).normalized()
    pushed = 0.0
    for _ in range(8):
        sds = [nearest(bvh, ob.data.vertices[i].co, sign)[2] for i in idxs]
        mn = min(sds)
        if mn >= min_clear:
            break
        step = min(min_clear - mn, 0.0020)
        if step <= 0.0 or pushed + step > max_push:
            break
        for v in ob.data.vertices:
            v.co += direction * step
        pushed += step
        ob.data.update()
    sds = [nearest(bvh, ob.data.vertices[i].co, sign)[2] for i in idxs]
    mn = min(sds) if sds else 0.0
    print(f"CLEAR {label} push={pushed:.4f} min_sd={mn:.4f} n={len(idxs)}", flush=True)


def pose_support_cuff(ob, palm, along, across):
    """Pull the extract cuff toward the camera. Translate, do not spin — rotation collapsed the cuff."""
    del across
    palm = Vector(palm)
    along = Vector(along).normalized()
    cuff = [v.index for v in ob.data.vertices if (v.co - palm).dot(along) < -0.008]
    if len(cuff) < 8:
        print("CUFF skipped", flush=True)
        return
    toward_cam = Vector((0.0, -0.040, 0.008))
    for i in cuff:
        w = min(1.0, abs((ob.data.vertices[i].co - palm).dot(along)) / 0.045)
        ob.data.vertices[i].co += toward_cam * w
    ob.data.update()
    print(f"CUFF n={len(cuff)} toward_cam", flush=True)


def authored_hinge(ob, idxs, pivot, axis, want, amount, label):
    """Hinge around a fixed axis. Sign is the one that moves the tip toward `want`."""
    if len(idxs) < 4:
        print(f"{label} skipped", flush=True)
        return
    pivot, axis, want = Vector(pivot), Vector(axis).normalized(), Vector(want)
    tip_i = max(idxs, key=lambda i: (ob.data.vertices[i].co - pivot).length)
    _rotate_verts(ob, idxs, pivot, axis, 0.12)
    d_pos = (ob.data.vertices[tip_i].co - want).length
    _rotate_verts(ob, idxs, pivot, axis, -0.24)
    d_neg = (ob.data.vertices[tip_i].co - want).length
    _rotate_verts(ob, idxs, pivot, axis, 0.12)
    sgn = 1.0 if d_pos < d_neg else -1.0
    _rotate_verts(ob, idxs, pivot, axis, sgn * amount)
    tip = ob.data.vertices[tip_i].co
    print(
        f"{label} ang={sgn * amount:.2f} tip={tuple(round(c, 3) for c in tip)} "
        f"dist={(tip - want).length:.4f}",
        flush=True,
    )


def pose_index_two_segment(ob, idxs, palm, along, across, out, bvh, sign):
    """Trigger index: two-segment path into the winter well. Slight +X clearance, not outboard of the wall."""
    del bvh, sign, out
    if len(idxs) < 6:
        print("INDEX skipped", flush=True)
        return
    palm = Vector(palm)
    along, across = Vector(along), Vector(across)
    kn = palm + along * 0.008 + across * 0.020
    waypoint = Vector((0.012, 0.032, -0.034))
    trigger = Vector((0.006, 0.028, -0.026))
    tip_i = _tip_index(ob, idxs, palm, along)
    pose_digit_to_target(ob, idxs, kn, waypoint, "INDEX-swing", t=0.90)
    scored = sorted(idxs, key=lambda i: (ob.data.vertices[i].co - ob.data.vertices[tip_i].co).length)
    dist = scored[: max(4, len(scored) // 2)]
    prox = [i for i in idxs if i not in set(dist)] or idxs
    mid_i = min(prox, key=lambda i: (ob.data.vertices[i].co - ob.data.vertices[tip_i].co).length)
    mid = ob.data.vertices[mid_i].co.copy()
    pose_digit_to_target(ob, dist, mid, trigger, "INDEX-in", t=0.70)
    for i in idxs:
        ob.data.vertices[i].co.x += 0.002
    ob.data.update()
    tip = ob.data.vertices[tip_i].co
    opening = abs(tip.x) < 0.022 and -0.012 < tip.y < 0.032 and -0.052 < tip.z < -0.010
    print(
        f"INDEX final tip={tuple(round(c, 3) for c in tip)} "
        f"to_lip={(tip - trigger).length:.4f} at_opening={opening}",
        flush=True,
    )


def pose_contact_hand(
    ob, side, palm_c, across, along, out, bvh, sign, glove_mat, plane_pt, plane_n, *,
    trigger=False, thumb_target=None, wrap_max_ang=1.05, wrap_min_ang=0.0, wrap_clearance=0.0018,
    wrap_prefer=None, palm_clearance=0.0020,
) -> bpy.types.Object:
    src = measure_tpose_hand(ob, side)
    _apply_basis(ob, src, palm_c, across, along, out)
    palm = snap_palm(ob, palm_c, along, across, out, bvh, sign, plane_pt, plane_n, clearance=palm_clearance)
    groups = digit_groups(ob, palm, along, across)
    knuckle = palm + Vector(along) * 0.016
    wrap = ("pinky", "ring", "middle") if trigger else ("pinky", "ring", "middle", "index")
    for name in wrap:
        idxs = groups.get(name, [])
        if not idxs:
            continue
        acc = Vector()
        for i in idxs:
            acc += ob.data.vertices[i].co
        band_c = acc / len(idxs)
        pivot = knuckle + Vector(across) * max(-0.03, min(0.03, (band_c - palm).dot(across)))
        curl_until_contact(
            ob, idxs, pivot, across, bvh, sign, palm, along,
            clearance=wrap_clearance, max_ang=wrap_max_ang,
            min_ang=wrap_min_ang if name == "index" else 0.0,
            prefer=wrap_prefer,
            label=f"{ob.name}-{name}",
        )
    if trigger:
        idx = groups.get("index", [])
        idx = [i for i in idx if (ob.data.vertices[i].co - palm).dot(along) > 0.024]
        pose_index_two_segment(ob, idx, palm, along, across, out, bvh, sign)
    else:
        for name in wrap:
            for i in groups.get(name, []):
                ob.data.vertices[i].co += Vector(plane_n) * 0.006
        ob.data.update()
        pose_support_cuff(ob, palm, along, across)
    thumb = groups.get("thumb", [])
    if trigger and thumb:
        # Distal thumb only, rest along the grip's right/front — do not drag the web through the receiver.
        t_pivot = palm + Vector(across) * 0.008 - Vector(along) * 0.006 + Vector(out) * 0.004
        distal = distal_indices(ob, thumb, palm, across, frac=0.50)
        pose_digit_to_target(ob, distal, t_pivot, Vector((0.018, 0.006, -0.040)), f"{ob.name}-thumb", t=0.70)
        web = web_indices(ob, palm, along, across, out)
        push_hand_clearance(ob, web or thumb, bvh, sign, plane_n, min_clear=0.0024, max_push=0.007, label=f"{ob.name}-web")
    assign_mat(ob, glove_mat)
    shade_auto(ob)
    return ob


def posed_trigger_hand(glove_mat, body, bvh, sign) -> list:
    """Right hm08 hand. Palm on the grip side with clearance; index into the winter well; distal thumb."""
    across, along, out = _hand_axes(
        (0.94, -0.34, -0.08),
        (0.06, 0.02, -0.99),
        (0.0, 1.0, 0.15),
    )
    plane_pt = Vector((0.020, -0.006, -0.070))
    plane_n = Vector((1.0, 0.0, 0.0))
    palm_c = plane_pt + out * 0.024
    hand = extract_viewmodel_arm(body, 1.0)
    pose_contact_hand(
        hand, 1.0, palm_c, across, along, out, bvh, sign, glove_mat, plane_pt, plane_n,
        trigger=True, palm_clearance=0.0038,
    )
    hand.name = "RHand"
    return [hand]


def posed_support_hand(glove_mat, body, bvh, sign) -> list:
    """Left hm08 hand. Palm on the LEFT FACE; light C-curl over the top; cuff toward camera."""
    across, along, out = _hand_axes(
        (-0.72, -0.58, 0.38),
        (0.10, 0.30, 0.95),
        (0.0, 1.0, 0.10),
    )
    plane_pt = Vector((-0.016, 0.218, 0.012))
    plane_n = Vector((-1.0, 0.0, 0.0))
    palm_c = plane_pt + out * 0.024
    hand = extract_viewmodel_arm(body, -1.0)
    pose_contact_hand(
        hand, -1.0, palm_c, across, along, out, bvh, sign, glove_mat, plane_pt, plane_n,
        trigger=False,
        wrap_max_ang=0.28, wrap_min_ang=0.08, wrap_clearance=0.0050,
        wrap_prefer=(1.0, 0.0, 0.25), palm_clearance=0.0085,
    )
    hand.name = "LHand"
    return [hand]


def build_fps_arms(glove_mat, sleeve_mat, gun_root, body) -> tuple[bpy.types.Object, dict]:
    """hm08 hands, short extract, palm-lock then contact curl, weapon-local."""
    del sleeve_mat
    gun_root.location = (0.0, 0.0, 0.0)
    bpy.context.view_layer.update()
    metal = gun_metal(gun_root)
    bvh = bvh_of(metal)
    sign = bvh_sign(bvh)
    print(f"GUN BVH sign={sign:.0f}", flush=True)
    parts = posed_trigger_hand(glove_mat, body, bvh, sign) + posed_support_hand(glove_mat, body, bvh, sign)
    joined = join_objects("ff_fps_arms", parts)
    active(joined)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    shade_auto(joined)
    t, v = count_tree(joined)
    print(f"FPS ARMS tris={t} verts={v} budget<=6000 {'OK' if t <= 6000 else 'OVER'}", flush=True)
    return joined, {
        "tris": t,
        "verts": v,
        "space": "weapon-local",
        "hands": "hm08 short extract — palm snap, wrap curl, authored index/thumb",
        "budget_ok": t <= 6000,
    }


def render_fps(out_dir, name, subjects, wire=False) -> None:
    """Gameplay camera: origin, 75° FOV, looking Godot -Z / Blender +Y."""
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 1200
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.show_shadows = True
    scene.display.shading.show_cavity = True
    world = bpy.data.worlds.get("W") or bpy.data.worlds.new("W")
    scene.world = world
    world.color = (0.10, 0.11, 0.12)
    cam = bpy.data.cameras.new("C_" + name)
    cam.lens_unit = "FOV"
    cam.angle = math.radians(GODOT_FOV)
    cob = bpy.data.objects.new("C_" + name, cam)
    cob.location = (0.0, 0.0, 0.0)
    cob.rotation_euler = (math.pi / 2.0, 0.0, 0.0)  # look +Y
    link(cob)
    scene.camera = cob
    st = hide_for_render(subjects)
    if wire:
        for o in bpy.context.scene.objects:
            if o.type == "MESH" and not o.hide_render:
                o.display_type = "WIRE"
        scene.display.shading.light = "FLAT"
        scene.display.shading.color_type = "SINGLE"
        scene.display.shading.show_cavity = False
    os.makedirs(out_dir, exist_ok=True)
    scene.render.filepath = os.path.join(out_dir, name)
    bpy.ops.render.render(write_still=True)
    if wire:
        for o in bpy.context.scene.objects:
            if o.type == "MESH":
                o.display_type = "TEXTURED"
    restore_hide(st)
    bpy.data.objects.remove(cob, do_unlink=True)
    bpy.data.cameras.remove(cam)


def save_blend(path) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=path)


def build_assault(svc, out_glb, render_dir, src_dir) -> dict:
    clear_scene()
    body, src = create_shaped_human(
        svc,
        "AssaultBody",
        {
            "gender": 1.0,
            "age": 0.52,
            "muscle": 0.78,
            "weight": 0.62,
            "height": 0.56,
            "proportions": 0.58,
            "cupsize": 0.35,
            "firmness": 0.45,
            "race": {"african": 0.25, "asian": 0.15, "caucasian": 0.60},
        },
    )
    mats = {
        "fabric": clay("a_fabric", (0.42, 0.40, 0.36), 0.04, 0.78),
        "armor": clay("a_armor", (0.34, 0.33, 0.30), 0.22, 0.48),
        "visor": clay("a_visor", (0.12, 0.13, 0.14), 0.72, 0.16),
        "glove": clay("a_glove", (0.22, 0.20, 0.18), 0.06, 0.70),
    }
    assign_mat(body, mats["fabric"])
    parts, hid = kit_assault(body, mats)
    joined = join_objects("ff_op_assault", parts)
    t, v = count_tree(joined)
    export_glb(out_glb, [joined])
    render_previews(render_dir, "assault_front.png", (0.0, -3.2, 0.95), (0.0, 0.0, 0.90), [joined], lens=55)
    render_previews(render_dir, "assault_34.png", (2.1, -2.6, 1.05), (0.0, 0.0, 0.90), [joined], lens=50)
    render_previews(render_dir, "assault_back.png", (0.0, 3.2, 0.95), (0.0, 0.0, 0.90), [joined], lens=55)
    render_previews(render_dir, "assault_close.png", (0.25, -0.95, 1.55), (0.0, 0.02, 1.50), [joined], lens=70)
    render_previews(render_dir, "assault_kit.png", (0.35, -0.80, 1.22), (0.0, 0.04, 1.18), [joined], lens=65)
    render_previews(render_dir, "assault_wire.png", (2.1, -2.6, 1.05), (0.0, 0.0, 0.90), [joined], wire=True, lens=50)
    render_one_silhouette(render_dir, "assault_sil.png", joined)
    save_blend(os.path.join(src_dir, "assault.blend"))
    return {
        "asset": "ff_op_assault",
        "tris": t,
        "verts": v,
        "source_body_tris": src["source_tris"],
        "source_body_verts": src["source_verts"],
        "height_m": src["height"],
        "hidden": hid,
        "materials": 4,
        "textures": "none — Gate A clay",
        "rig": "deferred",
    }


def build_phantom(svc, out_glb, render_dir, src_dir) -> dict:
    clear_scene()
    body, src = create_shaped_human(
        svc,
        "PhantomBody",
        {
            "gender": 1.0,
            "age": 0.48,
            "muscle": 0.58,
            "weight": 0.32,
            "height": 0.54,
            "proportions": 0.42,
            "cupsize": 0.30,
            "firmness": 0.40,
            "race": {"african": 0.20, "asian": 0.25, "caucasian": 0.55},
        },
    )
    mats = {
        "fabric": clay("p_fabric", (0.22, 0.24, 0.26), 0.05, 0.76),
        "armor": clay("p_armor", (0.16, 0.18, 0.20), 0.28, 0.40),
        "visor": clay("p_visor", (0.08, 0.14, 0.16), 0.78, 0.12, (0.04, 0.10, 0.12)),
        "glove": clay("p_glove", (0.12, 0.13, 0.14), 0.08, 0.68),
    }
    assign_mat(body, mats["fabric"])
    parts, hid = kit_phantom(body, mats)
    joined = join_objects("ff_sb_phantom", parts)
    t, v = count_tree(joined)
    print_mesh_bounds(joined, "phantom")
    print("KIT", hid, flush=True)
    export_glb(out_glb, [joined])
    render_previews(render_dir, "phantom_front.png", (0.0, -3.0, 0.90), (0.0, 0.0, 0.85), [joined], lens=55)
    render_previews(render_dir, "phantom_34.png", (2.0, -2.4, 1.00), (0.0, 0.0, 0.85), [joined], lens=50)
    render_previews(render_dir, "phantom_back.png", (0.0, 3.0, 0.90), (0.0, 0.0, 0.85), [joined], lens=55)
    render_previews(render_dir, "phantom_close.png", (0.22, -0.90, 1.48), (0.0, 0.02, 1.44), [joined], lens=70)
    render_previews(render_dir, "phantom_kit.png", (0.32, -0.75, 1.12), (0.0, 0.04, 1.08), [joined], lens=65)
    render_previews(render_dir, "phantom_wire.png", (2.0, -2.4, 1.00), (0.0, 0.0, 0.85), [joined], wire=True, lens=50)
    render_one_silhouette(render_dir, "phantom_sil.png", joined)
    save_blend(os.path.join(src_dir, "phantom.blend"))
    return {
        "asset": "ff_sb_phantom",
        "tris": t,
        "verts": v,
        "source_body_tris": src["source_tris"],
        "source_body_verts": src["source_verts"],
        "height_m": src["height"],
        "hidden": hid,
        "materials": 4,
        "textures": "none — Gate A clay",
        "rig": "deferred",
    }


def build_kf16(out_glb, render_dir, src_dir) -> dict:
    clear_scene()
    metal = clay("k_metal", (0.28, 0.29, 0.30), 0.78, 0.32)
    poly = clay("k_poly", (0.10, 0.10, 0.11), 0.06, 0.64)
    root, info = kf16_build(metal, poly)
    export_glb(out_glb, [root])
    look = (0.0, 0.16, 0.02)
    render_previews(render_dir, "kf16_left.png", (-0.62, 0.16, 0.14), look, [root], lens=55)
    render_previews(render_dir, "kf16_right.png", (0.62, 0.16, 0.14), look, [root], lens=55)
    render_previews(render_dir, "kf16_hero.png", (0.42, -0.22, 0.22), look, [root], lens=50)
    render_previews(render_dir, "kf16_close.png", (0.14, 0.00, 0.08), (0.0, 0.02, 0.02), [root], lens=70)
    render_previews(render_dir, "kf16_well.png", (0.14, 0.028, -0.012), (0.0, 0.024, -0.032), [root], lens=55)
    render_previews(render_dir, "kf16_wire.png", (0.42, -0.22, 0.22), look, [root], wire=True, lens=50)
    save_blend(os.path.join(src_dir, "kf16.blend"))
    return {
        "asset": "ff_wpn_kf16",
        "tris": info["tris"],
        "verts": info["verts"],
        "materials": 2,
        "textures": "none — Gate A clay",
        "rig": ", ".join(info["nodes"]),
    }


def build_arms(svc, out_glb, render_dir, src_dir) -> dict:
    clear_scene()
    body, _src = create_shaped_human(
        svc,
        "FpsDonor",
        {
            "gender": 1.0,
            "age": 0.52,
            "muscle": 0.78,
            "weight": 0.58,
            "height": 0.56,
            "proportions": 0.58,
            "cupsize": 0.35,
            "firmness": 0.45,
            "race": {"african": 0.25, "asian": 0.15, "caucasian": 0.60},
        },
    )
    glove = clay("fps_glove", (0.72, 0.50, 0.28), 0.04, 0.70)
    sleeve = clay("fps_sleeve", (0.22, 0.26, 0.22), 0.05, 0.74)
    metal = clay("k_metal_fps", (0.28, 0.29, 0.30), 0.78, 0.32)
    poly = clay("k_poly_fps", (0.10, 0.10, 0.11), 0.06, 0.64)
    gun, _ginfo = kf16_build(metal, poly)
    arms, info = build_fps_arms(glove, sleeve, gun, body)
    if body.name in bpy.data.objects:
        bpy.data.objects.remove(body, do_unlink=True)
    export_glb(out_glb, [arms])
    active(arms)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    arms.parent = gun
    arms.location = (0.0, 0.0, 0.0)
    hip = godot_to_blender(GODOT_HIP)
    ads = godot_to_blender(GODOT_ADS)
    gun.location = hip
    bpy.context.view_layer.update()
    render_fps(render_dir, "arms_clay.png", [arms, gun])
    render_fps(render_dir, "arms_hip.png", [arms, gun])
    render_fps(render_dir, "arms_wire.png", [arms, gun], wire=True)
    render_fps(render_dir, "arms_intersect.png", [arms, gun])
    gun.location = ads
    bpy.context.view_layer.update()
    render_fps(render_dir, "arms_ads.png", [arms, gun])
    gun.location = (0.0, 0.0, 0.0)
    bpy.context.view_layer.update()
    render_previews(render_dir, "arms_trigger.png", (0.16, 0.05, 0.04), (0.02, 0.002, -0.040), [arms, gun], lens=42)
    render_previews(render_dir, "arms_support.png", (-0.16, 0.12, 0.11), (0.00, 0.218, 0.032), [arms, gun], lens=42)
    render_previews(render_dir, "arms_hands_wire.png", (0.24, -0.14, 0.18), (0.00, 0.08, -0.01), [arms, gun], wire=True, lens=38)
    save_blend(os.path.join(src_dir, "fps_arms.blend"))
    return {
        "asset": "ff_fps_arms",
        "tris": info["tris"],
        "verts": info["verts"],
        "materials": 2,
        "textures": "none — Gate A2 clay",
        "rig": "deferred — dedicated FPS viewmodel, weapon-local, parented to KF-16",
        "space": "weapon-local",
        "hands": info["hands"],
        "source": "hm08 short extract, palm snap, contact curl",
        "budget_ok": info.get("budget_ok"),
        "gameplay_hip": list(GODOT_HIP),
        "gameplay_ads": list(GODOT_ADS),
        "gameplay_fov": GODOT_FOV,
    }


def render_one_silhouette(render_dir, name, subject) -> None:
    sil = clay("sil_one", (0.02, 0.02, 0.02), 0.0, 1.0)
    old = []
    for o in [subject] + list(subject.children_recursive):
        if o.type == "MESH" and o.data.materials:
            old.append((o, list(o.data.materials)))
            assign_mat(o, sil)
    m = metrics(subject) if subject.type == "MESH" else {"h": 1.8, "cz": 0.9}
    look_z = m.get("cz", 0.90)
    render_previews(render_dir, name, (0.0, -3.4, look_z), (0.0, 0.0, look_z), [subject], lens=50)
    for o, mats in old:
        o.data.materials.clear()
        for mat in mats:
            o.data.materials.append(mat)


def render_silhouette(assault_glb, phantom_glb, render_dir) -> None:
    """Load both exported GLBs into a fresh scene for a same-scale silhouette plate."""
    clear_scene()
    bpy.ops.import_scene.gltf(filepath=assault_glb)
    a = bpy.context.selected_objects[0] if bpy.context.selected_objects else bpy.context.view_layer.objects.active
    bpy.ops.import_scene.gltf(filepath=phantom_glb)
    # After second import, move phantom.
    phantoms = [o for o in bpy.context.scene.objects if o.type in {"MESH", "EMPTY"} and o != a and o.parent is None]
    p = phantoms[-1] if phantoms else None
    if a:
        a.location = Vector((-0.7, 0.0, 0.0))
    if p:
        p.location = Vector((0.7, 0.0, 0.0))
    sil = clay("sil", (0.02, 0.02, 0.02), 0.0, 1.0)
    for o in bpy.context.scene.objects:
        if o.type == "MESH":
            assign_mat(o, sil)
    subjects = [o for o in bpy.context.scene.objects if o.parent is None]
    render_previews(render_dir, "silhouette_compare.png", (0.0, -4.2, 0.95), (0.0, 0.0, 0.85), subjects, lens=45)


def _aim_cam(name, loc, look, *, lens=None, fov=None):
    cam = bpy.data.cameras.new(name)
    if fov is not None:
        cam.lens_unit = "FOV"
        cam.angle = math.radians(fov)
    else:
        cam.lens = lens if lens is not None else 50
    ob = bpy.data.objects.new(name, cam)
    ob.location = loc
    direction = Vector(look) - Vector(loc)
    if direction.length > 1e-6:
        ob.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    link(ob)
    return ob


def build_grip_handoff(svc, root: str) -> dict:
    """Gun at current receiving geo + unposed hm08 extracts + evidence cameras.

    Scripted posing stops here. A human poses in the viewport; bake/export is a later pass.
    """
    out_dir = os.path.join(root, "game", "assets", "v02", "handoff")
    blend_dir = os.path.join(root, "art", "v02", "handoff")
    prev = os.path.join(blend_dir, "preview")
    os.makedirs(out_dir, exist_ok=True)
    os.makedirs(prev, exist_ok=True)
    clear_scene()
    body, _src = create_shaped_human(
        svc,
        "FpsDonor",
        {
            "gender": 1.0,
            "age": 0.52,
            "muscle": 0.78,
            "weight": 0.58,
            "height": 0.56,
            "proportions": 0.58,
            "cupsize": 0.35,
            "firmness": 0.45,
            "race": {"african": 0.25, "asian": 0.15, "caucasian": 0.60},
        },
    )
    glove = clay("fps_glove", (0.72, 0.50, 0.28), 0.04, 0.70)
    metal = clay("k_metal_fps", (0.28, 0.29, 0.30), 0.78, 0.32)
    poly = clay("k_poly_fps", (0.10, 0.10, 0.11), 0.06, 0.64)
    gun, ginfo = kf16_build(metal, poly)

    def park(side, out, along_hint, index_fwd, plane_pt, name):
        across, along, out_v = _hand_axes(out, along_hint, index_fwd)
        palm = Vector(plane_pt) + out_v * 0.024
        hand = extract_viewmodel_arm(body, side)
        src = measure_tpose_hand(hand, side)
        _apply_basis(hand, src, palm, across, along, out_v)
        assign_mat(hand, glove)
        shade_auto(hand)
        hand.name = name
        return hand

    rhand = park(1.0, (0.94, -0.34, -0.08), (0.06, 0.02, -0.99), (0.0, 1.0, 0.15), (0.020, -0.006, -0.070), "RHand")
    lhand = park(-1.0, (-0.72, -0.58, 0.38), (0.10, 0.30, 0.95), (0.0, 1.0, 0.10), (-0.016, 0.218, 0.012), "LHand")
    if body.name in bpy.data.objects:
        bpy.data.objects.remove(body, do_unlink=True)
    rhand.parent = gun
    lhand.parent = gun

    hip = _aim_cam("cam_hip", (0.0, 0.0, 0.0), (0.0, 1.0, 0.0), fov=GODOT_FOV)
    hip.rotation_euler = (math.pi / 2.0, 0.0, 0.0)
    ads_off = godot_to_blender(GODOT_ADS)
    _aim_cam("cam_ads", (-ads_off.x, -ads_off.y, -ads_off.z), (0.0, 0.08, 0.02), fov=GODOT_FOV)
    _aim_cam("cam_trigger", (0.16, 0.05, 0.04), (0.02, 0.002, -0.040), lens=42)
    _aim_cam("cam_support", (-0.16, 0.12, 0.11), (0.00, 0.218, 0.032), lens=42)

    export_glb(os.path.join(out_dir, "grip_unposed.glb"), [gun, rhand, lhand])
    gun.location = godot_to_blender(GODOT_HIP)
    bpy.context.view_layer.update()
    render_fps(prev, "handoff_hip.png", [rhand, lhand, gun])
    render_previews(prev, "handoff_trigger.png", (0.16, 0.05, 0.04), (0.02, 0.002, -0.040), [rhand, lhand, gun], lens=42)
    render_previews(prev, "handoff_support.png", (-0.16, 0.12, 0.11), (0.00, 0.218, 0.032), [rhand, lhand, gun], lens=42)
    gun.location = godot_to_blender(GODOT_ADS)
    bpy.context.view_layer.update()
    render_fps(prev, "handoff_ads.png", [rhand, lhand, gun])
    gun.location = (0.0, 0.0, 0.0)
    save_blend(os.path.join(blend_dir, "grip_pose.blend"))
    print(f"HANDOFF blend={blend_dir}/grip_pose.blend glb={out_dir}/grip_unposed.glb", flush=True)
    return {"kf16_tris": ginfo["tris"], "nodes": ginfo["nodes"]}


def main() -> None:
    root = parse_root()
    glb_dir = os.path.join(root, "game", "assets", "v02")
    art = os.path.join(root, "art", "v02")
    renders = os.path.join(art, "renders")
    src = os.path.join(art, "src")
    os.makedirs(glb_dir, exist_ok=True)
    os.makedirs(renders, exist_ok=True)
    os.makedirs(src, exist_ok=True)

    args = argv_after_dash()
    only = args[args.index("--only") + 1] if "--only" in args else "all"
    if only == "grip":
        only = "arms"
    need_human = only in {"all", "assault", "phantom", "arms", "handoff"}
    svc = mpfb_services() if need_human else None
    clear_scene()
    if need_human:
        if "--skip-gender" in args:
            print("skip gender probe; using male=1.0", flush=True)
        else:
            print("using male gender value", verify_gender_polarity(svc), flush=True)

    if only == "handoff":
        print("BUILD grip handoff (unposed extracts)", flush=True)
        build_grip_handoff(svc, root)
        print("done", os.path.join(root, "game", "assets", "v02", "handoff"), flush=True)
        return

    stats = []

    def record(rec, glb_name, generation):
        rec["glb_bytes"] = os.path.getsize(os.path.join(glb_dir, glb_name))
        rec["generation"] = generation
        rec["date"] = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        stats.append(rec)
        print(" ", rec, flush=True)

    if only in {"all", "assault"}:
        print("BUILD ff_op_assault", flush=True)
        record(
            build_assault(svc, os.path.join(glb_dir, "ff_op_assault.glb"), renders, src),
            "ff_op_assault.glb",
            "Gate A2 clay: MPFB2 v2.0.17 hm08, wearable kit, no textures, no rig",
        )
    if only in {"all", "phantom"}:
        print("BUILD ff_sb_phantom", flush=True)
        record(
            build_phantom(svc, os.path.join(glb_dir, "ff_sb_phantom.glb"), renders, src),
            "ff_sb_phantom.glb",
            "Gate A2 clay: MPFB2 v2.0.17 hm08, leaner macros, wearable harness/pack",
        )
    if only in {"all", "kf16", "arms"}:
        print("BUILD ff_wpn_kf16", flush=True)
        record(
            build_kf16(os.path.join(glb_dir, "ff_wpn_kf16.glb"), renders, src),
            "ff_wpn_kf16.glb",
            "Gate A2 clay: KF-16 winter trigger well + support-corner relief (receiving geo)",
        )
    if only in {"all", "arms"}:
        print("BUILD ff_fps_arms", flush=True)
        record(
            build_arms(svc, os.path.join(glb_dir, "ff_fps_arms.glb"), renders, src),
            "ff_fps_arms.glb",
            "Gate A2 clay: hm08 short-extract FPS hands, palm snap + contact curl",
        )
    if only in {"all", "assault", "phantom"}:
        render_silhouette(os.path.join(glb_dir, "ff_op_assault.glb"), os.path.join(glb_dir, "ff_sb_phantom.glb"), renders)

    if only != "all":
        print("partial build; generation_stats.json not rewritten", flush=True)
        print("done", glb_dir, flush=True)
        return

    payload = {
        "gate": "A2",
        "base": "MakeHuman hm08 via MPFB2 v2.0.17",
        "license": "CC0 1.0 graphical assets; MPFB GPL-3.0 code not shipped",
        "assets": stats,
        "hidden_geo_strategy": (
            "hm08 is the source mesh. Helpers are baked and stripped before kit. Kit is closed "
            "grids/volumes shrinkwrapped onto an armless wrap cage so T-pose arms cannot spike plates. "
            "Gate A2 keeps the full body for form review (no hidden-torso collapse yet). After approval, "
            "collapse covered torso under armor; keep face, neck, hands, feet, shoulders, elbows, knees. "
            "FPS arms are a separate viewmodel (weapon-local), not the 3P body."
        ),
        "runtime_note": "Triangle budget is the complete visible character, not source hm08 plus stacked kit.",
    }
    with open(os.path.join(glb_dir, "generation_stats.json"), "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)
    print("done", glb_dir, flush=True)


if __name__ == "__main__":
    main()
