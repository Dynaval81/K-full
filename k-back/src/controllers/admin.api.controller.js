const prisma = require('../lib/prisma');

// ─── constants ───────────────────────────────────────────────────────────────

const VALID_ROLES = ['student', 'teacher', 'parent', 'schoolAdmin', 'appAdmin'];
const EXPIRES_IN_DAYS_MIN = 1;
const EXPIRES_IN_DAYS_MAX = 365;

// ─── helpers ────────────────────────────────────────────────────────────────

function generateCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no O/0, I/1
  const seg = () => Array.from({ length: 4 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
  return `KNOTY-${seg()}-${seg()}`;
}

async function generateUniqueCode() {
  for (let attempt = 0; attempt < 10; attempt++) {
    const code = generateCode();
    const existing = await prisma.activationCode.findUnique({ where: { code } });
    if (!existing) return code;
  }
  throw new Error('Failed to generate unique activation code after 10 attempts');
}

// ─── stats ───────────────────────────────────────────────────────────────────

exports.getStats = async (req, res) => {
  try {
    const [totalUsers, pendingUsers, totalSchools, unusedCodes, usedCodes] = await Promise.all([
      prisma.user.count(),
      prisma.user.count({ where: { isApproved: false, status: 'active' } }),
      prisma.school.count(),
      prisma.activationCode.count({ where: { status: 'unused' } }),
      prisma.activationCode.count({ where: { status: 'used' } }),
    ]);

    return res.json({
      success: true,
      data: { totalUsers, pendingUsers, totalSchools, unusedCodes, usedCodes },
    });
  } catch (error) {
    console.error('getStats error:', error);
    return res.status(500).json({ success: false, error: 'Failed to get stats' });
  }
};

// ─── schools ─────────────────────────────────────────────────────────────────

exports.listSchools = async (req, res) => {
  try {
    const schools = await prisma.school.findMany({
      orderBy: { name: 'asc' },
      include: {
        _count: { select: { users: true, activationCodes: true } },
      },
    });

    return res.json({ success: true, data: schools });
  } catch (error) {
    console.error('listSchools error:', error);
    return res.status(500).json({ success: false, error: 'Failed to list schools' });
  }
};

exports.createSchool = async (req, res) => {
  try {
    const { name, city, address } = req.body;

    if (!name || !city) {
      return res.status(400).json({ success: false, error: 'name and city are required' });
    }

    const school = await prisma.school.create({
      data: { name: name.trim(), city: city.trim(), address: address?.trim() || null },
    });

    return res.status(201).json({ success: true, data: school });
  } catch (error) {
    console.error('createSchool error:', error);
    return res.status(500).json({ success: false, error: 'Failed to create school' });
  }
};

exports.updateSchool = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, city, address } = req.body;

    const school = await prisma.school.update({
      where: { id },
      data: {
        ...(name && { name: name.trim() }),
        ...(city && { city: city.trim() }),
        ...(address !== undefined && { address: address?.trim() || null }),
      },
    });

    return res.json({ success: true, data: school });
  } catch (error) {
    if (error.code === 'P2025') {
      return res.status(404).json({ success: false, error: 'School not found' });
    }
    console.error('updateSchool error:', error);
    return res.status(500).json({ success: false, error: 'Failed to update school' });
  }
};

// ─── activation codes ────────────────────────────────────────────────────────

exports.listCodes = async (req, res) => {
  try {
    const { schoolId, status, classId } = req.query;

    const where = {};
    if (schoolId) where.schoolId = schoolId;
    if (status) where.status = status;
    if (classId) where.classId = classId;

    const codes = await prisma.activationCode.findMany({
      where,
      include: { school: { select: { id: true, name: true } } },
      orderBy: { createdAt: 'desc' },
    });

    return res.json({ success: true, data: codes });
  } catch (error) {
    console.error('listCodes error:', error);
    return res.status(500).json({ success: false, error: 'Failed to list codes' });
  }
};

exports.generateCodes = async (req, res) => {
  try {
    const { schoolId, classId, role = 'student', entries, expiresInDays = 30 } = req.body;

    // entries: [{ firstName, lastName }] or count (batch without names)
    if (!schoolId || !classId) {
      return res.status(400).json({ success: false, error: 'schoolId and classId are required' });
    }

    if (!VALID_ROLES.includes(role)) {
      return res.status(400).json({ success: false, error: `Invalid role. Allowed: ${VALID_ROLES.join(', ')}` });
    }

    const days = Number(expiresInDays);
    if (!Number.isInteger(days) || days < EXPIRES_IN_DAYS_MIN || days > EXPIRES_IN_DAYS_MAX) {
      return res.status(400).json({
        success: false,
        error: `expiresInDays must be an integer between ${EXPIRES_IN_DAYS_MIN} and ${EXPIRES_IN_DAYS_MAX}`,
      });
    }

    const school = await prisma.school.findUnique({ where: { id: schoolId } });
    if (!school) {
      return res.status(404).json({ success: false, error: 'School not found' });
    }

    const expiresAt = new Date(Date.now() + days * 24 * 60 * 60 * 1000);
    const createdBy = req.user.id;

    let toCreate = [];

    if (Array.isArray(entries) && entries.length > 0) {
      // Named codes — one per student/teacher
      for (const entry of entries) {
        if (!entry.firstName || !entry.lastName) continue;
        const code = await generateUniqueCode();
        toCreate.push({
          code,
          schoolId,
          classId,
          role,
          firstName: entry.firstName.trim(),
          lastName: entry.lastName.trim(),
          expiresAt,
          createdBy,
        });
      }
    } else {
      return res.status(400).json({ success: false, error: 'entries array is required' });
    }

    if (toCreate.length === 0) {
      return res.status(400).json({ success: false, error: 'No valid entries provided' });
    }

    const created = await prisma.activationCode.createMany({ data: toCreate });

    // Return the codes we just created
    const codes = await prisma.activationCode.findMany({
      where: { createdBy, schoolId, classId, createdAt: { gte: new Date(Date.now() - 5000) } },
      orderBy: { createdAt: 'desc' },
    });

    return res.status(201).json({ success: true, count: created.count, data: codes });
  } catch (error) {
    console.error('generateCodes error:', error);
    return res.status(500).json({ success: false, error: 'Failed to generate codes' });
  }
};

exports.deleteCode = async (req, res) => {
  try {
    const { code } = req.params;

    const existing = await prisma.activationCode.findUnique({ where: { code } });
    if (!existing) {
      return res.status(404).json({ success: false, error: 'Code not found' });
    }
    if (existing.status === 'used') {
      return res.status(400).json({ success: false, error: 'Cannot delete a used code' });
    }

    await prisma.activationCode.delete({ where: { code } });

    return res.json({ success: true, message: 'Code deleted' });
  } catch (error) {
    console.error('deleteCode error:', error);
    return res.status(500).json({ success: false, error: 'Failed to delete code' });
  }
};

// ─── users ───────────────────────────────────────────────────────────────────

exports.listUsers = async (req, res) => {
  try {
    const { schoolId, status, role, pending, search, page = 1, limit = 50 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const where = {};
    if (schoolId) where.schoolId = schoolId;
    if (status) where.status = status;
    if (role) where.role = role;
    if (pending === 'true') where.isApproved = false;
    if (search) {
      where.OR = [
        { email: { contains: search, mode: 'insensitive' } },
        { firstName: { contains: search, mode: 'insensitive' } },
        { lastName: { contains: search, mode: 'insensitive' } },
        { knNumber: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        select: {
          id: true, email: true, firstName: true, lastName: true,
          knNumber: true, role: true, verificationLevel: true,
          isApproved: true, status: true, schoolId: true, classId: true,
          createdAt: true, lastLoginAt: true,
          school: { select: { id: true, name: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: parseInt(limit),
      }),
      prisma.user.count({ where }),
    ]);

    return res.json({
      success: true,
      data: users,
      pagination: { page: parseInt(page), limit: parseInt(limit), total, pages: Math.ceil(total / parseInt(limit)) },
    });
  } catch (error) {
    console.error('listUsers error:', error);
    return res.status(500).json({ success: false, error: 'Failed to list users' });
  }
};

exports.approveUser = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });

    await prisma.user.update({
      where: { id },
      data: { isApproved: true, verificationLevel: 'schoolVerified' },
    });

    return res.json({ success: true, message: 'User approved' });
  } catch (error) {
    console.error('approveUser error:', error);
    return res.status(500).json({ success: false, error: 'Failed to approve user' });
  }
};

exports.banUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;

    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });

    await prisma.user.update({
      where: { id },
      data: {
        status: 'banned',
        banReason: reason || 'Banned by admin',
        bannedAt: new Date(),
        bannedBy: req.user.id,
      },
    });

    // Blacklist the email
    await prisma.bannedEmail.upsert({
      where: { email: user.email },
      create: { email: user.email, reason: reason || 'Banned by admin', bannedBy: req.user.id },
      update: { reason: reason || 'Banned by admin' },
    });

    return res.json({ success: true, message: 'User banned' });
  } catch (error) {
    console.error('banUser error:', error);
    return res.status(500).json({ success: false, error: 'Failed to ban user' });
  }
};

exports.unbanUser = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });

    await prisma.user.update({
      where: { id },
      data: { status: 'active', banReason: null, bannedAt: null, bannedBy: null },
    });

    await prisma.bannedEmail.deleteMany({ where: { email: user.email } });

    return res.json({ success: true, message: 'User unbanned' });
  } catch (error) {
    console.error('unbanUser error:', error);
    return res.status(500).json({ success: false, error: 'Failed to unban user' });
  }
};
