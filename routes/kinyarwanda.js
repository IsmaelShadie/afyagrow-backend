const router = require("express").Router();
const { InferenceClient } = require("@huggingface/inference");
const { GoogleGenAI } = require("@google/genai");

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
    const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
    const response = await ai.models.generateContent({
      model: "gemini-2.5-flash-preview-tts",
      contents: [{ parts: [{ text: text }] }],
      config: {
        responseModalities: ["AUDIO"],
        speechConfig: {
          voiceConfig: {
            prebuiltVoiceConfig: { voiceName: "Aoede" },
          },
        },
      },
    });
    const part = response.candidates?.[0]?.content?.parts?.[0];
    if (!part?.inlineData?.data) throw new Error("No audio data returned");
    res.json({ audio: part.inlineData.data, mimeType: "audio/wav" });
  } catch (err) {
    console.error("TTS error:", err.message);
    res.status(500).json({ error: err.message, fallback: true });
  }
});

module.exports = router;
