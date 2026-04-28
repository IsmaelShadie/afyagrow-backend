const db = require("../config/db");

exports.getAll = async (req, res, next) => {
  try {
    const { rows } = await db.query(
      "SELECT * FROM hmis_submissions WHERE chw_id=$1 ORDER BY submitted_at DESC",
      [req.user.id]
    );
    res.json({ submissions: rows });
  } catch (err) { next(err); }
};

exports.submit = async (req, res, next) => {
  try {
    const { period, households_visited, new_pregnancies, under5_seen, malaria_cases, tb_suspects, data_json } = req.body;
    const { rows } = await db.query(
      "INSERT INTO hmis_submissions (chw_id,period,households_visited,new_pregnancies,under5_seen,malaria_cases,tb_suspects,data_json) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *",
      [req.user.id, period, households_visited||0, new_pregnancies||0, under5_seen||0, malaria_cases||0, tb_suspects||0, JSON.stringify(data_json||{})]
    );
    res.status(201).json({ submission: rows[0] });
  } catch (err) { next(err); }
};
