const db = require("../config/db");
exports.getAll = async (req, res, next) => {
  try {
    const { rows } = await db.query("SELECT * FROM patients WHERE chw_id=$1 ORDER BY last_visit DESC NULLS LAST", [req.user.id]);
    res.json({ patients: rows });
  } catch (err) { next(err); }
};
exports.create = async (req, res, next) => {
  try {
    const { name, phone, dob, sex, village, mutuelle_id, conditions } = req.body;
    const { rows } = await db.query(
      "INSERT INTO patients (chw_id,name,phone,dob,sex,village,mutuelle_id,conditions) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *",
      [req.user.id, name, phone||null, dob||null, sex||null, village||null, mutuelle_id||null, JSON.stringify(conditions||[])]
    );
    res.status(201).json({ patient: rows[0] });
  } catch (err) { next(err); }
};
