CREATE DATABASE bookings;
USE bookings;
  
  CREATE TABLE appointments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  client_name VARCHAR(255) NOT NULL,
  service_name VARCHAR(255),
  start_time DATETIME NOT NULL,
  end_time DATETIME NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO appointments (client_name, service_name, start_time, end_time)
VALUES
  ("Jane Doe", "Consultation", "2026-01-20 10:00:00", "2026-01-20 10:25:00"),
  ("John Smith", "Haircut", "2026-01-21 14:00:00", "2026-01-21 14:25:00"),
  ("Alex Brown", "Coaching Session", "2026-01-22 09:30:00", "2026-01-22 09:55:00");



