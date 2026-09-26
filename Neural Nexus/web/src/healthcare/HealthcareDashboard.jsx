import React, { useState, useEffect } from 'react';
import {
  Stethoscope, FileText, Activity, AlertCircle, Plus, CheckCircle,
  Brain, User, Clock, ChevronRight, Download, ShieldCheck
} from 'lucide-react';
import {
  fetchAssignedPatientsHW, fetchCognitiveOverview, addProfessionalNote,
  addFollowUp, fetchPatientReport
} from '../services/api';

export default function HealthcareDashboard() {
  const [patients, setPatients] = useState([]);
  const [selectedPatientId, setSelectedPatientId] = useState(null);
  const [overview, setOverview] = useState(null);
  const [report, setReport] = useState(null);
  const [loading, setLoading] = useState(true);

  // New professional note form
  const [newNote, setNewNote] = useState({
    note_text: '',
    clinical_observation: ''
  });

  // New follow-up recommendation form
  const [newFollowUp, setNewFollowUp] = useState({
    recommendation_text: '',
    priority: 'Normal'
  });

  useEffect(() => {
    loadPatients();
  }, []);

  useEffect(() => {
    if (selectedPatientId) {
      loadOverview(selectedPatientId);
    }
  }, [selectedPatientId]);

  async function loadPatients() {
    try {
      const data = await fetchAssignedPatientsHW();
      setPatients(data);
      if (data.length > 0) {
        setSelectedPatientId(data[0].patient_id);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }

  async function loadOverview(pid) {
    try {
      const data = await fetchCognitiveOverview(pid);
      setOverview(data);
      setReport(null);
    } catch (err) {
      console.error(err);
    }
  }

  async function handleAddNote(e) {
    e.preventDefault();
    if (!newNote.note_text.trim()) return;
    try {
      await addProfessionalNote({
        patient_id: selectedPatientId,
        worker_name: 'Dr. Ritasri',
        note_text: newNote.note_text,
        clinical_observation: newNote.clinical_observation
      });
      setNewNote({ note_text: '', clinical_observation: '' });
      loadOverview(selectedPatientId);
    } catch (err) {
      alert(err.message);
    }
  }

  async function handleAddFollowUp(e) {
    e.preventDefault();
    if (!newFollowUp.recommendation_text.trim()) return;
    try {
      await addFollowUp({
        patient_id: selectedPatientId,
        recommendation_text: newFollowUp.recommendation_text,
        priority: newFollowUp.priority
      });
      setNewFollowUp({ recommendation_text: '', priority: 'Normal' });
      loadOverview(selectedPatientId);
    } catch (err) {
      alert(err.message);
    }
  }

  async function handleGenerateReport() {
    try {
      const rep = await fetchPatientReport(selectedPatientId);
      setReport(rep);
    } catch (err) {
      alert(err.message);
    }
  }

  if (loading) {
    return <div style={{ padding: 40, textAlign: 'center' }}>Loading Healthcare Worker Dashboard...</div>;
  }

  const selectedPatientInfo = patients.find(p => p.patient_id === selectedPatientId);

  return (
    <div style={{ maxWidth: 1280, margin: '0 auto', padding: '32px 24px' }}>
      {/* Top Banner */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 28 }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <span style={{ background: '#DCFCE7', color: '#166534', padding: '4px 10px', borderRadius: 8, fontSize: 12, fontWeight: 700 }}>
              CLINICAL PORTAL
            </span>
            <h2 style={{ fontSize: 24, fontWeight: 800, color: '#0F172A' }}>
              Healthcare Worker Console — Dr. Ritasri
            </h2>
          </div>
          <p style={{ color: '#64748B', fontSize: 14, marginTop: 4 }}>
            Guwahati Regional Health Centre • Geriatric Cognitive & Memory Monitoring
          </p>
        </div>

        <button onClick={handleGenerateReport} className="btn-primary">
          <FileText size={16} /> Generate Summary Report
        </button>
      </div>

      {/* Patient Selector */}
      <div style={{ display: 'flex', gap: 12, marginBottom: 24 }}>
        {patients.map(p => (
          <button
            key={p.patient_id}
            onClick={() => setSelectedPatientId(p.patient_id)}
            style={{
              flex: 1,
              padding: '16px 20px',
              borderRadius: 16,
              background: selectedPatientId === p.patient_id ? '#EFF6FF' : '#FFFFFF',
              border: selectedPatientId === p.patient_id ? '2px solid #2563EB' : '1px solid #E2E8F0',
              textAlign: 'left',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center'
            }}
          >
            <div>
              <div style={{ fontSize: 16, fontWeight: 800, color: '#0F172A' }}>{p.full_name}</div>
              <div style={{ fontSize: 12, color: '#64748B', marginTop: 2 }}>
                Age: {p.age} • Adherence: <strong style={{ color: '#10B981' }}>{p.adherence_rate}%</strong>
              </div>
            </div>
            <ChevronRight size={18} color={selectedPatientId === p.patient_id ? '#2563EB' : '#94A3B8'} />
          </button>
        ))}
      </div>

      {/* Generated Report View Modal/Card */}
      {report && (
        <div className="card" style={{ marginBottom: 28, background: '#F8FAFC', border: '2px solid #3B82F6' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
            <h3 style={{ fontSize: 18, fontWeight: 800, color: '#1E3A8A' }}>{report.report_title}</h3>
            <button onClick={() => setReport(null)} style={{ color: '#64748B', fontSize: 13 }}>Close</button>
          </div>
          <div style={{ fontSize: 13, color: '#475569', marginBottom: 12 }}>
            <strong>Patient:</strong> {report.patient.name} (Age {report.patient.age}, {report.patient.gender}) • <strong>Generated By:</strong> {report.generated_by}
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 16, marginBottom: 16, background: '#FFFFFF', padding: 16, borderRadius: 12 }}>
            <div>
              <div style={{ fontSize: 12, color: '#64748B' }}>Total Cognitive Sessions</div>
              <div style={{ fontSize: 20, fontWeight: 800 }}>{report.summary_metrics.total_cognitive_sessions}</div>
            </div>
            <div>
              <div style={{ fontSize: 12, color: '#64748B' }}>Average Accuracy</div>
              <div style={{ fontSize: 20, fontWeight: 800, color: '#2563EB' }}>{report.summary_metrics.average_accuracy}</div>
            </div>
            <div>
              <div style={{ fontSize: 12, color: '#64748B' }}>Reminder Adherence</div>
              <div style={{ fontSize: 20, fontWeight: 800, color: '#10B981' }}>{report.summary_metrics.reminder_adherence}</div>
            </div>
          </div>
          <p style={{ fontSize: 12, color: '#64748B', fontStyle: 'italic' }}>{report.disclaimer}</p>
        </div>
      )}

      {overview && (
        <>
          {/* Cognitive Domain Breakdown Radar/Bar Grid */}
          <div className="card" style={{ marginBottom: 28 }}>
            <h3 style={{ fontSize: 18, fontWeight: 800, marginBottom: 4 }}>Cognitive Engagement Breakdown</h3>
            <p style={{ fontSize: 13, color: '#64748B', marginBottom: 20 }}>
              Performance stability across memory, attention, pattern recognition, and routine recall.
            </p>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 16 }}>
              {Object.entries(overview.domain_analysis.domains).map(([domain, d]) => (
                <div key={domain} style={{ border: '1px solid #E2E8F0', borderRadius: 14, padding: 16, background: '#F8FAFC' }}>
                  <div style={{ textTransform: 'capitalize', fontWeight: 700, fontSize: 14, color: '#0F172A', display: 'flex', justifyContent: 'space-between' }}>
                    <span>{domain}</span>
                    <span style={{ color: '#2563EB' }}>{d.avg_accuracy}%</span>
                  </div>
                  <div style={{ height: 8, background: '#E2E8F0', borderRadius: 4, margin: '10px 0', overflow: 'hidden' }}>
                    <div style={{ width: `${d.avg_accuracy}%`, height: '100%', background: '#2563EB', borderRadius: 4 }} />
                  </div>
                  <div style={{ fontSize: 11, color: '#64748B' }}>
                    {d.total_sessions} sessions • Consistency {d.consistency}%
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Grid: Caregiver Notes & Professional Notes */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24, marginBottom: 28 }}>
            {/* Caregiver Notes Review */}
            <div className="card">
              <h3 style={{ fontSize: 17, fontWeight: 700, marginBottom: 4 }}>Caregiver Observations</h3>
              <p style={{ fontSize: 12, color: '#64748B', marginBottom: 16 }}>Notes submitted by family and caregivers</p>

              <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                {overview.caregiver_notes.length === 0 ? (
                  <p style={{ color: '#94A3B8', fontSize: 13 }}>No caregiver notes recorded.</p>
                ) : (
                  overview.caregiver_notes.map((n) => (
                    <div key={n.id} style={{ background: '#F8FAFC', padding: 14, borderRadius: 12, border: '1px solid #E2E8F0' }}>
                      <p style={{ fontSize: 14, color: '#1E293B' }}>"{n.note_text}"</p>
                      <span style={{ fontSize: 11, color: '#94A3B8', display: 'block', marginTop: 6 }}>
                        {new Date(n.created_at).toLocaleDateString()}
                      </span>
                    </div>
                  ))
                )}
              </div>
            </div>

            {/* Dr. Ritasri's Professional Notes */}
            <div className="card">
              <h3 style={{ fontSize: 17, fontWeight: 700, marginBottom: 4 }}>Professional Notes by Dr. Ritasri</h3>
              <p style={{ fontSize: 12, color: '#64748B', marginBottom: 16 }}>Clinical follow-up entries and observations</p>

              <form onSubmit={handleAddNote} style={{ marginBottom: 16 }}>
                <textarea
                  placeholder="Professional note / consultation summary..."
                  value={newNote.note_text}
                  onChange={(e) => setNewNote({ ...newNote, note_text: e.target.value })}
                  rows={2}
                  style={{ width: '100%', marginBottom: 8 }}
                  required
                />
                <input
                  placeholder="Clinical observation (e.g. Calm response, good recall)"
                  value={newNote.clinical_observation}
                  onChange={(e) => setNewNote({ ...newNote, clinical_observation: e.target.value })}
                  style={{ width: '100%', marginBottom: 8 }}
                />
                <div style={{ textAlign: 'right' }}>
                  <button type="submit" className="btn-primary" style={{ padding: '6px 14px', fontSize: 12 }}>
                    <Plus size={14} /> Add Note
                  </button>
                </div>
              </form>

              <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                {overview.professional_notes.map((n) => (
                  <div key={n.id} style={{ background: '#F0FDF4', padding: 14, borderRadius: 12, border: '1px solid #BBF7D0' }}>
                    <div style={{ fontSize: 12, fontWeight: 700, color: '#166534' }}>{n.worker_name}</div>
                    <p style={{ fontSize: 13, color: '#14532D', marginTop: 4 }}>{n.note_text}</p>
                    {n.clinical_observation && (
                      <p style={{ fontSize: 12, color: '#15803D', fontStyle: 'italic', marginTop: 2 }}>
                        Obs: {n.clinical_observation}
                      </p>
                    )}
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Follow-up Recommendations */}
          <div className="card" style={{ marginBottom: 28 }}>
            <h3 style={{ fontSize: 17, fontWeight: 700, marginBottom: 4 }}>Follow-up Recommendations</h3>
            <p style={{ fontSize: 12, color: '#64748B', marginBottom: 16 }}>Actionable guidance for caregivers and home environment</p>

            <form onSubmit={handleAddFollowUp} style={{ display: 'flex', gap: 12, marginBottom: 16 }}>
              <input
                placeholder="Recommendation (e.g. Schedule weekly family photo recall)..."
                value={newFollowUp.recommendation_text}
                onChange={(e) => setNewFollowUp({ ...newFollowUp, recommendation_text: e.target.value })}
                style={{ flex: 1 }}
                required
              />
              <select
                value={newFollowUp.priority}
                onChange={(e) => setNewFollowUp({ ...newFollowUp, priority: e.target.value })}
                style={{ width: 140 }}
              >
                <option value="Routine">Routine</option>
                <option value="Normal">Normal</option>
                <option value="Priority">Priority</option>
              </select>
              <button type="submit" className="btn-primary" style={{ padding: '8px 16px', fontSize: 13 }}>
                Submit
              </button>
            </form>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {overview.follow_up_recommendations.map((f) => (
                <div key={f.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 16px', borderRadius: 12, background: '#F8FAFC', border: '1px solid #E2E8F0' }}>
                  <div>
                    <span style={{ fontSize: 14, color: '#0F172A', fontWeight: 600 }}>{f.recommendation_text}</span>
                    <span style={{ fontSize: 11, color: '#64748B', marginLeft: 10 }}>Status: {f.status}</span>
                  </div>
                  <span style={{
                    fontSize: 11,
                    fontWeight: 700,
                    padding: '3px 8px',
                    borderRadius: 6,
                    background: f.priority === 'Priority' ? '#FEE2E2' : '#EFF6FF',
                    color: f.priority === 'Priority' ? '#991B1B' : '#1E40AF'
                  }}>
                    {f.priority}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </>
      )}

      {/* Medical Disclaimer */}
      <div style={{ textAlign: 'center', padding: '16px 0', borderTop: '1px solid #E2E8F0', color: '#64748B', fontSize: 12 }}>
        <p><strong>Medical Safety Notice:</strong> Neural Nexus supports cognitive engagement and caregiver monitoring. It is not a clinical diagnostic tool and does not generate automated dementia diagnoses.</p>
      </div>
    </div>
  );
}
