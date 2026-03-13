const { PrismaClient } = require('@prisma/client');
const axios = require('axios');

const prisma = new PrismaClient();

const MATRIX_HOMESERVER_URL = 'http://localhost:8008';

// Создание чата 1-на-1
exports.createChat = async (req, res) => {
  try {
    const { userId } = req.body;
    const currentUser = req.user;

    // Валидация
    if (!userId) {
      return res.status(400).json({
        success: false,
        error: 'userId is required'
      });
    }

    // Получаем данные собеседника
    const targetUser = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        username: true,
        vtNumber: true,
        matrixUserId: true,
        matrixAccessToken: true
      }
    });

    if (!targetUser) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    // Нельзя создать чат с самим собой
    if (userId === currentUser.id) {
      return res.status(400).json({
        success: false,
        error: 'Cannot create chat with yourself'
      });
    }

    console.log(`Creating chat between ${currentUser.matrixUserId} and ${targetUser.matrixUserId}`);

    // Создаем приватную комнату в Matrix от имени текущего пользователя
    const createRoomResponse = await axios.post(
      `${MATRIX_HOMESERVER_URL}/_matrix/client/r0/createRoom`,
      {
        preset: 'trusted_private_chat',
        is_direct: true,
        invite: [targetUser.matrixUserId],
        visibility: 'private'
      },
      {
        headers: {
          'Authorization': `Bearer ${currentUser.matrixAccessToken}`,
          'Content-Type': 'application/json'
        }
      }
    );

    const roomId = createRoomResponse.data.room_id;

    console.log('✅ Chat created:', roomId);

    res.json({
      success: true,
      data: {
        roomId,
        user: {
          id: targetUser.id,
          username: targetUser.username,
          vtNumber: targetUser.vtNumber,
          matrixUserId: targetUser.matrixUserId
        }
      }
    });
  } catch (error) {
    console.error('Create chat error:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to create chat: ' + (error.response?.data?.error || error.message)
    });
  }
};

// Получить список чатов
exports.listChats = async (req, res) => {
  try {
    const currentUser = req.user;

    // Получаем комнаты из Matrix
    const joinedRoomsResponse = await axios.get(
      `${MATRIX_HOMESERVER_URL}/_matrix/client/r0/joined_rooms`,
      {
        headers: {
          'Authorization': `Bearer ${currentUser.matrixAccessToken}`
        }
      }
    );

    const rooms = joinedRoomsResponse.data.joined_rooms || [];

    res.json({
      success: true,
      data: {
        rooms,
        total: rooms.length
      }
    });
  } catch (error) {
    console.error('List chats error:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to list chats'
    });
  }
};
