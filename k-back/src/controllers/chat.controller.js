// v2.0.0 — Prisma-based chat (replaces Matrix integration)
const prisma = require('../lib/prisma');
const log = require('../lib/logger');

// ── Helpers ───────────────────────────────────────────────────────────────────

function userSelect() {
  return { id: true, firstName: true, lastName: true, knNumber: true, role: true };
}

function formatChat(chat, userId, onlineSet = new Set()) {
  const me = chat.participants.find(p => p.userId === userId);
  const lastMsg = chat.messages[0] || null;

  let name = chat.name;
  let isOnline = false;

  if (chat.type === 'personal') {
    const other = chat.participants.find(p => p.userId !== userId);
    if (other?.user) {
      name = `${other.user.firstName ?? ''} ${other.user.lastName ?? ''}`.trim();
      isOnline = onlineSet.has(other.userId);
    }
  }

  return {
    id: chat.id,
    type: chat.type,
    name: name ?? 'Unbekannt',
    schoolId: chat.schoolId,
    className: chat.className,
    isGroup: chat.type !== 'personal',
    isClassGroup: chat.type === 'classGroup',
    isPersonal: chat.type === 'personal',
    isOnline,
    unread: me?.unread ?? 0,
    lastMessage: lastMsg
      ? {
          text: lastMsg.text,
          senderId: lastMsg.senderId,
          timestamp: lastMsg.createdAt,
        }
      : null,
    lastActivity: chat.lastMessageAt ?? chat.createdAt,
    participants: chat.participants.map(p => ({
      id: p.userId,
      firstName: p.user.firstName,
      lastName: p.user.lastName,
      knNumber: p.user.knNumber,
      role: p.user.role,
      isOnline: onlineSet.has(p.userId),
    })),
  };
}

function formatMessage(msg, currentUserId) {
  return {
    id: msg.id,
    chatId: msg.chatId,
    text: msg.text,
    type: msg.type,
    senderId: msg.senderId,
    senderName: `${msg.sender?.firstName ?? ''} ${msg.sender?.lastName ?? ''}`.trim(),
    isMe: msg.senderId === currentUserId,
    status: msg.status,
    replyToId: msg.replyToId ?? null,
    timestamp: msg.createdAt,
  };
}

// ── GET /api/v1/chats ─────────────────────────────────────────────────────────

exports.listChats = async (req, res) => {
  try {
    const userId = req.user.id;
    const socketHandler = req.app.get('socketHandler');
    const onlineSet = socketHandler?.getOnlineSet?.() ?? new Set();

    const chats = await prisma.chat.findMany({
      where: { participants: { some: { userId } } },
      include: {
        participants: { include: { user: { select: userSelect() } } },
        messages: {
          where: { deletedAt: null },
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
      orderBy: { lastMessageAt: 'desc' },
    });

    return res.json({
      success: true,
      data: { chats: chats.map(c => formatChat(c, userId, onlineSet)) },
    });
  } catch (error) {
    log.error(error, 'listChats error:');
    return res.status(500).json({ success: false, error: 'Failed to load chats' });
  }
};

// ── POST /api/v1/chats ────────────────────────────────────────────────────────

exports.createChat = async (req, res) => {
  try {
    const userId = req.user.id;
    const { targetUserId, targetKnNumber } = req.body;

    let target = null;
    if (targetUserId) {
      target = await prisma.user.findUnique({ where: { id: targetUserId } });
    } else if (targetKnNumber) {
      target = await prisma.user.findUnique({
        where: { knNumber: targetKnNumber.toUpperCase() },
      });
    }

    if (!target) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    if (target.id === userId) {
      return res.status(400).json({ success: false, error: 'Cannot chat with yourself' });
    }

    // Return existing personal chat if already exists
    const existing = await prisma.chat.findFirst({
      where: {
        type: 'personal',
        AND: [
          { participants: { some: { userId } } },
          { participants: { some: { userId: target.id } } },
        ],
      },
      include: {
        participants: { include: { user: { select: userSelect() } } },
        messages: {
          where: { deletedAt: null },
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
    });

    if (existing) {
      return res.json({
        success: true,
        data: { chat: formatChat(existing, userId), created: false },
      });
    }

    const chat = await prisma.chat.create({
      data: {
        type: 'personal',
        participants: { create: [{ userId }, { userId: target.id }] },
      },
      include: {
        participants: { include: { user: { select: userSelect() } } },
        messages: {
          where: { deletedAt: null },
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
    });

    // Notify target user via socket
    const io = req.app.get('io');
    if (io) {
      io.to(`user:${target.id}`).emit('chat:new', formatChat(chat, target.id));
    }

    return res.status(201).json({
      success: true,
      data: { chat: formatChat(chat, userId), created: true },
    });
  } catch (error) {
    log.error(error, 'createChat error:');
    return res.status(500).json({ success: false, error: 'Failed to create chat' });
  }
};

// ── GET /api/v1/chats/:id/messages ───────────────────────────────────────────

exports.getMessages = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id: chatId } = req.params;
    const { cursor, limit = '50' } = req.query;

    const participant = await prisma.chatParticipant.findUnique({
      where: { chatId_userId: { chatId, userId } },
    });
    if (!participant) {
      return res.status(403).json({ success: false, error: 'Not a participant of this chat' });
    }

    const take = Math.min(parseInt(limit, 10) || 50, 100);

    const messages = await prisma.message.findMany({
      where: {
        chatId,
        deletedAt: null,
        ...(cursor ? { createdAt: { lt: new Date(cursor) } } : {}),
      },
      include: { sender: { select: userSelect() } },
      orderBy: { createdAt: 'desc' },
      take,
    });

    const ordered = [...messages].reverse();
    const nextCursor =
      messages.length === take
        ? messages[messages.length - 1].createdAt.toISOString()
        : null;

    return res.json({
      success: true,
      data: {
        messages: ordered.map(m => formatMessage(m, userId)),
        nextCursor,
        hasMore: !!nextCursor,
      },
    });
  } catch (error) {
    log.error(error, 'getMessages error:');
    return res.status(500).json({ success: false, error: 'Failed to load messages' });
  }
};

// ── POST /api/v1/chats/:id/messages ──────────────────────────────────────────

exports.sendMessage = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id: chatId } = req.params;
    const { text, type = 'text', replyToId } = req.body;

    if (!text?.trim()) {
      return res.status(400).json({ success: false, error: 'Message text is required' });
    }

    const participant = await prisma.chatParticipant.findUnique({
      where: { chatId_userId: { chatId, userId } },
    });
    if (!participant) {
      return res.status(403).json({ success: false, error: 'Not a participant of this chat' });
    }

    const [message] = await prisma.$transaction([
      prisma.message.create({
        data: {
          chatId,
          senderId: userId,
          text: text.trim(),
          type,
          replyToId: replyToId ?? null,
          status: 'sent',
        },
        include: { sender: { select: userSelect() } },
      }),
      prisma.chat.update({
        where: { id: chatId },
        data: { lastMessageAt: new Date() },
      }),
      prisma.chatParticipant.updateMany({
        where: { chatId, userId: { not: userId } },
        data: { unread: { increment: 1 } },
      }),
    ]);

    const formatted = formatMessage(message, userId);

    // Broadcast to all chat members (recipients see isMe: false)
    const io = req.app.get('io');
    if (io) {
      io.to(`chat:${chatId}`).emit('message:new', { ...formatted, isMe: false });
    }

    return res.status(201).json({ success: true, data: { message: formatted } });
  } catch (error) {
    log.error(error, 'sendMessage error:');
    return res.status(500).json({ success: false, error: 'Failed to send message' });
  }
};

// ── POST /api/v1/chats/:id/read ───────────────────────────────────────────────

exports.markRead = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id: chatId } = req.params;

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

    const io = req.app.get('io');
    if (io) {
      io.to(`chat:${chatId}`).emit('message:read', { chatId, byUserId: userId });
    }

    return res.json({ success: true });
  } catch (error) {
    log.error(error, 'markRead error:');
    return res.status(500).json({ success: false, error: 'Failed to mark as read' });
  }
};

// ── POST /api/v1/chats/group ─────────────────────────────────────────────────

exports.createGroupChat = async (req, res) => {
  try {
    const userId = req.user.id;
    const { name, type = 'classGroup', className, memberIds = [] } = req.body;

    if (!['classGroup', 'schoolGroup'].includes(type)) {
      return res.status(400).json({ success: false, error: 'Invalid group type' });
    }
    if (!name?.trim()) {
      return res.status(400).json({ success: false, error: 'Group name is required' });
    }

    const allIds = [...new Set([userId, ...memberIds])];

    const chat = await prisma.chat.create({
      data: {
        type,
        name: name.trim(),
        schoolId: req.user.schoolId ?? null,
        className: className ?? null,
        participants: { create: allIds.map(uid => ({ userId: uid })) },
      },
      include: {
        participants: { include: { user: { select: userSelect() } } },
        messages: { take: 0 },
      },
    });

    // Notify new members
    const io = req.app.get('io');
    if (io) {
      for (const uid of allIds) {
        io.to(`user:${uid}`).emit('chat:new', formatChat(chat, uid));
      }
    }

    return res.status(201).json({
      success: true,
      data: { chat: formatChat(chat, userId) },
    });
  } catch (error) {
    log.error(error, 'createGroupChat error:');
    return res.status(500).json({ success: false, error: 'Failed to create group chat' });
  }
};
