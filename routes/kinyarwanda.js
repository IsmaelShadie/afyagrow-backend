const router = require("express").Router();
const axios = require("axios");
const { InferenceClient } = require("@huggingface/inference");

// POST /api/kinyarwanda/stt — Whisper Kinyarwanda STT
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

// POST /api/kinyarwanda/tts — mbazaNLP Gradio Space
router.post("/tts", async (req, res) => {
  try {
    const { text } = req.body;
    // Call mbazaNLP Kinyarwanda TTS Gradio Space API
    const predict = await axios.post(
      "https://mbazanlp-kinyarwanda-text-to-speech.hf.space/run/predict",
      { data: [text] },
      { headers: { "Content-Type": "application/json" }, timeout: 30000 }
    );
    const audioUrl = predict.data?.data?.[0];
    if (!audioUrl) throw new Error("No audio returned");
    // Fetch the audio file
    const audioRes = await axios.get(
      audioUrl.startsWith("http") ? audioUrl : `https://mbazanlp-kinyarwanda-text-to-speech.hf.space${audioUrl}`,
      { responseType: "arraybuffer", timeout: 15000 }
    );
    const base64Audio = Buffer.from(audioRes.data).toString("base64");
    res.json({ audio: base64Audio, mimeType: "audio/wav" });
  } catch (err) {
    console.error("TTS error:", err.message);
    res.status(500).json({ error: err.message, fallback: true });
  }
});

module.exports = router;
