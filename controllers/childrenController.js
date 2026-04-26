const db = require("../config/db");
exports.getAll = async (req, res, next) => {
  try {
    const { rows } = await db.query("SELECT * FROM children WHERE user_id=$1 ORDER BY dob DESC", [req.user.id]);
    res.json({ children: rows });
  } catch (err) { next(err); }
};
exports.create = async (req, res, next) => {
  try {
    const { name, dob, sex, birth_weight } = req.body;
    const { rows } = await db.query(
      "INSERT INTO children (user_id,name,dob,sex,birth_weight) VALUES ($1,$2,$3,$4,$5) RETURNING *",
      [req.user.id, name, dob, sex||null, birth_weight||null]
    );
    res.status(201).json({ child: rows[0] });
  } catch (err) { next(err); }
};
exports.updateVaccines = async (req, res, next) => {
  try {
    const { vaccines } = req.body;
    const { rows } = await db.query(
      "UPDATE children SET vaccines_given=$1 WHERE id=$2 AND user_id=$3 RETURNING *",
      [JSON.stringify(vaccines), req.params.id, req.user.id]
    );
    res.json({ child: rows[0] });
  } catch (err) { next(err); }
};
