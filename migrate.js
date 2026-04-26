require("dotenv").config();
const { Pool } = require("pg");
const fs = require("fs");

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

async function migrate() {
  try {
    const sql = fs.readFileSync("./models/schema.sql", "utf8");
    await pool.query(sql);
    console.log("Migration complete!");
  } catch (e) {
    console.error("Migration error:", e.message);
  } finally {
    await pool.end();
  }
}

migrate();
