const db = require("../config/db");
exports.get = async (req, res, next) => {
  try {
    const { rows } = await db.query("SELECT * FROM pregnancies WHERE user_id=$1 AND is_active=true LIMIT 1", [req.user.id]);
    res.json({ pregnancy: rows[0] || null });
  } catch (err) { next(err); }
};
exports.create = async (req, res, next) => {
  try {
    const { lmp_date, gravida, para } = req.body;
    const edd = new Date(lmp_date);
    edd.setDate(edd.getDate() + 280);
    const { rows } = await db.query(
      "INSERT INTO pregnancies (user_id,lmp_date,edd,gravida,para) VALUES ($1,$2,$3,$4,$5) RETURNING *",
      [req.user.id, lmp_date, edd.toISOString().split("T")[0], gravida||1, para||0]
    );
    res.status(201).json({ pregnancy: rows[0] });
  } catch (err) { next(err); }
};
exports.addANC = async (req, res, next) => {
  try {
    const { date, facility, notes } = req.body;
    const { rows } = await db.query(
      "UPDATE pregnancies SET anc_visits = anc_visits || $1::jsonb WHERE user_id=$2 AND is_active=true RETURNING *",
      [JSON.stringify({ date, facility, notes }), req.user.id]
    );
    res.json({ pregnancy: rows[0] });
  } catch (err) { next(err); }
};
