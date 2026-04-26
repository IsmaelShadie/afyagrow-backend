const router = require("express").Router();
const { InferenceClient } = require("@huggingface/inference");
const { ElevenLabsClient } = require("elevenlabs");

// POST /api/kinyarwanda/stt
router.post("/stt", async (req, res) => {
  try {
    const { audio } = req.body;
    const buffer = Buffer.from(audio, "base64");
    const blob = new Blob([buffer], { type: "audio/wav" });
    const client = new InferenceClient(process.env.HF_API_KEY);
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
    const client = new ElevenLabsClient({
      apiKey: process.env.ELEVENLABS_API_KEY,
    });
    // Use multilingual v2 model which supports Kinyarwanda
    const audio = await client.textToSpeech.convert("JBFqnCBsd6RMkjVDRZzb", {
      text,
      model_id: "eleven_multilingual_v2",
      voice_settings: {
        stability: 0.5,
        similarity_boost: 0.75,
      },
    });
    // Collect stream into buffer
    const chunks = [];
    for await (const chunk of audio) {
      chunks.push(chunk);
    }
    const base64Audio = Buffer.concat(chunks).toString("base64");
    res.json({ audio: base64Audio, mimeType: "audio/mpeg" });
  } catch (err) {
    console.error("TTS error:", err.message);
    res.status(500).json({ error: err.message, fallback: true });
  }
});

module.exports = router;
