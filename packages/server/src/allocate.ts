/**
 * Session allocator stub — production calls Hathora / PlayFab MGS / K8s.
 * Returns a dedicated-server connect token. Never expose the gameserver admin port.
 */

export interface AllocateRequest {
  mapId: string;
  modeId: string;
  region: string;
  matchId: string;
  teamA: string[];
  teamB: string[];
}

export interface AllocateResponse {
  host: string;
  port: number;
  token: string;
  mapId: string;
}

export async function allocateDedicated(req: AllocateRequest): Promise<AllocateResponse> {
  const token = Buffer.from(
    JSON.stringify({ matchId: req.matchId, exp: Date.now() + 120_000 }),
  ).toString("base64url");
  return {
    host: `ds-${req.region}.furyfront.example`,
    port: 7777,
    token,
    mapId: req.mapId,
  };
}

export function verifyConnectToken(token: string, matchId: string): boolean {
  try {
    const payload = JSON.parse(Buffer.from(token, "base64url").toString("utf8")) as {
      matchId: string;
      exp: number;
    };
    return payload.matchId === matchId && payload.exp > Date.now();
  } catch {
    return false;
  }
}
