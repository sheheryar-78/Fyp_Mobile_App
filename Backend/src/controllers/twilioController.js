/* export const handleIncomingCall = async (req, res) => {
  try {
    res.set("Content-Type", "text/xml");

    res.send(`
      <Response>
        <Say voice="alice">
          Hello! Your AI agent is now active.
        </Say>
      </Response>
    `);
    console.log("📞 Twilio hit ho raha hai");
  } catch (err) {
    console.log(err);
    res.status(500).send("Error");
  }
}; */

/* export const handleIncomingCall = (req, res) => {
  console.log("📞 Twilio CALL HIT");

  res.writeHead(200, { "Content-Type": "text/xml" });

  res.end(`
    <?xml version="1.0" encoding="UTF-8"?>
    <Response>
      <Say voice="alice">Hello Ahmad! Your AI agent is working now.</Say>
      <Pause length="1"/>
      <Say>Thank you for calling.</Say>
    </Response>
  `);
}; */

/* export const handleIncomingCall = async (req, res) => {
  try {
    console.log("🔥 TWILIO HIT SUCCESS");

    res.set("Content-Type", "text/xml");

    res.send(`
      <Response>
        <Say voice="alice">
          Hello Ahmad! Your AI agent is working perfectly.
        </Say>
      </Response>
    `);
  } catch (err) {
    console.log(err);
    res.status(500).send("Error");
  }
}; */

import twilio from "twilio";
import { transcribeAudio } from "../services/groqService.js";
import { generateRAGResponse } from "../services/searchService.js";
import Agent from "../models/Agent.js";
import Call from "../models/Call.js";

const getTwilioClient = () => {
  return twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
};

export const getConfig = (req, res) => {
  res.json({ twilioPhoneNumber: process.env.TWILIO_PHONE_NUMBER });
};

// Helper to escape special characters for Twilio XML
const escapeXml = (unsafeStr) => {
  if (!unsafeStr) return "";
  return unsafeStr.replace(/[<>&'"]/g, (c) => {
    switch (c) {
      case "<": return "&lt;";
      case ">": return "&gt;";
      case "&": return "&amp;";
      case "'": return "&apos;";
      case '"': return "&quot;";
    }
  });
};

export const handleIncomingCall = async (req, res) => {
  try {
    const callerNumber = req.body.From || "Unknown Caller";
    const twilioNumber = req.body.To;
    const callSid = req.body.CallSid; // Get CallSid

    // 🔹 Find Agent & Save Call Log
    const agent = await Agent.findOne({ phoneNumber: twilioNumber });
    if (agent) {
      const newCall = new Call({
        userId: agent.userId,
        callSid: callSid,
        caller: callerNumber,
        agent: agent.name,
        duration: "45s", // Using a placeholder duration for now
        status: "completed",
      });
      await newCall.save();
      console.log("✅ Call successfully saved to database for Agent:", agent.name);
    } else {
      console.log("⚠️ Call received but no Agent found for number:", twilioNumber);
    }

    const VoiceResponse = twilio.twiml.VoiceResponse;
    const twiml = new VoiceResponse();

    twiml.say({ voice: "Polly.Joanna-Neural" }, "Welcome to NexCall AI. How can I help you?");
    twiml.record({
      action: "/api/twilio/process-audio",
      maxLength: 15,
      playBeep: true,
      trim: "trim-silence"
    });

    res.type("text/xml");
    res.send(twiml.toString());
  } catch (err) {
    console.error("Incoming Call Error:", err);
    res.type("text/xml").send("<Response><Say>Sorry, an error occurred.</Say></Response>");
  }
};

export const processAudio = async (req, res) => {
  const callSid = req.body.CallSid;
  const recordingUrl = req.body.RecordingUrl;
  const VoiceResponse = twilio.twiml.VoiceResponse;

  if (!recordingUrl || !callSid) {
    const twiml = new VoiceResponse();
    twiml.say({ voice: "Polly.Joanna-Neural" }, "I didn't hear anything. Let's try again.");
    twiml.record({ action: "/api/twilio/process-audio", maxLength: 10 });
    return res.type("text/xml").send(twiml.toString());
  }

  // 1. INSTANTLY RESPOND TO TWILIO TO PREVENT TIMEOUT
  const initialTwiml = new VoiceResponse();
  
  // A quick natural filler word to buy time
  initialTwiml.say({ voice: "Polly.Joanna-Neural" }, "Let me quickly check that for you.");
  initialTwiml.pause({ length: 60 }); // Keep call active for 1 minute while APIs process

  res.type("text/xml");
  res.send(initialTwiml.toString());

  // 2. PROCESS IN BACKGROUND (Asynchronous)
  (async () => {
    try {
      console.log("📥 Twilio Recording URL:", recordingUrl);

      // Transcribe
      const userText = await transcribeAudio(recordingUrl);
      console.log("🗣️ User said:", userText);

      let aiResponse = "";
      if (!userText || userText.trim().length === 0) {
        aiResponse = "I didn't catch that. Could you please repeat?";
      } else {
        // Query RAG System
        aiResponse = await generateRAGResponse(userText);
        console.log("🤖 AI Response:", aiResponse);
      }

      // 3. UPDATE THE LIVE CALL VIA REST API
      const client = getTwilioClient();
      const updatedTwiml = new VoiceResponse();
      
      updatedTwiml.say({ voice: "Polly.Joanna-Neural" }, aiResponse);
      
      // MUST be absolute URL because TwiML injected via REST API has no base URL
      const actionUrl = `${process.env.BASE_URL}/api/twilio/process-audio`;
      
      updatedTwiml.record({
        action: actionUrl,
        maxLength: 15,
        playBeep: true,
        trim: "trim-silence"
      });

      await client.calls(callSid).update({
        twiml: updatedTwiml.toString()
      });
      console.log("✅ Call successfully updated with AI response!");

      // 4. Save to DB
      if (userText && userText.trim().length > 0) {
        const timestamp = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        Call.findOneAndUpdate(
          { callSid: callSid },
          {
            $push: {
              transcript: {
                $each: [
                  { speaker: "customer", message: userText, timestamp },
                  { speaker: "agent", message: aiResponse, timestamp }
                ]
              }
            }
          }
        ).catch(err => console.error("❌ Failed to update DB:", err));
      }

    } catch (error) {
      console.error("❌ Audio Process Error:", error);
      try {
        const client = getTwilioClient();
        const errorTwiml = new VoiceResponse();
        errorTwiml.say({ voice: "Polly.Joanna-Neural" }, "Sorry, I encountered an internal error.");
        
        const actionUrl = `${process.env.BASE_URL}/api/twilio/process-audio`;
        errorTwiml.record({ action: actionUrl, maxLength: 10 });
        
        await client.calls(callSid).update({ twiml: errorTwiml.toString() });
      } catch (updateError) {
        console.error("❌ Failed to play error message:", updateError);
      }
    }
  })();
};