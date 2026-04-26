const router  = require("express").Router();
const Groq    = require("groq-sdk");
const groq    = new Groq({ apiKey: process.env.GROQ_API_KEY });
const { Readable } = require("stream");

// POST /api/voice/transcribe
// Accepts base64 audio, returns transcript using Whisper
router.post("/transcribe", async (req, res) => {
  try {
    const { audio, lang = "sw" } = req.body;
    const buffer = Buffer.from(audio, "base64");
    const file   = new File([buffer], "voice.webm", { type: "audio/webm" });
    const LANG_MAP = { sw:"sw", en:"en", fr:"fr", rw:"fr" };
    const transcription = await groq.audio.transcriptions.create({
      file,
      model: "whisper-large-v3",
      language: LANG_MAP[lang] || "sw",
      response_format: "json",
      temperature: 0.0,
    });
    res.json({ transcript: transcription.text });
  } catch (err) {
    console.error("Whisper error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
