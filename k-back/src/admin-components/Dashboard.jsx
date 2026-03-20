import React, { useEffect, useState } from 'react';
import { ApiClient } from 'adminjs';
import { Box, H2, H5, Text, Loader } from '@adminjs/design-system';

const api = new ApiClient();

const StatCard = ({ label, value, sub }) => (
  <Box
    style={{
      background: '#fff',
      borderRadius: 16,
      padding: '24px 28px',
      border: '1px solid #E0E0E0',
      boxShadow: '0 1px 6px rgba(0,0,0,0.05)',
      minWidth: 160,
      flex: '1 1 160px',
    }}
  >
    <Text style={{ color: '#6B6B6B', fontSize: 12, fontWeight: 600, letterSpacing: '0.06em', textTransform: 'uppercase', marginBottom: 8 }}>
      {label}
    </Text>
    <H2 style={{ color: '#1A1A1A', margin: '4px 0', fontSize: 36, fontWeight: 700 }}>
      {value ?? '—'}
    </H2>
    {sub && (
      <Text style={{ color: '#6B6B6B', fontSize: 13, marginTop: 4 }}>{sub}</Text>
    )}
  </Box>
);

const RoleBadge = ({ role, count }) => {
  const colors = {
    appAdmin:    { bg: '#FFF8CC', text: '#C9A200' },
    schoolAdmin: { bg: '#E8F5E9', text: '#2E7D32' },
    teacher:     { bg: '#E3F2FD', text: '#1565C0' },
    parent:      { bg: '#FFF3E0', text: '#E65100' },
    student:     { bg: '#F3E5F5', text: '#6A1B9A' },
  };
  const c = colors[role] || { bg: '#F5F5F5', text: '#6B6B6B' };
  return (
    <Box style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 0', borderBottom: '1px solid #F0F0F0' }}>
      <span style={{ display: 'inline-block', background: c.bg, color: c.text, borderRadius: 999, padding: '3px 12px', fontSize: 12, fontWeight: 600 }}>
        {role}
      </span>
      <Text style={{ fontWeight: 700, color: '#1A1A1A' }}>{count}</Text>
    </Box>
  );
};

const Dashboard = () => {
  const [stats, setStats] = useState(null);
  const [recentUsers, setRecentUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchAll = async () => {
      try {
        const roles = ['appAdmin', 'schoolAdmin', 'teacher', 'parent', 'student'];
        const [usersRes, pendingRes, schoolsRes, codesUnusedRes, codesUsedRes, recentRes, ...roleRes] = await Promise.all([
          api.resourceAction({ resourceId: 'User',   actionName: 'list', params: { perPage: 1, page: 1 } }),
          api.resourceAction({ resourceId: 'User',   actionName: 'list', params: { perPage: 1, page: 1, 'filters.isApproved': 'false' } }),
          api.resourceAction({ resourceId: 'School', actionName: 'list', params: { perPage: 1, page: 1 } }),
          api.resourceAction({ resourceId: 'ActivationCode', actionName: 'list', params: { perPage: 1, page: 1, 'filters.status': 'unused' } }),
          api.resourceAction({ resourceId: 'ActivationCode', actionName: 'list', params: { perPage: 1, page: 1, 'filters.status': 'used' } }),
          api.resourceAction({ resourceId: 'User',   actionName: 'list', params: { perPage: 5, page: 1 } }),
          ...roles.map(role =>
            api.resourceAction({ resourceId: 'User', actionName: 'list', params: { perPage: 1, page: 1, 'filters.role': role } })
          ),
        ]);

        const roleCounts = {};
        roles.forEach((role, i) => {
          roleCounts[role] = roleRes[i].data.meta?.total ?? 0;
        });

        setStats({
          totalUsers:   usersRes.data.meta?.total ?? 0,
          pendingUsers: pendingRes.data.meta?.total ?? 0,
          totalSchools: schoolsRes.data.meta?.total ?? 0,
          unusedCodes:  codesUnusedRes.data.meta?.total ?? 0,
          usedCodes:    codesUsedRes.data.meta?.total ?? 0,
          roleCounts,
        });

        const records = recentRes.data.records || [];
        setRecentUsers(records.map(r => r.params));
      } catch (e) {
        console.error('Dashboard fetch error:', e);
      } finally {
        setLoading(false);
      }
    };
    fetchAll();
  }, []);

  if (loading) {
    return (
      <Box style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 300 }}>
        <Loader />
      </Box>
    );
  }

  const roles = ['appAdmin', 'schoolAdmin', 'teacher', 'parent', 'student'];
  const roleCounts = stats?.roleCounts ?? {};

  return (
    <Box style={{ padding: '32px 40px', background: '#F5F5F5', minHeight: '100vh' }}>

      {/* Header */}
      <Box style={{ marginBottom: 32 }}>
        <H2 style={{ color: '#1A1A1A', fontWeight: 700, marginBottom: 4 }}>Knoty Admin</H2>
        <Text style={{ color: '#6B6B6B' }}>
          {new Date().toLocaleDateString('de-DE', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
        </Text>
      </Box>

      {/* Stat cards */}
      <Box style={{ display: 'flex', gap: 16, flexWrap: 'wrap', marginBottom: 32 }}>
        <StatCard label="Nutzer gesamt"   value={stats?.totalUsers}    sub="alle Rollen" />
        <StatCard label="Ausstehend"      value={stats?.pendingUsers}  sub="warten auf Freischaltung" />
        <StatCard label="Schulen"         value={stats?.totalSchools}  sub="registriert" />
        <StatCard label="Codes verfügbar" value={stats?.unusedCodes}   sub="unbenutzt" />
        <StatCard label="Codes verwendet" value={stats?.usedCodes}     sub="aktiviert" />
      </Box>

      <Box style={{ display: 'flex', gap: 20, flexWrap: 'wrap' }}>

        {/* Role breakdown */}
        <Box style={{ flex: '1 1 260px', background: '#fff', borderRadius: 16, padding: 24, border: '1px solid #E0E0E0', boxShadow: '0 1px 6px rgba(0,0,0,0.05)' }}>
          <H5 style={{ marginBottom: 16, color: '#1A1A1A' }}>Nutzer nach Rolle</H5>
          {roles.map(role => (
            <RoleBadge key={role} role={role} count={roleCounts[role] ?? '—'} />
          ))}
        </Box>

        {/* Recent users */}
        <Box style={{ flex: '2 1 400px', background: '#fff', borderRadius: 16, padding: 24, border: '1px solid #E0E0E0', boxShadow: '0 1px 6px rgba(0,0,0,0.05)' }}>
          <Box style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <H5 style={{ color: '#1A1A1A' }}>Zuletzt registriert</H5>
            <a href="/admin/resources/User" style={{ color: '#E6B800', fontSize: 13, fontWeight: 600, textDecoration: 'none' }}>Alle anzeigen →</a>
          </Box>
          {recentUsers.length === 0
            ? <Text style={{ color: '#6B6B6B' }}>Keine Nutzer gefunden.</Text>
            : recentUsers.map((u, i) => (
              <Box key={u.id || i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 0', borderBottom: '1px solid #F0F0F0' }}>
                <Box>
                  <Text style={{ fontWeight: 600, color: '#1A1A1A', fontSize: 14 }}>{u.firstName} {u.lastName}</Text>
                  <Text style={{ color: '#6B6B6B', fontSize: 12 }}>{u.email}</Text>
                </Box>
                <Box style={{ textAlign: 'right' }}>
                  <span style={{ display: 'inline-block', background: '#FFF8CC', color: '#C9A200', borderRadius: 999, padding: '2px 10px', fontSize: 11, fontWeight: 600, marginBottom: 2 }}>
                    {u.role || 'student'}
                  </span>
                  <Text style={{ color: '#AAAAAA', fontSize: 11 }}>
                    {u.isApproved ? '✓ aktiv' : '⏳ ausstehend'}
                  </Text>
                </Box>
              </Box>
            ))
          }
        </Box>

      </Box>

      {/* Quick links */}
      <Box style={{ display: 'flex', gap: 12, flexWrap: 'wrap', marginTop: 24 }}>
        {[
          { label: '+ Schule erstellen',  href: '/admin/resources/School/actions/new' },
          { label: '+ Klasse erstellen',  href: '/admin/resources/SchoolClass/actions/new' },
          { label: 'Ausstehende Nutzer',  href: '/admin/resources/User?filters.isApproved=false' },
          { label: 'Aktivierungscodes',   href: '/admin/resources/ActivationCode' },
          { label: 'Gesperrte E-Mails',   href: '/admin/resources/BannedEmail' },
          { label: 'Login-Protokoll',     href: '/admin/resources/LoginHistory' },
        ].map(l => (
          <a key={l.href} href={l.href} style={{
            background: '#fff', border: '1px solid #E0E0E0', borderRadius: 24,
            padding: '8px 18px', fontSize: 13, fontWeight: 600, color: '#1A1A1A',
            textDecoration: 'none', boxShadow: '0 1px 4px rgba(0,0,0,0.04)',
          }}>
            {l.label}
          </a>
        ))}
      </Box>

    </Box>
  );
};

export default Dashboard;
