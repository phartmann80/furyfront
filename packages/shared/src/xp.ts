import xpDef from "../../../data/xp-curve.json" with { type: "json" };

export function xpToNext(level: number): number {
  if (level < 1 || level >= xpDef.maxLevel) return 0;
  const f = xpDef.formula;
  return Math.round(
    f.base +
      level * f.linear +
      Math.floor(level / f.milestoneEvery) * f.milestone +
      Math.pow(level, f.pow) * f.powScale,
  );
}

export function totalXpToLevel(level: number): number {
  let sum = 0;
  for (let l = 1; l < level; l++) sum += xpToNext(l);
  return sum;
}

export function prestigeMultiplier(prestige: number): number {
  const p = Math.max(0, Math.min(xpDef.prestigeMax, prestige));
  return 1 + p * xpDef.prestigeXpPerTier;
}

export function matchXp(opts: {
  kills: number;
  assists: number;
  headshots: number;
  won: boolean;
  draw?: boolean;
  objectiveXp?: number;
  event2x?: boolean;
  boost?: number;
  squad?: boolean;
  prestige?: number;
}): number {
  const m = xpDef.match;
  let xp =
    opts.kills * m.kill +
    opts.assists * m.assist +
    opts.headshots * m.headshot +
    (opts.objectiveXp ?? 0);
  if (opts.draw) xp += m.draw;
  else xp += opts.won ? m.win : m.loss;

  const boost = Math.max(opts.event2x ? 2 : 1, opts.boost ?? 1);
  const squad = opts.squad ? 1.1 : 1;
  return Math.round(xp * boost * squad * prestigeMultiplier(opts.prestige ?? 0));
}
