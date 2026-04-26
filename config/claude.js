const Groq = require("groq-sdk");

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

module.exports = {
  call: async (messages, system, maxTokens) => {
    const fullMessages = system
      ? [{ role: "system", content: system }, ...messages]
      : messages;
    const res = await groq.chat.completions.create({
      model: "llama-3.3-70b-versatile",
      max_tokens: maxTokens || 400,
      messages: fullMessages,
    });
    return res.choices[0].message.content;
  }
};
