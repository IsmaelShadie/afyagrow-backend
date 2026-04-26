const bcrypt = require("bcryptjs");
const jwt    = require("jsonwebtoken");
const db     = require("../config/db");

exports.register = async (req, res, next) => {
  try {
    const { name, email, phone, password, role, lang, province, district } = req.body;
    if (!password || password.length < 6)
      return res.status(400).json({ error: "Password min 6 characters" });
    const hash = await bcrypt.hash(password, 12);
    const { rows } = await db.query(
      "INSERT INTO users (name,email,phone,password_hash,role,lang,province,district) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id,name,email,phone,role,lang",
      [name, email||null, phone||null, hash, role||"citizen", lang||"rw", province||null, district||null]
    );
    const token = jwt.sign({ id: rows[0].id, role: rows[0].role }, process.env.JWT_SECRET, { expiresIn: "7d" });
    res.status(201).json({ user: rows[0], token });
  } catch (err) {
    if (err.code === "23505") return res.status(400).json({ error: "Email or phone already registered" });
    next(err);
  }
};

exports.login = async (req, res, next) => {
  try {
    const { email, phone, password } = req.body;
    const { rows } = await db.query(
      "SELECT * FROM users WHERE email=$1 OR phone=$2 LIMIT 1",
      [email||null, phone||null]
    );
    if (!rows.length) return res.status(401).json({ error: "User not found" });
    const ok = await bcrypt.compare(password, rows[0].password_hash);
    if (!ok) return res.status(401).json({ error: "Wrong password" });
    const { password_hash, ...user } = rows[0];
    const token = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: "7d" });
    res.json({ user, token });
  } catch (err) { next(err); }
};
