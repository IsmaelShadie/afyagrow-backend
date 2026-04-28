require("dotenv").config();
const express = require("express");
const cors    = require("cors");
const helmet  = require("helmet");
const db      = require("./config/db");
const fs      = require("fs");

const app = express();

app.use(helmet());
app.use(cors({ origin: "*", credentials: true }));
app.use(express.json({ limit: "10mb" }));

app.use("/api/auth",      require("./routes/auth"));
app.use("/api/chat",      require("./routes/chat"));
app.use("/api/symptoms",  require("./routes/symptoms"));
app.use("/api/clinics",   require("./routes/clinics"));
app.use("/api/reminders", require("./routes/reminders"));
app.use("/api/pregnancy", require("./routes/pregnancy"));
app.use("/api/children",  require("./routes/children"));
app.use("/api/vitals",    require("./routes/vitals"));
app.use("/api/sos",       require("./routes/sos"));
app.use("/api/patients",  require("./routes/patients"));
app.use("/api/referrals", require("./routes/referrals"));
app.use("/api/hmis",      require("./routes/hmis"));
app.use("/api/alerts",    require("./routes/alerts"));
app.use("/api/kinyarwanda", require("./routes/kinyarwanda"));
app.use("/api/voice",     require("./routes/voice"));

app.get("/health", (req, res) =>
  res.json({ status: "ok", service: "AfyaGrow API", version: "1.0.0" })
);

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({ error: err.message || "Server error" });
});

async function startServer() {
  try {
    // Auto-migrate database on startup
    console.log("Running database migrations...");
    const sql = fs.readFileSync("./models/schema.sql", "utf8");
    await db.query(sql);
    console.log("Database ready!");
  } catch (e) {
    console.log("Migration note:", e.message);
  }

  const PORT = process.env.PORT || 5000;
  app.listen(PORT, () => console.log("AfyaGrow API running on port " + PORT));
}

startServer();
