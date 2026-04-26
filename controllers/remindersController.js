const db = require("../config/db");
exports.getAll = async (req, res, next) => {
  try {
    const { rows } = await db.query("SELECT * FROM reminders WHERE user_id=$1 AND is_active=true ORDER BY created_at DESC", [req.user.id]);
    res.json({ reminders: rows });
  } catch (err) { next(err); }
};
exports.create = async (req, res, next) => {
  try {
    const { medicine, dose, frequency, times, start_date, end_date } = req.body;
    const { rows } = await db.query(
      "INSERT INTO reminders (user_id,medicine,dose,frequency,times,start_date,end_date) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *",
      [req.user.id, medicine, dose||null, frequency||"daily", JSON.stringify(times||[]), start_date||null, end_date||null]
    );
    res.status(201).json({ reminder: rows[0] });
  } catch (err) { next(err); }
};
exports.remove = async (req, res, next) => {
  try {
    await db.query("UPDATE reminders SET is_active=false WHERE id=$1 AND user_id=$2", [req.params.id, req.user.id]);
    res.json({ message: "Reminder deleted" });
  } catch (err) { next(err); }
};
