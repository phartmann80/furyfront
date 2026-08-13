import attachmentsDef from "../../../data/attachments.json" with { type: "json" };

export interface StatMods {
  ads: number;
  recoil: number;
  range: number;
  move: number;
  mag: number;
  reload: number;
  damage: number;
}

const ZERO: StatMods = { ads: 0, recoil: 0, range: 0, move: 0, mag: 0, reload: 0, damage: 0 };

export function stackAttachments(ids: string[]): StatMods {
  const byId = new Map(attachmentsDef.attachments.map((a) => [a.id, a]));
  const acc = { ...ZERO };
  for (const id of ids) {
    const a = byId.get(id) as Record<string, unknown> | undefined;
    if (!a) continue;
    acc.ads += Number(a.ads ?? 0);
    acc.recoil += Number(a.recoil ?? 0) + Number(a.recoilYaw ?? 0) * 0.5 + Number(a.recoilPitch ?? 0) * 0.5;
    acc.range += Number(a.range ?? 0);
    acc.move += Number(a.move ?? 0);
    acc.mag += Number(a.mag ?? 0);
    acc.reload += Number(a.reload ?? 0);
  }
  const c = attachmentsDef.caps;
  acc.ads = Math.max(c.adsTime, acc.ads);
  acc.recoil = Math.max(c.recoil, acc.recoil);
  acc.move = Math.min(c.moveMax, Math.max(c.moveMin, acc.move));
  acc.damage = c.damage;
  return acc;
}
