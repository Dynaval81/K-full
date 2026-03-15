// Socket.io handler — real-time messaging, presence, typing
const jwt = require('jsonwebtoken');
const prisma = require('../lib/prisma');

// userId → Set<socketId>
const onlineUsers = new Map();

function getOnlineSet() {
  return new Set(onlineUsers.keys());
}

async function broadcastPresence(io, userId, isOnline) {
  try {
    const participants = await prisma.chatParticipant.findMany({
      where: { userId },
      select: { chatId: true },
    });
    for (const { chatId } of participants) {
      io.to(`chat:${chatId}`).emit('user:presence', { userId, isOnline });
    }
  } catch { /* best-effort */ }
}

function setupSocket(io) {
  // ── JWT auth middleware ───────────────────────────────────────────────────
  io.use(async (socket, next) => {
    try {
      const token =
        socket.handshake.auth?.token ??
        socket.handshake.query?.token;
      if (!token) return next(new Error('Authentication required'));

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await prisma.user.findUnique({ where: { id: decoded.userId } });
      if (!user || user.status !== 'active') return next(new Error('Invalid user'));

      socket.userId = user.id;
      socket.user = user;
      next();
    } catch {
      next(new Error('Authentication failed'));
    }
  });

  // ── Connection ────────────────────────────────────────────────────────────
  io.on('connection', async (socket) => {
    const userId = socket.userId;

    // Track presence
    if (!onlineUsers.has(userId)) onlineUsers.set(userId, new Set());
    onlineUsers.get(userId).add(socket.id);

    // Auto-join all personal chat rooms
    socket.join(`user:${userId}`);
    try {
      const participants = await prisma.chatParticipant.findMany({
        where: { userId },
        select: { chatId: true },
      });
      for (const { chatId } of participants) {
        socket.join(`chat:${chatId}`);
      }
    } catch { /* non-fatal */ }

    broadcastPresence(io, userId, true);

    // ── Events ─────────────────────────────────────────────────────────────

    // Join a specific chat room (after creating a new chat)
    socket.on('chat:join', async ({ chatId }) => {
      try {
        const p = await prisma.chatParticipant.findUnique({
          where: { chatId_userId: { chatId, userId } },
        });
        if (p) socket.join(`chat:${chatId}`);
      } catch { /* ignore */ }
    });

    // Typing indicators
    socket.on('typing:start', ({ chatId }) => {
      socket.to(`chat:${chatId}`).emit('typing', { chatId, userId, isTyping: true });
    });
    socket.on('typing:stop', ({ chatId }) => {
      socket.to(`chat:${chatId}`).emit('typing', { chatId, userId, isTyping: false });
    });

    // Mark read via socket (alternative to REST)
    socket.on('message:read', async ({ chatId }) => {
      try {
        await prisma.$transaction([
          prisma.chatParticipant.updateMany({
            where: { chatId, userId },
            data: { unread: 0 },
          }),
          prisma.message.updateMany({
            where: { chatId, senderId: { not: userId }, status: { not: 'read' } },
            data: { status: 'read' },
          }),
        ]);
        io.to(`chat:${chatId}`).emit('message:read', { chatId, byUserId: userId });
      } catch { /* ignore */ }
    });

    // ── Disconnect ──────────────────────────────────────────────────────────
    socket.on('disconnect', () => {
      const sockets = onlineUsers.get(userId);
      if (sockets) {
        sockets.delete(socket.id);
        if (sockets.size === 0) {
          onlineUsers.delete(userId);
          broadcastPresence(io, userId, false);
        }
      }
    });
  });
}

module.exports = { setupSocket, getOnlineSet };
