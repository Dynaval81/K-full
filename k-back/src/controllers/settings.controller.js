// Global settings management (appAdmin only)
const prisma = require('../lib/prisma');
const log = require('../lib/logger');

const DEFAULTS = {
  maintenanceMode:     'false',
  registrationEnabled: 'true',
  minAppVersion:       '1.0.0',
  maxMessageLength:    '4000',
};

const ALLOWED_KEYS = Object.keys(DEFAULTS);

exports.getSettings = async (req, res) => {
  try {
    const rows = await prisma.globalSettings.findMany();
    const stored = Object.fromEntries(rows.map(r => [r.key, r.value]));
    const settings = { ...DEFAULTS, ...stored };
    return res.json({ success: true, data: { settings } });
  } catch (error) {
    log.error(error, 'getSettings error:');
    return res.status(500).json({ success: false, error: 'Failed to load settings' });
  }
};

exports.updateSettings = async (req, res) => {
  try {
    const { settings } = req.body;
    if (!settings || typeof settings !== 'object' || Array.isArray(settings)) {
      return res.status(400).json({ success: false, error: 'settings must be an object' });
    }

    const ops = [];
    for (const [key, value] of Object.entries(settings)) {
      if (!ALLOWED_KEYS.includes(key)) continue;
      ops.push(
        prisma.globalSettings.upsert({
          where: { key },
          update: { value: String(value), updatedBy: req.user.id },
          create: { key, value: String(value), updatedBy: req.user.id },
        })
      );
    }
    if (!ops.length) {
      return res.status(400).json({ success: false, error: 'No valid settings keys provided' });
    }
    await prisma.$transaction(ops);

    // Bust maintenance cache immediately
    req.app.set('maintenanceCacheTime', 0);

    return res.json({ success: true });
  } catch (error) {
    log.error(error, 'updateSettings error:');
    return res.status(500).json({ success: false, error: 'Failed to update settings' });
  }
};
