const db = require("../config/db");
exports.getAll = async (req, res, next) => {
  try {
    const { type } = req.query;
    const { rows } = await db.query(
      "SELECT * FROM vitals WHERE user_id=$1 " + (type ? "AND type=$2 " : "") + "ORDER BY recorded_at DESC LIMIT 50",
      [req.user.id, ...(type ? [type] : [])]
    );
    res.json({ vitals: rows });
  } catch (err) { next(err); }
};
exports.create = async (req, res, next) => {
  try {
    const { type, value_1, value_2, unit, notes } = req.body;
    const { rows } = await db.query(
      "INSERT INTO vitals (user_id,type,value_1,value_2,unit,notes) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *",
      [req.user.id, type, value_1, value_2||null, unit||null, notes||null]
    );
    res.status(201).json({ vital: rows[0] });
  } catch (err) { next(err); }
};
