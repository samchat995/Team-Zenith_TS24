import React, { useState, useEffect } from 'react';
import { Shield, Users, ListFilter, CheckCircle, Database } from 'lucide-react';
import { fetchAdminUsers, fetchAdminAuditLogs } from '../services/api';

export default function AdminDashboard() {
  const [users, setUsers] = useState([]);
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    try {
      const [u, l] = await Promise.all([fetchAdminUsers(), fetchAdminAuditLogs()]);
      setUsers(u);
      setLogs(l);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }

  if (loading) return <div style={{ padding: 40, textAlign: 'center' }}>Loading Admin Console...</div>;

  return (
    <div style={{ maxWidth: 1280, margin: '0 auto', padding: '32px 24px' }}>
      <div style={{ marginBottom: 28 }}>
        <h2 style={{ fontSize: 24, fontWeight: 800, color: '#0F172A' }}>System Administration Console</h2>
        <p style={{ color: '#64748B', fontSize: 14 }}>User access control, role provisioning, and system audit trails.</p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24 }}>
        {/* Users Table */}
        <div className="card">
          <h3 style={{ fontSize: 17, fontWeight: 700, marginBottom: 16 }}>System Users ({users.length})</h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {users.map(u => (
              <div key={u.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 14px', borderRadius: 10, background: '#F8FAFC', border: '1px solid #E2E8F0' }}>
                <div>
                  <div style={{ fontWeight: 700, fontSize: 14 }}>{u.full_name}</div>
                  <div style={{ fontSize: 12, color: '#64748B' }}>{u.email || u.username}</div>
                </div>
                <span className="badge-role">{u.role}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Audit Logs */}
        <div className="card">
          <h3 style={{ fontSize: 17, fontWeight: 700, marginBottom: 16 }}>Security Audit Trail</h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10, maxHeight: 420, overflowY: 'auto' }}>
            {logs.map(l => (
              <div key={l.id} style={{ padding: '10px 14px', borderRadius: 10, background: '#F8FAFC', border: '1px solid #E2E8F0', fontSize: 12 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontWeight: 600 }}>
                  <span style={{ color: '#2563EB' }}>{l.action}</span>
                  <span style={{ color: '#94A3B8' }}>{new Date(l.timestamp).toLocaleTimeString()}</span>
                </div>
                <p style={{ color: '#475569', marginTop: 4 }}>{l.details || l.resource}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
