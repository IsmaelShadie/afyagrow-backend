const db = require("../config/db");
exports.getAll = async (req, res, next) => {
  try {
    const { rows } = await db.query("SELECT * FROM moh_alerts WHERE (expires_at IS NULL OR expires_at > NOW()) ORDER BY published_at DESC LIMIT 20");
    res.json({ alerts: rows });
  } catch (err) { next(err); }
};
exports.create = async (req, res, next) => {
  try {
    const { title, body, severity, province, district } = req.body;
    const { rows } = await db.query(
      "INSERT INTO moh_alerts (title,body,severity,province,district) VALUES ($1,$2,$3,$4,$5) RETURNING *",
      [title, body, severity||"info", province||null, district||null]
    );
    res.status(201).json({ alert: rows[0] });
  } catch (err) { next(err); }
};
