// backend/app.js
const express = require("express");
const db = require("./db");
const app = express();

app.use(express.json());

// ------------------------
// GET all appointments
// ------------------------
app.get("/appointments", async (req, res) => {
  try {
    const [rows] = await db.query("SELECT * FROM appointments ORDER BY start_time");
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Database error" });
  }
});

// ------------------------
// POST new appointment
// ------------------------
app.post("/appointments", async (req, res) => {
  const { client_name, service_name, start_time, end_time } = req.body;

  if (!client_name || !start_time || !end_time) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  if (new Date(end_time) <= new Date(start_time)) {
    return res.status(400).json({ error: "End time must be after start time" });
  }

  try {
    // Check for overlapping appointments
    const [conflicts] = await db.query(
      `SELECT COUNT(*) AS count
       FROM appointments
       WHERE start_time < ? AND end_time > ?`,
      [end_time, start_time]
    );

    if (conflicts[0].count > 0) {
      return res.status(400).json({ error: "Time slot already booked" });
    }

    // Insert appointment
    const [result] = await db.query(
      `INSERT INTO appointments (client_name, service_name, start_time, end_time)
       VALUES (?, ?, ?, ?)`,
      [client_name, service_name, start_time, end_time]
    );

    res.status(201).json({ id: result.insertId, client_name, service_name, start_time, end_time });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Database error" });
  }
});

module.exports = app;
