const { Pool } = require("pg");

const connectionString = process.env.DATABASE_URL;
const isExternal = connectionString && connectionString.includes("proxy.rlwy.net");

const pool = new Pool({
  connectionString,
  ssl: isExternal ? { rejectUnauthorized: false } : false,
});

pool.on("connect", () => console.log("DB connected!"));
pool.on("error", (err) => console.error("DB error:", err));
module.exports = pool;
