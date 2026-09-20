import React, { useState, useEffect } from 'react';
import Navbar from './components/Navbar';
import CaregiverDashboard from './caregiver/CaregiverDashboard';
import HealthcareDashboard from './healthcare/HealthcareDashboard';
import AdminDashboard from './admin/AdminDashboard';
import { loginStaff, getCurrentUser, logout } from './services/api';
import { Brain, Lock, Mail, Activity, Sparkles } from 'lucide-react';

export default function App() {
  const [currentUser, setCurrentUser] = useState(null);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const user = getCurrentUser();
    if (user) setCurrentUser(user);
  }, []);

  async function handleLogin(e) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const user = await loginStaff(email, password);
      setCurrentUser(user);
    } catch (err) {
      setError(err.message || 'Login failed. Check your credentials.');
    } finally {
      setLoading(false);
    }
  }

  function handleDemoFill(roleEmail, rolePass) {
    setEmail(roleEmail);
    setPassword(rolePass);
    setError('');
  }

  if (!currentUser) {
    return (
      <div style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'linear-gradient(135deg, #EFF6FF 0%, #F0FDF4 100%)',
        padding: 20
      }}>
        <div style={{
          width: '100%',
          maxWidth: 440,
          background: '#FFFFFF',
          borderRadius: 24,
          padding: '40px 32px',
          boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
          border: '1px solid #E2E8F0'
        }}>
          {/* Logo & Header */}
          <div style={{ textAlign: 'center', marginBottom: 28 }}>
            <div style={{
              width: 56,
              height: 56,
              borderRadius: 16,
              background: 'linear-gradient(135deg, #0284C7 0%, #10B981 100%)',
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#FFFFFF',
              marginBottom: 12
            }}>
              <Brain size={32} />
            </div>
            <h1 style={{ fontSize: 24, fontWeight: 800, color: '#0F172A', letterSpacing: '-0.5px' }}>
              NEURAL NEXUS
            </h1>
            <p style={{ fontSize: 13, color: '#64748B', marginTop: 4 }}>
              Caregiver & Healthcare Worker Portal
            </p>
          </div>

          {error && (
            <div style={{ background: '#FEE2E2', border: '1px solid #FECACA', color: '#991B1B', padding: '10px 14px', borderRadius: 10, fontSize: 13, marginBottom: 16 }}>
              {error}
            </div>
          )}

          <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <div>
              <label style={{ display: 'block', fontSize: 12, fontWeight: 700, color: '#475569', marginBottom: 6 }}>
                EMAIL / PROFESSIONAL ID
              </label>
              <div style={{ position: 'relative' }}>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="name@neuralnexus.demo"
                  required
                  style={{ width: '100%', paddingLeft: 36 }}
                />
                <Mail size={16} color="#94A3B8" style={{ position: 'absolute', left: 12, top: 12 }} />
              </div>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: 12, fontWeight: 700, color: '#475569', marginBottom: 6 }}>
                PASSWORD
              </label>
              <div style={{ position: 'relative' }}>
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                  style={{ width: '100%', paddingLeft: 36 }}
                />
                <Lock size={16} color="#94A3B8" style={{ position: 'absolute', left: 12, top: 12 }} />
              </div>
            </div>

            <button type="submit" className="btn-primary" disabled={loading} style={{ justifyContent: 'center', marginTop: 6, padding: '12px' }}>
              {loading ? 'Authenticating...' : 'Sign In to Console →'}
            </button>
          </form>

          {/* Demo Login Quick Selectors */}
          <div style={{ marginTop: 28, borderTop: '1px solid #E2E8F0', paddingTop: 20 }}>
            <span style={{ fontSize: 11, fontWeight: 700, color: '#94A3B8', textTransform: 'uppercase', letterSpacing: 0.5, display: 'block', marginBottom: 10 }}>
              Quick Demo Credentials:
            </span>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              <button
                type="button"
                onClick={() => handleDemoFill('caregiver@neuralnexus.demo', 'Caregiver@123')}
                style={{ padding: '8px 12px', background: '#F8FAFC', borderRadius: 8, fontSize: 12, textAlign: 'left', border: '1px solid #E2E8F0', display: 'flex', justifyContent: 'space-between' }}
              >
                <span>👩👧 <strong>Caregiver</strong> (Ananya)</span>
                <span style={{ color: '#2563EB' }}>Auto-fill</span>
              </button>
              <button
                type="button"
                onClick={() => handleDemoFill('ritasri@neuralnexus.demo', 'Doctor@123')}
                style={{ padding: '8px 12px', background: '#F0FDF4', borderRadius: 8, fontSize: 12, textAlign: 'left', border: '1px solid #BBF7D0', display: 'flex', justifyContent: 'space-between' }}
              >
                <span>🩺 <strong>Healthcare Worker</strong> (Dr. Ritasri)</span>
                <span style={{ color: '#166534' }}>Auto-fill</span>
              </button>
              <button
                type="button"
                onClick={() => handleDemoFill('admin@neuralnexus.demo', 'Admin@123')}
                style={{ padding: '8px 12px', background: '#F8FAFC', borderRadius: 8, fontSize: 12, textAlign: 'left', border: '1px solid #E2E8F0', display: 'flex', justifyContent: 'space-between' }}
              >
                <span>🛡️ <strong>System Admin</strong></span>
                <span style={{ color: '#2563EB' }}>Auto-fill</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      <Navbar user={currentUser} onLogout={() => setCurrentUser(null)} />
      <main style={{ flex: 1 }}>
        {currentUser.role === 'CAREGIVER' && <CaregiverDashboard />}
        {currentUser.role === 'HEALTHCARE_WORKER' && <HealthcareDashboard />}
        {currentUser.role === 'ADMIN' && <AdminDashboard />}
      </main>
    </div>
  );
}
