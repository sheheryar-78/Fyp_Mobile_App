import Chunk from "../models/Chunk.js";

const cosineSimilarity = (a, b) => {
  const dot = a.reduce((sum, val, i) => sum + val * b[i], 0);
  const magA = Math.sqrt(a.reduce((sum, val) => sum + val * val, 0));
  const magB = Math.sqrt(b.reduce((sum, val) => sum + val * val, 0));

  return dot / (magA * magB);
};

export const findRelevantChunks = async (queryEmbedding) => {
  const chunks = await Chunk.find();

  const scored = chunks.map((c) => ({
    text: c.text,
    score: cosineSimilarity(queryEmbedding, c.embedding),
  }));

  return scored
    .sort((a, b) => b.score - a.score)
    .slice(0, 3);
};

// 🔥 NEW: Connect context to Groq for Conversational Response (Faster & Avoids 404)
import { createEmbedding } from "./embeddingService.js";
import Groq from "groq-sdk";

export const generateRAGResponse = async (userQuery) => {
  try {
    // 1. Convert query to vector (Gemini Embeddings works fine)
    const queryEmbedding = await createEmbedding(userQuery);
    
    // 2. Find closest document chunks
    const relevantChunks = await findRelevantChunks(queryEmbedding);
    const context = relevantChunks.map(c => c.text).join("\n\n---\n\n");

    // 3. Prompt Groq (Llama 3)
    const groq = new Groq({ apiKey: process.env.GROQ_API_KEY?.trim() });

    const prompt = `You are a helpful AI Voice Assistant for NexCall.
Answer the user's question concisely in a friendly conversational tone. 
Keep it short because this will be spoken out loud over a phone call.
If the answer is not in the context, say: "I don't have that information right now."

CONTEXT:
${context}

USER QUERY:
${userQuery}`;

    const chatCompletion = await groq.chat.completions.create({
      messages: [{ role: "user", content: prompt }],
      model: "llama-3.1-8b-instant",
      temperature: 0.5,
    });

    return chatCompletion.choices[0].message.content;
  } catch (error) {
    console.error("RAG Response Error:", error);
    return "Sorry, I am having trouble fetching the information right now.";
  }
};