// Classes management
const prisma = require('../lib/prisma');
const log = require('../lib/logger');

// GET /api/v1/classes — list classes in current user's school
exports.listClasses = async (req, res) => {
  try {
    const { schoolId } = req.user;
    if (!schoolId) {
      return res.status(400).json({ success: false, error: 'User is not assigned to a school' });
    }

    const classes = await prisma.schoolClass.findMany({
      where: { schoolId },
      orderBy: { name: 'asc' },
      include: { _count: { select: {} } }, // placeholder
    });

    // Count members per class (users with matching schoolId + classId string)
    const result = await Promise.all(
      classes.map(async (c) => {
        const memberCount = await prisma.user.count({
          where: { schoolId, classId: c.name, status: 'active' },
        });
        return {
          id: c.id,
          name: c.name,
          schoolId: c.schoolId,
          teacherId: c.teacherId,
          memberCount,
          createdAt: c.createdAt,
        };
      })
    );

    return res.json({ success: true, data: { classes: result } });
  } catch (error) {
    log.error(error, 'listClasses error:');
    return res.status(500).json({ success: false, error: 'Failed to load classes' });
  }
};

// POST /api/v1/classes — create class (schoolAdmin or appAdmin)
exports.createClass = async (req, res) => {
  try {
    const { role, schoolId } = req.user;
    const { name, teacherId } = req.body;

    if (!['schoolAdmin', 'appAdmin'].includes(role)) {
      return res.status(403).json({ success: false, error: 'Insufficient permissions' });
    }
    if (!name?.trim()) {
      return res.status(400).json({ success: false, error: 'Class name is required' });
    }
    if (!schoolId) {
      return res.status(400).json({ success: false, error: 'User is not assigned to a school' });
    }

    const existing = await prisma.schoolClass.findUnique({
      where: { name_schoolId: { name: name.trim(), schoolId } },
    });
    if (existing) {
      return res.status(409).json({ success: false, error: 'Class already exists in this school' });
    }

    const newClass = await prisma.schoolClass.create({
      data: { name: name.trim(), schoolId, teacherId: teacherId ?? null },
    });

    return res.status(201).json({ success: true, data: { class: newClass } });
  } catch (error) {
    log.error(error, 'createClass error:');
    return res.status(500).json({ success: false, error: 'Failed to create class' });
  }
};

// PUT /api/v1/classes/:id — update class (schoolAdmin or appAdmin)
exports.updateClass = async (req, res) => {
  try {
    const { role, schoolId } = req.user;
    const { id } = req.params;
    const { name, teacherId } = req.body;

    if (!['schoolAdmin', 'appAdmin'].includes(role)) {
      return res.status(403).json({ success: false, error: 'Insufficient permissions' });
    }

    const existing = await prisma.schoolClass.findUnique({ where: { id } });
    if (!existing || existing.schoolId !== schoolId) {
      return res.status(404).json({ success: false, error: 'Class not found' });
    }

    const updated = await prisma.schoolClass.update({
      where: { id },
      data: {
        ...(name?.trim() ? { name: name.trim() } : {}),
        ...(teacherId !== undefined ? { teacherId: teacherId ?? null } : {}),
      },
    });

    return res.json({ success: true, data: { class: updated } });
  } catch (error) {
    log.error(error, 'updateClass error:');
    return res.status(500).json({ success: false, error: 'Failed to update class' });
  }
};

// GET /api/v1/classes/:id/members — list members of a class
exports.getClassMembers = async (req, res) => {
  try {
    const { schoolId } = req.user;
    const { id } = req.params;

    const classData = await prisma.schoolClass.findUnique({ where: { id } });
    if (!classData || classData.schoolId !== schoolId) {
      return res.status(404).json({ success: false, error: 'Class not found' });
    }

    const members = await prisma.user.findMany({
      where: { schoolId, classId: classData.name, status: 'active' },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        knNumber: true,
        role: true,
        isApproved: true,
        email: true,
      },
      orderBy: [{ lastName: 'asc' }, { firstName: 'asc' }],
    });

    return res.json({
      success: true,
      data: {
        class: { id: classData.id, name: classData.name, teacherId: classData.teacherId },
        members,
      },
    });
  } catch (error) {
    log.error(error, 'getClassMembers error:');
    return res.status(500).json({ success: false, error: 'Failed to load class members' });
  }
};
