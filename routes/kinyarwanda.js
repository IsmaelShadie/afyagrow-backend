const router = require("express").Router();
const axios  = require("axios");

const HF = "https://router.huggingface.co/hf-inference/models";
const key = () => process.env.HF_API_KEY;

// POST /api/kinyarwanda/stt
router.post("/stt", async (req, res) => {
  try {
    const { audio } = req.body;
    const buffer = Buffer.from(audio, "base64");
    const response = await axios.post(
      `${HF}/mbazaNLP/Whisper-Small-Kinyarwanda`,
      buffer,
      {
        headers: {
          "Authorization": `Bearer ${key()}`,
          "Content-Type": "audio/wav",
        },
        timeout: 30000,
      }
    );
    res.json({ transcript: response.data?.text || "" });
  } catch (err) {
    console.error("STT error:", err.response?.data || err.message);
    res.status(500).json({ error: err.message });
  }
});

// POST /api/kinyarwanda/tts
router.post("/tts", async (req, res) => {
  try {
    const { text } = req.body;
    // Use text_inputs format for VITS/MMS models
    const response = await axios.post(
      `${HF}/facebook/mms-tts-kin`,
      { text_inputs: text },
      {
        headers: {
          "Authorization": `Bearer ${key()}`,
          "Content-Type": "application/json",
          "Accept": "audio/wav",
        },
        responseType: "arraybuffer",
        timeout: 30000,
      }
    );
    const base64Audio = Buffer.from(response.data).toString("base64");
    res.json({ audio: base64Audio, mimeType: "audio/wav" });
  } catch (err) {
    const errMsg = err.response?.data
      ? Buffer.from(err.response.data).toString()
      : err.message;
    console.error("TTS error:", errMsg);
    res.status(500).json({ error: errMsg, fallback: true });
  }
});

module.exports = router;
