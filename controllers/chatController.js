const db     = require("../config/db");
const CLAUDE = require("../config/claude");

const SYSTEM = (lang) => {
  const ln = { en:"English", rw:"Kinyarwanda", fr:"French", sw:"Swahili" }[lang] || "English";
  return "You are AfyaGrow AI, community health assistant for Rwanda. Respond in " + ln + ". Max 150 words. Practical advice. Never diagnose. Reference Mutuelle de Sante, CHWs, district hospitals when relevant. SEVERE symptoms start with: EMERGENCY - GO TO HOSPITAL NOW";
};

exports.chat = async (req, res, next) => {
  try {
    const { messages, lang } = req.body;
    const userId = req.user?.id;
    if (userId && messages.length > 0) {
      const last = messages[messages.length - 1];
      if (last.role === "user") {
        await db.query(
          "INSERT INTO chat_messages (user_id,role,content,lang) VALUES ($1,'user',$2,$3)",
          [userId, last.content, lang||"rw"]
        );
      }
    }
    const reply = await CLAUDE.call(messages, SYSTEM(lang||"rw"));
    const isEmergency = /emergency|hospital now/i.test(reply);
    if (userId) {
      await db.query(
        "INSERT INTO chat_messages (user_id,role,content,lang,is_emergency) VALUES ($1,'assistant',$2,$3,$4)",
        [userId, reply, lang||"rw", isEmergency]
      );
    }
    res.json({ reply, isEmergency });
  } catch (err) { next(err); }
};
