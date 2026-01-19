<template>
  <div class="app">
    <!-- Header -->
    <header class="header">
      <h1>⚡Quickbook</h1>
      <p class="subtitle">Simple appointment booking</p>
    </header>

    <!-- Appointments -->
    <section class="appointments">

      <button class="add-btn" @click="openCreateModal">
  + Add Booking
</button>


      <h2>Upcoming Appointments</h2>

      <p v-if="appointments.length === 0" class="empty">
        No appointments booked yet.
      </p>

     <div class="cards">
      <div class="card" v-for="appt in appointments" :key="appt.id">
  <h3>{{ appt.client_name }}</h3>
  <p class="service">{{ appt.service_name }}</p>

  <p class="time">
    {{ formatDate(appt.start_time) }} <br />
    <span class="weekday">{{ formatWeekday(appt.start_time) }}</span><br />
    {{ formatTime(appt.start_time) }} – {{ formatTime(appt.end_time) }}
  </p>

  <div class="card-actions">
<button class="edit" @click="openEditModal(appt)">Edit</button>
<button class="delete" @click="deleteAppointment(appt.id)">Cancel</button>

  </div>
</div>
</div>

    </section>

    <!-- Booking Form -->
    <!-- <section class="form-section">
      <h2>Book New Appointment</h2>

      <form @submit.prevent="submitAppointment" class="form">

        <input v-model="newAppointment.client_name" placeholder="Client Name" required />
        <input v-model="newAppointment.service_name" placeholder="Service Name" required />
        <input type="datetime-local" v-model="newAppointment.start_time" required />
        <input type="datetime-local" v-model="newAppointment.end_time" required />
        
        <button type="submit">
          {{ editingId ? "Update Appointment" : "Book Appointment" }}
        </button>
        
      </form>
    </section> -->

      <div v-if="showCreateModal" class="modal-overlay">
  <div class="modal">
    <h2>New Appointment</h2>

    <form @submit.prevent="createAppointment">
      <label>
        Client
        <input v-model="newAppointment.client_name" required />
      </label>

      <label>
        Service
        <input v-model="newAppointment.service_name" required />
      </label>

      <label>
        Start
        <input type="datetime-local" v-model="newAppointment.start_time" required />
      </label>

      <label>
        End
        <input type="datetime-local" v-model="newAppointment.end_time" required />
      </label>

      <div class="modal-actions">
        <button type="button" class="cancel" @click="closeCreateModal">
          Close
        </button>
        <button type="submit" class="save">
          Book
        </button>
      </div>
    </form>
  </div>
</div>


<div v-if="showEditModal" class="modal-overlay">
  <div class="modal">
    <h2>Edit Appointment</h2>

    <form @submit.prevent="updateAppointment">
      <label>
        Client
        <input v-model="editingAppointment.client_name" required />
      </label>

      <label>
        Service
        <input v-model="editingAppointment.service_name" required />
      </label>

      <label>
        Start
        <input type="datetime-local" v-model="editingAppointment.start_time" required />
      </label>

      <label>
        End
        <input type="datetime-local" v-model="editingAppointment.end_time" required />
      </label>

      <div class="modal-actions">
        <button type="button" class="cancel" @click="closeEditModal">
          Close
        </button>
        <button type="submit" class="save">
          Update
        </button>
      </div>
    </form>
  </div>
</div>

<div v-if="showDeleteModal" class="modal-overlay">
  <div class="modal">
    <h2>Cancel Appointment</h2>

    <p style="margin-top: 0.5rem; color: #555;">
      Are you sure you want to cancel this appointment?
    </p>

    <div class="modal-actions">
      <button class="cancel" @click="cancelDelete">
        No, keep it
      </button>
      <button class="save" @click="confirmDelete">
        Yes, cancel
      </button>
    </div>
  </div>
</div>


  </div>

  
</template>

<script setup>
import { ref, onMounted } from "vue";
import api from "@/services/api";

const appointments = ref([]);

const editingId = ref(null);

const showEditModal = ref(false);
const editingAppointment = ref(null);

const showCreateModal = ref(false);

const openCreateModal = () => {
  newAppointment.value = {
    client_name: "",
    service_name: "",
    start_time: "",
    end_time: ""
  };
  showCreateModal.value = true;
};

const closeCreateModal = () => {
  showCreateModal.value = false;
};


const createAppointment = async () => {
  const payload = {
    client_name: newAppointment.value.client_name,
    service_name: newAppointment.value.service_name,
    start_time: new Date(newAppointment.value.start_time).toISOString(),
    end_time: new Date(newAppointment.value.end_time).toISOString()
  };

  await api.post("/appointments", payload);

  closeCreateModal();
  fetchAppointments();
};




const newAppointment = ref({
  client_name: "",
  service_name: "",
  start_time: "",
  end_time: ""
});

const fetchAppointments = async () => {
  const res = await api.get("/appointments");
  appointments.value = res.data;
};

onMounted(fetchAppointments);

const submitAppointment = async () => {
  if (editingId.value) {
    await api.put(`/appointments/${editingId.value}`, newAppointment.value);
    editingId.value = null;
  } else {
    await api.post("/appointments", newAppointment.value);
  }

  newAppointment.value = {
    client_name: "",
    service_name: "",
    start_time: "",
    end_time: ""
  };

  fetchAppointments();
};

const startEdit = (appt) => {
  editingId.value = appt.id;
  newAppointment.value = {
    client_name: appt.client_name,
    service_name: appt.service_name,
    start_time: appt.start_time.slice(0, 16),
    end_time: appt.end_time.slice(0, 16)
  };

  window.scrollTo({ top: document.body.scrollHeight, behavior: "smooth" });
};

const deleteAppointment = async (id) => {
  deleteId.value = id;
  showDeleteModal.value = true;
};

const confirmDelete = async () => {
  await api.delete(`/appointments/${deleteId.value}`);
  showDeleteModal.value = false;
  deleteId.value = null;
  fetchAppointments();
};

const cancelDelete = () => {
  showDeleteModal.value = false;
  deleteId.value = null;
};



const openEditModal = (appt) => {
  editingAppointment.value = {
    id: appt.id,
    client_name: appt.client_name,
    service_name: appt.service_name,
    start_time: appt.start_time.slice(0, 16),
    end_time: appt.end_time.slice(0, 16)
  };

  showEditModal.value = true;
};

const closeEditModal = () => {
  showEditModal.value = false;
  editingAppointment.value = null;
};

const updateAppointment = async () => {
  const payload = {
    client_name: editingAppointment.value.client_name,
    service_name: editingAppointment.value.service_name,
    start_time: new Date(editingAppointment.value.start_time).toISOString(),
    end_time: new Date(editingAppointment.value.end_time).toISOString()
  };

  await api.put(`/appointments/${editingAppointment.value.id}`, payload);

  closeEditModal();
  fetchAppointments();
};




const formatDate = (date) =>
  new Date(date).toLocaleDateString();

const formatTime = (date) =>
  new Date(date).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });

  const formatWeekday = (date) =>
  new Date(date).toLocaleDateString(undefined, { weekday: "long" });


const showDeleteModal = ref(false);
const deleteId = ref(null);

</script>

<style>
* {
  box-sizing: border-box;
  font-family: Inter, system-ui, sans-serif;
}

body {
  margin: 0;
  background: #f5f7fa;
    overflow-x: hidden;
}


.app {

  margin: auto;
  padding: 2rem;
}

/* Header */
.header {
  text-align: center;
  margin-bottom: 3rem;
}

.header h1 {
  font-size: 3rem;
  margin: 0;
  font-weight: bold;
  color: rgb(33, 33, 33);
}

.subtitle {
  color: #666;
  font-size: 1.1rem;
}

/* Appointments */

.appointments {
  width: 100%;
}

.appointments h2 {
  margin-bottom: 2rem;
  font-weight: 700;
  color: rgb(33, 33, 33);
}


.cards {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

/* Desktop slider */
@media (min-width: 768px) {
  .cards {
    flex-direction: row;
    gap: 1.25rem;
    overflow-x: auto;
    padding-bottom: 0.5rem;

    scroll-snap-type: x mandatory;
    -webkit-overflow-scrolling: touch;
  }
}

/* Hide scrollbar */
.cards::-webkit-scrollbar {
  display: none;
}

.cards {
  scrollbar-width: none; /* Firefox */
}


.card {
  background: white;
  padding: 1.5rem;
  border-radius: 12px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.05);
}

/* Desktop card sizing */
@media (min-width: 768px) {
  .card {
    min-width: 280px;
    flex-shrink: 0;
    scroll-snap-align: start;
  }
}


.card h3 {
  margin: 0;
  color: rgb(33, 33, 33);
}

.service {
  color: rgb(33, 33, 33);
  font-weight: 700;
}

.time {
  margin-top: 0.5rem;
  color: #555;
}

.empty {
  color: #777;
}

/* Form */
.form-section {
  margin-top: 4rem;
}

.form-section h2 {
  font-weight: 700;
  color: rgb(33, 33, 33);
  margin-bottom: 1rem;
}



.form {
  display: grid;
  gap: 1rem;
  max-width: 400px;
}

.form input {
  padding: 0.75rem;
  border-radius: 8px;
  border: 1px solid #ddd;
}

.form button {
  padding: 0.75rem;
  background: rgb(33, 33, 33);
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: bold;
  cursor: pointer;
}

.form button:hover {
  background: rgb(55, 55, 55);
}

@media (min-width: 768px) {
  .cards {
    flex-direction: row;
    overflow-x: auto;
  }

  .card {
    min-width: 280px;
    flex-shrink: 0;
  }
}


.appointments {
  position: relative;
}

@media (min-width: 768px) {
  .appointments::after {
    content: "";
    position: absolute;
    right: 0;
    top: 3rem;
    width: 40px;
    height: calc(100% - 3rem);
    background: linear-gradient(to right, transparent, #f5f7fa);
    pointer-events: none;
  }
}


.card-actions {
  display: flex;
  gap: 0.5rem;
  margin-top: 1rem;
}

.card-actions button {
  flex: 1;
  padding: 0.5rem;
  border-radius: 6px;
  border: none;
  cursor: pointer;
  font-size: 0.85rem;
}

.card-actions .edit {
  background: #e5e7eb;
}

.card-actions .delete {
  background: rgb(33, 33, 33);
  color: #ffffff;
}

.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background: white;
  padding: 1.5rem;
  width: 100%;
  max-width: 420px;
  border-radius: 12px;
}

.modal label {
  display: block;
  margin-bottom: 0.75rem;
  font-size: 0.85rem;
}

.modal input {
  width: 100%;
  padding: 0.5rem;
  margin-top: 0.25rem;
}

.modal-actions {
  display: flex;
  gap: 0.75rem;
  margin-top: 1rem;
}

.modal-actions .cancel {
  flex: 1;
  background: #e5e7eb;
    border-radius: 8px;
  font-weight: bold;
  cursor: pointer;
    margin-bottom: 1rem;
  padding: 0.6rem 1rem;
    border: none;
}

.modal-actions .save {
  flex: 1;
  background: rgb(33, 33, 33);
  color: white;
    border-radius: 8px;
  font-weight: bold;
  cursor: pointer;
    margin-bottom: 1rem;
  padding: 0.6rem 1rem;
    border: none;
}

/* create booking modal */

.add-btn {
  margin-bottom: 3rem;
  padding: 0.8rem 1.5rem;
  background: rgb(237, 111, 22);
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: bold;
  cursor: pointer;
  font-size: 1rem;
}

</style>
