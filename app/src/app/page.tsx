import { Suspense } from "react";
import { connection } from "next/server";
import { pool } from "@/lib/db";

type SiteRow = {
  id: string;
  name: string;
  url: string;
  is_up: boolean | null;
  status_code: number | null;
  response_time_ms: number | null;
  error: string | null;
  checked_at: Date | null;
  uptime_pct: string | null;
  avg_ms: string | null;
};

type HistoryRow = { site_id: string; is_up: boolean };

async function getSites() {
  const { rows } = await pool.query<SiteRow>(`
    SELECT s.id, s.name, s.url,
           latest.is_up, latest.status_code, latest.response_time_ms,
           latest.error, latest.checked_at,
           stats.uptime_pct, stats.avg_ms
    FROM sites s
    LEFT JOIN LATERAL (
      SELECT is_up, status_code, response_time_ms, error, checked_at
      FROM checks c
      WHERE c.site_id = s.id
      ORDER BY checked_at DESC
      LIMIT 1
    ) latest ON true
    LEFT JOIN LATERAL (
      SELECT ROUND(100.0 * AVG(CASE WHEN is_up THEN 1 ELSE 0 END), 1) AS uptime_pct,
             ROUND(AVG(response_time_ms)) AS avg_ms
      FROM checks c
      WHERE c.site_id = s.id AND c.checked_at > now() - interval '24 hours'
    ) stats ON true
    ORDER BY s.name
  `);
  return rows;
}

async function getHistory() {
  const { rows } = await pool.query<HistoryRow>(`
    SELECT site_id, is_up FROM (
      SELECT site_id, is_up, checked_at,
             ROW_NUMBER() OVER (PARTITION BY site_id ORDER BY checked_at DESC) AS rn
      FROM checks
    ) t
    WHERE rn <= 30
    ORDER BY checked_at
  `);
  return rows;
}

async function SiteList() {
  await connection();
  const [sites, history] = await Promise.all([getSites(), getHistory()]);

  const historyBySite = new Map<string, boolean[]>();
  for (const h of history) {
    const list = historyBySite.get(h.site_id) ?? [];
    list.push(h.is_up);
    historyBySite.set(h.site_id, list);
  }

  if (sites.length === 0) {
    return <p className="text-gray-500">No sites yet.</p>;
  }

  return (
    <ul className="space-y-4">
      {sites.map((site) => {
        const status =
          site.is_up === null ? "Pending" : site.is_up ? "Up" : "Down";
        const dot =
          site.is_up === null
            ? "bg-gray-400"
            : site.is_up
              ? "bg-green-500"
              : "bg-red-500";

        return (
          <li key={site.id} className="rounded-lg border border-gray-200 p-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <span className={`h-3 w-3 rounded-full ${dot}`} />
                <div>
                  <p className="font-medium">{site.name}</p>
                  <p className="text-sm text-gray-500">{site.url}</p>
                </div>
              </div>
              <div className="text-right text-sm">
                <p className="font-medium">{status}</p>
                <p className="text-gray-500">
                  {site.response_time_ms !== null
                    ? `${site.response_time_ms} ms`
                    : "–"}
                </p>
              </div>
            </div>

            <div className="mt-3 flex gap-0.5">
              {(historyBySite.get(site.id) ?? []).map((up, i) => (
                <span
                  key={i}
                  className={`h-6 flex-1 rounded-sm ${up ? "bg-green-500" : "bg-red-500"}`}
                />
              ))}
            </div>

            <div className="mt-2 flex justify-between text-xs text-gray-500">
              <span>
                24h uptime: {site.uptime_pct ?? "–"}% · avg{" "}
                {site.avg_ms ?? "–"} ms
              </span>
              <span>
                {site.checked_at
                  ? `Checked ${new Date(site.checked_at).toLocaleTimeString("en-GB")}`
                  : "Not checked yet"}
              </span>
            </div>

            {site.error && (
              <p className="mt-2 text-xs text-red-600">{site.error}</p>
            )}
          </li>
        );
      })}
    </ul>
  );
}

export default function Home() {
  return (
    <main className="mx-auto max-w-3xl p-8">
      <h1 className="text-2xl font-semibold">Vigilo</h1>
      <p className="mb-6 text-sm text-gray-500">
        Uptime for the sites you watch
      </p>
      <Suspense fallback={<p className="text-gray-500">Loading…</p>}>
        <SiteList />
      </Suspense>
    </main>
  );
}