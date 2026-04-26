const { Pool } = require("pg");

const isProduction = process.env.NODE_ENV === "production";

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: isProduction ? { rejectUnauthorized: false, checkServerIdentity: () => undefined } : false,
});

pool.on("connect", () => console.log("DB connected"));
pool.on("error", (err) => console.error("DB error:", err));
module.exports = pool;
