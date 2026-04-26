const router = require("express").Router();
const { InferenceClient } = require("@huggingface/inference");

const getClient = () => new InferenceClient(process.env.HF_API_KEY);

// POST /api/kinyarwanda/stt
router.post("/stt", async (req, res) => {
  try {
    const { audio } = req.body;
    const buffer = Buffer.from(audio, "base64");
    const blob = new Blob([buffer], { type: "audio/wav" });
    const client = getClient();
    const result = await client.automaticSpeechRecognition({
      model: "mbazaNLP/Whisper-Small-Kinyarwanda",
      data: blob,
    });
    res.json({ transcript: result.text || "" });
  } catch (err) {
    console.error("STT error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// POST /api/kinyarwanda/tts
router.post("/tts", async (req, res) => {
  try {
    const { text } = req.body;
    const client = getClient();
    const audioBlob = await client.textToSpeech({
      model: "facebook/mms-tts-kin",
      inputs: text,
    });
    const arrayBuffer = await audioBlob.arrayBuffer();
    const base64Audio = Buffer.from(arrayBuffer).toString("base64");
    res.json({ audio: base64Audio, mimeType: "audio/wav" });
  } catch (err) {
    console.error("TTS error:", err.message);
    res.status(500).json({ error: err.message, fallback: true });
  }
});

module.exports = router;
