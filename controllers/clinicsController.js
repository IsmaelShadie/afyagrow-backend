const db = require("../config/db");

exports.search = async (req, res, next) => {
  try {
    const { lat, lon, district } = req.query;
    let rows;
    if (lat && lon) {
      const result = await db.query(
        "SELECT * FROM health_facilities ORDER BY name ASC LIMIT 10",
        []
      );
      rows = result.rows;
    } else if (district) {
      const result = await db.query(
        "SELECT * FROM health_facilities WHERE district ILIKE $1 ORDER BY name LIMIT 10",
        ["%" + district + "%"]
      );
      rows = result.rows;
    } else {
      return res.status(400).json({ error: "Provide lat/lon or district" });
    }
    res.json({ facilities: rows });
  } catch (err) { next(err); }
};
