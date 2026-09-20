import React from 'react';
import { Activity, LogOut, UserCheck } from 'lucide-react';
import { logout } from '../services/api';

export default function Navbar({ user, onLogout }) {
  return (
    <header style={{
      background: '#FFFFFF',
      borderBottom: '1px solid #E2E8F0',
      padding: '16px 32px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      position: 'sticky',
      top: 0,
      zIndex: 50
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
        <div style={{
          width: 44,
          height: 44,
          borderRadius: 12,
          background: 'linear-gradient(135deg, #0284C7 0%, #10B981 100%)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          color: '#FFFFFF'
        }}>
          <Activity size={24} />
        </div>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <h1 style={{ fontSize: '18px', fontWeight: '800', letterSpacing: '-0.3px', color: '#0F172A' }}>
              NEURAL NEXUS
            </h1>
            <span className="badge-online">🟢 Online & Synced</span>
          </div>
          <p style={{ fontSize: '12px', color: '#64748B', fontWeight: '500' }}>
            Adaptive Cognitive Games + Memory Assistance
          </p>
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
        <div style={{ textAlign: 'right' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', justifyContent: 'flex-end' }}>
            <span style={{ fontSize: '14px', fontWeight: '700', color: '#0F172A' }}>{user.full_name}</span>
            <span className="badge-role">{user.role}</span>
          </div>
          <p style={{ fontSize: '12px', color: '#64748B' }}>Smart India Hackathon 2026</p>
        </div>

        <button
          onClick={() => {
            logout();
            onLogout();
          }}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '6px',
            padding: '8px 14px',
            borderRadius: '10px',
            background: '#F1F5F9',
            color: '#475569',
            fontSize: '13px',
            fontWeight: '600'
          }}
          onMouseOver={(e) => e.currentTarget.style.background = '#E2E8F0'}
          onMouseOut={(e) => e.currentTarget.style.background = '#F1F5F9'}
        >
          <LogOut size={16} />
          Logout
        </button>
      </div>
    </header>
  );
}
