const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const ejs = require('ejs');
const path = require('path');

const prisma = new PrismaClient();

// Helper для рендера с layout
async function render(view, data) {
  const viewPath = path.join(__dirname, '../views/admin', view + '.ejs');
  const layoutPath = path.join(__dirname, '../views/admin/layout.ejs');

  const body = await ejs.renderFile(viewPath, data);
  return ejs.renderFile(layoutPath, { ...data, body });
}

// Dashboard
exports.dashboard = async (req, res) => {
  try {
    const stats = {
      totalUsers: await prisma.user.count(),
      premiumUsers: await prisma.user.count({ where: { isPremium: true } }),
      verifiedUsers: await prisma.user.count({ where: { emailVerified: true } }),
      vpnNodes: await prisma.vpnNode.count({ where: { status: 'active' } }),
      totalLogins: await prisma.loginHistory.count(),
      totalVpnConnections: await prisma.vpnConnection.count()
    };

    const html = await render('dashboard', { page: 'dashboard', stats });
    res.send(html);
  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).send('Error loading dashboard');
  }
};

// List Users
exports.listUsers = async (req, res) => {
  try {
    const { search, page = 1, limit = 20 } = req.query;
    const skip = (page - 1) * limit;

    const where = search ? {
      OR: [
        { email: { contains: search, mode: 'insensitive' } },
        { username: { contains: search, mode: 'insensitive' } },
        { vtNumber: { contains: search, mode: 'insensitive' } }
      ]
    } : {};

    const users = await prisma.user.findMany({
      where,
      select: {
        id: true,
        email: true,
        username: true,
        vtNumber: true,
        isPremium: true,
        emailVerified: true,
        createdAt: true,
        lastLoginAt: true,
        lastLoginIp: true,
        country: true
      },
      orderBy: { createdAt: 'desc' },
      skip: parseInt(skip),
      take: parseInt(limit)
    });

    const total = await prisma.user.count({ where });

    const html = await render('users', {
      page: 'users',
      users,
      search: search || '',
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });

    res.send(html);
  } catch (error) {
    console.error('List users error:', error);
    res.status(500).send('Error loading users');
  }
};

// View User Details
exports.viewUser = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await prisma.user.findUnique({
      where: { id },
      include: {
        loginHistory: {
          orderBy: { timestamp: 'desc' },
          take: 20
        },
        sessions: {
          where: { isActive: true },
          orderBy: { lastActive: 'desc' }
        },
        vpnConnections: {
          orderBy: { connectedAt: 'desc' },
          take: 10
        }
      }
    });

    if (!user) {
      return res.status(404).send('User not found');
    }

    const vpnStats = await prisma.vpnConnection.groupBy({
      by: ['nodeId'],
      where: { userId: id },
      _count: { id: true },
      _sum: { duration: true }
    });

    const totalVpnTime = await prisma.vpnConnection.aggregate({
      where: { userId: id },
      _sum: { duration: true }
    });

    const html = await render('user-detail', {
      page: 'users',
      user: {
        ...user,
        password: undefined,
        matrixAccessToken: undefined
      },
      stats: {
        vpn: {
          totalConnections: user.vpnConnections.length,
          totalTime: totalVpnTime._sum.duration || 0,
          byNode: vpnStats
        },
        logins: {
          total: user.loginHistory.length
        }
      }
    });

    res.send(html);
  } catch (error) {
    console.error('View user error:', error);
    res.status(500).send('Error loading user');
  }
};

// Ban User
exports.banUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;

    const user = await prisma.user.findUnique({
      where: { id }
    });

    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    // Ban user
    await prisma.user.update({
      where: { id },
      data: {
        isBanned: true,
        isPremium: false,
        emailVerified: false
      }
    });

    // Add to blacklist
    await prisma.bannedEmail.upsert({
      where: { email: user.email },
      create: {
        email: user.email,
        previousUsername: user.username,
        previousVtNumber: user.vtNumber,
        reason: reason || 'Banned by admin',
        bannedBy: 'admin'
      },
      update: {
        reason: reason || 'Banned by admin'
      }
    });

    res.json({
      success: true,
      message: 'User banned and added to blacklist'
    });
  } catch (error) {
    console.error('Ban user error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

// Unban User
exports.unbanUser = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await prisma.user.findUnique({
      where: { id }
    });

    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    // Unban user
    await prisma.user.update({
      where: { id },
      data: { isBanned: false }
    });

    // Remove from blacklist
    await prisma.bannedEmail.deleteMany({
      where: { email: user.email }
    });

    res.json({
      success: true,
      message: 'User unbanned and removed from blacklist'
    });
  } catch (error) {
    console.error('Unban user error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

// Delete User Permanently
exports.deleteUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;

    const user = await prisma.user.findUnique({
      where: { id }
    });

    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    // Add to blacklist
    await prisma.bannedEmail.upsert({
      where: { email: user.email },
      create: {
        email: user.email,
        previousUsername: user.username,
        previousVtNumber: user.vtNumber,
        reason: reason || 'Account deleted by admin',
        bannedBy: 'admin'
      },
      update: {
        previousUsername: user.username,
        previousVtNumber: user.vtNumber,
        reason: reason || 'Account deleted by admin'
      }
    });

    // Delete user (cascade will delete relations)
    await prisma.user.delete({
      where: { id }
    });

    res.json({
      success: true,
      message: 'User deleted and added to blacklist'
    });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

// Grant Premium
exports.grantPremium = async (req, res) => {
  try {
    const { id } = req.params;
    const { days = 30 } = req.body;

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + parseInt(days));

    await prisma.user.update({
      where: { id },
      data: {
        isPremium: true,
        premiumPlan: 'admin_granted',
        premiumExpiresAt: expiresAt
      }
    });

    res.json({
      success: true,
      message: `Premium granted for ${days} days`
    });
  } catch (error) {
    console.error('Grant premium error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

// Toggle Permission (VPN/AI/Premium)
exports.togglePermission = async (req, res) => {
  try {
    const { id, type } = req.params;
    const { enabled } = req.body;

    const updateData = {};

    if (type === 'premium') {
      updateData.isPremium = enabled;
      if (enabled) {
        // Premium включает ВСЕ доступы
        updateData.premiumPlan = 'admin_granted';
        updateData.premiumExpiresAt = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);
        updateData.hasVpnAccess = true;
        updateData.vpnExpiresAt = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);
        updateData.hasAiAccess = true;
        updateData.aiExpiresAt = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);
      } else {
        updateData.premiumExpiresAt = null;
      }
    } else if (type === 'vpn') {
    } else if (type === 'vpn') {
      updateData.hasVpnAccess = enabled;
    } else if (type === 'ai') {
      updateData.hasAiAccess = enabled;
    } else {
      return res.status(400).json({ success: false, error: 'Invalid permission type' });
    }

    await prisma.user.update({
      where: { id },
      data: updateData
    });

    res.json({
      success: true,
      message: `${type} ${enabled ? 'enabled' : 'disabled'}`
    });
  } catch (error) {
    console.error('Toggle permission error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

// Reset Password
exports.resetPassword = async (req, res) => {
  try {
    const { id } = req.params;

    const tempPassword = Math.random().toString(36).slice(-8).toUpperCase();
    const hashedPassword = await bcrypt.hash(tempPassword, 10);

    await prisma.user.update({
      where: { id },
      data: { password: hashedPassword }
    });

    res.json({
      success: true,
      message: 'Password reset successfully',
      data: { tempPassword }
    });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

// Set Custom Password
exports.setPassword = async (req, res) => {
  try {
    const { id } = req.params;
    const { password } = req.body;

    if (!password || password.length < 6) {
      return res.status(400).json({
        success: false,
        error: 'Password must be at least 6 characters'
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    await prisma.user.update({
      where: { id },
      data: { password: hashedPassword }
    });

    res.json({
      success: true,
      message: 'Password updated successfully'
    });
  } catch (error) {
    console.error('Set password error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

// List VPN Nodes
exports.listVpnNodes = async (req, res) => {
  try {
    const nodes = await prisma.vpnNode.findMany({
      orderBy: { createdAt: 'desc' }
    });

    const html = await render('vpn', { page: 'vpn', nodes });
    res.send(html);
  } catch (error) {
    console.error('List VPN nodes error:', error);
    res.status(500).send('Error loading VPN nodes');
  }
};

// List Activation Codes
exports.listCodes = async (req, res) => {
  try {
    const codes = await prisma.activationPassword.findMany({
      orderBy: { createdAt: 'desc' }
    });

    const html = await render('codes', { page: 'codes', codes });
    res.send(html);
  } catch (error) {
    console.error('List codes error:', error);
    res.status(500).send('Error loading codes');
  }
};

// Show Create Code Form
exports.showCreateCode = async (req, res) => {
  try {
    const html = await render('create-code', { page: 'codes' });
    res.send(html);
  } catch (error) {
    console.error('Show create code error:', error);
    res.status(500).send('Error loading form');
  }
};

// Create Activation Code
exports.createCode = async (req, res) => {
  try {
    let { password, plan, duration, maxUses } = req.body;

    if (!password || password.trim() === '') {
      password = Math.random().toString(36).substring(2, 12).toUpperCase();
    }

    const code = await prisma.activationPassword.create({
      data: {
        password: password.trim(),
        plan,
        duration: parseInt(duration),
        maxUses: parseInt(maxUses),
        createdBy: 'admin'
      }
    });

    res.json({
      success: true,
      data: code
    });
  } catch (error) {
    console.error('Create code error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

// Show Create VPN Form
exports.showCreateVpn = async (req, res) => {
  try {
    const html = await render('create-vpn', { page: 'vpn' });
    res.send(html);
  } catch (error) {
    console.error('Show create VPN error:', error);
    res.status(500).send('Error loading form');
  }
};

// Create VPN Node
exports.createVpnNode = async (req, res) => {
  try {
    const { nodeId, location, countryCode, endpoint, purpose, capacity, vlessUri } = req.body;

    const node = await prisma.vpnNode.create({
      data: {
        nodeId,
        location,
        countryCode: countryCode.toUpperCase(),
        endpoint,
        purpose,
        capacity: parseInt(capacity),
        vlessUri,
        configType: 'vless',
        status: 'active'
      }
    });

    res.json({
      success: true,
      data: node
    });
  } catch (error) {
    console.error('Create VPN node error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

// Show Create User Form
exports.showCreateUser = async (req, res) => {
  try {
    const html = await render('create-user', { page: 'users' });
    res.send(html);
  } catch (error) {
    console.error('Show create user error:', error);
    res.status(500).send('Error loading form');
  }
};

// Create User
exports.createUser = async (req, res) => {
  try {
    let { email, username, vtNumber, password, region, emailVerified, isPremium } = req.body;

    // Check if email is banned
    const banned = await prisma.bannedEmail.findUnique({
      where: { email }
    });

    if (banned) {
      return res.status(403).json({
        success: false,
        error: 'This email is banned and cannot register'
      });
    }

    if (!vtNumber || vtNumber.trim() === '') {
      vtNumber = 'VT-' + String(Math.floor(10000 + Math.random() * 90000));
    } else {
      vtNumber = 'VT-' + vtNumber.replace(/^VT-/, '');
    }

    const existing = await prisma.user.findFirst({
      where: {
        OR: [
          { email },
          { vtNumber },
          { username }
        ]
      }
    });

    if (existing) {
      let errorMsg = 'Already exists: ';
      if (existing.email === email) errorMsg += 'Email';
      else if (existing.vtNumber === vtNumber) errorMsg += 'VT-Number';
      else if (existing.username === username) errorMsg += 'Username';
      
      return res.status(400).json({
        success: false,
        error: errorMsg
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const numericPart = vtNumber.replace('VT-', '');
    const matrixUsername = `v${numericPart}`;
    const matrixUserId = `@${matrixUsername}:hypermax.duckdns.org`;

    const user = await prisma.user.create({
      data: {
        email,
        username,
        vtNumber,
        password: hashedPassword,
        region: region || 'RU',
        emailVerified: emailVerified || false,
        isPremium: isPremium || false,
        premiumPlan: isPremium ? 'admin_granted' : null,
        premiumExpiresAt: isPremium ? new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) : null,
        matrixUserId,
        registrationIp: req.ip || '127.0.0.1'
      }
    });

    try {
      const axios = require('axios');
      await axios.put(
        `http://localhost:8008/_synapse/admin/v2/users/${matrixUserId}`,
        {
          password: password,
          displayname: username,
          admin: false
        },
        {
          headers: {
            'Authorization': `Bearer ${process.env.MATRIX_ADMIN_TOKEN}`
          }
        }
      );
    } catch (matrixError) {
      console.error('Matrix user creation failed:', matrixError.message);
    }

    res.json({
      success: true,
      data: {
        id: user.id,
        email: user.email,
        username: user.username,
        vtNumber: user.vtNumber,
        matrixUserId: user.matrixUserId
      }
    });
  } catch (error) {
    console.error('Create user error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

// Show Edit User Form
exports.showEditUser = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await prisma.user.findUnique({
      where: { id }
    });

    if (!user) {
      return res.status(404).send('User not found');
    }

    const html = await render('edit-user', {
      page: 'users',
      user: {
        ...user,
        password: undefined,
        matrixAccessToken: undefined
      }
    });
    res.send(html);
  } catch (error) {
    console.error('Show edit user error:', error);
    res.status(500).send('Error loading form');
  }
};

// Edit User
exports.editUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { email, username, vtNumber, region, country } = req.body;

    const existing = await prisma.user.findFirst({
      where: {
        AND: [
          { id: { not: id } },
          {
            OR: [
              { email },
              { vtNumber },
              { username }
            ]
          }
        ]
      }
    });

    if (existing) {
      let errorMsg = 'Already taken: ';
      if (existing.email === email) errorMsg += 'Email';
      else if (existing.vtNumber === vtNumber) errorMsg += 'VT-Number';
      else if (existing.username === username) errorMsg += 'Username';
      
      return res.status(400).json({
        success: false,
        error: errorMsg
      });
    }

    await prisma.user.update({
      where: { id },
      data: {
        email,
        username,
        vtNumber,
        region,
        country: country || null
      }
    });

    res.json({
      success: true,
      message: 'User updated successfully'
    });
  } catch (error) {
    console.error('Edit user error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

// List Banned Emails
exports.listBannedEmails = async (req, res) => {
  try {
    const bannedEmails = await prisma.bannedEmail.findMany({
      orderBy: { bannedAt: 'desc' }
    });

    const html = await render('banlist', {
      page: 'banlist',
      bannedEmails
    });
    res.send(html);
  } catch (error) {
    console.error('List banned emails error:', error);
    res.status(500).send('Error loading banned emails');
  }
};

// Unban Email
exports.unbanEmail = async (req, res) => {
  try {
    const { id } = req.params;

    await prisma.bannedEmail.delete({
      where: { id }
    });

    res.json({
      success: true,
      message: 'Email unbanned'
    });
  } catch (error) {
    console.error('Unban email error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};


// Delete Activation Code
exports.deleteCode = async (req, res) => {
  try {
    const { id } = req.params;
    
    await prisma.activationPassword.delete({
      where: { id }
    });
    
    res.json({
      success: true,
      message: 'Code deleted successfully'
    });
  } catch (error) {
    console.error('Delete code error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};
