import express from "express";
import Call from "../models/Call.js";
const router = express.Router();

// Real dynamic data from the database
router.get("/weekly-calls", async (req, res) => {
  try {
    const today = new Date();
    
    // Calculate the Monday of the current week
    const currentDayOfWeek = today.getDay(); // 0 = Sunday, 1 = Monday
    const distanceToMonday = (currentDayOfWeek + 6) % 7; 
    
    const monday = new Date(today);
    monday.setDate(today.getDate() - distanceToMonday);
    monday.setHours(0, 0, 0, 0);

    const sunday = new Date(monday);
    sunday.setDate(monday.getDate() + 6);
    sunday.setHours(23, 59, 59, 999);

    const calls = await Call.find({
      userId: req.userId,
      createdAt: { $gte: monday, $lte: sunday }
    });

    const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    const outputDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    
    const result = {};
    outputDays.forEach(day => result[day] = 0);

    calls.forEach(call => {
      if (call.createdAt) {
        const dayName = days[new Date(call.createdAt).getDay()];
        if (result[dayName] !== undefined) {
            result[dayName]++;
        }
      }
    });

    const data = outputDays.map(dayName => ({ day: dayName, calls: result[dayName] }));

    res.json(data);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;