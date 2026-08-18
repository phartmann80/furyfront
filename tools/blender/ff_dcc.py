#!/usr/bin/env python3
"""Fury Front V0.2 DCC refine — Blender 4.5 bpy.

Metaball human volumes, shrinkwrapped armor, boolean KF-16.
No Meshy. No production deploy. Rigging deferred until forms are keepable.

  blender --background --python tools/blender/ff_dcc.py -- --root <repo>
"""
from __future__ import annotations

import json
import math
import os
import random
import sys
from datetime import datetime, timezone

import bpy
import bmesh
from mathutils import Euler, Vector

TEX = 256


def argv_after_dash() -> list[str]:
    if "--" in sys.argv:
        return sys.argv[sys.argv.index("--") + 1 :]
    return []


def parse_root() -> str:
    args = argv_after_dash()
    if "--root" in args:
        return args[args.index("--root") + 1]
    return os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


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
    for p in obj.data.polygons:
        p.use_smooth = True


def add_bevel(obj, width=0.0024, segments=3, angle=0.45) -> None:
    m = obj.modifiers.new("Bevel", "BEVEL")
    m.width = width
    m.segments = segments
    m.limit_method = "ANGLE"
    m.angle_limit = angle
    m.harden_normals = True
    m.miter_outer = "MITER_ARC"


def add_weighted_normals(obj) -> None:
    m = obj.modifiers.new("WN", "WEIGHTED_NORMAL")
    m.keep_sharp = True
    m.mode = "FACE_AREA_WITH_ANGLE"
    m.weight = 50


def noise_image(name, rgb, size=TEX, amp=0.10) -> bpy.types.Image:
    if name in bpy.data.images:
        return bpy.data.images[name]
    img = bpy.data.images.new(name, size, size, alpha=False)
    rng = random.Random(hash(name) & 0xFFFFFFFF)
    px = [0.0] * (size * size * 4)
    for i in range(size * size):
        n = 1.0 + (rng.random() - 0.5) * amp
        px[i * 4 + 0] = max(0.0, min(1.0, rgb[0] * n))
        px[i * 4 + 1] = max(0.0, min(1.0, rgb[1] * n))
        px[i * 4 + 2] = max(0.0, min(1.0, rgb[2] * n))
        px[i * 4 + 3] = 1.0
    img.pixels = px
    img.pack()
    return img


def mat(name, color, metallic, roughness, emission=None, tex=True):
    if name in bpy.data.materials:
        return bpy.data.materials[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    principled = nt.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = (*color, 1.0)
    principled.inputs["Metallic"].default_value = metallic
    principled.inputs["Roughness"].default_value = roughness
    if emission:
        if "Emission Color" in principled.inputs:
            principled.inputs["Emission Color"].default_value = (*emission, 1.0)
            principled.inputs["Emission Strength"].default_value = 0.28
    if tex:
        img = noise_image(name + "_alb", color)
        texn = nt.nodes.new("ShaderNodeTexImage")
        texn.image = img
        texn.location = (-280, 200)
        nt.links.new(texn.outputs["Color"], principled.inputs["Base Color"])
    return m


def assign_mat(obj, material) -> None:
    obj.data.materials.clear()
    obj.data.materials.append(material)


def tris(obj) -> int:
    mesh = obj.data
    mesh.calc_loop_triangles()
    return len(mesh.loop_triangles)


def smart_uv(obj) -> None:
    active(obj)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.018)
    bpy.ops.object.mode_set(mode="OBJECT")


def cube_uv(obj) -> None:
    active(obj)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.cube_project(cube_size=0.25, correct_aspect=True)
    bpy.ops.object.mode_set(mode="OBJECT")


def empty(name, loc) -> bpy.types.Object:
    e = bpy.data.objects.new(name, None)
    e.empty_display_size = 0.03
    e.empty_display_type = "PLAIN_AXES"
    e.location = loc
    link(e)
    return e


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


def finish_hard(obj, bevel=0.0022, segs=3) -> None:
    add_bevel(obj, bevel, segs, math.radians(28))
    add_weighted_normals(obj)
    apply_mods(obj)
    shade_auto(obj)
    cube_uv(obj)


def boolean_cut(obj, cutter) -> None:
    active(obj)
    m = obj.modifiers.new("Cut", "BOOLEAN")
    m.operation = "DIFFERENCE"
    m.object = cutter
    m.solver = "FAST"
    try:
        apply_mods(obj)
    except Exception as exc:
        print("boolean skip", cutter.name, exc, flush=True)
        if "Cut" in obj.modifiers:
            obj.modifiers.remove(obj.modifiers["Cut"])
    if cutter.name in bpy.data.objects:
        bpy.data.objects.remove(cutter, do_unlink=True)


def decimate_to(obj, cap) -> None:
    n = tris(obj)
    if n <= cap:
        return
    d = obj.modifiers.new("Dec", "DECIMATE")
    d.ratio = cap / float(n)
    apply_mods(obj)


def join_objects(name, objects, material=None) -> bpy.types.Object:
    objects = [o for o in objects if o is not None]
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


def smooth_mesh(obj, iterations=10, factor=0.55) -> None:
    m = obj.modifiers.new("Smooth", "SMOOTH")
    m.iterations = iterations
    m.factor = factor
    apply_mods(obj)
    shade_auto(obj)


def human_metaball(name: str, lean: float = 0.0, wide: float = 0.0) -> bpy.types.Object:
    """Continuous human volume. Limb radii stay large enough to merge at the threshold."""
    slim = 1.0 - 0.12 * lean
    bulk = 1.0 + 0.16 * wide
    h = 1.0 - 0.03 * lean
    bpy.ops.object.metaball_add(type="ELLIPSOID", location=(0.0, 0.0, 0.0))
    mb = bpy.context.object
    mb.name = name
    mb.data.resolution = 0.036
    mb.data.render_resolution = 0.036
    mb.data.threshold = 0.36
    first = True

    def el(co, radius, size=(1.0, 1.0, 1.0), stiff=2.0):
        nonlocal first
        e = mb.data.elements[0] if first else mb.data.elements.new()
        first = False
        e.type = "ELLIPSOID"
        e.co = Vector(co)
        e.radius = float(radius)
        e.stiffness = stiff
        e.size_x, e.size_y, e.size_z = size
        return e

    el((0.0, 0.04, 0.96 * h), 0.20 * bulk, (1.15 * slim, 0.82, 0.78))
    el((0.0, 0.06, 1.12 * h), 0.19 * bulk, (1.08 * slim, 0.78, 0.72))
    el((0.0, 0.07, 1.28 * h), 0.21 * bulk, (1.18 * slim, 0.76, 0.90))
    el((0.0, 0.04, 1.42 * h), 0.18 * bulk, (1.24 * slim, 0.68, 0.62))
    el((-0.08 * bulk, 0.12, 1.32 * h), 0.10 * bulk, (1.0, 0.75, 0.75))
    el((0.08 * bulk, 0.12, 1.32 * h), 0.10 * bulk, (1.0, 0.75, 0.75))
    el((0.0, -0.08, 0.98 * h), 0.16 * bulk, (1.10 * slim, 0.72, 0.70))
    el((0.0, 0.02, 1.52 * h), 0.085, (0.90, 0.85, 1.20))
    el((0.0, 0.03, 1.62 * h), 0.08, (0.88, 0.82, 0.90))
    el((0.0, 0.04, 1.72 * h), 0.13, (0.90, 1.05, 1.15))
    el((0.0, 0.02, 1.80 * h), 0.09, (0.95, 0.92, 0.60))
    for s in (-1.0, 1.0):
        el((0.20 * bulk * s, 0.02, 1.46 * h), 0.11 * bulk, (1.10, 0.90, 0.80))
        el((0.24 * bulk * s, 0.03, 1.38 * h), 0.09, (0.85, 0.80, 1.05))
        el((0.28 * bulk * s, 0.04, 1.24 * h), 0.085, (0.78, 0.78, 1.35))
        el((0.32 * bulk * s, 0.05, 1.10 * h), 0.072, (0.72, 0.72, 1.20))
        el((0.35 * bulk * s, 0.04, 0.98 * h), 0.062, (0.75, 0.70, 0.85))
    for s in (-1.0, 1.0):
        el((0.10 * s, 0.03, 0.82 * h), 0.12 * bulk, (0.90, 0.85, 1.45))
        el((0.105 * s, 0.03, 0.64 * h), 0.105 * bulk, (0.85, 0.80, 1.20))
        el((0.11 * s, 0.04, 0.50 * h), 0.09, (0.80, 0.78, 0.75))
        el((0.11 * s, 0.02, 0.34 * h), 0.08, (0.75, 0.72, 1.30))
        el((0.11 * s, 0.02, 0.18 * h), 0.07, (0.72, 0.70, 0.90))
        el((0.11 * s, 0.08, 0.06), 0.065, (0.75, 1.45, 0.60))
        el((0.11 * s, 0.14, 0.04), 0.055, (0.70, 1.15, 0.50))
    active(mb)
    bpy.ops.object.convert(target="MESH")
    body = bpy.context.object
    body.name = name
    xs = [v.co.x for v in body.data.vertices]
    ys = [v.co.y for v in body.data.vertices]
    zs = [v.co.z for v in body.data.vertices]
    print(
        f"BODY {name} verts={len(body.data.vertices)} tris={tris(body)} "
        f"bbox x={min(xs):.2f}:{max(xs):.2f} y={min(ys):.2f}:{max(ys):.2f} z={min(zs):.2f}:{max(zs):.2f}",
        flush=True,
    )
    smooth_mesh(body, 8, 0.45)
    decimate_to(body, 15000 if wide >= 0 else 12500)
    shade_auto(body)
    return body


def modeled_hand(name: str, side: float, wrist, glove) -> bpy.types.Object:
    s = side
    palm_c = (wrist[0] + 0.028 * s, wrist[1] + 0.012, wrist[2] - 0.035)
    palm = add_box(name + "_palm", palm_c, (0.034, 0.020, 0.042))
    bits = [palm]
    for i, xoff in enumerate((-0.014, -0.005, 0.005, 0.014)):
        leng = 0.052 - abs(i - 1.5) * 0.004
        base = (palm_c[0] + xoff * s, palm_c[1] + 0.006, palm_c[2] - 0.028)
        bits.append(add_box(f"{name}_f{i}a", (base[0], base[1], base[2] - 0.012), (0.0075, 0.0070, 0.018)))
        bits.append(add_box(f"{name}_f{i}b", (base[0], base[1] + 0.002, base[2] - 0.030), (0.0068, 0.0064, 0.016)))
        bits.append(add_box(f"{name}_f{i}c", (base[0], base[1] + 0.003, base[2] - 0.044), (0.0060, 0.0056, leng * 0.22)))
    th = (palm_c[0] + 0.022 * s, palm_c[1] + 0.012, palm_c[2] - 0.004)
    bits.append(add_box(name + "_th0", th, (0.009, 0.008, 0.018), (0.0, 0.0, 0.45 * s)))
    bits.append(
        add_box(name + "_th1", (th[0] + 0.008 * s, th[1] + 0.008, th[2] - 0.014), (0.008, 0.007, 0.016), (0.0, 0.0, 0.7 * s))
    )
    hand = join_objects(name, bits)
    add_bevel(hand, 0.0026, 2, math.radians(35))
    apply_mods(hand)
    assign_mat(hand, glove)
    shade_auto(hand)
    smart_uv(hand)
    return hand


def conform_plate(name, body, loc, scale, material, thickness=0.014, offset=0.005) -> bpy.types.Object:
    """Plate that shrinkwraps onto the body instead of floating as a cut shell."""
    ob = add_box(name, loc, scale)
    sw = ob.modifiers.new("SW", "SHRINKWRAP")
    sw.target = body
    sw.wrap_method = "NEAREST_SURFACEPOINT"
    sw.wrap_mode = "ABOVE_SURFACE"
    sw.offset = offset
    sol = ob.modifiers.new("Sol", "SOLIDIFY")
    sol.thickness = thickness
    sol.offset = 1.0
    sol.use_even_offset = True
    add_bevel(ob, min(0.004, thickness * 0.35), 2, math.radians(32))
    apply_mods(ob)
    assign_mat(ob, material)
    shade_auto(ob)
    cube_uv(ob)
    return ob


def helmet_kit(loc, radius, visor_mat, armor_mat, stealth=False) -> list:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=22, ring_count=12, radius=radius, location=loc)
    helm = bpy.context.object
    helm.name = "Helmet"
    helm.scale = (1.06, 1.12, 0.88)
    bpy.ops.object.transform_apply(scale=True)
    # Keep the dome; flatten the open face instead of deleting verts (that floated the helmet).
    active(helm)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="DESELECT")
    bpy.ops.object.mode_set(mode="OBJECT")
    face_z = loc[2] - 0.04
    for v in helm.data.vertices:
        if v.co.z < face_z and v.co.y > loc[1] + radius * 0.15:
            v.co.y = loc[1] + radius * 0.15
            v.co.z = max(v.co.z, loc[2] - radius * 0.35)
    sol = helm.modifiers.new("Sol", "SOLIDIFY")
    sol.thickness = 0.011 if stealth else 0.015
    add_bevel(helm, 0.003, 2)
    apply_mods(helm)
    assign_mat(helm, armor_mat)
    shade_auto(helm)
    cube_uv(helm)

    vis_h = 0.055 if stealth else 0.028
    vis = add_box("Visor", (loc[0], loc[1] + radius * 0.42, loc[2] - (0.012 if stealth else 0.018)), (radius * (0.78 if stealth else 0.62), 0.012, vis_h))
    add_bevel(vis, 0.002, 2)
    apply_mods(vis)
    assign_mat(vis, visor_mat)
    shade_auto(vis)
    cube_uv(vis)

    brim = add_box("Brim", (loc[0], loc[1] + radius * 0.28, loc[2] - radius * 0.22), (radius * 0.95, 0.06, 0.012))
    add_bevel(brim, 0.002, 2)
    apply_mods(brim)
    assign_mat(brim, armor_mat)
    shade_auto(brim)

    cups = []
    for sx in (-1.0, 1.0):
        cup = add_box("Cup", (loc[0] + sx * radius * 0.78, loc[1] * 0.15, loc[2] - 0.015), (0.028, 0.046, 0.040))
        add_bevel(cup, 0.003, 2)
        apply_mods(cup)
        assign_mat(cup, armor_mat)
        shade_auto(cup)
        cups.append(cup)
        band = add_cyl("Band", (loc[0] + sx * radius * 0.55, loc[1], loc[2] + 0.01), 0.007, radius * 0.55, (0.0, math.pi / 2, 0.0), 10)
        assign_mat(band, armor_mat)
        cups.append(band)
    return [helm, vis, brim] + cups


def count_tree(obj) -> tuple[int, int]:
    t = 0
    v = 0

    def walk(o):
        nonlocal t, v
        if o.type == "MESH":
            t += tris(o)
            v += len(o.data.vertices)
        for c in o.children:
            walk(c)

    walk(obj)
    return t, v


def triangulate(obj) -> None:
    if obj.type != "MESH":
        return
    t = obj.modifiers.new("Tri", "TRIANGULATE")
    t.quad_method = "FIXED"
    apply_mods(obj)


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


def render_previews(out_dir, name, camera_loc, look, wire=False) -> None:
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
    world.color = (0.12, 0.13, 0.14)
    cam = bpy.data.cameras.new("C_" + name)
    cam.lens = 50
    cob = bpy.data.objects.new("C_" + name, cam)
    cob.location = camera_loc
    link(cob)
    scene.camera = cob
    direction = Vector(look) - Vector(camera_loc)
    cob.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    if wire:
        for o in bpy.context.scene.objects:
            if o.type == "MESH":
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


def pouch(loc, size, material) -> bpy.types.Object:
    ob = add_box("Pouch", loc, size)
    finish_hard(ob, 0.0035, 3)
    assign_mat(ob, material)
    return ob


def build_assault(out_glb, render_dir) -> dict:
    reset_scene()
    armor = mat("armor", (0.38, 0.36, 0.30), 0.42, 0.46)
    fabric = mat("fabric", (0.16, 0.17, 0.15), 0.04, 0.84)
    visor = mat("visor", (0.07, 0.07, 0.06), 0.88, 0.12, (0.05, 0.04, 0.02))
    glove = mat("glove", (0.12, 0.11, 0.09), 0.08, 0.74)
    body = human_metaball("AssaultBody", lean=0.0, wide=1.0)
    assign_mat(body, fabric)
    smart_uv(body)

    chest = conform_plate("Plate", body, (0.0, 0.12, 1.30), (0.28, 0.06, 0.28), armor, 0.016, 0.006)
    back = conform_plate("BackPlate", body, (0.0, -0.10, 1.30), (0.26, 0.05, 0.26), armor, 0.014, 0.006)
    lpad = conform_plate("LPad", body, (-0.22, 0.02, 1.46), (0.12, 0.10, 0.10), armor, 0.014, 0.005)
    rpad = conform_plate("RPad", body, (0.22, 0.02, 1.46), (0.12, 0.10, 0.10), armor, 0.014, 0.005)
    belt = conform_plate("Belt", body, (0.0, 0.02, 1.00), (0.30, 0.12, 0.08), armor, 0.010, 0.004)
    lknee = conform_plate("LKnee", body, (-0.10, 0.08, 0.50), (0.09, 0.06, 0.10), armor, 0.012, 0.004)
    rknee = conform_plate("RKnee", body, (0.10, 0.08, 0.50), (0.09, 0.06, 0.10), armor, 0.012, 0.004)
    lboot = conform_plate("LBoot", body, (-0.10, 0.08, 0.08), (0.09, 0.16, 0.10), armor, 0.010, 0.003)
    rboot = conform_plate("RBoot", body, (0.10, 0.08, 0.08), (0.09, 0.16, 0.10), armor, 0.010, 0.003)
    plates = join_objects("Armor", [chest, back, lpad, rpad, belt, lknee, rknee, lboot, rboot], armor)

    pouches = [pouch((x, 0.16, 1.16), (0.042, 0.038, 0.068), armor) for x in (-0.075, 0.0, 0.075)]
    radio = pouch((-0.18, -0.04, 1.40), (0.032, 0.038, 0.068), armor)
    ant = add_cyl("Ant", (-0.18, -0.04, 1.52), 0.005, 0.16, (0.0, 0.0, 0.0), 10)
    assign_mat(ant, armor)
    helm_bits = helmet_kit((0.0, 0.03, 1.71), 0.125, visor, armor, stealth=False)
    visor_obj = helm_bits[1]
    helm_armor = join_objects("HelmetKit", [helm_bits[0]] + helm_bits[2:] + pouches + [radio, ant], armor)
    lh = modeled_hand("LHand", -1.0, (-0.37, 0.03, 0.96), glove)
    rh = modeled_hand("RHand", 1.0, (0.37, 0.03, 0.96), glove)
    hands = join_objects("Hands", [lh, rh], glove)

    for ob in (body, plates, helm_armor, visor_obj, hands):
        if ob.data.materials:
            continue
    joined = join_objects("ff_op_assault", [body, plates, helm_armor, visor_obj, hands])
    decimate_to(joined, 24500)
    t, v = count_tree(joined)
    export_glb(out_glb, [joined])
    render_previews(render_dir, "assault_clay.png", (1.6, -3.1, 1.55), (0.0, 0.05, 1.05))
    render_previews(render_dir, "assault_wire.png", (1.6, -3.1, 1.55), (0.0, 0.05, 1.05), wire=True)
    render_previews(render_dir, "assault_close.png", (0.28, -0.95, 1.68), (0.0, 0.04, 1.62))
    return {
        "asset": "ff_op_assault",
        "tris": t,
        "verts": v,
        "materials": 3,
        "textures": f"{TEX} albedo x3",
        "rig": "deferred — forms first",
    }


def build_phantom(out_glb, render_dir) -> dict:
    reset_scene()
    armor = mat("stealth_armor", (0.14, 0.18, 0.22), 0.48, 0.30)
    fabric = mat("stealth_suit", (0.07, 0.08, 0.09), 0.05, 0.80)
    visor = mat("sensor", (0.03, 0.11, 0.13), 0.92, 0.08, (0.02, 0.11, 0.13))
    glove = mat("stealth_glove", (0.08, 0.09, 0.10), 0.10, 0.70)
    body = human_metaball("PhantomBody", lean=1.0, wide=-0.25)
    assign_mat(body, fabric)
    smart_uv(body)

    chest = conform_plate("SPlate", body, (0.0, 0.10, 1.28), (0.20, 0.045, 0.20), armor, 0.010, 0.004)
    pack = add_box("Pack", (0.0, -0.14, 1.26), (0.16, 0.08, 0.22))
    finish_hard(pack, 0.003, 3)
    assign_mat(pack, armor)
    helm_bits = helmet_kit((0.0, 0.03, 1.64), 0.108, visor, armor, stealth=True)
    visor_obj = helm_bits[1]
    sensor = add_cyl("Sensor", (0.06, 0.10, 1.64), 0.012, 0.036, (math.pi / 2, 0.0, 0.0), 12)
    assign_mat(sensor, visor)
    cube_uv(sensor)
    kit = join_objects("PhantomKit", [chest, pack, helm_bits[0]] + helm_bits[2:], armor)
    lh = modeled_hand("PLHand", -1.0, (-0.32, 0.03, 0.94), glove)
    rh = modeled_hand("PRHand", 1.0, (0.32, 0.03, 0.94), glove)
    hands = join_objects("PHands", [lh, rh], glove)
    joined = join_objects("ff_sb_phantom", [body, kit, visor_obj, sensor, hands])
    decimate_to(joined, 19500)
    t, v = count_tree(joined)
    export_glb(out_glb, [joined])
    render_previews(render_dir, "phantom_clay.png", (1.5, -2.9, 1.45), (0.0, 0.04, 1.00))
    render_previews(render_dir, "phantom_wire.png", (1.5, -2.9, 1.45), (0.0, 0.04, 1.00), wire=True)
    render_previews(render_dir, "phantom_close.png", (0.22, -0.88, 1.60), (0.0, 0.04, 1.54))
    return {
        "asset": "ff_sb_phantom",
        "tris": t,
        "verts": v,
        "materials": 3,
        "textures": f"{TEX} albedo x3",
        "rig": "deferred — forms first",
    }


def kf16_mesh() -> tuple[bpy.types.Object, bpy.types.Object]:
    # Receiver — longer, slightly taller at the rear.
    rec = add_box("recv", (0.0, 0.015, 0.032), (0.042, 0.195, 0.058))
    # Upper rail deck
    deck = add_box("deck", (0.0, 0.000, 0.066), (0.028, 0.210, 0.010))
    # Magwell
    well = add_box("well", (0.0, 0.012, -0.018), (0.038, 0.048, 0.055))
    # Stock / buffer
    tube = add_cyl("tube", (0.0, 0.195, 0.028), 0.016, 0.16, (math.pi / 2, 0.0, 0.0), 16)
    butt = add_box("butt", (0.0, 0.285, 0.010), (0.038, 0.028, 0.092))
    comb = add_box("comb", (0.0, 0.255, 0.055), (0.028, 0.055, 0.022))
    # Trigger guard U
    tg_f = add_box("tgf", (0.0, 0.000, -0.042), (0.010, 0.008, 0.028))
    tg_b = add_box("tgb", (0.0, 0.038, -0.042), (0.010, 0.008, 0.028))
    tg_bt = add_box("tgt", (0.0, 0.019, -0.058), (0.010, 0.046, 0.008))
    trig = add_box("trig", (0.0, 0.018, -0.032), (0.006, 0.008, 0.018), (math.radians(12), 0.0, 0.0))
    # Handguard
    hg = add_cyl("hg", (0.0, -0.195, 0.026), 0.022, 0.195, (math.pi / 2, 0.0, 0.0), 8)
    # Barrel assembly
    barrel = add_cyl("bar", (0.0, -0.42, 0.026), 0.0095, 0.36, (math.pi / 2, 0.0, 0.0), 20)
    gas = add_cyl("gas", (0.0, -0.30, 0.046), 0.0045, 0.22, (math.pi / 2, 0.0, 0.0), 12)
    gblock = add_box("gblock", (0.0, -0.38, 0.040), (0.018, 0.028, 0.024))
    # Muzzle device
    muzzle = add_cyl("mz", (0.0, -0.64, 0.026), 0.013, 0.055, (math.pi / 2, 0.0, 0.0), 18)
    # Optic
    optic = add_box("optic", (0.0, -0.02, 0.086), (0.020, 0.062, 0.026))
    glass = add_cyl("glass", (0.0, -0.048, 0.086), 0.010, 0.008, (math.pi / 2, 0.0, 0.0), 12)
    # Charging handle
    ch = add_box("ch", (0.018, 0.085, 0.058), (0.036, 0.016, 0.008))
    # Ejection lip (cut later)
    lip = add_box("lip", (0.024, -0.015, 0.038), (0.006, 0.048, 0.018))
    # Pins / screws
    pins = []
    for y, z in ((0.06, 0.012), (0.02, 0.012), (-0.08, 0.026)):
        pins.append(add_cyl("pin", (0.022, y, z), 0.0032, 0.046, (0.0, math.pi / 2, 0.0), 8))
    # Rail teeth
    teeth = []
    for i in range(14):
        teeth.append(add_box("tooth", (0.0, 0.08 - i * 0.016, 0.074), (0.022, 0.006, 0.005)))

    metal = join_objects(
        "kf16_metal",
        [rec, deck, well, tube, butt, comb, hg, barrel, gas, gblock, muzzle, optic, glass, ch, lip] + pins + teeth,
    )
    # Ejection port cut
    cutter = add_box("eject_cut", (0.028, -0.012, 0.038), (0.020, 0.052, 0.022))
    boolean_cut(metal, cutter)
    # Magwell hollow
    well_cut = add_box("well_cut", (0.0, 0.012, -0.028), (0.026, 0.032, 0.070))
    boolean_cut(metal, well_cut)
    # Muzzle slots
    for ang in range(4):
        t = ang / 4 * math.tau
        slot = add_box("slot", (math.cos(t) * 0.012, -0.64, 0.026 + math.sin(t) * 0.012), (0.005, 0.030, 0.004))
        boolean_cut(metal, slot)
    finish_hard(metal, 0.0016, 3)
    decimate_to(metal, 8200)

    mag = add_box("Magazine", (0.0, 0.010, -0.115), (0.022, 0.036, 0.125))
    # Taper the floor plate / body
    active(mag)
    bpy.ops.object.mode_set(mode="EDIT")
    bm = bmesh.from_edit_mesh(mag.data)
    for v in bm.verts:
        if v.co.z < -0.04:
            v.co.x *= 0.86
            v.co.y *= 0.90
            v.co.y += 0.012
    bmesh.update_edit_mesh(mag.data)
    bpy.ops.object.mode_set(mode="OBJECT")
    finish_hard(mag, 0.002, 3)
    return metal, mag


def build_kf16(out_glb, render_dir) -> dict:
    reset_scene()
    metal = mat("metal", (0.20, 0.21, 0.22), 0.84, 0.30)
    polymer = mat("polymer", (0.07, 0.07, 0.07), 0.06, 0.68)
    body, mag = kf16_mesh()
    assign_mat(body, metal)
    assign_mat(mag, polymer)
    grip = add_box("kf16_grip", (0.0, 0.048, -0.078), (0.024, 0.036, 0.095), (math.radians(18), 0.0, 0.0))
    finish_hard(grip, 0.0024, 3)
    assign_mat(grip, polymer)
    body = join_objects("kf16_metal", [body, grip])

    root = bpy.data.objects.new("ff_wpn_kf16", None)
    link(root)
    body.parent = root
    mag.name = "Magazine"
    mag.parent = root
    mz = empty("MuzzleFlash", (0.0, -0.70, 0.026))
    se = empty("ShellEject", (0.040, -0.012, 0.045))
    ads = empty("AdsAlign", (0.0, -0.020, 0.092))
    for e in (mz, se, ads):
        e.parent = root
    t = tris(body) + tris(mag)
    v = len(body.data.vertices) + len(mag.data.vertices)
    export_glb(out_glb, [root])
    render_previews(render_dir, "kf16_clay.png", (0.42, -0.42, 0.20), (0.0, -0.12, 0.02))
    render_previews(render_dir, "kf16_wire.png", (0.42, -0.42, 0.20), (0.0, -0.12, 0.02), wire=True)
    render_previews(render_dir, "kf16_hero.png", (0.20, -0.18, 0.10), (0.0, -0.10, 0.03))
    return {
        "asset": "ff_wpn_kf16",
        "tris": t,
        "verts": v,
        "materials": 2,
        "textures": f"{TEX} albedo x2",
        "rig": "MuzzleFlash, ShellEject, Magazine, AdsAlign",
    }


def fps_arm(side: float, glove, sleeve) -> list:
    s = side
    # Sleeve / forearm
    sleeve_ob = add_cyl("sleeve", (0.20 * s, -0.24, -0.04), 0.036, 0.22, (math.radians(62), 0.0, 0.18 * s), 14)
    assign_mat(sleeve_ob, sleeve)
    add_bevel(sleeve_ob, 0.003, 2)
    apply_mods(sleeve_ob)
    shade_auto(sleeve_ob)
    smart_uv(sleeve_ob)
    cuff = add_cyl("cuff", (0.155 * s, -0.205, -0.18), 0.032, 0.028, (math.radians(62), 0.0, 0.18 * s), 14)
    assign_mat(cuff, sleeve)
    finish_hard(cuff, 0.002, 2)
    # Wrist brick
    brick = add_box("wrist", (0.14 * s, -0.195, -0.22), (0.028, 0.018, 0.022))
    finish_hard(brick, 0.002, 2)
    assign_mat(brick, glove)
    wrist = (0.13 * s, -0.19, -0.26)
    hand = modeled_hand("FPS" + ("R" if s > 0 else "L"), s, wrist, glove)
    # Curl fingers a bit toward a rifle grip by rotating the hand
    hand.rotation_euler = Euler((math.radians(18), math.radians(-8 * s), math.radians(-12 * s)))
    return [sleeve_ob, cuff, brick, hand]


def build_arms(out_glb, render_dir) -> dict:
    reset_scene()
    glove = mat("glove", (0.13, 0.12, 0.10), 0.08, 0.72)
    sleeve = mat("sleeve", (0.20, 0.22, 0.18), 0.04, 0.82)
    parts = fps_arm(1.0, glove, sleeve) + fps_arm(-1.0, glove, sleeve)
    joined = join_objects("ff_fps_arms", parts)
    decimate_to(joined, 5800)
    t, v = count_tree(joined)
    export_glb(out_glb, [joined])
    render_previews(render_dir, "arms_clay.png", (0.20, -0.85, 0.12), (0.04, -0.22, -0.22))
    render_previews(render_dir, "arms_wire.png", (0.20, -0.85, 0.12), (0.04, -0.22, -0.22), wire=True)
    return {
        "asset": "ff_fps_arms",
        "tris": t,
        "verts": v,
        "materials": 2,
        "textures": f"{TEX} albedo x2",
        "rig": "deferred — forms first",
    }


def save_blend(path) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=path)


def main() -> None:
    root = parse_root()
    glb_dir = os.path.join(root, "game", "assets", "v02")
    art = os.path.join(root, "art", "v02")
    renders = os.path.join(art, "renders")
    src = os.path.join(art, "src")
    os.makedirs(glb_dir, exist_ok=True)
    os.makedirs(renders, exist_ok=True)
    os.makedirs(src, exist_ok=True)
    stats = []
    jobs = [
        ("ff_op_assault.glb", build_assault, "assault.blend"),
        ("ff_sb_phantom.glb", build_phantom, "phantom.blend"),
        ("ff_wpn_kf16.glb", build_kf16, "kf16.blend"),
        ("ff_fps_arms.glb", build_arms, "fps_arms.blend"),
    ]
    for glb_name, builder, blend_name in jobs:
        print("BUILD", glb_name, flush=True)
        rec = builder(os.path.join(glb_dir, glb_name), renders)
        save_blend(os.path.join(src, blend_name))
        rec["glb_bytes"] = os.path.getsize(os.path.join(glb_dir, glb_name))
        rec["generation"] = "Blender 4.5 DCC refine: metaball body, shrinkwrap armor, boolean KF-16. No Meshy. Rig deferred."
        rec["date"] = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        stats.append(rec)
        print("  ", rec, flush=True)
    with open(os.path.join(glb_dir, "generation_stats.json"), "w", encoding="utf-8") as f:
        json.dump(stats, f, indent=2)
    print("done", glb_dir, flush=True)


if __name__ == "__main__":
    main()
