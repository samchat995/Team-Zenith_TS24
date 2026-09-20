/**
 * API service for Neural Nexus Web Dashboards.
 */
const API_BASE = 'http://127.0.0.1:8000';

export function getAuthHeaders() {
  const token = localStorage.getItem('nn_token');
  return {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {})
  };
}

export async function loginStaff(email, password) {
  const res = await fetch(`${API_BASE}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });
  if (!res.ok) {
    const err = await res.json();
    throw new Error(err.detail || 'Login failed');
  }
  const data = await res.json();
  localStorage.setItem('nn_token', data.access_token);
  localStorage.setItem('nn_user', JSON.stringify(data));
  return data;
}

export function logout() {
  localStorage.removeItem('nn_token');
  localStorage.removeItem('nn_user');
}

export function getCurrentUser() {
  const user = localStorage.getItem('nn_user');
  return user ? JSON.parse(user) : null;
}

export async function fetchPatients() {
  const res = await fetch(`${API_BASE}/patients`, { headers: getAuthHeaders() });
  if (!res.ok) throw new Error('Failed to fetch patients');
  return res.json();
}

export async function fetchPatientSummary(patientId) {
  const res = await fetch(`${API_BASE}/patients/${patientId}/dashboard-summary`, { headers: getAuthHeaders() });
  if (!res.ok) throw new Error('Failed to fetch summary');
  return res.json();
}

export async function fetchPatientSessions(patientId) {
  const res = await fetch(`${API_BASE}/games/patient/${patientId}/sessions`, { headers: getAuthHeaders() });
  if (!res.ok) throw new Error('Failed to fetch game sessions');
  return res.json();
}

export async function fetchReminders(patientId) {
  const res = await fetch(`${API_BASE}/reminders?patient_id=${patientId}`, { headers: getAuthHeaders() });
  if (!res.ok) throw new Error('Failed to fetch reminders');
  return res.json();
}

export async function createReminder(reminder) {
  const res = await fetch(`${API_BASE}/reminders`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify(reminder)
  });
  if (!res.ok) throw new Error('Failed to create reminder');
  return res.json();
}

export async function updateReminder(id, updates) {
  const res = await fetch(`${API_BASE}/reminders/${id}`, {
    method: 'PUT',
    headers: getAuthHeaders(),
    body: JSON.stringify(updates)
  });
  if (!res.ok) throw new Error('Failed to update reminder');
  return res.json();
}

export async function deleteReminder(id) {
  const res = await fetch(`${API_BASE}/reminders/${id}`, {
    method: 'DELETE',
    headers: getAuthHeaders()
  });
  if (!res.ok) throw new Error('Failed to delete reminder');
  return res.json();
}

export async function fetchMoods(patientId) {
  const res = await fetch(`${API_BASE}/mood?patient_id=${patientId}`, { headers: getAuthHeaders() });
  if (!res.ok) throw new Error('Failed to fetch mood logs');
  return res.json();
}

export async function fetchMemoryItems(patientId) {
  const res = await fetch(`${API_BASE}/memory?patient_id=${patientId}`, { headers: getAuthHeaders() });
  if (!res.ok) throw new Error('Failed to fetch memory items');
  return res.json();
}

export async function createMemoryItem(item) {
  const res = await fetch(`${API_BASE}/memory`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify(item)
  });
  if (!res.ok) throw new Error('Failed to create memory item');
  return res.json();
}

// Healthcare Worker (Dr. Ritasri) Endpoints
export async function fetchAssignedPatientsHW() {
  const res = await fetch(`${API_BASE}/healthcare/assigned-patients`, { headers: getAuthHeaders() });
  if (!res.ok) throw new Error('Failed to fetch assigned patients');
  return res.json();
}

export async function fetchCognitiveOverview(patientId) {
  const res = await fetch(`${API_BASE}/healthcare/patient/${patientId}/cognitive-overview`, { headers: getAuthHeaders() });
  if (!res.ok) throw new Error('Failed to fetch cognitive overview');
  return res.json();
}

export async function addProfessionalNote(note) {
  const res = await fetch(`${API_BASE}/healthcare/professional-note`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify(note)
  });
  if (!res.ok) throw new Error('Failed to add note');
  return res.json();
}

export async function addFollowUp(rec) {
  const res = await fetch(`${API_BASE}/healthcare/follow-up`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify(rec)
  });
  if (!res.ok) throw new Error('Failed to submit follow-up');
  return res.json();
}

export async function fetchPatientReport(patientId) {
  const res = await fetch(`${API_BASE}/healthcare/patient/${patientId}/report`, { headers: getAuthHeaders() });
  if (!res.ok) throw new Error('Failed to generate report');
  return res.json();
}

// Admin Endpoints
export async function fetchAdminUsers() {
  const res = await fetch(`${API_BASE}/admin/users`, { headers: getAuthHeaders() });
  if (!res.ok) throw new Error('Failed to fetch users');
  return res.json();
}

export async function fetchAdminAuditLogs() {
  const res = await fetch(`${API_BASE}/admin/audit-logs`, { headers: getAuthHeaders() });
  if (!res.ok) throw new Error('Failed to fetch audit logs');
  return res.json();
}
