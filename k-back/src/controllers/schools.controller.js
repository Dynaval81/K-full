const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Публичный список школ (для экрана регистрации)
exports.getPublicSchools = async (req, res) => {
  try {
    const schools = await prisma.school.findMany({
      select: { id: true, name: true, city: true },
      orderBy: { name: 'asc' },
    });
    return res.json({ success: true, schools });
  } catch (error) {
    console.error('getPublicSchools error:', error);
    return res.status(500).json({ success: false, error: 'Failed to load schools' });
  }
};
