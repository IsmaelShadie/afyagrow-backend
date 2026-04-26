const router = require("express").Router();
const { InferenceClient } = require("@huggingface/inference");
const axios = require("axios");

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
    res.status(500).json({ error: err.message });
  }
});

router.post("/tts", async (req, res) => {
  try {
    const { text } = req.body;
    const key = process.env.ELEVENLABS_API_KEY;
    console.log("KEY LENGTH:", key ? key.length : "MISSING");
    console.log("KEY PREVIEW:", key ? key.substring(0,15) : "NONE");

    const response = await axios.post(
      "https://api.elevenlabs.io/v1/text-to-speech/JBFqnCBsd6RMkjVDRZzb",
      {
        text,
        model_id: "eleven_multilingual_v2",
        voice_settings: { stability: 0.5, similarity_boost: 0.75 },
      },
      {
        headers: {
          "xi-api-key": key,
          "Content-Type": "application/json",
          "Accept": "audio/mpeg",
        },
        responseType: "arraybuffer",
        timeout: 30000,
      }
    );
    const base64Audio = Buffer.from(response.data).toString("base64");
    res.json({ audio: base64Audio, mimeType: "audio/mpeg" });
  } catch (err) {
    const raw = err.response?.data ? Buffer.from(err.response.data).toString() : err.message;
    console.error("TTS FULL ERROR:", raw);
    console.error("STATUS:", err.response?.status);
    res.status(500).json({ error: raw, status: err.response?.status, fallback: true });
  }
});

module.exports = router;
