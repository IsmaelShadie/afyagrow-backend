#!/bin/bash
# 
═══════════════════════════════════════════════
#  AfyaGrow Backend — One-shot setup script
#  Run: bash setup.sh
# 
═══════════════════════════════════════════════

echo "🌱 Creating AfyaGrow backend structure..."
mkdir -p config middleware routes controllers services models utils logs

# ── .env 
────────────────────────────────────────
cat > .env << 'EOF'
PORT=5000
DATABASE_URL=postgresql://thechiefcook@localhost:5432/afyagrow
JWT_SECRET=afyagrow_super_secret_jwt_2024
JWT_EXPIRES_IN=7d
ANTHROPIC_API_KEY=sk-ant-PASTE_YOUR_KEY_HERE
AT_API_KEY=sandbox
AT_USERNAME=sandbox
AT_SENDER_ID=AfyaGrow
EMERGENCY_NUMBER=912
NODE_ENV=development
FRONTEND_URL=http://localhost:3000
EOF

# ── package.json 
────────────────────────────────
cat > package.json << 'EOF'
{
  "name": "afyagrow-backend",
  "version": "1.0.0",
  "description": "AfyaGrow Rwanda Health Platform API",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "db:migrate": "psql $DATABASE_URL -f models/schema.sql"
  },
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.11.3",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "express-rate-limit": "^7.1.5",
    "helmet": "^7.1.0",
    "axios": "^1.6.2",
    "winston": "^3.11.0",
    "africastalking": "^0.6.4",
    "express-validator": "^7.0.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.2"
  }
}
EOF

# ── server.js 
───────────────────────────────────
cat > server.js << 'EOF'
require("dotenv").config();
const express = require("express");
const cors    = require("cors");
const helmet  = require("helmet");

const app = express();

app.use(helmet());
app.use(cors({ origin: process.env.FRONTEND_URL || "*", credentials: true 
}));
app.use(express.json({ limit: "10mb" }));

// Routes
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
app.use("/api/alerts",    require("./routes/alerts"));

app.get("/health", (req, res) =>
  res.json({ status: "ok", service: "AfyaGrow API", version: "1.0.0" })
);

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({ error: err.message || "Internal 
server error" });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`✅ AfyaGrow API running on port 
${PORT}`));
EOF

# ── config/db.js 
────────────────────────────────
cat > config/db.js << 'EOF'
const { Pool } = require("pg");
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
pool.on("error", (err) => console.error("DB error:", err));
module.exports = pool;
EOF

# ── config/claude.js 
────────────────────────────
cat > config/claude.js << 'EOF'
const axios = require("axios");
module.exports = {
  call: async (messages, system, maxTokens = 400) => {
    const res = await axios.post("https://api.anthropic.com/v1/messages", 
{
      model: "claude-sonnet-4-20250514",
      max_tokens: maxTokens,
      system,
      messages,
    }, {
      headers: {
        "x-api-key": process.env.ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
        "Content-Type": "application/json",
      }
    });
    return res.data?.content?.[0]?.text || "";
  }
};
EOF

# ── middleware/auth.js 
──────────────────────────
cat > middleware/auth.js << 'EOF'
const jwt = require("jsonwebtoken");
module.exports = (req, res, next) => {
  const token = req.headers.authorization?.split(" ")[1];
  if (!token) return res.status(401).json({ error: "No token provided" });
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: "Invalid token" });
  }
};
EOF

# ── middleware/optionalAuth.js ──────────────────
cat > middleware/optionalAuth.js << 'EOF'
const jwt = require("jsonwebtoken");
module.exports = (req, res, next) => {
  const token = req.headers.authorization?.split(" ")[1];
  if (token) {
    try { req.user = jwt.verify(token, process.env.JWT_SECRET); } catch {}
  }
  next();
};
EOF

# ── controllers/authController.js ──────────────
cat > controllers/authController.js << 'EOF'
const bcrypt = require("bcryptjs");
const jwt    = require("jsonwebtoken");
const db     = require("../config/db");

exports.register = async (req, res, next) => {
  try {
    const { name, email, phone, password, role = "citizen", lang = "rw", 
province, district } = req.body;
    if (!password || password.length < 6)
      return res.status(400).json({ error: "Password min 6 characters" });
    const hash = await bcrypt.hash(password, 12);
    const { rows } = await db.query(
      `INSERT INTO users 
(name,email,phone,password_hash,role,lang,province,district)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       RETURNING id,name,email,phone,role,lang`,
      [name, email||null, phone||null, hash, role, lang, province||null, 
district||null]
    );
    const token = jwt.sign(
      { id: rows[0].id, role: rows[0].role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );
    res.status(201).json({ user: rows[0], token });
  } catch (err) {
    if (err.code === "23505")
      return res.status(400).json({ error: "Email or phone already 
registered" });
    next(err);
  }
};

exports.login = async (req, res, next) => {
  try {
    const { email, phone, password } = req.body;
    const { rows } = await db.query(
      `SELECT * FROM users WHERE email=$1 OR phone=$2 LIMIT 1`,
      [email||null, phone||null]
    );
    if (!rows.length) return res.status(401).json({ error: "User not 
found" });
    const ok = await bcrypt.compare(password, rows[0].password_hash);
    if (!ok) return res.status(401).json({ error: "Wrong password" });
    const { password_hash, ...user } = rows[0];
    const token = jwt.sign(
      { id: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );
    res.json({ user, token });
  } catch (err) { next(err); }
};
EOF

# ── controllers/chatController.js ──────────────
cat > controllers/chatController.js << 'EOF'
const db     = require("../config/db");
const CLAUDE = require("../config/claude");

const SYSTEM = (lang) => {
  const ln = { en:"English", rw:"Kinyarwanda", fr:"French", sw:"Swahili" 
}[lang] || "English";
  return `You are AfyaGrow AI, community health assistant for Rwanda. 
Respond in ${ln}. Max 150 words. Practical advice. Never diagnose. 
Reference Mutuelle de Santé, CHWs, district hospitals when relevant. 
SEVERE symptoms → start with: 🚨 EMERGENCY - GO TO HOSPITAL NOW`;
};

exports.chat = async (req, res, next) => {
  try {
    const { messages, lang = "rw" } = req.body;
    const userId = req.user?.id;
    if (userId && messages.length > 0) {
      const last = messages[messages.length - 1];
      if (last.role === "user") {
        await db.query(
          `INSERT INTO chat_messages (user_id,role,content,lang) VALUES 
($1,'user',$2,$3)`,
          [userId, last.content, lang]
        );
      }
    }
    const reply = await CLAUDE.call(messages, SYSTEM(lang));
    const isEmergency = /🚨|emergency|hospital now/i.test(reply);
    if (userId) {
      await db.query(
        `INSERT INTO chat_messages 
(user_id,role,content,lang,is_emergency) VALUES 
($1,'assistant',$2,$3,$4)`,
        [userId, reply, lang, isEmergency]
      );
    }
    res.json({ reply, isEmergency });
  } catch (err) { next(err); }
};
EOF

# ── controllers/symptomsController.js ──────────
cat > controllers/symptomsController.js << 'EOF'
const db     = require("../config/db");
const CLAUDE = require("../config/claude");

exports.check = async (req, res, next) => {
  try {
    const { symptoms, lang = "rw", lat, lon } = req.body;
    const userId = req.user?.id;
    const ln = { en:"English", rw:"Kinyarwanda", fr:"French", sw:"Swahili" 
}[lang] || "English";
    const prompt = `Patient reports these symptoms: ${symptoms.join(", 
")}. Classify severity as mild, urgent, or emergency. Give brief practical 
advice. Max 80 words. Respond in ${ln}.`;
    const reply = await CLAUDE.call([{ role:"user", content: prompt }],
      `You are AfyaGrow triage AI for Rwanda. Always respond in ${ln}.`
    );
    const triage =
      /emergency|hospital now|🚨/i.test(reply) ? "emergency" :
      /urgent|clinic today|see a doctor/i.test(reply) ? "urgent" : "mild";
    if (userId) {
      await db.query(
        `INSERT INTO symptom_checks 
(user_id,symptoms,triage,ai_response,lat,lon)
         VALUES ($1,$2,$3,$4,$5,$6)`,
        [userId, JSON.stringify(symptoms), triage, reply, lat||null, 
lon||null]
      );
    }
    res.json({ triage, advice: reply, symptoms });
  } catch (err) { next(err); }
};
EOF

# ── controllers/clinicsController.js ───────────
cat > controllers/clinicsController.js << 'EOF'
const db = require("../config/db");

exports.search = async (req, res, next) => {
  try {
    const { lat, lon, radius = 20000, type, district } = req.query;
    let query, params;
    if (lat && lon) {
      query = `
        SELECT *,
          ROUND(CAST(point(lon,lat) <@> point($1,$2) AS numeric) * 
1.60934, 2) AS dist_km
        FROM health_facilities
        WHERE point(lon,lat) <@> point($1,$2) < $3
        ${type ? "AND type=$4" : ""}
        ORDER BY dist_km ASC LIMIT 10
      `;
      params = [lon, lat, radius/1000, ...(type?[type]:[])];
    } else if (district) {
      query = `SELECT * FROM health_facilities WHERE district ILIKE $1 
ORDER BY name LIMIT 10`;
      params = [`%${district}%`];
    } else {
      return res.status(400).json({ error: "Provide lat/lon or district" 
});
    }
    const { rows } = await db.query(query, params);
    res.json({ facilities: rows });
  } catch (err) { next(err); }
};
EOF

# ── controllers/sosController.js ───────────────
cat > controllers/sosController.js << 'EOF'
const db  = require("../config/db");

exports.trigger = async (req, res, next) => {
  try {
    const { lat, lon, triggeredBy = "manual" } = req.body;
    const userId = req.user?.id;
    let contacts = [];
    if (userId) {
      const { rows } = await db.query(
        `SELECT name, phone FROM emergency_contacts WHERE user_id=$1`, 
[userId]
      );
      contacts = rows;
    }
    const mapsLink = `https://maps.google.com/?q=${lat},${lon}`;
    console.log(`🚨 SOS triggered! GPS: ${mapsLink} | Contacts: 
${contacts.map(c=>c.phone).join(", ")}`);
    const { rows } = await db.query(
      `INSERT INTO sos_events 
(user_id,lat,lon,triggered_by,contacts_notified)
       VALUES ($1,$2,$3,$4,$5) RETURNING id`,
      [userId||null, lat, lon, triggeredBy, 
JSON.stringify(contacts.map(c=>c.phone))]
    );
    res.json({
      sosId: rows[0].id,
      contactsNotified: contacts.length,
      emergencyNumber: "912",
      mapsLink,
      message: "SOS triggered successfully.",
    });
  } catch (err) { next(err); }
};
EOF

# ── controllers/remindersController.js ─────────
cat > controllers/remindersController.js << 'EOF'
const db = require("../config/db");
exports.getAll = async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT * FROM reminders WHERE user_id=$1 AND is_active=true ORDER 
BY created_at DESC`,
      [req.user.id]
    );
    res.json({ reminders: rows });
  } catch (err) { next(err); }
};
exports.create = async (req, res, next) => {
  try {
    const { medicine, dose, frequency, times, start_date, end_date } = 
req.body;
    const { rows } = await db.query(
      `INSERT INTO reminders 
(user_id,medicine,dose,frequency,times,start_date,end_date)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [req.user.id, medicine, dose||null, frequency||"daily", 
JSON.stringify(times||[]), start_date||null, end_date||null]
    );
    res.status(201).json({ reminder: rows[0] });
  } catch (err) { next(err); }
};
exports.remove = async (req, res, next) => {
  try {
    await db.query(`UPDATE reminders SET is_active=false WHERE id=$1 AND 
user_id=$2`, [req.params.id, req.user.id]);
    res.json({ message: "Reminder deleted" });
  } catch (err) { next(err); }
};
EOF

# ── controllers/alertsController.js ────────────
cat > controllers/alertsController.js << 'EOF'
const db = require("../config/db");
exports.getAll = async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT * FROM moh_alerts
       WHERE (expires_at IS NULL OR expires_at > NOW())
       ORDER BY published_at DESC LIMIT 20`
    );
    res.json({ alerts: rows });
  } catch (err) { next(err); }
};
exports.create = async (req, res, next) => {
  try {
    const { title, body, severity, province, district } = req.body;
    const { rows } = await db.query(
      `INSERT INTO moh_alerts (title,body,severity,province,district)
       VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [title, body, severity||"info", province||null, district||null]
    );
    res.status(201).json({ alert: rows[0] });
  } catch (err) { next(err); }
};
EOF

# ── controllers/pregnancyController.js ─────────
cat > controllers/pregnancyController.js << 'EOF'
const db = require("../config/db");
exports.get = async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT * FROM pregnancies WHERE user_id=$1 AND is_active=true LIMIT 
1`, [req.user.id]
    );
    res.json({ pregnancy: rows[0] || null });
  } catch (err) { next(err); }
};
exports.create = async (req, res, next) => {
  try {
    const { lmp_date, gravida, para } = req.body;
    const edd = new Date(lmp_date);
    edd.setDate(edd.getDate() + 280);
    const { rows } = await db.query(
      `INSERT INTO pregnancies (user_id,lmp_date,edd,gravida,para)
       VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [req.user.id, lmp_date, edd.toISOString().split("T")[0], gravida||1, 
para||0]
    );
    res.status(201).json({ pregnancy: rows[0] });
  } catch (err) { next(err); }
};
exports.addANC = async (req, res, next) => {
  try {
    const { date, facility, notes } = req.body;
    const { rows } = await db.query(
      `UPDATE pregnancies SET anc_visits = anc_visits || $1::jsonb
       WHERE user_id=$2 AND is_active=true RETURNING *`,
      [JSON.stringify({ date, facility, notes }), req.user.id]
    );
    res.json({ pregnancy: rows[0] });
  } catch (err) { next(err); }
};
EOF

# ── controllers/childrenController.js ──────────
cat > controllers/childrenController.js << 'EOF'
const db = require("../config/db");
exports.getAll = async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT * FROM children WHERE user_id=$1 ORDER BY dob DESC`, 
[req.user.id]
    );
    res.json({ children: rows });
  } catch (err) { next(err); }
};
exports.create = async (req, res, next) => {
  try {
    const { name, dob, sex, birth_weight } = req.body;
    const { rows } = await db.query(
      `INSERT INTO children (user_id,name,dob,sex,birth_weight)
       VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [req.user.id, name, dob, sex||null, birth_weight||null]
    );
    res.status(201).json({ child: rows[0] });
  } catch (err) { next(err); }
};
exports.updateVaccines = async (req, res, next) => {
  try {
    const { vaccines } = req.body;
    const { rows } = await db.query(
      `UPDATE children SET vaccines_given=$1 WHERE id=$2 AND user_id=$3 
RETURNING *`,
      [JSON.stringify(vaccines), req.params.id, req.user.id]
    );
    res.json({ child: rows[0] });
  } catch (err) { next(err); }
};
EOF

# ── controllers/vitalsController.js ────────────
cat > controllers/vitalsController.js << 'EOF'
const db = require("../config/db");
exports.getAll = async (req, res, next) => {
  try {
    const { type } = req.query;
    const { rows } = await db.query(
      `SELECT * FROM vitals WHERE user_id=$1 ${type?"AND type=$2":""} 
ORDER BY recorded_at DESC LIMIT 50`,
      [req.user.id, ...(type?[type]:[])  ]
    );
    res.json({ vitals: rows });
  } catch (err) { next(err); }
};
exports.create = async (req, res, next) => {
  try {
    const { type, value_1, value_2, unit, notes } = req.body;
    const { rows } = await db.query(
      `INSERT INTO vitals (user_id,type,value_1,value_2,unit,notes)
       VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
      [req.user.id, type, value_1, value_2||null, unit||null, notes||null]
    );
    res.status(201).json({ vital: rows[0] });
  } catch (err) { next(err); }
};
EOF

# ── controllers/patientsController.js ──────────
cat > controllers/patientsController.js << 'EOF'
const db = require("../config/db");
exports.getAll = async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT * FROM patients WHERE chw_id=$1 ORDER BY last_visit DESC 
NULLS LAST`, [req.user.id]
    );
    res.json({ patients: rows });
  } catch (err) { next(err); }
};
exports.create = async (req, res, next) => {
  try {
    const { name, phone, dob, sex, village, mutuelle_id, conditions } = 
req.body;
    const { rows } = await db.query(
      `INSERT INTO patients 
(chw_id,name,phone,dob,sex,village,mutuelle_id,conditions)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
      [req.user.id, name, phone||null, dob||null, sex||null, 
village||null, mutuelle_id||null, JSON.stringify(conditions||[])]
    );
    res.status(201).json({ patient: rows[0] });
  } catch (err) { next(err); }
};
EOF

# ── routes 
──────────────────────────────────────
cat > routes/auth.js << 'EOF'
const r = require("express").Router();
const c = require("../controllers/authController");
r.post("/register", c.register);
r.post("/login",    c.login);
module.exports = r;
EOF

cat > routes/chat.js << 'EOF'
const r    = require("express").Router();
const opt  = require("../middleware/optionalAuth");
const c    = require("../controllers/chatController");
r.post("/", opt, c.chat);
module.exports = r;
EOF

cat > routes/symptoms.js << 'EOF'
const r   = require("express").Router();
const opt = require("../middleware/optionalAuth");
const c   = require("../controllers/symptomsController");
r.post("/check", opt, c.check);
module.exports = r;
EOF

cat > routes/clinics.js << 'EOF'
const r = require("express").Router();
const c = require("../controllers/clinicsController");
r.get("/", c.search);
module.exports = r;
EOF

cat > routes/sos.js << 'EOF'
const r   = require("express").Router();
const opt = require("../middleware/optionalAuth");
const c   = require("../controllers/sosController");
r.post("/trigger", opt, c.trigger);
module.exports = r;
EOF

cat > routes/reminders.js << 'EOF'
const r    = require("express").Router();
const auth = require("../middleware/auth");
const c    = require("../controllers/remindersController");
r.get("/",        auth, c.getAll);
r.post("/",       auth, c.create);
r.delete("/:id",  auth, c.remove);
module.exports = r;
EOF

cat > routes/pregnancy.js << 'EOF'
const r    = require("express").Router();
const auth = require("../middleware/auth");
const c    = require("../controllers/pregnancyController");
r.get("/",       auth, c.get);
r.post("/",      auth, c.create);
r.post("/anc",   auth, c.addANC);
module.exports = r;
EOF

cat > routes/children.js << 'EOF'
const r    = require("express").Router();
const auth = require("../middleware/auth");
const c    = require("../controllers/childrenController");
r.get("/",              auth, c.getAll);
r.post("/",             auth, c.create);
r.put("/:id/vaccines",  auth, c.updateVaccines);
module.exports = r;
EOF

cat > routes/vitals.js << 'EOF'
const r    = require("express").Router();
const auth = require("../middleware/auth");
const c    = require("../controllers/vitalsController");
r.get("/",   auth, c.getAll);
r.post("/",  auth, c.create);
module.exports = r;
EOF

cat > routes/patients.js << 'EOF'
const r    = require("express").Router();
const auth = require("../middleware/auth");
const c    = require("../controllers/patientsController");
r.get("/",   auth, c.getAll);
r.post("/",  auth, c.create);
module.exports = r;
EOF

cat > routes/alerts.js << 'EOF'
const r    = require("express").Router();
const auth = require("../middleware/auth");
const c    = require("../controllers/alertsController");
r.get("/",   c.getAll);
r.post("/",  auth, c.create);
module.exports = r;
EOF

# ── models/schema.sql 
───────────────────────────
cat > models/schema.sql << 'EOF'
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name          VARCHAR(120) NOT NULL,
  email         VARCHAR(255) UNIQUE,
  phone         VARCHAR(20)  UNIQUE,
  password_hash VARCHAR(255),
  role          VARCHAR(20)  DEFAULT 'citizen' CHECK (role IN 
('citizen','chw','doctor','admin')),
  lang          VARCHAR(5)   DEFAULT 'rw',
  blood_type    VARCHAR(5),
  allergies     TEXT,
  province      VARCHAR(60),
  district      VARCHAR(60),
  sector        VARCHAR(60),
  mutuelle_id   VARCHAR(50),
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS emergency_contacts (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID REFERENCES users(id) ON DELETE CASCADE,
  name       VARCHAR(120) NOT NULL,
  phone      VARCHAR(20)  NOT NULL,
  relation   VARCHAR(60),
  is_primary BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chat_messages (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID REFERENCES users(id) ON DELETE CASCADE,
  role         VARCHAR(20) CHECK (role IN ('user','assistant')),
  content      TEXT NOT NULL,
  lang         VARCHAR(5) DEFAULT 'rw',
  is_emergency BOOLEAN DEFAULT FALSE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS symptom_checks (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  symptoms    JSONB NOT NULL,
  triage      VARCHAR(20) CHECK (triage IN ('mild','urgent','emergency')),
  ai_response TEXT,
  lat         DECIMAL(9,6),
  lon         DECIMAL(9,6),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS health_facilities (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name             VARCHAR(200) NOT NULL,
  type             VARCHAR(40) CHECK (type IN 
('hospital','health_center','clinic','pharmacy','district_hospital','referral_hospital')),
  province         VARCHAR(60),
  district         VARCHAR(60),
  sector           VARCHAR(60),
  address          TEXT,
  phone            VARCHAR(20),
  lat              DECIMAL(9,6),
  lon              DECIMAL(9,6),
  opening_hours    TEXT,
  accepts_mutuelle BOOLEAN DEFAULT TRUE,
  has_maternity    BOOLEAN DEFAULT FALSE,
  has_lab          BOOLEAN DEFAULT FALSE,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS appointments (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  facility_id UUID REFERENCES health_facilities(id),
  date        DATE NOT NULL,
  time        TIME NOT NULL,
  reason      TEXT,
  status      VARCHAR(20) DEFAULT 'pending' CHECK (status IN 
('pending','confirmed','completed','cancelled')),
  queue_no    INTEGER,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reminders (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID REFERENCES users(id) ON DELETE CASCADE,
  medicine   VARCHAR(200) NOT NULL,
  dose       VARCHAR(100),
  frequency  VARCHAR(40) DEFAULT 'daily',
  times      JSONB DEFAULT '[]',
  start_date DATE,
  end_date   DATE,
  is_active  BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pregnancies (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID REFERENCES users(id) ON DELETE CASCADE,
  lmp_date       DATE NOT NULL,
  edd            DATE,
  gravida        INTEGER DEFAULT 1,
  para           INTEGER DEFAULT 0,
  anc_visits     JSONB DEFAULT '[]',
  danger_signs   JSONB DEFAULT '[]',
  birth_plan     TEXT,
  pmtct_enrolled BOOLEAN DEFAULT FALSE,
  is_active      BOOLEAN DEFAULT TRUE,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS children (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID REFERENCES users(id) ON DELETE CASCADE,
  name           VARCHAR(120) NOT NULL,
  dob            DATE NOT NULL,
  sex            VARCHAR(10),
  birth_weight   DECIMAL(4,2),
  vaccines_given JSONB DEFAULT '[]',
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS growth_records (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id   UUID REFERENCES children(id) ON DELETE CASCADE,
  date       DATE NOT NULL,
  weight_kg  DECIMAL(5,2),
  height_cm  DECIMAL(5,1),
  muac_cm    DECIMAL(4,1),
  notes      TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS vitals (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  type        VARCHAR(40) CHECK (type IN 
('blood_pressure','glucose','temperature','weight','pulse_ox')),
  value_1     DECIMAL(6,2),
  value_2     DECIMAL(6,2),
  unit        VARCHAR(20),
  notes       TEXT,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS patients (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chw_id      UUID REFERENCES users(id),
  name        VARCHAR(120) NOT NULL,
  phone       VARCHAR(20),
  dob         DATE,
  sex         VARCHAR(10),
  village     VARCHAR(100),
  mutuelle_id VARCHAR(50),
  conditions  JSONB DEFAULT '[]',
  notes       TEXT,
  last_visit  DATE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS referrals (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  from_user_id UUID REFERENCES users(id),
  patient_id   UUID REFERENCES patients(id),
  to_facility  UUID REFERENCES health_facilities(id),
  reason       TEXT NOT NULL,
  urgency      VARCHAR(20) DEFAULT 'routine' CHECK (urgency IN 
('routine','urgent','emergency')),
  status       VARCHAR(20) DEFAULT 'pending' CHECK (status IN 
('pending','accepted','completed','rejected')),
  notes        TEXT,
  referred_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sos_events (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID REFERENCES users(id),
  lat               DECIMAL(9,6),
  lon               DECIMAL(9,6),
  triggered_by      VARCHAR(20) CHECK (triggered_by IN 
('double_tap','voice','manual')),
  contacts_notified JSONB,
  resolved          BOOLEAN DEFAULT FALSE,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS moh_alerts (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title        VARCHAR(255) NOT NULL,
  body         TEXT NOT NULL,
  severity     VARCHAR(20) DEFAULT 'info' CHECK (severity IN 
('info','warning','critical')),
  province     VARCHAR(60),
  district     VARCHAR(60),
  published_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at   TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS hmis_submissions (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chw_id              UUID REFERENCES users(id),
  period              VARCHAR(20),
  households_visited  INTEGER,
  new_pregnancies     INTEGER,
  under5_seen         INTEGER,
  malaria_cases       INTEGER,
  tb_suspects         INTEGER,
  data_json           JSONB,
  submitted_at        TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_chat_user     ON chat_messages(user_id, 
created_at DESC);
CREATE INDEX IF NOT EXISTS idx_vitals_user   ON vitals(user_id, type, 
recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_active ON moh_alerts(published_at, 
expires_at);

-- Seed: Rwanda health facilities
INSERT INTO health_facilities 
(name,type,district,lat,lon,phone,accepts_mutuelle,has_maternity) VALUES
  ('King Faisal 
Hospital','referral_hospital','Gasabo',-1.9342,30.0776,'+250788300000',TRUE,TRUE),
  ('CHUK University Teaching 
Hospital','referral_hospital','Nyarugenge',-1.9500,30.0588,'+250788301000',TRUE,TRUE),
  ('Kibagabaga 
Hospital','district_hospital','Gasabo',-1.9167,30.1167,'+250788302000',TRUE,TRUE),
  ('Kacyiru Health 
Center','health_center','Gasabo',-1.9380,30.0633,'+250788303000',TRUE,FALSE),
  ('Remera Health 
Center','health_center','Gasabo',-1.9500,30.1000,'+250788304000',TRUE,TRUE),
  ('Butaro District 
Hospital','district_hospital','Burera',-1.4733,29.8167,'+250788305000',TRUE,TRUE),
  ('Rwamagana Provincial 
Hospital','district_hospital','Rwamagana',-1.9500,30.4333,'+250788306000',TRUE,TRUE)
ON CONFLICT DO NOTHING;
EOF

echo ""
echo "✅ All files created successfully!"
echo ""
echo "Next steps:"
echo "  1. Open .env and paste your Anthropic API key"
echo "  2. Run: psql afyagrow -f models/schema.sql"
echo "  3. Run: npm run dev"
echo ""
echo "🌱 AfyaGrow is ready to launch!"
