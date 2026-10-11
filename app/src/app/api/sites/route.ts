import { pool } from "@/lib/db";


export async function GET() {
  const { rows } = await pool.query("SELECT id, name, url FROM sites ORDER BY id");
  return Response.json(rows);
}