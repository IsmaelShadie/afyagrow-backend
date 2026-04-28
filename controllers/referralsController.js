const db = require("../config/db");

exports.getAll = async (req, res, next) => {
  try {
    const { rows } = await db.query(
      "SELECT r.*, p.name as patient_name, h.name as facility_name FROM referrals r LEFT JOIN patients p ON r.patient_id=p.id LEFT JOIN health_facilities h ON r.to_facility=h.id WHERE r.from_user_id=$1 ORDER BY r.referred_at DESC",
      [req.user.id]
    );
    res.json({ referrals: rows });
  } catch (err) { next(err); }
};

exports.create = async (req, res, next) => {
  try {
    const { patient_id, to_facility, reason, urgency, notes } = req.body;
    const { rows } = await db.query(
      "INSERT INTO referrals (from_user_id,patient_id,to_facility,reason,urgency,notes) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *",
      [req.user.id, patient_id, to_facility||null, reason, urgency||"routine", notes||null]
    );
    res.status(201).json({ referral: rows[0] });
  } catch (err) { next(err); }
};

exports.updateStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const { rows } = await db.query(
      "UPDATE referrals SET status=$1 WHERE id=$2 RETURNING *",
      [status, req.params.id]
    );
    res.json({ referral: rows[0] });
  } catch (err) { next(err); }
};
