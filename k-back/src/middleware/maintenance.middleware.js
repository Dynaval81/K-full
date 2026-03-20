// Maintenance mode middleware — blocks all non-admin requests when enabled.
// Result is cached for 30s to avoid a DB hit on every request.
const prisma = require('../lib/prisma');

const CACHE_TTL = 30_000; // ms

module.exports = async (req, res, next) => {
  // Admin routes, health check, and token refresh always pass through
  const bypass = ['/api/v1/admin', '/admin', '/health', '/api/v1/auth/refresh', '/api/v1/auth/login'];
  if (bypass.some(p => req.path.startsWith(p))) return next();

  const app = req.app;
  const now = Date.now();
  const cacheTime = app.get('maintenanceCacheTime') ?? 0;

  let maintenance = app.get('maintenanceMode') ?? false;

  if (now - cacheTime > CACHE_TTL) {
    try {
      const setting = await prisma.globalSettings.findUnique({ where: { key: 'maintenanceMode' } });
      maintenance = setting?.value === 'true';
      app.set('maintenanceMode', maintenance);
      app.set('maintenanceCacheTime', now);
    } catch {
      // DB unreachable — fail open (don't block users)
    }
  }

  if (maintenance) {
    return res.status(503).json({
      success: false,
      error: 'Server is undergoing maintenance. Please try again shortly.',
      code: 'MAINTENANCE_MODE',
    });
  }

  next();
};
