// Parent ↔ Child linking
const prisma = require('../lib/prisma');
const log = require('../lib/logger');

const childSelect = {
  id: true, firstName: true, lastName: true, knNumber: true,
  schoolId: true, classId: true, role: true,
  school: { select: { name: true, city: true } },
};
const parentSelect = {
  id: true, firstName: true, lastName: true, knNumber: true,
};

// POST /api/v1/family/link — parent requests link using child's KN number
exports.requestLink = async (req, res) => {
  try {
    if (req.user.role !== 'parent') {
      return res.status(403).json({ success: false, error: 'Only parents can link to children' });
    }

    const parentId = req.user.id;
    const childKnNumber = req.body.childKnNumber.toUpperCase();

    const child = await prisma.user.findUnique({ where: { knNumber: childKnNumber } });
    if (!child) {
      return res.status(404).json({ success: false, error: 'Student not found' });
    }
    if (child.role !== 'student') {
      return res.status(400).json({ success: false, error: 'Target user must be a student' });
    }
    if (child.id === parentId) {
      return res.status(400).json({ success: false, error: 'Cannot link to yourself' });
    }

    const existing = await prisma.parentChild.findUnique({
      where: { parentId_childId: { parentId, childId: child.id } },
    });
    if (existing) {
      return res.status(409).json({
        success: false,
        error: 'Link already exists',
        data: { status: existing.status, linkId: existing.id },
      });
    }

    const link = await prisma.parentChild.create({
      data: { parentId, childId: child.id, status: 'pending' },
    });

    // Notify child in real-time
    const io = req.app.get('io');
    if (io) {
      io.to(`user:${child.id}`).emit('family:link_request', {
        linkId: link.id,
        parentId,
        parentName: `${req.user.firstName ?? ''} ${req.user.lastName ?? ''}`.trim(),
        parentKnNumber: req.user.knNumber,
      });
    }

    return res.status(201).json({
      success: true,
      data: { linkId: link.id, status: 'pending' },
    });
  } catch (error) {
    log.error(error, 'requestLink error:');
    return res.status(500).json({ success: false, error: 'Failed to request link' });
  }
};

// POST /api/v1/family/link/:id/accept — child accepts
exports.acceptLink = async (req, res) => {
  try {
    const childId = req.user.id;
    const { id } = req.params;

    const link = await prisma.parentChild.findUnique({ where: { id } });
    if (!link || link.childId !== childId) {
      return res.status(404).json({ success: false, error: 'Link request not found' });
    }
    if (link.status !== 'pending') {
      return res.status(400).json({ success: false, error: 'Link is not in pending state' });
    }

    await prisma.parentChild.update({ where: { id }, data: { status: 'active' } });

    const io = req.app.get('io');
    if (io) {
      io.to(`user:${link.parentId}`).emit('family:link_accepted', {
        linkId: id,
        childName: `${req.user.firstName ?? ''} ${req.user.lastName ?? ''}`.trim(),
        childKnNumber: req.user.knNumber,
      });
    }

    return res.json({ success: true, data: { status: 'active' } });
  } catch (error) {
    log.error(error, 'acceptLink error:');
    return res.status(500).json({ success: false, error: 'Failed to accept link' });
  }
};

// POST /api/v1/family/link/:id/reject — child rejects or parent cancels
exports.rejectLink = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const link = await prisma.parentChild.findUnique({ where: { id } });
    if (!link || (link.childId !== userId && link.parentId !== userId)) {
      return res.status(404).json({ success: false, error: 'Link not found' });
    }

    await prisma.parentChild.delete({ where: { id } });

    // Notify the other party
    const io = req.app.get('io');
    if (io) {
      const otherUserId = link.childId === userId ? link.parentId : link.childId;
      io.to(`user:${otherUserId}`).emit('family:link_rejected', { linkId: id });
    }

    return res.json({ success: true });
  } catch (error) {
    log.error(error, 'rejectLink error:');
    return res.status(500).json({ success: false, error: 'Failed to reject link' });
  }
};

// DELETE /api/v1/family/link/:id — unlink active connection
exports.deleteLink = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const link = await prisma.parentChild.findUnique({ where: { id } });
    if (!link || (link.childId !== userId && link.parentId !== userId)) {
      return res.status(404).json({ success: false, error: 'Link not found' });
    }

    await prisma.parentChild.delete({ where: { id } });

    const io = req.app.get('io');
    if (io) {
      const otherUserId = link.childId === userId ? link.parentId : link.childId;
      io.to(`user:${otherUserId}`).emit('family:link_removed', { linkId: id });
    }

    return res.json({ success: true });
  } catch (error) {
    log.error(error, 'deleteLink error:');
    return res.status(500).json({ success: false, error: 'Failed to delete link' });
  }
};

// GET /api/v1/family/children — parent views linked children
exports.getChildren = async (req, res) => {
  try {
    const parentId = req.user.id;

    const links = await prisma.parentChild.findMany({
      where: { parentId, status: 'active' },
      include: { child: { select: childSelect } },
      orderBy: { createdAt: 'asc' },
    });

    return res.json({
      success: true,
      data: {
        children: links.map(l => ({
          linkId: l.id,
          id: l.child.id,
          firstName: l.child.firstName,
          lastName: l.child.lastName,
          knNumber: l.child.knNumber,
          schoolId: l.child.schoolId,
          schoolName: l.child.school?.name ?? null,
          classId: l.child.classId,
          role: l.child.role,
        })),
      },
    });
  } catch (error) {
    log.error(error, 'getChildren error:');
    return res.status(500).json({ success: false, error: 'Failed to get children' });
  }
};

// GET /api/v1/family/parents — child views linked parents
exports.getParents = async (req, res) => {
  try {
    const childId = req.user.id;

    const [active, pending] = await Promise.all([
      prisma.parentChild.findMany({
        where: { childId, status: 'active' },
        include: { parent: { select: parentSelect } },
      }),
      prisma.parentChild.findMany({
        where: { childId, status: 'pending' },
        include: { parent: { select: parentSelect } },
      }),
    ]);

    return res.json({
      success: true,
      data: {
        parents: active.map(l => ({ linkId: l.id, ...l.parent })),
        pendingRequests: pending.map(l => ({
          linkId: l.id,
          parent: l.parent,
          createdAt: l.createdAt,
        })),
      },
    });
  } catch (error) {
    log.error(error, 'getParents error:');
    return res.status(500).json({ success: false, error: 'Failed to get parents' });
  }
};
