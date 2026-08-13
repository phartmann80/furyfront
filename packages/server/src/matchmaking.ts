/**
 * Glicko-2-lite matchmaking queue. Production swaps this for Open Match + Redis.
 * Skill is hidden MMR; ping and input device are hard filters in ranked.
 */

export interface QueueTicket {
  accountId: string;
  mmr: number;
  pingMs: Record<string, number>;
  region: string;
  input: "mnk" | "controller" | "touch";
  partyId: string;
  partySize: number;
  ranked: boolean;
  enqueuedAt: number;
}

export interface MatchSlot {
  tickets: QueueTicket[];
  region: string;
  playlist: string;
}

const EXPAND_MS = 8000;
const WINDOWS = [50, 150, 300, 9999];

export function mmrWindow(waitMs: number): number {
  const i = Math.min(WINDOWS.length - 1, Math.floor(waitMs / EXPAND_MS));
  return WINDOWS[i];
}

export function pingOk(t: QueueTicket, region: string, ranked: boolean): boolean {
  const p = t.pingMs[region];
  if (p == null) return false;
  return ranked ? p <= 110 : p <= 180;
}

export function compatible(a: QueueTicket, b: QueueTicket, now: number): boolean {
  if (a.ranked !== b.ranked) return false;
  if (a.ranked && a.input !== b.input) return false;
  const wait = now - Math.min(a.enqueuedAt, b.enqueuedAt);
  const win = mmrWindow(wait);
  if (Math.abs(a.mmr - b.mmr) > win) return false;
  const region = a.region;
  if (!pingOk(a, region, a.ranked) || !pingOk(b, region, a.ranked)) return false;
  return true;
}

/** Greedy fill: 12 tickets for 6v6. Parties stay together. */
export function formMatch(queue: QueueTicket[], now: number, size = 12): MatchSlot | null {
  const ranked = queue[0]?.ranked ?? false;
  const byParty = new Map<string, QueueTicket[]>();
  for (const t of queue) {
    const arr = byParty.get(t.partyId) ?? [];
    arr.push(t);
    byParty.set(t.partyId, arr);
  }
  const parties = [...byParty.values()].sort((a, b) => b.length - a.length);
  const picked: QueueTicket[] = [];
  for (const party of parties) {
    if (party.length > (ranked ? 3 : 6)) continue;
    if (picked.length + party.length > size) continue;
    if (picked.length && !compatible(picked[0], party[0], now)) continue;
    picked.push(...party);
    if (picked.length === size) {
      return { tickets: picked, region: picked[0].region, playlist: ranked ? "ranked" : "casual" };
    }
  }
  return null;
}

export function splitTeams(tickets: QueueTicket[]): [QueueTicket[], QueueTicket[]] {
  const sorted = [...tickets].sort((a, b) => b.mmr - a.mmr);
  const a: QueueTicket[] = [];
  const b: QueueTicket[] = [];
  let sa = 0;
  let sb = 0;
  for (const t of sorted) {
    if (sa <= sb) {
      a.push(t);
      sa += t.mmr;
    } else {
      b.push(t);
      sb += t.mmr;
    }
  }
  return [a, b];
}
