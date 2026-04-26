const router = require("express").Router();
const axios  = require("axios");

const HF_ROUTER = "https://router.huggingface.co/hf-inference/models";
const headers = () => ({
  "Authorization": `Bearer ${process.env.HF_API_KEY}`,
  "Content-Type": "application/json",
});

// POST /api/kinyarwanda/stt
router.post("/stt", async (req, res) => {
  try {
    const { audio } = req.body;
    const buffer = Buffer.from(audio, "base64");
    const response = await axios.post(
      `${HF_ROUTER}/mbazaNLP/Whisper-Small-Kinyarwanda`,
      buffer,
      {
        headers: {
          "Authorization": `Bearer ${process.env.HF_API_KEY}`,
          "Content-Type": "audio/wav",
        },
        timeout: 30000,
      }
    );
    res.json({ transcript: response.data?.text || "" });
  } catch (err) {
    console.error("STT error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// POST /api/kinyarwanda/tts
router.post("/tts", async (req, res) => {
  try {
    const { text } = req.body;
    const response = await axios.post(
      `${HF_ROUTER}/facebook/mms-tts-kin`,
      { inputs: text },
      {
        headers: headers(),
        responseType: "arraybuffer",
        timeout: 30000,
      }
    );
    const base64Audio = Buffer.from(response.data).toString("base64");
    res.json({ audio: base64Audio, mimeType: "audio/wav" });
  } catch (err) {
    console.error("TTS error:", err.response?.data?.toString() || err.message);
    res.status(500).json({ error: err.message, fallback: true });
  }
});

module.exports = router;
