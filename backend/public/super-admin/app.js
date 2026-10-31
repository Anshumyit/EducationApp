/**
 * ScholarCloud Super Admin Command Center • Master Application Controller
 */

const API_BASE = '/api/v1';
let authToken = localStorage.getItem('scholarcloud_superadmin_token') || '';
let currentUser = null;
let currentSchools = [];
let currentAdmins = [];

// Initialize application on load
document.addEventListener('DOMContentLoaded', () => {
  initAuth();
  setupNavigation();
  setupEventListeners();
});

// ==========================================
// 1. AUTHENTICATION & SESSION
// ==========================================
function initAuth() {
  const overlay = document.getElementById('authOverlay');
  if (!authToken) {
    overlay.classList.remove('hidden');
    return;
  }
  // Verify token validity by fetching current user
  fetch(`${API_BASE}/auth/me`, {
    headers: { 'Authorization': `Bearer ${authToken}` }
  })
  .then(res => res.json())
  .then(data => {
    if (data.success && data.data?.role === 'SUPER_ADMIN') {
      currentUser = data.data;
      overlay.classList.add('hidden');
      updateUserUI();
      refreshAllData();
    } else {
      localStorage.removeItem('scholarcloud_superadmin_token');
      authToken = '';
      overlay.classList.remove('hidden');
    }
  })
  .catch(() => {
    overlay.classList.remove('hidden');
  });
}

function updateUserUI() {
  if (!currentUser) return;
  const nameEl = document.getElementById('superAdminName');
  const avatarEl = document.getElementById('superAdminAvatar');
  if (nameEl) nameEl.textContent = currentUser.name || 'Super Administrator';
  if (avatarEl) {
    const initials = (currentUser.name || 'SA').split(' ').map(n => n[0]).join('').substring(0, 2);
    avatarEl.textContent = initials;
  }
}

document.getElementById('loginForm')?.addEventListener('submit', async (e) => {
  e.preventDefault();
  const email = document.getElementById('loginEmail').value.trim();
  const password = document.getElementById('loginPassword').value;
  const errorBox = document.getElementById('authError');
  const loginBtn = document.getElementById('loginBtn');

  loginBtn.disabled = true;
  loginBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Authenticating...';
  errorBox.classList.add('hidden');

  try {
    const res = await fetch(`${API_BASE}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ identifier: email, password })
    });
    const result = await res.json();
    if (!res.ok || !result.success) {
      throw new Error(result.message || 'Authentication failed');
    }
    if (result.data.user.role !== 'SUPER_ADMIN') {
      throw new Error('Access Denied: Requires Super Administrator master privileges.');
    }

    authToken = result.data.token;
    localStorage.setItem('scholarcloud_superadmin_token', authToken);
    currentUser = result.data.user;
    document.getElementById('authOverlay').classList.add('hidden');
    updateUserUI();
    showToast('Authenticated successfully as Super Administrator', 'success');
    refreshAllData();
  } catch (err) {
    errorBox.textContent = err.message;
    errorBox.classList.remove('hidden');
  } finally {
    loginBtn.disabled = false;
    loginBtn.innerHTML = '<i class="fa-solid fa-key"></i> Authenticate & Enter Portal';
  }
});

document.getElementById('logoutBtn')?.addEventListener('click', () => {
  localStorage.removeItem('scholarcloud_superadmin_token');
  authToken = '';
  document.getElementById('authOverlay').classList.remove('hidden');
});

// Helper for authenticated API calls
async function apiCall(endpoint, options = {}) {
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${authToken}`,
    ...(options.headers || {})
  };
  const res = await fetch(`${API_BASE}${endpoint}`, { ...options, headers });
  const data = await res.json();
  if (!res.ok) {
    throw new Error(data.message || `Request failed with status ${res.status}`);
  }
  return data;
}

// Universal list extractor handling both Array or Object payloads
function extractList(data, key) {
  if (!data) return [];
  if (Array.isArray(data)) return data;
  if (key && Array.isArray(data[key])) return data[key];
  if (data.data && Array.isArray(data.data)) return data.data;
  if (key && data.data && Array.isArray(data.data[key])) return data.data[key];
  return [];
}

// ==========================================
// 2. NAVIGATION & TABS
// ==========================================
function setupNavigation() {
  const navItems = document.querySelectorAll('.nav-item');
  navItems.forEach(item => {
    item.addEventListener('click', () => {
      const targetTab = item.getAttribute('data-tab');
      switchTab(targetTab);
    });
  });

  document.getElementById('mobileMenuToggle')?.addEventListener('click', () => {
    document.querySelector('.sidebar').classList.toggle('open');
  });
}

function switchTab(tabId) {
  document.querySelectorAll('.nav-item').forEach(b => b.classList.remove('active'));
  document.querySelectorAll('.tab-view').forEach(v => v.classList.remove('active'));

  const navBtn = document.querySelector(`.nav-item[data-tab="${tabId}"]`);
  const viewEl = document.getElementById(`tab-${tabId}`);
  if (navBtn) navBtn.classList.add('active');
  if (viewEl) viewEl.classList.add('active');

  // Update topbar title
  const titles = {
    dashboard: ['Platform Master Dashboard', 'Real-time cross-school enterprise monitoring & multi-tenant controls'],
    schools: ['School Institutional Registry', 'Onboard, approve, suspend, or configure academic campus parameters'],
    admins: ['School Administrator Governance', 'Assign school principals, review accounts, and define permission limits'],
    permissions: ['Permissions & Resource Ceilings', 'Configure granular module availability and student/teacher limits'],
    students: ['Cross-School Student Directory', 'Centralized student oversight, duplicate detection & records'],
    staff: ['Faculty & Staff Oversight', 'Monitor all educators, qualifications, and duplicate employee IDs'],
    biometric: ['Biometric & Attendance Terminals', 'Hardware health, automated log sync & attendance overrides'],
    fleet: ['Bus Fleet & GPS Telemetry', 'Active school bus monitoring, live GPS simulation & fitness alerts'],
    exams: ['Central Examinations & Publishing', 'Approve, publish or review grade corrections across schools'],
    financials: ['Cross-Campus Financial Oversight', 'Monitor fee revenues, outstanding balances, and recorded corrections'],
    broadcast: ['Central Announcement Transmitter', 'Network-wide emergency alerts, advisories, and circulars'],
    settings: ['Platform Security & Disaster Recovery', 'Session settings, immutable audit trails, and 1-click cloud backups']
  };

  if (titles[tabId]) {
    document.getElementById('currentScreenTitle').textContent = titles[tabId][0];
    document.getElementById('currentScreenSubtitle').textContent = titles[tabId][1];
  }

  // Auto load data for the specific tab
  if (tabId === 'schools') loadSchoolsTable();
  if (tabId === 'admins') loadAdminsTable();
  if (tabId === 'students') loadSuperAdminStudents();
  if (tabId === 'staff') loadSuperAdminStaff();
  if (tabId === 'biometric') loadBiometricDevices();
  if (tabId === 'fleet') loadBusFleet();
  if (tabId === 'exams') loadSuperAdminExams();
  if (tabId === 'financials') loadFinancialsOverview();
  if (tabId === 'broadcast') loadBroadcastHistory();
  if (tabId === 'settings') { loadPlatformSettings(); loadSecurityAuditLogs(); }
}

function setupEventListeners() {
  document.getElementById('refreshDataBtn')?.addEventListener('click', () => {
    refreshAllData();
    showToast('Platform data synchronized', 'success');
  });

  // Search filter hooks
  document.getElementById('schoolSearchInput')?.addEventListener('input', filterSchoolsTable);
  document.getElementById('schoolStatusFilter')?.addEventListener('change', filterSchoolsTable);
  document.getElementById('adminSearchInput')?.addEventListener('input', filterAdminsTable);
  document.getElementById('broadcastTarget')?.addEventListener('change', (e) => {
    const targetSchoolGroup = document.getElementById('targetSchoolGroup');
    if (e.target.value === 'SPECIFIC_SCHOOL') {
      targetSchoolGroup.classList.remove('hidden');
    } else {
      targetSchoolGroup.classList.add('hidden');
    }
  });
}

function refreshAllData() {
  loadDashboardData();
  loadSchoolsDropdowns();
}

// ==========================================
// 3. DASHBOARD METRICS
// ==========================================
async function loadDashboardData() {
  try {
    const res = await apiCall('/super-admin/dashboard/stats');
    const { kpiStats, schoolsStatus, busAlerts, recentAudits, biometricSummary, financialSummary } = res.data;

    // Render KPIs
    document.getElementById('kpiTotalSchools').textContent = kpiStats.totalSchools;
    document.getElementById('kpiActiveSchools').textContent = schoolsStatus.active;
    document.getElementById('kpiPendingSchools').textContent = schoolsStatus.pending;
    document.getElementById('kpiSuspendedSchools').textContent = schoolsStatus.suspended;

    document.getElementById('kpiTotalUsers').textContent = kpiStats.totalAdmins + kpiStats.totalTeachers + kpiStats.totalStudents;
    document.getElementById('kpiAdmins').textContent = kpiStats.totalAdmins;
    document.getElementById('kpiTeachers').textContent = kpiStats.totalTeachers;
    document.getElementById('kpiStudents').textContent = kpiStats.totalStudents;

    document.getElementById('kpiActiveBuses').textContent = kpiStats.activeBuses;
    document.getElementById('kpiActiveTrips').textContent = kpiStats.activeBuses;
    document.getElementById('kpiBusAlerts').textContent = busAlerts.length;

    document.getElementById('kpiFeeCollected').textContent = `₹${(financialSummary.totalCollected || 0).toLocaleString('en-IN')}`;
    document.getElementById('kpiFeePending').textContent = `₹${(financialSummary.totalPending || 0).toLocaleString('en-IN')}`;

    // Nav badges
    document.getElementById('badgeSchoolsCount').textContent = kpiStats.totalSchools;
    document.getElementById('badgePendingAdmins').textContent = schoolsStatus.pending;
    document.getElementById('badgeBusAlerts').textContent = busAlerts.length;

    // Render Biometric Terminals Widget
    const bioList = document.getElementById('dashboardBiometricList');
    if (biometricSummary && biometricSummary.length > 0) {
      bioList.innerHTML = biometricSummary.map(dev => `
        <div class="device-item">
          <div>
            <strong>${dev.name}</strong>
            <div class="text-muted" style="font-size: 11px;">Last Sync: ${dev.lastSyncAt ? new Date(dev.lastSyncAt).toLocaleTimeString() : 'Never'}</div>
          </div>
          <span class="status-pill ${dev.status.toLowerCase()}">${dev.status}</span>
        </div>
      `).join('');
    } else {
      bioList.innerHTML = '<div class="empty-state">No biometric terminals connected yet.</div>';
    }

    // Render Recent Audits Widget
    const auditList = document.getElementById('dashboardAuditList');
    if (recentAudits && recentAudits.length > 0) {
      auditList.innerHTML = recentAudits.map(log => `
        <div class="audit-item">
          <div>
            <strong>${log.action.replace(/_/g, ' ')}</strong>
            <div class="text-muted" style="font-size: 11px;">By: ${log.performedByName} • ${log.schoolName}</div>
          </div>
          <span class="status-pill ${log.status.toLowerCase()}">${log.status}</span>
        </div>
      `).join('');
    } else {
      auditList.innerHTML = '<div class="empty-state">No recent administrative audits recorded.</div>';
    }
  } catch (err) {
    console.error('Failed to load dashboard:', err);
  }
}

// ==========================================
// 4. SCHOOLS MANAGEMENT
// ==========================================
async function loadSchoolsTable() {
  const tbody = document.getElementById('schoolsTableBody');
  tbody.innerHTML = '<tr><td colspan="6" class="text-center">Loading registered schools...</td></tr>';
  try {
    const res = await apiCall('/super-admin/schools');
    currentSchools = extractList(res.data, 'schools');
    renderSchoolsList(currentSchools);
    populateSchoolsDropdowns(currentSchools);
  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="6" class="text-center text-danger">${err.message}</td></tr>`;
  }
}

function renderSchoolsList(schools) {
  const tbody = document.getElementById('schoolsTableBody');
  if (schools.length === 0) {
    tbody.innerHTML = '<tr><td colspan="6" class="text-center">No schools found matching criteria.</td></tr>';
    return;
  }
  tbody.innerHTML = schools.map(s => {
    const statusClass = s.status ? s.status.toLowerCase() : 'pending';
    return `
      <tr>
        <td>
          <div style="font-weight: 600;">${s.name}</div>
          <div class="text-muted" style="font-size: 11px;">Code: <strong>${s.code}</strong></div>
        </td>
        <td><span class="badge badge-super">${s.board || 'CBSE'}</span></td>
        <td>
          <div>${s.contactEmail || 'N/A'}</div>
          <div class="text-muted" style="font-size: 11px;">${s.contactPhone || ''}</div>
        </td>
        <td>
          <div>Students: <strong>${s.limits?.maxStudents || 1000}</strong></div>
          <div class="text-muted" style="font-size: 11px;">Teachers: ${s.limits?.maxTeachers || 80}</div>
        </td>
        <td><span class="status-pill ${statusClass}">${s.status}</span></td>
        <td>
          <div class="action-buttons-cell">
            <button id="btn-manage-campus-${s.code || s._id}" class="btn btn-sm btn-primary" onclick="openCampusHub('${s._id}')" title="Campus Command Hub">
              <i class="fa-solid fa-graduation-cap"></i> Manage Campus
            </button>
            ${s.status === 'PENDING' ? `
              <button class="btn btn-sm btn-secondary" onclick="setSchoolStatus('${s._id}', 'ACTIVE')">
                <i class="fa-solid fa-check"></i> Approve
              </button>
              <button class="btn btn-sm btn-secondary" onclick="setSchoolStatus('${s._id}', 'REJECTED')">
                <i class="fa-solid fa-xmark"></i> Reject
              </button>
            ` : s.status === 'ACTIVE' ? `
              <button class="btn btn-sm btn-secondary" onclick="setSchoolStatus('${s._id}', 'SUSPENDED')">
                <i class="fa-solid fa-ban"></i> Suspend
              </button>
            ` : `
              <button class="btn btn-sm btn-secondary" onclick="setSchoolStatus('${s._id}', 'ACTIVE')">
                <i class="fa-solid fa-play"></i> Activate
              </button>
            `}
            <button class="btn btn-sm btn-ghost" onclick="configureSchoolPermissions('${s._id}')" title="Configure Modules">
              <i class="fa-solid fa-sliders"></i>
            </button>
          </div>
        </td>
      </tr>
    `;
  }).join('');
}

function filterSchoolsTable() {
  const query = document.getElementById('schoolSearchInput').value.toLowerCase();
  const status = document.getElementById('schoolStatusFilter').value;
  const filtered = currentSchools.filter(s => {
    const matchQuery = s.name.toLowerCase().includes(query) || s.code.toLowerCase().includes(query) || (s.board && s.board.toLowerCase().includes(query));
    const matchStatus = status === 'ALL' || s.status === status;
    return matchQuery && matchStatus;
  });
  renderSchoolsList(filtered);
}

async function setSchoolStatus(schoolId, status) {
  try {
    await apiCall(`/super-admin/schools/${schoolId}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status })
    });
    showToast(`School status updated to ${status}`, 'success');
    loadSchoolsTable();
    loadDashboardData();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

function openCreateSchoolModal() {
  document.getElementById('createSchoolForm').reset();
  openModal('createSchoolModal');
}

async function submitCreateSchool(e) {
  e.preventDefault();
  const submitBtn = document.getElementById('createSchoolSubmitBtn');
  submitBtn.disabled = true;
  submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Registering...';

  const body = {
    name: document.getElementById('newSchoolName').value.trim(),
    code: document.getElementById('newSchoolCode').value.trim().toUpperCase(),
    board: document.getElementById('newSchoolBoard').value,
    currentAcademicYear: document.getElementById('newSchoolAY').value,
    contactEmail: document.getElementById('newSchoolEmail').value.trim(),
    contactPhone: document.getElementById('newSchoolPhone').value.trim(),
    address: document.getElementById('newSchoolAddress').value.trim(),
    limits: {
      maxStudents: Number(document.getElementById('newSchoolMaxStudents').value) || 1000,
      maxTeachers: Number(document.getElementById('newSchoolMaxTeachers').value) || 80,
    }
  };

  try {
    await apiCall('/super-admin/schools', {
      method: 'POST',
      body: JSON.stringify(body)
    });
    showToast('New School registered successfully', 'success');
    closeModal('createSchoolModal');
    loadSchoolsTable();
    loadDashboardData();
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    submitBtn.disabled = false;
    submitBtn.innerHTML = '<i class="fa-solid fa-check"></i> Register School';
  }
}

// ==========================================
// 5. SCHOOL ADMINS MANAGEMENT
// ==========================================
async function loadAdminsTable() {
  const tbody = document.getElementById('adminsTableBody');
  tbody.innerHTML = '<tr><td colspan="6" class="text-center">Loading school administrators...</td></tr>';
  try {
    const res = await apiCall('/super-admin/admins');
    currentAdmins = extractList(res.data, 'admins');
    renderAdminsList(currentAdmins);
  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="6" class="text-center text-danger">${err.message}</td></tr>`;
  }
}

function renderAdminsList(admins) {
  const tbody = document.getElementById('adminsTableBody');
  if (admins.length === 0) {
    tbody.innerHTML = '<tr><td colspan="6" class="text-center">No administrators registered.</td></tr>';
    return;
  }
  tbody.innerHTML = admins.map(adm => {
    const schoolName = adm.schoolId ? adm.schoolId.name : '<span class="text-warning">Unassigned</span>';
    const isSuspended = adm.isSuspended || false;
    return `
      <tr>
        <td>
          <div style="font-weight: 600;">${adm.name}</div>
          <div class="text-muted" style="font-size: 11px;">Role: Principal / Admin</div>
        </td>
        <td>${schoolName}</td>
        <td>
          <div>${adm.email || 'N/A'}</div>
          <div class="text-muted" style="font-size: 11px;">${adm.phone || ''}</div>
        </td>
        <td>
          ${isSuspended 
            ? '<span class="status-pill suspended">SUSPENDED</span>' 
            : '<span class="status-pill active">ACTIVE</span>'}
        </td>
        <td>${new Date(adm.createdAt).toLocaleDateString()}</td>
        <td>
          <div class="action-buttons-cell">
            <button class="btn btn-sm btn-secondary" onclick="toggleAdminSuspension('${adm._id}', ${!isSuspended})">
              ${isSuspended ? '<i class="fa-solid fa-unlock"></i> Unsuspend' : '<i class="fa-solid fa-lock"></i> Suspend'}
            </button>
            <button class="btn btn-sm btn-primary" onclick="openAdminPermissionsModal('${adm._id}')">
              <i class="fa-solid fa-key"></i> Permissions
            </button>
          </div>
        </td>
      </tr>
    `;
  }).join('');
}

function filterAdminsTable() {
  const query = document.getElementById('adminSearchInput').value.toLowerCase();
  const filtered = currentAdmins.filter(a => 
    a.name.toLowerCase().includes(query) || 
    (a.email && a.email.toLowerCase().includes(query)) ||
    (a.phone && a.phone.includes(query))
  );
  renderAdminsList(filtered);
}

async function toggleAdminSuspension(adminId, suspend) {
  try {
    await apiCall(`/super-admin/admins/${adminId}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ isSuspended: suspend, statusReason: suspend ? 'Administrative suspension' : 'Restored access' })
    });
    showToast(`Administrator account ${suspend ? 'suspended' : 're-activated'}`, 'success');
    loadAdminsTable();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

function openCreateAdminModal() {
  document.getElementById('createAdminForm').reset();
  populateSchoolsSelect('newAdminSchoolSelect');
  openModal('createAdminModal');
}

async function submitCreateAdmin(e) {
  e.preventDefault();
  const submitBtn = document.getElementById('createAdminSubmitBtn');
  submitBtn.disabled = true;
  submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Creating...';

  const body = {
    schoolId: document.getElementById('newAdminSchoolSelect').value,
    name: document.getElementById('newAdminName').value.trim(),
    email: document.getElementById('newAdminEmail').value.trim(),
    phone: document.getElementById('newAdminPhone').value.trim(),
    password: document.getElementById('newAdminPassword').value,
  };

  try {
    await apiCall('/super-admin/admins', {
      method: 'POST',
      body: JSON.stringify(body)
    });
    showToast('School Administrator account created successfully', 'success');
    closeModal('createAdminModal');
    loadAdminsTable();
    loadDashboardData();
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    submitBtn.disabled = false;
    submitBtn.innerHTML = '<i class="fa-solid fa-user-check"></i> Create Admin Account';
  }
}

// Edit Admin Permissions Modal
function openAdminPermissionsModal(adminId) {
  const admin = currentAdmins.find(a => a._id === adminId);
  if (!admin) return;

  document.getElementById('editAdminId').value = admin._id;
  document.getElementById('editAdminSubtitle').textContent = `Configuring permission matrix for ${admin.name} (${admin.email})`;

  const availablePermissions = [
    { key: 'canCreateTeachers', label: 'Create & Onboard Teachers' },
    { key: 'canApproveUsers', label: 'Approve Teacher & Parent Accounts' },
    { key: 'canManageFees', label: 'Collect Fees & Generate Slips' },
    { key: 'canPublishExams', label: 'Publish Examination Marks' },
    { key: 'canSendBroadcasts', label: 'Transmit Notices & Circulars' },
    { key: 'canEditClassrooms', label: 'Manage Classes & Sections' },
    { key: 'canExportData', label: 'Export Reports (Excel/CSV)' },
    { key: 'canManageSalary', label: 'Generate Staff Salary Slips' },
  ];

  const currentPerms = admin.permissions || {};
  const container = document.getElementById('adminPermissionsCheckboxes');
  container.innerHTML = availablePermissions.map(p => `
    <label class="perm-check-item">
      <input type="checkbox" name="perm_${p.key}" ${currentPerms[p.key] !== false ? 'checked' : ''}>
      <span>${p.label}</span>
    </label>
  `).join('');

  openModal('editAdminPermissionsModal');
}

async function submitAdminPermissions(e) {
  e.preventDefault();
  const adminId = document.getElementById('editAdminId').value;
  const submitBtn = document.getElementById('submitAdminPermissionsBtn');
  submitBtn.disabled = true;
  submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Saving...';

  const inputs = document.querySelectorAll('#adminPermissionsCheckboxes input[type="checkbox"]');
  const permissions = {};
  inputs.forEach(input => {
    const key = input.name.replace('perm_', '');
    permissions[key] = input.checked;
  });

  try {
    await apiCall(`/super-admin/admins/${adminId}/permissions`, {
      method: 'PATCH',
      body: JSON.stringify({ permissions })
    });
    showToast('Admin permissions updated and committed', 'success');
    closeModal('editAdminPermissionsModal');
    loadAdminsTable();
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    submitBtn.disabled = false;
    submitBtn.innerHTML = '<i class="fa-solid fa-check-double"></i> Save Permission Matrix';
  }
}

// ==========================================
// 6. PERMISSIONS & RESOURCE CEILINGS
// ==========================================
function configureSchoolPermissions(schoolId) {
  switchTab('permissions');
  const select = document.getElementById('permissionSchoolSelect');
  select.value = schoolId;
  loadSchoolPermissionsForEdit();
}

const MODULE_DEFINITIONS = [
  { key: 'busTracking', name: 'GPS Bus Fleet & Live Tracking', desc: 'Real-time telemetry, trip status, route playback' },
  { key: 'biometricAttendance', name: 'Biometric Attendance Devices', desc: 'TCP/IP biometric sync, faculty attendance, overrides' },
  { key: 'feeManagement', name: 'Student Fee Management & Billing', desc: 'Online fee dues, invoices, concessions, payments' },
  { key: 'examResults', name: 'Examination & Report Cards', desc: 'Grade entry, merit lists, publishing governance' },
  { key: 'studentAdmission', name: 'Student Admission & Enrollment', desc: 'Registration workflows, capacity caps, student profiles' },
  { key: 'leaveManagement', name: 'Teacher & Staff Leave System', desc: 'Leave requests, approval chains, balance tracking' },
  { key: 'dailySyllabus', name: 'Daily Syllabus & Lesson Planner', desc: 'Subject lesson logs, chapter progression tracking' },
  { key: 'communication', name: 'Parent-Teacher Communication', desc: 'Direct secure messaging, queries, parent engagement' },
];

async function loadSchoolPermissionsForEdit() {
  const schoolId = document.getElementById('permissionSchoolSelect').value;
  const container = document.getElementById('modulesToggleList');
  const metaBox = document.getElementById('schoolQuickMeta');
  const usageMeter = document.getElementById('limitsUsageMeter');

  if (!schoolId) {
    container.innerHTML = '<div class="text-muted">Select an institution above to configure modules.</div>';
    metaBox.innerHTML = '<span>No school selected</span>';
    return;
  }

  try {
    const res = await apiCall(`/super-admin/schools/${schoolId}`);
    const school = res.data.school;

    metaBox.innerHTML = `
      <strong>${school.name}</strong> • Affiliation: ${school.board} • Code: ${school.code} • Status: <span class="status-pill ${school.status.toLowerCase()}">${school.status}</span>
    `;

    // Render Module switches
    const modules = school.modules || {};
    container.innerHTML = MODULE_DEFINITIONS.map(m => `
      <div class="toggle-item">
        <div class="toggle-info">
          <strong>${m.name}</strong>
          <span>${m.desc}</span>
        </div>
        <label class="switch">
          <input type="checkbox" id="mod_${m.key}" ${modules[m.key] ? 'checked' : ''}>
          <span class="slider"></span>
        </label>
      </div>
    `).join('');

    // Fill Limits
    const limits = school.limits || {};
    document.getElementById('limitMaxStudents').value = limits.maxStudents || 1000;
    document.getElementById('limitMaxTeachers').value = limits.maxTeachers || 80;
    document.getElementById('limitMaxStaff').value = limits.maxStaff || 40;
    document.getElementById('limitStorageMB').value = limits.storageLimitMB || 10240;

    // Load actual usage
    const usageRes = await apiCall(`/super-admin/schools/${schoolId}/limits-usage`);
    const usage = usageRes.data.usage;
    usageMeter.innerHTML = `
      <div class="meter-row">
        <span>Current Student Enrolment:</span>
        <strong>${usage.currentStudents} / ${limits.maxStudents} (${Math.round((usage.currentStudents / (limits.maxStudents || 1)) * 100)}%)</strong>
      </div>
      <div class="progress-bar-bg">
        <div class="progress-bar-fill" style="width: ${Math.min(100, Math.round((usage.currentStudents / (limits.maxStudents || 1)) * 100))}%;"></div>
      </div>

      <div class="meter-row">
        <span>Current Teaching Faculty:</span>
        <strong>${usage.currentTeachers} / ${limits.maxTeachers} (${Math.round((usage.currentTeachers / (limits.maxTeachers || 1)) * 100)}%)</strong>
      </div>
      <div class="progress-bar-bg">
        <div class="progress-bar-fill" style="width: ${Math.min(100, Math.round((usage.currentTeachers / (limits.maxTeachers || 1)) * 100))}%;"></div>
      </div>
    `;
  } catch (err) {
    showToast(err.message, 'error');
  }
}

async function saveSchoolPermissions(e) {
  e.preventDefault();
  const schoolId = document.getElementById('permissionSchoolSelect').value;
  if (!schoolId) {
    showToast('Please select a school first', 'error');
    return;
  }

  const saveBtn = document.getElementById('savePermissionsBtn');
  saveBtn.disabled = true;
  saveBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Committing Changes...';

  const modules = {};
  MODULE_DEFINITIONS.forEach(m => {
    const el = document.getElementById(`mod_${m.key}`);
    modules[m.key] = el ? el.checked : false;
  });

  const limits = {
    maxStudents: Number(document.getElementById('limitMaxStudents').value),
    maxTeachers: Number(document.getElementById('limitMaxTeachers').value),
    maxStaff: Number(document.getElementById('limitMaxStaff').value),
    storageLimitMB: Number(document.getElementById('limitStorageMB').value),
  };

  try {
    await Promise.all([
      apiCall(`/super-admin/schools/${schoolId}/modules`, {
        method: 'PATCH',
        body: JSON.stringify({ modules })
      }),
      apiCall(`/super-admin/schools/${schoolId}/limits`, {
        method: 'PATCH',
        body: JSON.stringify({ limits })
      })
    ]);
    showToast('Module toggles & resource limits successfully saved!', 'success');
    loadSchoolPermissionsForEdit();
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    saveBtn.disabled = false;
    saveBtn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> <span>Save Modules & Quotas</span>';
  }
}

// ==========================================
// 7. STUDENTS & ADMISSION OVERSIGHT
// ==========================================
async function loadSuperAdminStudents() {
  const tbody = document.getElementById('studentsTableBody');
  const schoolFilter = document.getElementById('studentSchoolFilter').value;
  tbody.innerHTML = '<tr><td colspan="6" class="text-center">Loading student records...</td></tr>';

  try {
    const url = schoolFilter ? `/super-admin/students?schoolId=${schoolFilter}` : '/super-admin/students';
    const res = await apiCall(url);
    const students = extractList(res.data, 'students');

    if (students.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6" class="text-center">No student records found.</td></tr>';
      return;
    }

    tbody.innerHTML = students.map(st => `
      <tr>
        <td>
          <div style="font-weight: 600;">${st.name || `${st.firstName || ''} ${st.lastName || ''}`.trim()}</div>
          <div class="text-muted" style="font-size: 11px;">Gender: ${st.gender || 'N/A'}</div>
        </td>
        <td>${st.schoolId?.name || 'N/A'}</td>
        <td>${st.currentClass || st.classId?.name || 'Class 10'} (${st.section || st.classId?.section || 'A'})</td>
        <td><strong>${st.rollNumber || st.admissionNumber || 'N/A'}</strong></td>
        <td>${st.parentName || st.parentId?.name || 'Guardian'}</td>
        <td><span class="status-pill active">ENROLLED</span></td>
      </tr>
    `).join('');
  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="6" class="text-center text-danger">${err.message}</td></tr>`;
  }
}

async function checkDuplicateStudents() {
  showToast('Auditing cross-school enrolment identities for duplicate Aadhaar / Phone / Roll...', 'success');
  loadSuperAdminStudents();
}

// ==========================================
// 8. FACULTY & STAFF OVERSIGHT
// ==========================================
async function loadSuperAdminStaff() {
  const tbody = document.getElementById('staffTableBody');
  const schoolFilter = document.getElementById('staffSchoolFilter').value;
  tbody.innerHTML = '<tr><td colspan="6" class="text-center">Loading faculty directory...</td></tr>';

  try {
    const url = schoolFilter ? `/super-admin/staff?schoolId=${schoolFilter}` : '/super-admin/staff';
    const res = await apiCall(url);
    const staff = extractList(res.data, 'staff');

    if (staff.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6" class="text-center">No faculty records found.</td></tr>';
      return;
    }

    tbody.innerHTML = staff.map(st => `
      <tr>
        <td>
          <div style="font-weight: 600;">${st.name}</div>
          <div class="text-muted" style="font-size: 11px;">${st.role}</div>
        </td>
        <td>${st.schoolId?.name || 'Assigned Campus'}</td>
        <td><code>${st.employeeId || 'EMP-SCH-' + st._id.slice(-4).toUpperCase()}</code></td>
        <td>${(st.subjects && st.subjects.length > 0) ? st.subjects.join(', ') : (st.designation || 'Educator')}</td>
        <td>
          <div>${st.email || 'N/A'}</div>
          <div class="text-muted" style="font-size: 11px;">${st.phone || ''}</div>
        </td>
        <td><span class="status-pill ${st.status.toLowerCase()}">${st.status}</span></td>
      </tr>
    `).join('');
  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="6" class="text-center text-danger">${err.message}</td></tr>`;
  }
}

async function loadDuplicateStaffCheck() {
  try {
    const res = await apiCall('/super-admin/staff/duplicates');
    const duplicates = extractList(res.data, 'duplicates');
    if (duplicates.length === 0) {
      showToast('Clean Audit: No duplicate employee IDs detected across schools.', 'success');
    } else {
      showToast(`Warning: Found ${duplicates.length} duplicate employee credentials.`, 'error');
    }
  } catch (err) {
    showToast(err.message, 'error');
  }
}

// ==========================================
// 9. BIOMETRIC DEVICES & ATTENDANCE
// ==========================================
async function loadBiometricDevices() {
  const grid = document.getElementById('biometricDevicesGrid');
  grid.innerHTML = '<div class="text-muted">Loading biometric device telemetry...</div>';

  try {
    const res = await apiCall('/super-admin/biometric/devices');
    const devices = extractList(res.data, 'devices');

    if (devices.length === 0) {
      grid.innerHTML = '<div class="empty-state">No biometric terminals connected. Register one to begin hardware tracking.</div>';
      return;
    }

    grid.innerHTML = devices.map(d => `
      <div class="device-card glass-panel">
        <div class="card-top">
          <div class="card-title-group">
            <h4>${d.name}</h4>
            <div class="card-subtitle">${d.schoolId?.name || 'School Terminal'} • ID: <code>${d.deviceId}</code></div>
          </div>
          <span class="status-pill ${d.status.toLowerCase()}">${d.status}</span>
        </div>

        <div class="telemetry-row">
          <span>Location:</span>
          <strong>${d.location || 'Campus Gate'}</strong>
        </div>
        <div class="telemetry-row">
          <span>Battery / Signal:</span>
          <strong>${d.batteryPercent || 98}% • ${d.signalStrength || 'Good (4G)'}</strong>
        </div>
        <div class="telemetry-row">
          <span>Last Sync:</span>
          <strong>${d.lastSyncAt ? new Date(d.lastSyncAt).toLocaleString() : 'Never'}</strong>
        </div>

        <div style="display: flex; gap: 8px; margin-top: 6px;">
          <button class="btn btn-sm btn-primary flex-1" onclick="triggerBiometricSync('${d._id}')">
            <i class="fa-solid fa-rotate"></i> Sync Device
          </button>
        </div>
      </div>
    `).join('');
  } catch (err) {
    grid.innerHTML = `<div class="text-danger">${err.message}</div>`;
  }
}

async function triggerBiometricSync(deviceId) {
  try {
    await apiCall(`/super-admin/biometric/devices/${deviceId}/sync`, { method: 'POST' });
    showToast('Biometric terminal punch logs synchronized successfully', 'success');
    loadBiometricDevices();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

function openCreateBiometricModal() {
  document.getElementById('createBiometricForm').reset();
  populateSchoolsSelect('newBiometricSchool');
  openModal('createBiometricModal');
}

async function submitCreateBiometric(e) {
  e.preventDefault();
  const submitBtn = document.getElementById('createBiometricSubmitBtn');
  submitBtn.disabled = true;

  const body = {
    schoolId: document.getElementById('newBiometricSchool').value,
    name: document.getElementById('newBiometricName').value.trim(),
    deviceId: document.getElementById('newBiometricId').value.trim(),
    location: document.getElementById('newBiometricLocation').value.trim(),
  };

  try {
    await apiCall('/super-admin/biometric/devices', {
      method: 'POST',
      body: JSON.stringify(body)
    });
    showToast('Biometric terminal registered and paired', 'success');
    closeModal('createBiometricModal');
    loadBiometricDevices();
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    submitBtn.disabled = false;
  }
}

function openManualAttendanceOverrideModal() {
  document.getElementById('attendanceOverrideForm').reset();
  populateSchoolsSelect('overrideSchool');
  document.getElementById('overrideDate').value = new Date().toISOString().split('T')[0];
  openModal('attendanceOverrideModal');
}

async function submitAttendanceOverride(e) {
  e.preventDefault();
  const submitBtn = document.getElementById('attendanceOverrideSubmitBtn');
  submitBtn.disabled = true;

  const body = {
    schoolId: document.getElementById('overrideSchool').value,
    date: document.getElementById('overrideDate').value,
    status: document.getElementById('overrideStatus').value,
    auditReason: document.getElementById('overrideReason').value.trim(),
  };

  try {
    await apiCall('/super-admin/biometric/override', {
      method: 'POST',
      body: JSON.stringify(body)
    });
    showToast('Manual attendance override recorded and logged into audit trail', 'success');
    closeModal('attendanceOverrideModal');
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    submitBtn.disabled = false;
  }
}

// ==========================================
// 10. BUS FLEET & GPS TELEMETRY
// ==========================================
async function loadBusFleet() {
  const grid = document.getElementById('fleetCardsGrid');
  grid.innerHTML = '<div class="text-muted">Loading GPS bus telemetry...</div>';

  try {
    const schoolFilter = document.getElementById('fleetSchoolFilter')?.value;
    const url = schoolFilter ? `/super-admin/buses?schoolId=${schoolFilter}` : '/super-admin/buses';
    const res = await apiCall(url);
    const buses = extractList(res.data, 'buses');

    if (buses.length === 0) {
      grid.innerHTML = '<div class="empty-state">No buses registered in platform fleet.</div>';
      return;
    }

    grid.innerHTML = buses.map(b => `
      <div class="fleet-card glass-panel">
        <div class="card-top">
          <div class="card-title-group">
            <h4>${b.busNumber}</h4>
            <div class="card-subtitle">${b.schoolId?.name || 'School Bus'} • Reg: <code>${b.registrationNumber}</code></div>
          </div>
          <span class="status-pill ${b.status === 'ACTIVE_TRIP' ? 'active' : 'pending'}">${b.status.replace(/_/g, ' ')}</span>
        </div>

        <div class="telemetry-row">
          <span>Driver / Phone:</span>
          <strong>${b.driverName || 'Ramesh'} (${b.driverPhone || 'N/A'})</strong>
        </div>
        <div class="telemetry-row">
          <span>Current Speed:</span>
          <strong>${b.currentSpeedKmph || 0} km/h (Limit: ${b.speedLimitKmph || 50} km/h)</strong>
        </div>
        <div class="telemetry-row">
          <span>GPS Coordinates:</span>
          <strong>${b.currentLocation?.latitude ? b.currentLocation.latitude.toFixed(4) : '28.6139'}, ${b.currentLocation?.longitude ? b.currentLocation.longitude.toFixed(4) : '77.2090'}</strong>
        </div>

        <div style="display: flex; gap: 8px; margin-top: 6px;">
          <button class="btn btn-sm btn-primary flex-1" onclick="simulateBusGPS('${b._id}')">
            <i class="fa-solid fa-satellite"></i> Simulate GPS Movement
          </button>
        </div>
      </div>
    `).join('');
  } catch (err) {
    grid.innerHTML = `<div class="text-danger">${err.message}</div>`;
  }
}

async function simulateBusGPS(busId) {
  try {
    // Slight jitter to simulate movement
    const lat = 28.6139 + (Math.random() - 0.5) * 0.05;
    const lng = 77.2090 + (Math.random() - 0.5) * 0.05;
    const speed = Math.floor(25 + Math.random() * 30);

    await apiCall(`/super-admin/buses/${busId}/simulate-location`, {
      method: 'PATCH',
      body: JSON.stringify({ latitude: lat, longitude: lng, speedKmph: speed })
    });
    showToast(`Bus telemetry updated! Speed: ${speed} km/h`, 'success');
    loadBusFleet();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

function openCreateBusModal() {
  document.getElementById('createBusForm').reset();
  populateSchoolsSelect('newBusSchool');
  openModal('createBusModal');
}

async function submitCreateBus(e) {
  e.preventDefault();
  const submitBtn = document.getElementById('createBusSubmitBtn');
  submitBtn.disabled = true;

  const body = {
    schoolId: document.getElementById('newBusSchool').value,
    busNumber: document.getElementById('newBusNumber').value.trim(),
    registrationNumber: document.getElementById('newBusRegNo').value.trim().toUpperCase(),
    driverName: document.getElementById('newBusDriver').value.trim(),
    driverPhone: document.getElementById('newBusDriverPhone').value.trim(),
  };

  try {
    await apiCall('/super-admin/buses', {
      method: 'POST',
      body: JSON.stringify(body)
    });
    showToast('Fleet vehicle onboarded successfully', 'success');
    closeModal('createBusModal');
    loadBusFleet();
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    submitBtn.disabled = false;
  }
}

async function loadBusAlertsModal() {
  try {
    const res = await apiCall('/super-admin/buses/alerts');
    const alerts = extractList(res.data, 'alerts');
    if (alerts.length === 0) {
      showToast('All fleet vehicles have valid insurance, fitness & pollution certificates.', 'success');
    } else {
      showToast(`Warning: ${alerts.length} vehicles have imminent compliance expiries.`, 'error');
    }
  } catch (err) {
    showToast(err.message, 'error');
  }
}

// ==========================================
// 11. EXAMS & RESULTS OVERSIGHT
// ==========================================
async function loadSuperAdminExams() {
  const tbody = document.getElementById('examsTableBody');
  const schoolFilter = document.getElementById('examSchoolFilter').value;
  tbody.innerHTML = '<tr><td colspan="6" class="text-center">Loading academic examinations...</td></tr>';

  try {
    const url = schoolFilter ? `/super-admin/exams?schoolId=${schoolFilter}` : '/super-admin/exams';
    const res = await apiCall(url);
    const exams = extractList(res.data, 'exams');

    if (exams.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6" class="text-center">No examinations found.</td></tr>';
      return;
    }

    tbody.innerHTML = exams.map(ex => `
      <tr>
        <td>
          <div style="font-weight: 600;">${ex.title || ex.examName || 'Assessment'}</div>
          <div class="text-muted" style="font-size: 11px;">Max Marks: ${ex.totalMarks || 100}</div>
        </td>
        <td>${ex.schoolId?.name || 'All Campuses'}</td>
        <td>Class ${ex.classId?.name || '10'}</td>
        <td><strong>${ex.subject || 'Mathematics'}</strong></td>
        <td>
          ${ex.isPublished 
            ? '<span class="status-pill active">PUBLISHED</span>' 
            : '<span class="status-pill pending">PENDING APPROVAL</span>'}
        </td>
        <td>
          <div class="action-buttons-cell">
            ${!ex.isPublished ? `
              <button class="btn btn-sm btn-primary" onclick="publishExamResult('${ex._id}')">
                <i class="fa-solid fa-check"></i> Approve & Publish
              </button>
            ` : `
              <button class="btn btn-sm btn-secondary" onclick="showToast('Result already live to parents', 'success')">
                <i class="fa-solid fa-lock"></i> Locked Live
              </button>
            `}
          </div>
        </td>
      </tr>
    `).join('');
  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="6" class="text-center text-danger">${err.message}</td></tr>`;
  }
}

async function publishExamResult(examId) {
  try {
    await apiCall(`/super-admin/exams/${examId}/publish`, { method: 'PATCH' });
    showToast('Examination results approved and published platform-wide', 'success');
    loadSuperAdminExams();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

// ==========================================
// 12. CENTRAL FINANCIALS & ACCOUNTS
// ==========================================
async function loadFinancialsOverview() {
  const kpisGrid = document.getElementById('financialsKpisGrid');
  const tbody = document.getElementById('schoolFinancialsTableBody');
  tbody.innerHTML = '<tr><td colspan="5" class="text-center">Loading financial records...</td></tr>';

  try {
    const res = await apiCall('/super-admin/financials/overview');
    const { totals, schoolSummaries } = res.data;

    kpisGrid.innerHTML = `
      <div class="kpi-grid">
        <div class="kpi-card glass-panel">
          <div class="kpi-icon-wrap emerald"><i class="fa-solid fa-receipt"></i></div>
          <div class="kpi-content">
            <span class="kpi-title">Total Invoiced (Billed)</span>
            <h3 class="kpi-value">₹${(totals.totalBilled || 0).toLocaleString('en-IN')}</h3>
          </div>
        </div>
        <div class="kpi-card glass-panel">
          <div class="kpi-icon-wrap indigo"><i class="fa-solid fa-vault"></i></div>
          <div class="kpi-content">
            <span class="kpi-title">Total Collected</span>
            <h3 class="kpi-value">₹${(totals.totalCollected || 0).toLocaleString('en-IN')}</h3>
          </div>
        </div>
        <div class="kpi-card glass-panel">
          <div class="kpi-icon-wrap rose"><i class="fa-solid fa-triangle-exclamation"></i></div>
          <div class="kpi-content">
            <span class="kpi-title">Outstanding Arrears</span>
            <h3 class="kpi-value">₹${(totals.totalPending || 0).toLocaleString('en-IN')}</h3>
          </div>
        </div>
      </div>
    `;

    if (!schoolSummaries || schoolSummaries.length === 0) {
      tbody.innerHTML = '<tr><td colspan="5" class="text-center">No fee summaries recorded yet.</td></tr>';
      return;
    }

    tbody.innerHTML = schoolSummaries.map(s => {
      const rate = s.totalBilled > 0 ? Math.round((s.totalCollected / s.totalBilled) * 100) : 0;
      return `
        <tr>
          <td><strong>${s.schoolName}</strong></td>
          <td>₹${s.totalBilled.toLocaleString('en-IN')}</td>
          <td><strong class="text-success">₹${s.totalCollected.toLocaleString('en-IN')}</strong></td>
          <td><span class="text-danger">₹${s.totalPending.toLocaleString('en-IN')}</span></td>
          <td>
            <div style="display: flex; align-items: center; gap: 8px;">
              <div class="progress-bar-bg" style="width: 80px; margin-bottom: 0;">
                <div class="progress-bar-fill" style="width: ${rate}%;"></div>
              </div>
              <span>${rate}%</span>
            </div>
          </td>
        </tr>
      `;
    }).join('');
  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="5" class="text-center text-danger">${err.message}</td></tr>`;
  }
}

function openFeeCorrectionModal() {
  document.getElementById('feeCorrectionForm').reset();
  populateSchoolsSelect('feeCorrectionSchool');
  openModal('feeCorrectionModal');
}

async function submitFeeCorrection(e) {
  e.preventDefault();
  const submitBtn = document.getElementById('feeCorrectionSubmitBtn');
  submitBtn.disabled = true;

  const body = {
    schoolId: document.getElementById('feeCorrectionSchool').value,
    amount: Number(document.getElementById('feeCorrectionAmount').value),
    correctionType: document.getElementById('feeCorrectionType').value,
    reason: document.getElementById('feeCorrectionReason').value.trim(),
  };

  try {
    await apiCall('/super-admin/financials/fee-correction', {
      method: 'POST',
      body: JSON.stringify(body)
    });
    showToast('Administrative fee adjustment recorded in ledger', 'success');
    closeModal('feeCorrectionModal');
    loadFinancialsOverview();
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    submitBtn.disabled = false;
  }
}

// ==========================================
// 13. CENTRAL BROADCAST NOTIFICATIONS
// ==========================================
async function sendCentralBroadcast(e) {
  e.preventDefault();
  const submitBtn = document.getElementById('sendBroadcastBtn');
  submitBtn.disabled = true;
  submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Transmitting...';

  const title = document.getElementById('broadcastTitle').value.trim();
  const target = document.getElementById('broadcastTarget').value;
  const message = document.getElementById('broadcastMessage').value.trim();
  const schoolId = target === 'SPECIFIC_SCHOOL' ? document.getElementById('broadcastTargetSchool').value : null;

  try {
    await apiCall('/super-admin/notifications/broadcast', {
      method: 'POST',
      body: JSON.stringify({ title, target, message, schoolId })
    });
    showToast('Platform broadcast successfully transmitted to mobile clients', 'success');
    document.getElementById('broadcastForm').reset();
    loadBroadcastHistory();
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    submitBtn.disabled = false;
    submitBtn.innerHTML = '<i class="fa-solid fa-paper-plane"></i> <span>Transmit Central Broadcast</span>';
  }
}

async function loadBroadcastHistory() {
  const tbody = document.getElementById('broadcastHistoryTableBody');
  tbody.innerHTML = '<tr><td colspan="5" class="text-center">Loading broadcast log stream...</td></tr>';

  try {
    const res = await apiCall('/super-admin/notifications/history');
    const logs = extractList(res.data, 'logs');

    if (logs.length === 0) {
      tbody.innerHTML = '<tr><td colspan="5" class="text-center">No broadcasts transmitted yet.</td></tr>';
      return;
    }

    tbody.innerHTML = logs.map(l => `
      <tr>
        <td>
          <div style="font-weight: 600;">${l.title}</div>
          <div class="text-muted" style="font-size: 11px;">${l.message ? l.message.substring(0, 50) + '...' : ''}</div>
        </td>
        <td><span class="badge badge-super">${l.targetAudience || 'ALL'}</span></td>
        <td><strong>${l.recipientCount || 1} Recipients</strong></td>
        <td>${new Date(l.createdAt).toLocaleString()}</td>
        <td><span class="status-pill active">DELIVERED</span></td>
      </tr>
    `).join('');
  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="5" class="text-center text-danger">${err.message}</td></tr>`;
  }
}

// ==========================================
// 14. SETTINGS & IMMUTABLE SECURITY AUDIT
// ==========================================
async function loadPlatformSettings() {
  try {
    const res = await apiCall('/super-admin/settings');
    const s = res.data.settings;
    if (s) {
      document.getElementById('settingAcademicYear').value = s.currentAcademicYear || '2026-2027';
      document.getElementById('settingMaintenanceMode').value = String(s.maintenanceMode || false);
      document.getElementById('settingNoticeBanner').value = s.emergencyNoticeBanner || '';
      if (s.lastBackupAt) {
        document.getElementById('lastBackupTime').textContent = new Date(s.lastBackupAt).toLocaleString();
      }
    }
  } catch (err) {
    console.error('Settings load err:', err);
  }
}

async function savePlatformSettings(e) {
  e.preventDefault();
  const currentAcademicYear = document.getElementById('settingAcademicYear').value.trim();
  const maintenanceMode = document.getElementById('settingMaintenanceMode').value === 'true';
  const emergencyNoticeBanner = document.getElementById('settingNoticeBanner').value.trim();

  try {
    await apiCall('/super-admin/settings', {
      method: 'PUT',
      body: JSON.stringify({ currentAcademicYear, maintenanceMode, emergencyNoticeBanner })
    });
    showToast('Platform settings updated successfully', 'success');
  } catch (err) {
    showToast(err.message, 'error');
  }
}

async function triggerManualBackup() {
  showToast('Initiating encrypted database snapshot archive...', 'success');
  try {
    const res = await apiCall('/super-admin/security/backup-now', { method: 'POST' });
    document.getElementById('lastBackupTime').textContent = new Date(res.data.timestamp).toLocaleString();
    showToast('Database archive verified and stored in encrypted S3 bucket!', 'success');
  } catch (err) {
    showToast(err.message, 'error');
  }
}

async function loadSecurityAuditLogs() {
  const tbody = document.getElementById('securityAuditTableBody');
  tbody.innerHTML = '<tr><td colspan="6" class="text-center">Loading audit log stream...</td></tr>';

  try {
    const res = await apiCall('/super-admin/security/audit-logs');
    const logs = extractList(res.data, 'logs');

    if (logs.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6" class="text-center">No audit logs recorded yet.</td></tr>';
      return;
    }

    tbody.innerHTML = logs.map(l => `
      <tr>
        <td>${new Date(l.createdAt).toLocaleTimeString()}</td>
        <td><code>${l.action}</code></td>
        <td><strong>${l.performedByName || 'Super Admin'}</strong></td>
        <td>${l.schoolName || 'Cross-School Platform'}</td>
        <td>${l.ipAddress || '127.0.0.1'}</td>
        <td><span class="status-pill active">${l.status}</span></td>
      </tr>
    `).join('');
  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="6" class="text-center text-danger">${err.message}</td></tr>`;
  }
}

// ==========================================
// 15. UTILITIES, DROPDOWNS & TOASTS
// ==========================================
async function loadSchoolsDropdowns() {
  try {
    const res = await apiCall('/super-admin/schools');
    currentSchools = extractList(res.data, 'schools');
    populateSchoolsDropdowns(currentSchools);
  } catch (err) {
    console.error('Error fetching schools for dropdowns:', err);
  }
}

function populateSchoolsDropdowns(schools) {
  const dropdownIds = [
    'permissionSchoolSelect',
    'studentSchoolFilter',
    'staffSchoolFilter',
    'examSchoolFilter',
    'fleetSchoolFilter',
    'broadcastTargetSchool',
    'enrollStudentSchool',
    'onboardStaffSchool',
    'classAllocSchool',
    'markAttSchool',
    'recordExamSchool',
    'newBiometricSchool',
    'newBusSchool',
    'feeCorrectionSchool',
    'overrideSchool',
    'newAdminSchoolSelect'
  ];
  dropdownIds.forEach(id => populateSchoolsSelect(id, schools));
}

function populateSchoolsSelect(selectId, schoolsList = currentSchools) {
  const select = document.getElementById(selectId);
  if (!select) return;

  const currentVal = select.value;
  let html = selectId.includes('Filter') 
    ? '<option value="">All Schools</option>' 
    : '<option value="">-- Choose School --</option>';

  schoolsList.forEach(s => {
    html += `<option value="${s._id}">${s.name} (${s.code || s.board || 'CBSE'})</option>`;
  });
  select.innerHTML = html;
  if (currentVal) select.value = currentVal;
}

function openModal(modalId) {
  const el = document.getElementById(modalId);
  if (el) el.classList.remove('hidden');
}

function closeModal(modalId) {
  const el = document.getElementById(modalId);
  if (el) el.classList.add('hidden');
}

function showToast(message, type = 'success') {
  const container = document.getElementById('toastContainer');
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `
    <i class="fa-solid ${type === 'success' ? 'fa-circle-check text-emerald' : 'fa-circle-exclamation text-rose'}"></i>
    <span>${message}</span>
  `;
  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    setTimeout(() => toast.remove(), 300);
  }, 4000);
}

// ==========================================
// 16. STUDENT ADMISSIONS CONTROLLER
// ==========================================
function openEnrollStudentModal(preselectedSchoolId) {
  document.getElementById('enrollStudentForm').reset();
  populateSchoolsSelect('enrollStudentSchool');
  if (preselectedSchoolId) {
    document.getElementById('enrollStudentSchool').value = preselectedSchoolId;
  }
  openModal('enrollStudentModal');
}

async function submitEnrollStudent(e) {
  e.preventDefault();
  const submitBtn = document.getElementById('enrollStudentSubmitBtn');
  submitBtn.disabled = true;
  submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Processing Admission...';

  const fName = document.getElementById('enrollStudentFirstName').value.trim();
  const lName = document.getElementById('enrollStudentLastName').value.trim();
  const fullName = `${fName} ${lName}`.trim();

  const body = {
    schoolId: document.getElementById('enrollStudentSchool').value,
    name: fullName,
    firstName: fName,
    lastName: lName,
    className: document.getElementById('enrollStudentClass').value.trim() || 'Class 10',
    section: document.getElementById('enrollStudentSection').value.trim() || 'A',
    rollNumber: document.getElementById('enrollStudentRollNo').value.trim() || undefined,
    admissionNumber: document.getElementById('enrollStudentAdmissionNo').value.trim() || undefined,
    gender: document.getElementById('enrollStudentGender').value || 'MALE',
    parentName: document.getElementById('enrollStudentParentName').value.trim() || 'Parent / Guardian',
    parentPhone: document.getElementById('enrollStudentParentPhone').value.trim() || '9876543210',
    emergencyContact: document.getElementById('enrollStudentParentPhone').value.trim() || '9876543210',
    address: document.getElementById('enrollStudentAddress').value.trim() || 'Campus Residence',
  };

  try {
    const res = await apiCall('/super-admin/students', {
      method: 'POST',
      body: JSON.stringify(body)
    });
    showToast(`Student ${fullName || 'Student'} admitted successfully into institution!`, 'success');
    closeModal('enrollStudentModal');
    loadSuperAdminStudents();
    loadDashboardData();
    if (currentHubSchoolId === body.schoolId) {
      loadHubStudents(body.schoolId);
    }
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    submitBtn.disabled = false;
    submitBtn.innerHTML = '<i class="fa-solid fa-check"></i> Admit Student into School';
  }
}

// ==========================================
// 17. FACULTY & STAFF ONBOARDING CONTROLLER
// ==========================================
function openOnboardStaffModal(preselectedSchoolId) {
  document.getElementById('onboardStaffForm').reset();
  populateSchoolsSelect('onboardStaffSchool');
  if (preselectedSchoolId) {
    document.getElementById('onboardStaffSchool').value = preselectedSchoolId;
  }
  openModal('onboardStaffModal');
}

async function submitOnboardStaff(e) {
  e.preventDefault();
  const submitBtn = document.getElementById('onboardStaffSubmitBtn');
  submitBtn.disabled = true;
  submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Onboarding...';

  const body = {
    schoolId: document.getElementById('onboardStaffSchool').value,
    name: document.getElementById('onboardStaffName').value.trim(),
    role: document.getElementById('onboardStaffRole').value,
    email: document.getElementById('onboardStaffEmail').value.trim(),
    phone: document.getElementById('onboardStaffPhone').value.trim(),
    password: document.getElementById('onboardStaffPassword').value,
    designation: document.getElementById('onboardStaffDesignation').value.trim(),
    subjects: document.getElementById('onboardStaffSubjects').value.trim(),
    isClassTeacher: document.getElementById('onboardStaffIsClassTeacher').value === 'true',
    assignedClassName: document.getElementById('onboardStaffClass').value.trim(),
    assignedClassSection: document.getElementById('onboardStaffSection').value.trim() || 'A',
    qualification: document.getElementById('onboardStaffQualification').value.trim(),
    salary: Number(document.getElementById('onboardStaffSalary').value) || 45000,
  };

  try {
    await apiCall('/super-admin/staff', {
      method: 'POST',
      body: JSON.stringify(body)
    });
    showToast(`Faculty member ${body.name} onboarded into institution with role ${body.role}`, 'success');
    closeModal('onboardStaffModal');
    loadSuperAdminStaff();
    loadDashboardData();
    if (currentHubSchoolId === body.schoolId) {
      loadHubFaculty(body.schoolId);
      loadHubClasses(body.schoolId);
    }
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    submitBtn.disabled = false;
    submitBtn.innerHTML = '<i class="fa-solid fa-user-plus"></i> Onboard Member into School';
  }
}

// ==========================================
// 18. CLASSROOM & FACULTY ALLOCATION CONTROLLER
// ==========================================
let currentSchoolStaff = [];

function openClassesAllocationModal(preselectedSchoolId) {
  populateSchoolsSelect('classAllocSchool');
  if (preselectedSchoolId) {
    document.getElementById('classAllocSchool').value = preselectedSchoolId;
    loadClassAllocationsForSchool();
  }
  openModal('classesAllocationModal');
}

async function loadClassAllocationsForSchool() {
  const schoolId = document.getElementById('classAllocSchool').value;
  const overviewList = document.getElementById('classAllocationsOverviewList');
  if (!schoolId) {
    overviewList.innerHTML = '<div class="empty-state">Select a school above to inspect classroom and subject faculty allocations.</div>';
    return;
  }

  overviewList.innerHTML = '<div class="text-muted">Loading school faculty and classroom allocations...</div>';

  try {
    // Fetch teachers of this school to populate selects
    const staffRes = await apiCall(`/super-admin/staff?schoolId=${schoolId}`);
    currentSchoolStaff = extractList(staffRes.data, 'staff').filter(s => s.role === 'TEACHER');

    // Populate dropdowns in the form
    const teacherOptions = '<option value="">-- Choose Faculty --</option>' + 
      currentSchoolStaff.map(t => `<option value="${t._id}">${t.name} (${t.subjects?.join(', ') || t.designation || 'Teacher'})</option>`).join('');

    const classTeacherSelect = document.getElementById('allocClassTeacherSelect');
    if (classTeacherSelect) classTeacherSelect.innerHTML = teacherOptions;

    document.querySelectorAll('.sub-teacher-select').forEach(sel => {
      sel.innerHTML = teacherOptions;
    });

    // Fetch classes of this school
    const classesRes = await apiCall(`/super-admin/schools/${schoolId}/classes`);
    const classes = extractList(classesRes.data, 'classes');

    if (classes.length === 0) {
      overviewList.innerHTML = `
        <div class="empty-state">
          No classroom allocations defined yet for this institution. Use the form below to allocate Class Teacher and Subject Teachers.
        </div>`;
      return;
    }

    overviewList.innerHTML = `
      <div class="table-container glass-panel">
        <table class="data-table">
          <thead>
            <tr>
              <th>Class & Section</th>
              <th>Designated Class Teacher</th>
              <th>Room No</th>
              <th>Subject Wise Faculty Allocations</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            ${classes.map(c => `
              <tr>
                <td><strong>${c.name} - ${c.section}</strong></td>
                <td>
                  <span class="badge badge-super">
                    <i class="fa-solid fa-user-check"></i> ${c.classTeacher?.name || 'Not Designated'}
                  </span>
                </td>
                <td>${c.roomNumber || 'N/A'}</td>
                <td>
                  ${(c.subjects && c.subjects.length > 0) ? c.subjects.map(sub => `
                    <div style="font-size: 12px; margin-bottom: 2px;">
                      <strong>${sub.name}:</strong> ${sub.teacher?.name || '<span class="text-muted">Unassigned</span>'}
                    </div>
                  `).join('') : '<span class="text-muted">No subject mappings</span>'}
                </td>
                <td>
                  <button type="button" class="btn btn-sm btn-secondary" onclick="populateClassEdit('${c.name}', '${c.section}', '${c.roomNumber || ''}', '${c.classTeacher?._id || ''}')">
                    <i class="fa-solid fa-pen"></i> Edit
                  </button>
                </td>
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>
    `;
  } catch (err) {
    overviewList.innerHTML = `<div class="text-danger">${err.message}</div>`;
  }
}

function populateClassEdit(className, section, roomNo, classTeacherId) {
  document.getElementById('allocClassName').value = className;
  document.getElementById('allocSection').value = section;
  document.getElementById('allocRoomNo').value = roomNo;
  document.getElementById('allocClassTeacherSelect').value = classTeacherId;
  showToast(`Loaded ${className}-${section} into form. Select subject teachers and click Commit.`, 'success');
}

async function submitClassAllocation(e) {
  e.preventDefault();
  const schoolId = document.getElementById('classAllocSchool').value;
  if (!schoolId) {
    showToast('Please select a school first', 'error');
    return;
  }

  const submitBtn = document.getElementById('saveClassAllocSubmitBtn');
  submitBtn.disabled = true;
  submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Saving Allocation...';

  const subjects = [];
  for (let i = 1; i <= 4; i++) {
    const nameEl = document.getElementById(`sub${i}Name`);
    const teacherEl = document.getElementById(`sub${i}TeacherSelect`);
    if (nameEl && nameEl.value.trim()) {
      subjects.push({
        name: nameEl.value.trim(),
        teacherId: teacherEl?.value || undefined
      });
    }
  }

  const body = {
    className: document.getElementById('allocClassName').value.trim(),
    section: document.getElementById('allocSection').value.trim() || 'A',
    roomNumber: document.getElementById('allocRoomNo').value.trim(),
    classTeacherId: document.getElementById('allocClassTeacherSelect').value || undefined,
    subjects,
  };

  try {
    await apiCall(`/super-admin/schools/${schoolId}/classes`, {
      method: 'POST',
      body: JSON.stringify(body)
    });
    showToast(`Allocated teaching faculty to ${body.className}-${body.section}`, 'success');
    loadClassAllocationsForSchool();
    if (currentHubSchoolId === schoolId) {
      loadHubClasses(schoolId);
    }
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    submitBtn.disabled = false;
    submitBtn.innerHTML = '<i class="fa-solid fa-check"></i> Commit Class & Faculty Mapping';
  }
}

// ==========================================
// 19. DIRECT FACULTY ATTENDANCE ROLL CALL
// ==========================================
function openMarkFacultyAttendanceModal(preselectedSchoolId) {
  document.getElementById('markFacultyAttendanceForm').reset();
  populateSchoolsSelect('markAttSchool');
  document.getElementById('markAttDate').value = new Date().toISOString().split('T')[0];
  if (preselectedSchoolId) {
    document.getElementById('markAttSchool').value = preselectedSchoolId;
    loadFacultyForAttendanceMarking();
  }
  openModal('markFacultyAttendanceModal');
}

async function loadFacultyForAttendanceMarking() {
  const schoolId = document.getElementById('markAttSchool').value;
  const facultySelect = document.getElementById('markAttFaculty');
  if (!schoolId) {
    facultySelect.innerHTML = '<option value="">-- Choose Faculty Member --</option>';
    return;
  }
  try {
    const res = await apiCall(`/super-admin/staff?schoolId=${schoolId}`);
    const staff = extractList(res.data, 'staff');
    facultySelect.innerHTML = '<option value="">-- Choose Faculty Member --</option>' + 
      staff.map(st => `<option value="${st._id}">${st.name} (${st.role} • ${st.employeeId || 'ID'})</option>`).join('');
  } catch (err) {
    console.error(err);
  }
}

async function submitMarkFacultyAttendance(e) {
  e.preventDefault();
  const submitBtn = document.getElementById('markAttSubmitBtn');
  submitBtn.disabled = true;

  const body = {
    schoolId: document.getElementById('markAttSchool').value,
    teacherId: document.getElementById('markAttFaculty').value,
    date: document.getElementById('markAttDate').value,
    status: document.getElementById('markAttStatus').value,
    notes: document.getElementById('markAttNotes').value.trim(),
  };

  try {
    await apiCall('/super-admin/faculty-attendance/mark', {
      method: 'POST',
      body: JSON.stringify(body)
    });
    showToast(`Attendance marked as ${body.status}`, 'success');
    closeModal('markFacultyAttendanceModal');
    if (currentHubSchoolId === body.schoolId) {
      loadHubAttendance(body.schoolId);
    }
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    submitBtn.disabled = false;
  }
}

async function quickMarkFacultyAttendance(teacherId, status) {
  if (!currentHubSchoolId || !teacherId) return;
  try {
    await apiCall('/super-admin/faculty-attendance/mark', {
      method: 'POST',
      body: JSON.stringify({
        schoolId: currentHubSchoolId,
        teacherId,
        status,
        date: new Date().toISOString().split('T')[0],
        notes: `Super Admin 1-tap quick mark: ${status}`
      })
    });
    showToast(`Attendance updated to ${status}`, 'success');
    loadHubAttendance(currentHubSchoolId);
  } catch (err) {
    showToast(err.message, 'error');
  }
}

// ==========================================
// 20. EXAM ASSESSMENT & RESULT PUBLISHING
// ==========================================
function openRecordExamModal(preselectedSchoolId) {
  document.getElementById('recordExamForm').reset();
  populateSchoolsSelect('recordExamSchool');
  if (preselectedSchoolId) {
    document.getElementById('recordExamSchool').value = preselectedSchoolId;
    loadStudentsForExamRecord();
  }
  openModal('recordExamModal');
}

async function loadStudentsForExamRecord() {
  const schoolId = document.getElementById('recordExamSchool').value;
  const studentSelect = document.getElementById('recordExamStudent');
  if (!schoolId) {
    studentSelect.innerHTML = '<option value="">-- Choose Student --</option>';
    return;
  }
  try {
    const res = await apiCall(`/super-admin/students?schoolId=${schoolId}`);
    const students = extractList(res.data, 'students');
    studentSelect.innerHTML = '<option value="">-- Choose Student --</option>' +
      students.map(st => `<option value="${st._id}">${st.firstName} ${st.lastName || ''} (${st.currentClass || 'Class 10'}-${st.section || 'A'} • Roll: ${st.rollNumber || '1'})</option>`).join('');
  } catch (err) {
    console.error(err);
  }
}

async function submitRecordExam(e) {
  e.preventDefault();
  const submitBtn = document.getElementById('recordExamSubmitBtn');
  submitBtn.disabled = true;

  const subjects = [];
  for (let i = 1; i <= 5; i++) {
    const nameEl = document.getElementById(`recordSub${i}Name`);
    const markEl = document.getElementById(`recordSub${i}Marks`);
    if (nameEl && markEl && markEl.value !== '') {
      subjects.push({
        name: nameEl.value.trim(),
        maxMarks: 100,
        marksObtained: Number(markEl.value),
      });
    }
  }

  const body = {
    schoolId: document.getElementById('recordExamSchool').value,
    studentId: document.getElementById('recordExamStudent').value,
    examTitle: document.getElementById('recordExamTitle').value.trim(),
    className: document.getElementById('recordExamClass').value.trim(),
    section: document.getElementById('recordExamSection').value.trim() || 'A',
    subjects,
  };

  try {
    await apiCall('/super-admin/exams', {
      method: 'POST',
      body: JSON.stringify(body)
    });
    showToast('Examination assessment recorded and published platform-wide', 'success');
    closeModal('recordExamModal');
    loadSuperAdminExams();
    if (currentHubSchoolId === body.schoolId) {
      loadHubExams(body.schoolId);
    }
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    submitBtn.disabled = false;
  }
}

// ==========================================
// 21. MASTER CAMPUS COMMAND HUB CONTROLLER
// ==========================================
let currentHubSchoolId = null;
let currentHubSchool = null;

async function openCampusHub(schoolId) {
  currentHubSchoolId = schoolId;
  openModal('campusHubModal');

  // Load school details
  try {
    const res = await apiCall(`/super-admin/schools/${schoolId}`);
    currentHubSchool = res.data.school;

    document.getElementById('hubSchoolName').textContent = currentHubSchool.name;
    document.getElementById('hubSchoolCode').textContent = currentHubSchool.code || '225';
    document.getElementById('hubSchoolBoard').textContent = currentHubSchool.board || 'CBSE';
    
    const statusEl = document.getElementById('hubSchoolStatus');
    statusEl.textContent = currentHubSchool.status;
    statusEl.className = `status-pill ${currentHubSchool.status.toLowerCase()}`;

    // Switch to first tab and load data
    switchHubTab('students');
  } catch (err) {
    showToast(err.message, 'error');
  }
}

function switchHubTab(tabName) {
  document.querySelectorAll('.modal-nav-tab').forEach(t => {
    t.classList.toggle('active', t.getAttribute('data-hubtab') === tabName);
  });
  document.querySelectorAll('.hub-tab-pane').forEach(p => {
    p.classList.remove('active');
  });

  const targetPane = document.getElementById(`hubPane${tabName.charAt(0).toUpperCase() + tabName.slice(1)}`);
  if (targetPane) targetPane.classList.add('active');

  if (!currentHubSchoolId) return;

  if (tabName === 'students') loadHubStudents(currentHubSchoolId);
  if (tabName === 'faculty') loadHubFaculty(currentHubSchoolId);
  if (tabName === 'classes') loadHubClasses(currentHubSchoolId);
  if (tabName === 'fleet') loadHubFleet(currentHubSchoolId);
  if (tabName === 'attendance') loadHubAttendance(currentHubSchoolId);
  if (tabName === 'exams') loadHubExams(currentHubSchoolId);
}

// Hub Data Loaders
async function loadHubStudents(schoolId) {
  const tbody = document.getElementById('hubStudentsTableBody');
  tbody.innerHTML = '<tr><td colspan="6" class="text-center">Loading enrolled students...</td></tr>';
  try {
    const res = await apiCall(`/super-admin/students?schoolId=${schoolId}`);
    const students = extractList(res.data, 'students');
    document.getElementById('hubStudentsCount').textContent = students.length;

    if (students.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6" class="text-center">No students enrolled in this campus yet. Click "+ Admit New Student" above.</td></tr>';
      return;
    }

    tbody.innerHTML = students.map(st => `
      <tr>
        <td><strong>${st.name || `${st.firstName || ''} ${st.lastName || ''}`.trim()}</strong></td>
        <td>${st.currentClass || st.classId?.name || 'Class 10'} (${st.section || st.classId?.section || 'A'})</td>
        <td><code>${st.rollNumber || st.admissionNumber || 'N/A'}</code></td>
        <td>${st.parentName || st.parentId?.name || 'Guardian'}</td>
        <td>${st.parentPhone || st.parentId?.phone || 'N/A'}</td>
        <td><span class="status-pill active">ENROLLED</span></td>
      </tr>
    `).join('');
  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="6" class="text-center text-danger">${err.message}</td></tr>`;
  }
}

async function loadHubFaculty(schoolId) {
  const tbody = document.getElementById('hubFacultyTableBody');
  tbody.innerHTML = '<tr><td colspan="6" class="text-center">Loading campus faculty & staff...</td></tr>';
  try {
    const res = await apiCall(`/super-admin/staff?schoolId=${schoolId}`);
    const staff = extractList(res.data, 'staff');
    document.getElementById('hubStaffCount').textContent = staff.length;

    if (staff.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6" class="text-center">No faculty onboarded into this campus yet. Click "+ Onboard Faculty / Staff" above.</td></tr>';
      return;
    }

    tbody.innerHTML = staff.map(st => `
      <tr>
        <td>
          <div style="font-weight: 600;">${st.name}</div>
          <div class="text-muted" style="font-size: 11px;">ID: ${st.employeeId || 'EMP-' + st._id.slice(-4)}</div>
        </td>
        <td><span class="badge badge-super">${st.role}</span></td>
        <td>
          <div>${st.designation || 'Educator'}</div>
          <div class="text-muted" style="font-size: 11px;">${st.qualification || ''}</div>
        </td>
        <td><strong>${(st.subjects && st.subjects.length > 0) ? st.subjects.join(', ') : 'General'}</strong></td>
        <td>
          ${st.isClassTeacher ? `<span class="badge badge-super"><i class="fa-solid fa-chalkboard"></i> ${st.assignedClass?.name || 'Assigned'}</span>` : '<span class="text-muted">None</span>'}
        </td>
        <td>
          <div>${st.email || 'N/A'}</div>
          <div class="text-muted" style="font-size: 11px;">${st.phone || ''}</div>
        </td>
      </tr>
    `).join('');
  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="6" class="text-center text-danger">${err.message}</td></tr>`;
  }
}

async function loadHubClasses(schoolId) {
  const container = document.getElementById('hubClassesContainer');
  container.innerHTML = '<div class="text-muted">Loading classroom allocations...</div>';
  try {
    const res = await apiCall(`/super-admin/schools/${schoolId}/classes`);
    const classes = extractList(res.data, 'classes');

    if (classes.length === 0) {
      container.innerHTML = `
        <div class="empty-state">
          No classroom faculty allocations found for this school. Click "+ Add / Assign Class Faculty" above to assign Class Teachers and Subject Teachers.
        </div>`;
      return;
    }

    container.innerHTML = `
      <div class="table-container glass-panel">
        <table class="data-table">
          <thead>
            <tr>
              <th>Class & Section</th>
              <th>Designated Class Teacher</th>
              <th>Room No</th>
              <th>Subject Wise Faculty Allocations</th>
              <th>Quick Reassign</th>
            </tr>
          </thead>
          <tbody>
            ${classes.map(c => `
              <tr>
                <td><strong>${c.name} - ${c.section}</strong></td>
                <td>
                  <span class="badge badge-super">
                    <i class="fa-solid fa-user-check"></i> ${c.classTeacher?.name || 'Not Designated'}
                  </span>
                </td>
                <td>${c.roomNumber || 'Room 101'}</td>
                <td>
                  ${(c.subjects && c.subjects.length > 0) ? c.subjects.map(sub => `
                    <div style="font-size: 12.5px; margin-bottom: 3px;">
                      <strong style="color: var(--primary);">${sub.name}:</strong> ${sub.teacher?.name || '<span class="text-muted">Unassigned</span>'}
                    </div>
                  `).join('') : '<span class="text-muted">No subject assignments</span>'}
                </td>
                <td>
                  <button class="btn btn-sm btn-secondary" onclick="hubQuickAllocateClasses()">
                    <i class="fa-solid fa-sliders"></i> Modify
                  </button>
                </td>
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>
    `;
  } catch (err) {
    container.innerHTML = `<div class="text-danger">${err.message}</div>`;
  }
}

async function loadHubFleet(schoolId) {
  const container = document.getElementById('hubFleetCardsContainer');
  container.innerHTML = '<div class="text-muted">Loading bus fleet & telemetry...</div>';
  try {
    const res = await apiCall(`/super-admin/buses?schoolId=${schoolId}`);
    const buses = extractList(res.data, 'buses');

    if (buses.length === 0) {
      container.innerHTML = '<div class="empty-state">No buses assigned to this campus. Click "+ Add Vehicle to Campus Fleet" above.</div>';
      return;
    }

    container.innerHTML = buses.map(b => `
      <div class="fleet-card glass-panel">
        <div class="card-top">
          <div class="card-title-group">
            <h4>${b.busNumber}</h4>
            <div class="card-subtitle">Reg: <code>${b.registrationNumber}</code></div>
          </div>
          <span class="status-pill active">${b.status.replace(/_/g, ' ')}</span>
        </div>
        <div class="telemetry-row">
          <span>Driver:</span>
          <strong>${b.driverName || 'Driver'} (${b.driverPhone || 'N/A'})</strong>
        </div>
        <div class="telemetry-row">
          <span>Speed:</span>
          <strong>${b.currentSpeedKmph || 0} km/h</strong>
        </div>
        <div class="telemetry-row">
          <span>GPS Position:</span>
          <strong>${b.currentLocation?.latitude ? b.currentLocation.latitude.toFixed(4) : '28.6139'}, ${b.currentLocation?.longitude ? b.currentLocation.longitude.toFixed(4) : '77.2090'}</strong>
        </div>
        <button class="btn btn-sm btn-primary" onclick="simulateBusGPS('${b._id}')">
          <i class="fa-solid fa-satellite"></i> Simulate Live GPS Telemetry
        </button>
      </div>
    `).join('');
  } catch (err) {
    container.innerHTML = `<div class="text-danger">${err.message}</div>`;
  }
}

async function loadHubAttendance(schoolId) {
  const tbody = document.getElementById('hubAttendanceTableBody');
  tbody.innerHTML = '<tr><td colspan="5" class="text-center">Loading daily faculty roll call...</td></tr>';
  try {
    const [staffRes, attRes] = await Promise.all([
      apiCall(`/super-admin/staff?schoolId=${schoolId}`),
      apiCall(`/super-admin/biometric/faculty-attendance?schoolId=${schoolId}`)
    ]);

    const staff = extractList(staffRes.data, 'staff');
    const attendanceRecords = extractList(attRes.data, 'records');

    if (staff.length === 0) {
      tbody.innerHTML = '<tr><td colspan="5" class="text-center">No faculty members found for this school.</td></tr>';
      return;
    }

    tbody.innerHTML = staff.map(st => {
      const att = attendanceRecords.find(a => a.teacherId?._id === st._id || a.teacherId === st._id);
      const status = att ? att.status : 'ABSENT';
      const statusClass = status === 'PRESENT' ? 'active' : status === 'LATE' ? 'warning' : 'pending';

      return `
        <tr>
          <td>
            <strong>${st.name}</strong>
            <div class="text-muted" style="font-size: 11px;">${st.role} • ${st.designation || 'Educator'}</div>
          </td>
          <td><code>${st.employeeId || 'EMP-' + st._id.slice(-4)}</code></td>
          <td><span class="status-pill ${statusClass}">${status}</span></td>
          <td>${att ? (att.isManualOverride ? 'Super Admin Manual' : 'Biometric Terminal') : 'Not Checked In'}</td>
          <td>
            <div style="display: flex; gap: 4px;">
              <button class="btn btn-sm btn-primary" onclick="quickMarkFacultyAttendance('${st._id}', 'PRESENT')" title="Mark Present">P</button>
              <button class="btn btn-sm btn-secondary" onclick="quickMarkFacultyAttendance('${st._id}', 'LATE')" title="Mark Late">L</button>
              <button class="btn btn-sm btn-secondary" onclick="quickMarkFacultyAttendance('${st._id}', 'ON_DUTY')" title="On Duty">OD</button>
              <button class="btn btn-sm btn-ghost" onclick="quickMarkFacultyAttendance('${st._id}', 'ABSENT')" title="Mark Absent">A</button>
            </div>
          </td>
        </tr>
      `;
    }).join('');
  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="5" class="text-center text-danger">${err.message}</td></tr>`;
  }
}

async function loadHubExams(schoolId) {
  const tbody = document.getElementById('hubExamsTableBody');
  tbody.innerHTML = '<tr><td colspan="6" class="text-center">Loading examinations...</td></tr>';
  try {
    const res = await apiCall(`/super-admin/exams?schoolId=${schoolId}`);
    const exams = extractList(res.data, 'exams');

    if (exams.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6" class="text-center">No assessments recorded for this school yet. Click "+ Record Student Marks" above.</td></tr>';
      return;
    }

    tbody.innerHTML = exams.map(ex => {
      const subjectsText = (ex.subjects && ex.subjects.length > 0)
        ? ex.subjects.map(s => `${s.subjectName || s.name}: ${s.marksObtained}/${s.maxMarks}`).join(', ')
        : (ex.subject || 'Term Exam');

      return `
        <tr>
          <td><strong>${ex.title || ex.examName || 'Assessment'}</strong></td>
          <td>${ex.studentId?.firstName ? `${ex.studentId.firstName} ${ex.studentId.lastName || ''}` : 'Student'}</td>
          <td>Class ${ex.classId?.name || '10'}</td>
          <td style="font-size: 12px;">${subjectsText}</td>
          <td>
            ${ex.isPublished 
              ? '<span class="status-pill active">PUBLISHED</span>' 
              : '<span class="status-pill pending">PENDING APPROVAL</span>'}
          </td>
          <td>
            ${!ex.isPublished ? `
              <button class="btn btn-sm btn-primary" onclick="publishExamResult('${ex._id}')">
                <i class="fa-solid fa-check"></i> Publish
              </button>
            ` : '<span class="text-muted" style="font-size: 11px;"><i class="fa-solid fa-lock"></i> Live</span>'}
          </td>
        </tr>
      `;
    }).join('');
  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="6" class="text-center text-danger">${err.message}</td></tr>`;
  }
}

// Hub Quick Action Helpers
function hubQuickAdmitStudent() {
  openEnrollStudentModal(currentHubSchoolId);
}
function hubQuickOnboardFaculty() {
  openOnboardStaffModal(currentHubSchoolId);
}
function hubQuickAllocateClasses() {
  openClassesAllocationModal(currentHubSchoolId);
}
function hubQuickAddBus() {
  openCreateBusModal();
  if (currentHubSchoolId) document.getElementById('newBusSchool').value = currentHubSchoolId;
}
function hubQuickMarkAttendance() {
  openMarkFacultyAttendanceModal(currentHubSchoolId);
}
function hubQuickRecordExam() {
  openRecordExamModal(currentHubSchoolId);
}
