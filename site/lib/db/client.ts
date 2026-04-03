import { drizzle } from "drizzle-orm/node-postgres";
import { Pool } from "pg";
import { analyticsSchema } from "./schema";

let database:
  | ReturnType<typeof drizzle<typeof analyticsSchema>>
  | null
  | undefined;

function createPool() {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    return null;
  }

  const needsSsl = /sslmode=/i.test(connectionString);

  return new Pool({
    connectionString,
    max: 4,
    ssl: needsSsl ? { rejectUnauthorized: true } : undefined,
  });
}

export function getDb() {
  if (database !== undefined) {
    return database;
  }

  const pool = createPool();
  database = pool ? drizzle(pool, { schema: analyticsSchema }) : null;
  return database;
}
