const express = require("express");
const cors = require("cors");
const db = require("./db");

const app = express();

const allowedOrigins = [
  "http://localhost:5173",
  process.env.FRONTEND_ORIGIN, // set this on EC2 via env
].filter(Boolean);

app.use(
  cors({
    origin: function (origin, callback) {
      // allow server-to-server/no-origin requests (curl, health checks)
      if (!origin) return callback(null, true);

      if (allowedOrigins.includes(origin)) return callback(null, true);

      return callback(new Error(`CORS blocked for origin: ${origin}`));
    },
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type"],
    credentials: false,
  })
);

app.use(express.json());


// ------------------------
// Helper: ISO → MySQL DATETIME
// ------------------------
const toMySQLDateTime = (isoString) => {
  return new Date(isoString)
    .toISOString()
    .slice(0, 19)
    .replace("T", " ");
};

app.get("/health", (req, res) => {
  res.status(200).send("OK");
});



// ------------------------
// GET all appointments
// ------------------------
app.get("/appointments", async (req, res) => {
  try {
    const [rows] = await db.query(
      "SELECT * FROM appointments ORDER BY start_time"
    );
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
      [
        toMySQLDateTime(end_time),
        toMySQLDateTime(start_time)
      ]
    );

    if (conflicts[0].count > 0) {
      return res.status(400).json({ error: "Time slot already booked" });
    }

    // Insert appointment
    const [result] = await db.query(
      `INSERT INTO appointments (client_name, service_name, start_time, end_time)
       VALUES (?, ?, ?, ?)`,
      [
        client_name,
        service_name,
        toMySQLDateTime(start_time),
        toMySQLDateTime(end_time)
      ]
    );

    res.status(201).json({
      id: result.insertId,
      client_name,
      service_name,
      start_time,
      end_time
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Database error" });
  }
});

// ------------------------
// UPDATE appointment
// ------------------------
app.put("/appointments/:id", async (req, res) => {
  const { id } = req.params;
  const { client_name, service_name, start_time, end_time } = req.body;

  try {
    await db.query(
      `UPDATE appointments
       SET client_name = ?, service_name = ?, start_time = ?, end_time = ?
       WHERE id = ?`,
      [
        client_name,
        service_name,
        toMySQLDateTime(start_time),
        toMySQLDateTime(end_time),
        id
      ]
    );

    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Update failed" });
  }
});

// ------------------------
// DELETE appointment
// ------------------------
app.delete("/appointments/:id", async (req, res) => {
  try {
    await db.query(
      `DELETE FROM appointments WHERE id = ?`,
      [req.params.id]
    );
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Delete failed" });
  }
});

app.get("/db-check", async (req, res) => {
  try {
    const [rows] = await db.query("SELECT 1");
    res.status(200).json({ status: "DB connected", result: rows });
  } catch (err) {
    res.status(500).json({ status: "DB connection failed", error: err.message });
  }
});

module.exports = app;
