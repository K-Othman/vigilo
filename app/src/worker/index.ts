import { pool } from "../lib/db";
import { checkSite } from "../lib/check";

const INTERVAL_MS = Number(process.env.CHECK_INTERVAL_SECONDS ?? 60) * 1000;

let running = true;
let wake: (() => void) | null = null;

function sleep(ms: number) {
  return new Promise<void>((resolve) => {
    const timer = setTimeout(resolve, ms);
    wake = () => {
      clearTimeout(timer);
      resolve();
    };
  });
}

function stop() {
  running = false;
  wake?.();
}

async function runOnce() {
  const { rows: sites } = await pool.query<{ id: string; url: string }>(
    "SELECT id, url FROM sites"
  );

  await Promise.all(
    sites.map(async (site) => {
      const result = await checkSite(site.url);

      await pool.query(
        `INSERT INTO checks (site_id, is_up, status_code, response_time_ms, error)
         VALUES ($1, $2, $3, $4, $5)`,
        [site.id, result.isUp, result.statusCode, result.responseTimeMs, result.error]
      );

      console.log(
        `${result.isUp ? "UP  " : "DOWN"} ${site.url} ${result.responseTimeMs ?? "-"}ms ${result.error ?? ""}`
      );
    })
  );
}

async function main() {
  console.log(`Worker started, checking every ${INTERVAL_MS / 1000}s`);

  while (running) {
    try {
      await runOnce();
    } catch (err) {
      console.error("Check round failed:", err);
    }
    if (running) await sleep(INTERVAL_MS);
  }

  await pool.end();
  console.log("Worker stopped");
}

process.on("SIGTERM", stop);
process.on("SIGINT", stop);

main();