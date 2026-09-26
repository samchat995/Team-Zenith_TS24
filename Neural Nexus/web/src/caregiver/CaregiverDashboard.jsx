import React, { useState, useEffect } from 'react';
import {
  Users, Calendar, Clock, Bell, Heart, Plus, Trash2, CheckCircle2,
  AlertCircle, BookOpen, Brain, Sparkles, Smile, ShieldAlert
} from 'lucide-react';
import {
  fetchPatients, fetchPatientSummary, fetchPatientSessions,
  fetchReminders, createReminder, updateReminder, deleteReminder,
  fetchMoods, fetchMemoryItems, createMemoryItem
} from '../services/api';

export default function CaregiverDashboard() {
  const [patients, setPatients] = useState([]);
  const [selectedPatientId, setSelectedPatientId] = useState(null);
  const [summary, setSummary] = useState(null);
  const [sessions, setSessions] = useState([]);
  const [reminders, setReminders] = useState([]);
  const [moods, setMoods] = useState([]);
  const [memoryItems, setMemoryItems] = useState([]);
  const [loading, setLoading] = useState(true);

  // New reminder form
  const [showAddReminder, setShowAddReminder] = useState(false);
  const [newReminder, setNewReminder] = useState({
    title: '',
    reminder_type: 'medicine',
    time_of_day: '09:00 AM',
    notes: ''
  });

  // New memory item form
  const [showAddMemory, setShowAddMemory] = useState(false);
  const [newMemory, setNewMemory] = useState({
    title: '',
    category: 'family',
    relationship: '',
    details: ''
  });

  useEffect(() => {
    loadPatients();
  }, []);

  useEffect(() => {
    if (selectedPatientId) {
      loadPatientDetails(selectedPatientId);
    }
  }, [selectedPatientId]);

  async function loadPatients() {
    try {
      const data = await fetchPatients();
      setPatients(data);
      if (data.length > 0) {
        setSelectedPatientId(data[0].id);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }

  async function loadPatientDetails(pid) {
    try {
      const [sum, sess, rems, mds, mems] = await Promise.all([
        fetchPatientSummary(pid),
        fetchPatientSessions(pid),
        fetchReminders(pid),
        fetchMoods(pid),
        fetchMemoryItems(pid)
      ]);
      setSummary(sum);
      setSessions(sess);
      setReminders(rems);
      setMoods(mds);
      setMemoryItems(mems);
    } catch (err) {
      console.error(err);
    }
  }

  async function handleToggleReminder(id, currentCompleted) {
    try {
      await updateReminder(id, { completed: !currentCompleted });
      loadPatientDetails(selectedPatientId);
    } catch (err) {
      alert(err.message);
    }
  }

  async function handleDeleteReminder(id) {
    if (!confirm('Are you sure you want to delete this reminder?')) return;
    try {
      await deleteReminder(id);
      loadPatientDetails(selectedPatientId);
    } catch (err) {
      alert(err.message);
    }
  }

  async function handleCreateReminder(e) {
    e.preventDefault();
    if (!newReminder.title.trim()) return;
    try {
      await createReminder({
        ...newReminder,
        patient_id: selectedPatientId,
        frequency: 'Daily'
      });
      setNewReminder({ title: '', reminder_type: 'medicine', time_of_day: '09:00 AM', notes: '' });
      setShowAddReminder(false);
      loadPatientDetails(selectedPatientId);
    } catch (err) {
      alert(err.message);
    }
  }

  async function handleCreateMemory(e) {
    e.preventDefault();
    if (!newMemory.title.trim() || !newMemory.details.trim()) return;
    try {
      await createMemoryItem({
        ...newMemory,
        patient_id: selectedPatientId
      });
      setNewMemory({ title: '', category: 'family', relationship: '', details: '' });
      setShowAddMemory(false);
      loadPatientDetails(selectedPatientId);
    } catch (err) {
      alert(err.message);
    }
  }

  if (loading) {
    return <div style={{ padding: 40, textAlign: 'center' }}>Loading Caregiver Dashboard...</div>;
  }

  return (
    <div style={{ maxWidth: 1280, margin: '0 auto', padding: '32px 24px' }}>
      {/* Patient Selector Tabs */}
      <div style={{ marginBottom: 24, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <h2 style={{ fontSize: 24, fontWeight: 800, color: '#0F172A' }}>Caregiver Monitoring Center</h2>
          <p style={{ color: '#64748B', fontSize: 14 }}>Daily cognitive progress, reminders, and family memory support.</p>
        </div>
        <div style={{ display: 'flex', gap: 10, background: '#FFFFFF', padding: 6, borderRadius: 14, border: '1px solid #E2E8F0' }}>
          {patients.map((p) => (
            <button
              key={p.id}
              onClick={() => setSelectedPatientId(p.id)}
              style={{
                padding: '8px 18px',
                borderRadius: 10,
                fontWeight: 700,
                fontSize: 14,
                background: selectedPatientId === p.id ? '#2563EB' : 'transparent',
                color: selectedPatientId === p.id ? '#FFFFFF' : '#475569'
              }}
            >
              👴 {p.full_name}
            </button>
          ))}
        </div>
      </div>

      {summary && (
        <>
          {/* Quick Metrics Grid */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: 20, marginBottom: 28 }}>
            <div className="card" style={{ borderLeft: '5px solid #2563EB' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', color: '#64748B', fontSize: 13, fontWeight: 600 }}>
                <span>TODAY'S PROGRESS</span>
                <Sparkles size={18} color="#2563EB" />
              </div>
              <div style={{ fontSize: 32, fontWeight: 800, color: '#0F172A', marginTop: 8 }}>
                {summary.progress_percentage}%
              </div>
              <p style={{ fontSize: 12, color: '#10B981', fontWeight: 600, marginTop: 4 }}>
                {summary.games_completed_today} of {summary.target_games_today} activities completed
              </p>
            </div>

            <div className="card" style={{ borderLeft: '5px solid #F59E0B' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', color: '#64748B', fontSize: 13, fontWeight: 600 }}>
                <span>PENDING REMINDERS</span>
                <Bell size={18} color="#F59E0B" />
              </div>
              <div style={{ fontSize: 32, fontWeight: 800, color: '#0F172A', marginTop: 8 }}>
                {summary.pending_reminders_count}
              </div>
              <p style={{ fontSize: 12, color: '#64748B', marginTop: 4 }}>
                {summary.total_reminders_count} total scheduled
              </p>
            </div>

            <div className="card" style={{ borderLeft: '5px solid #10B981' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', color: '#64748B', fontSize: 13, fontWeight: 600 }}>
                <span>RECENT MOOD</span>
                <Smile size={18} color="#10B981" />
              </div>
              <div style={{ fontSize: 32, fontWeight: 800, color: '#0F172A', marginTop: 8 }}>
                {moods[0]?.mood || 'Calm'}
              </div>
              <p style={{ fontSize: 12, color: '#64748B', marginTop: 4 }}>
                {moods[0]?.note ? `"${moods[0].note.slice(0, 32)}..."` : 'Steady emotional balance'}
              </p>
            </div>

            <div className="card" style={{ borderLeft: '5px solid #8B5CF6' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', color: '#64748B', fontSize: 13, fontWeight: 600 }}>
                <span>TODAY'S ACTIVITY</span>
                <Brain size={18} color="#8B5CF6" />
              </div>
              <div style={{ fontSize: 18, fontWeight: 800, color: '#0F172A', marginTop: 10 }}>
                {summary.today_activity.title}
              </div>
              <p style={{ fontSize: 12, color: '#8B5CF6', fontWeight: 600, marginTop: 4 }}>
                Level {summary.today_activity.recommended_level} Recommended
              </p>
            </div>
          </div>

          {/* AI Non-alarmist Caregiver Alerts */}
          <div style={{ background: '#EFF6FF', border: '1px solid #BFDBFE', borderRadius: 16, padding: '16px 20px', marginBottom: 28, display: 'flex', alignItems: 'center', gap: 14 }}>
            <AlertCircle size={24} color="#2563EB" />
            <div>
              <h4 style={{ fontSize: 14, fontWeight: 700, color: '#1E40AF' }}>Caregiver Routine Check-in Alert</h4>
              <p style={{ fontSize: 13, color: '#1E3A8A', marginTop: 2 }}>
                {summary.today_activity.reason}
              </p>
            </div>
          </div>

          {/* Grid: Reminders and Recent Cognitive Sessions */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24, marginBottom: 28 }}>
            {/* Reminders Manager */}
            <div className="card">
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
                <div>
                  <h3 style={{ fontSize: 17, fontWeight: 700 }}>Reminders for {summary.full_name}</h3>
                  <p style={{ fontSize: 12, color: '#64748B' }}>Medicine, hydration, daily activities, doctor appointments</p>
                </div>
                <button
                  onClick={() => setShowAddReminder(!showAddReminder)}
                  className="btn-primary"
                  style={{ padding: '6px 12px', fontSize: 12 }}
                >
                  <Plus size={14} /> Add Reminder
                </button>
              </div>

              {showAddReminder && (
                <form onSubmit={handleCreateReminder} style={{ background: '#F8FAFC', padding: 16, borderRadius: 12, marginBottom: 16 }}>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 10 }}>
                    <input
                      placeholder="Reminder title (e.g. Afternoon Water)"
                      value={newReminder.title}
                      onChange={(e) => setNewReminder({ ...newReminder, title: e.target.value })}
                      required
                    />
                    <select
                      value={newReminder.reminder_type}
                      onChange={(e) => setNewReminder({ ...newReminder, reminder_type: e.target.value })}
                    >
                      <option value="medicine">💊 Medicine</option>
                      <option value="hydration">💧 Hydration</option>
                      <option value="daily_activity">🌞 Daily Activity</option>
                      <option value="appointment">📅 Appointment</option>
                    </select>
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: 10, marginBottom: 10 }}>
                    <input
                      placeholder="Time (e.g. 03:00 PM)"
                      value={newReminder.time_of_day}
                      onChange={(e) => setNewReminder({ ...newReminder, time_of_day: e.target.value })}
                    />
                    <input
                      placeholder="Optional notes"
                      value={newReminder.notes}
                      onChange={(e) => setNewReminder({ ...newReminder, notes: e.target.value })}
                    />
                  </div>
                  <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
                    <button type="button" onClick={() => setShowAddReminder(false)} style={{ padding: '6px 12px', color: '#64748B', fontSize: 12 }}>Cancel</button>
                    <button type="submit" className="btn-primary" style={{ padding: '6px 14px', fontSize: 12 }}>Save</button>
                  </div>
                </form>
              )}

              <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                {reminders.map((r) => (
                  <div
                    key={r.id}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      padding: '12px 14px',
                      borderRadius: 12,
                      background: r.completed ? '#F1F5F9' : '#FFFFFF',
                      border: '1px solid #E2E8F0'
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                      <button onClick={() => handleToggleReminder(r.id, r.completed)}>
                        <CheckCircle2 size={20} color={r.completed ? '#10B981' : '#94A3B8'} />
                      </button>
                      <div>
                        <span style={{ fontSize: 14, fontWeight: 600, textDecoration: r.completed ? 'line-through' : 'none', color: r.completed ? '#64748B' : '#0F172A' }}>
                          {r.title}
                        </span>
                        <div style={{ fontSize: 11, color: '#64748B', display: 'flex', gap: 8, marginTop: 2 }}>
                          <span>🕒 {r.time_of_day}</span>
                          <span style={{ textTransform: 'capitalize' }}>• {r.reminder_type.replace('_', ' ')}</span>
                          {r.notes && <span>• {r.notes}</span>}
                        </div>
                      </div>
                    </div>
                    <button onClick={() => handleDeleteReminder(r.id)} style={{ color: '#EF4444' }}>
                      <Trash2 size={16} />
                    </button>
                  </div>
                ))}
              </div>
            </div>

            {/* Cognitive Game Sessions History */}
            <div className="card">
              <h3 style={{ fontSize: 17, fontWeight: 700, marginBottom: 4 }}>Recent Cognitive Sessions</h3>
              <p style={{ fontSize: 12, color: '#64748B', marginBottom: 16 }}>Play history & adaptive difficulty changes</p>

              <div style={{ display: 'flex', flexDirection: 'column', gap: 10, maxHeight: 380, overflowY: 'auto' }}>
                {sessions.length === 0 ? (
                  <p style={{ color: '#94A3B8', fontSize: 13, textAlign: 'center', padding: 20 }}>No sessions recorded yet.</p>
                ) : (
                  sessions.map((s) => (
                    <div key={s.id} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 14px', borderRadius: 12, background: '#F8FAFC', border: '1px solid #E2E8F0' }}>
                      <div>
                        <div style={{ fontSize: 14, fontWeight: 700, color: '#0F172A' }}>{s.game_id.replace(/_/g, ' ').toUpperCase()}</div>
                        <div style={{ fontSize: 11, color: '#64748B', marginTop: 2 }}>
                          Level {s.level} • {s.duration_seconds}s • Reaction {s.response_time_ms}ms
                        </div>
                      </div>
                      <div style={{ textAlign: 'right' }}>
                        <span style={{ background: '#DCFCE7', color: '#15803D', padding: '3px 8px', borderRadius: 6, fontSize: 12, fontWeight: 700 }}>
                          {s.accuracy}%
                        </span>
                        <div style={{ fontSize: 11, color: '#64748B', marginTop: 2 }}>{s.score} pts</div>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>

          {/* Memory Items ('My Memory') Manager */}
          <div className="card" style={{ marginBottom: 28 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
              <div>
                <h3 style={{ fontSize: 17, fontWeight: 700 }}>Personalized Memory Profile ("My Memory")</h3>
                <p style={{ fontSize: 12, color: '#64748B' }}>
                  Family members, familiar faces, favorite foods, and comforting memories used in personalized games.
                </p>
              </div>
              <button
                onClick={() => setShowAddMemory(!showAddMemory)}
                className="btn-primary"
                style={{ padding: '6px 12px', fontSize: 12 }}
              >
                <Plus size={14} /> Add Memory Item
              </button>
            </div>

            {showAddMemory && (
              <form onSubmit={handleCreateMemory} style={{ background: '#F8FAFC', padding: 16, borderRadius: 12, marginBottom: 16 }}>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, marginBottom: 10 }}>
                  <input
                    placeholder="Name / Title (e.g. Meena)"
                    value={newMemory.title}
                    onChange={(e) => setNewMemory({ ...newMemory, title: e.target.value })}
                    required
                  />
                  <select
                    value={newMemory.category}
                    onChange={(e) => setNewMemory({ ...newMemory, category: e.target.value })}
                  >
                    <option value="family">👨‍👩‍👧 Family Member</option>
                    <option value="favorite">🍵 Favorite Food / Thing</option>
                    <option value="place">🏡 Familiar Place</option>
                    <option value="routine">🌅 Comfort Routine</option>
                  </select>
                  <input
                    placeholder="Relationship (e.g. Granddaughter)"
                    value={newMemory.relationship}
                    onChange={(e) => setNewMemory({ ...newMemory, relationship: e.target.value })}
                  />
                </div>
                <textarea
                  placeholder="Details (e.g. Loves reading storybooks and bringing marigolds)"
                  value={newMemory.details}
                  onChange={(e) => setNewMemory({ ...newMemory, details: e.target.value })}
                  rows={2}
                  style={{ width: '100%', marginBottom: 10 }}
                  required
                />
                <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
                  <button type="button" onClick={() => setShowAddMemory(false)} style={{ padding: '6px 12px', color: '#64748B', fontSize: 12 }}>Cancel</button>
                  <button type="submit" className="btn-primary" style={{ padding: '6px 14px', fontSize: 12 }}>Save Memory</button>
                </div>
              </form>
            )}

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: 16 }}>
              {memoryItems.map((item) => (
                <div key={item.id} style={{ border: '1px solid #E2E8F0', borderRadius: 14, padding: 16, background: '#FFFFFF' }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <span style={{ fontSize: 11, textTransform: 'uppercase', fontWeight: 700, color: '#2563EB', background: '#EFF6FF', padding: '2px 8px', borderRadius: 6 }}>
                      {item.category}
                    </span>
                    {item.relationship && (
                      <span style={{ fontSize: 12, color: '#64748B', fontWeight: 500 }}>{item.relationship}</span>
                    )}
                  </div>
                  <h4 style={{ fontSize: 16, fontWeight: 700, marginTop: 8, color: '#0F172A' }}>{item.title}</h4>
                  <p style={{ fontSize: 13, color: '#475569', marginTop: 4 }}>{item.details}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Medical Disclaimer */}
          <div style={{ textAlign: 'center', padding: '16px 0', borderTop: '1px solid #E2E8F0', color: '#64748B', fontSize: 12 }}>
            <p><strong>Medical Disclaimer:</strong> Neural Nexus is a cognitive stimulation, memory assistance, and caregiver-support platform. It is not a diagnostic tool and does not replace professional medical evaluation.</p>
          </div>
        </>
      )}
    </div>
  );
}
