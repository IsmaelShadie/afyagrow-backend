const db = require("../config/db");

exports.trigger = async (req, res, next) => {
  try {
    const { lat, lon, triggeredBy } = req.body;
    const userId = req.user?.id;
    const validTriggers = ["double_tap", "voice", "manual", "test"];
    const trigger = validTriggers.includes(triggeredBy) ? triggeredBy : "manual";
    let contacts = [];
    if (userId) {
      const { rows } = await db.query("SELECT name, phone FROM emergency_contacts WHERE user_id=$1", [userId]);
      contacts = rows;
    }
    const mapsLink = "https://maps.google.com/?q=" + lat + "," + lon;
    console.log("SOS triggered! GPS: " + mapsLink);
    const { rows } = await db.query(
      "INSERT INTO sos_events (user_id,lat,lon,triggered_by,contacts_notified) VALUES ($1,$2,$3,$4,$5) RETURNING id",
      [userId||null, lat, lon, trigger, JSON.stringify(contacts.map(c=>c.phone))]
    );
    res.json({ sosId: rows[0].id, contactsNotified: contacts.length, emergencyNumber: "912", mapsLink });
  } catch (err) { next(err); }
};
