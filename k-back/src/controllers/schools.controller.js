const prisma = require('../lib/prisma');
const log = require('../lib/logger');

// Публичный список школ (для экрана регистрации)
exports.getPublicSchools = async (req, res) => {
  try {
    const schools = await prisma.school.findMany({
      select: { id: true, name: true, city: true },
      orderBy: { name: 'asc' },
    });
    return res.json({ success: true, schools });
  } catch (error) {
    log.error(error, 'getPublicSchools error:');
    return res.status(500).json({ success: false, error: 'Failed to load schools' });
  }
};
