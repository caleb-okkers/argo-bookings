<template>
  <div>
    <h1>Appointments</h1>

    <ul>
      <li v-for="a in appointments" :key="a.id">
        {{ a.client_name }} — {{ a.service_name }}
      </li>
    </ul>
  </div>
</template>

<script setup>
import { onMounted, ref } from "vue";
import api from "@/services/api";

const appointments = ref([]);

onMounted(async () => {
  const res = await api.get("/appointments");
  appointments.value = res.data;
});
</script>

