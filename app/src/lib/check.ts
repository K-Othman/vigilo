export type CheckResult = {
  isUp: boolean;
  statusCode: number | null;
  responseTimeMs: number | null;
  error: string | null;
};

const TIMEOUT_MS = 10_000;

function describeError(err: unknown): string {
  if (err instanceof Error) {
    const code = (err.cause as { code?: string } | undefined)?.code;
    return code ?? err.message;
  }
  return "Unknown error";
}

export async function checkSite(url: string): Promise<CheckResult> {
  const start = performance.now();
  try {
    const res = await fetch(url, {
      redirect: "follow",
      signal: AbortSignal.timeout(TIMEOUT_MS),
      headers: { "User-Agent": "Vigilo uptime monitor" },
    });
    await res.body?.cancel();

    return {
      isUp: res.ok,
      statusCode: res.status,
      responseTimeMs: Math.round(performance.now() - start),
      error: res.ok ? null : `HTTP ${res.status}`,
    };
  } catch (err) {
    return {
      isUp: false,
      statusCode: null,
      responseTimeMs: null,
      error: describeError(err),
    };
  }
}