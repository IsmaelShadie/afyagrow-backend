const router = require("express").Router();
const axios  = require("axios");

const HF_API = "https://api-inference.huggingface.co/models";
const HEADERS = () => ({
  "Authorization": `Bearer ${process.env.HF_API_KEY}`,
  "Content-Type": "application/json",
});

// POST /api/kinyarwanda/stt
// Speech to text — Kinyarwanda audio → text
router.post("/stt", async (req, res) => {
  try {
    const { audio } = req.body; // base64 audio
    const buffer = Buffer.from(audio, "base64");
    const response = await axios.post(
      `${HF_API}/facebook/mms-300m`,
      buffer,
      {
        headers: {
          "Authorization": `Bearer ${process.env.HF_API_KEY}`,
          "Content-Type": "audio/wav",
        },
        responseType: "json",
      }
    );
    res.json({ transcript: response.data?.text || "" });
  } catch (err) {
    console.error("STT error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// POST /api/kinyarwanda/tts
// Text to speech — Kinyarwanda text → audio
router.post("/tts", async (req, res) => {
  try {
    const { text } = req.body;
    const response = await axios.post(
      `${HF_API}/mbazaNLP/kinyarwanda-tts-model`,
      { inputs: text },
      {
        headers: HEADERS(),
        responseType: "arraybuffer",
      }
    );
    const base64Audio = Buffer.from(response.data).toString("base64");
    res.json({ audio: base64Audio, mimeType: "audio/wav" });
  } catch (err) {
    console.error("TTS error:", err.message);
    // Fallback to browser TTS if model unavailable
    res.status(500).json({ error: err.message, fallback: true });
  }
});

module.exports = router;
