import axios from "axios";

const api = axios.create({
  baseURL: "http://localhost:4000",
});

// Fetch all appointments
export const getAppointments = async () => {
  try {
    const res = await api.get("/appointments");
    return res.data;
  } catch (err) {
    console.error(err);
    return [];
  }
};

// Create a new appointment
export const createAppointment = async (appointment) => {
  try {
    const res = await api.post("/appointments", appointment);
    return res.data;
  } catch (err) {
    console.error(err);
    return { error: err.message };
  }
};

export default api;
