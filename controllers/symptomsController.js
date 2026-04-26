const db     = require("../config/db");
const CLAUDE = require("../config/claude");

exports.check = async (req, res, next) => {
  try {
    const { symptoms, lang, lat, lon } = req.body;
    const userId = req.user?.id;
    const ln = { en:"English", rw:"Kinyarwanda", fr:"French", sw:"Swahili" }[lang] || "English";
    const prompt = "Patient reports: " + symptoms.join(", ") + ". Classify as mild, urgent, or emergency. Give brief advice in " + ln + ". Max 80 words.";
    const reply = await CLAUDE.call([{ role:"user", content: prompt }], "You are AfyaGrow triage AI for Rwanda.");
    const triage = /emergency|hospital now/i.test(reply) ? "emergency" : /urgent|clinic today/i.test(reply) ? "urgent" : "mild";
    if (userId) {
      await db.query(
        "INSERT INTO symptom_checks (user_id,symptoms,triage,ai_response,lat,lon) VALUES ($1,$2,$3,$4,$5,$6)",
        [userId, JSON.stringify(symptoms), triage, reply, lat||null, lon||null]
      );
    }
    res.json({ triage, advice: reply, symptoms });
  } catch (err) { next(err); }
};
