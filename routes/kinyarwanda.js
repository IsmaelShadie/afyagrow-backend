const router = require("express").Router();
const axios  = require("axios");

const HF = "https://api-inference.huggingface.co/models";
const headers = () => ({
  "Authorization": `Bearer ${process.env.HF_API_KEY}`,
});

// POST /api/kinyarwanda/stt — Kinyarwanda speech to text
router.post("/stt", async (req, res) => {
  try {
    const { audio } = req.body;
    const buffer = Buffer.from(audio, "base64");
    const response = await axios.post(
      `${HF}/mbazaNLP/Whisper-Small-Kinyarwanda`,
      buffer,
      {
        headers: {
          ...headers(),
          "Content-Type": "audio/wav",
        },
        responseType: "json",
        timeout: 30000,
      }
    );
    res.json({ transcript: response.data?.text || "" });
  } catch (err) {
    console.error("STT error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// POST /api/kinyarwanda/tts — Kinyarwanda text to speech
router.post("/tts", async (req, res) => {
  try {
    const { text } = req.body;
    const response = await axios.post(
      `${HF}/facebook/mms-tts-kin`,
      { inputs: text },
      {
        headers: { ...headers(), "Content-Type": "application/json" },
        responseType: "arraybuffer",
        timeout: 30000,
      }
    );
    const base64Audio = Buffer.from(response.data).toString("base64");
    res.json({ audio: base64Audio, mimeType: "audio/wav" });
  } catch (err) {
    console.error("TTS error:", err.message);
    res.status(500).json({ error: err.message, fallback: true });
  }
});

module.exports = router;
