const prisma = require('../lib/prisma');

// Список запрещенных слов в username
const RESTRICTED_WORDS = [
  'admin',
  'support',
  'vtalk',
  'moderator',
  'official',
  'system',
  'root',
  'administrator'
];

// Проверка на запрещенные слова
function containsRestrictedWords(username) {
  const lowerUsername = username.toLowerCase();
  return RESTRICTED_WORDS.some(word => lowerUsername.includes(word));
}

// Обновление username
exports.updateUsername = async (req, res) => {
  try {
    const { username } = req.body;
    const userId = req.user.id;

    // Валидация
    if (!username || username.trim() === '') {
      return res.status(400).json({
        success: false,
        error: 'Username is required'
      });
    }

    const trimmedUsername = username.trim();

    // Проверка длины
    if (trimmedUsername.length < 2) {
      return res.status(400).json({
        success: false,
        error: 'Username must be at least 2 characters'
      });
    }

    if (trimmedUsername.length > 50) {
      return res.status(400).json({
        success: false,
        error: 'Username must be less than 50 characters'
      });
    }

    // Проверка на запрещенные слова
    if (containsRestrictedWords(trimmedUsername)) {
      return res.status(400).json({
        success: false,
        error: 'Username contains restricted words'
      });
    }

    // Проверка лимита смены (1 раз в 30 дней)
    if (req.user.lastUsernameChangeAt) {
      const daysSinceLastChange = Math.floor(
        (new Date() - req.user.lastUsernameChangeAt) / (1000 * 60 * 60 * 24)
      );

      if (daysSinceLastChange < 30) {
        const nextAvailableDate = new Date(req.user.lastUsernameChangeAt);
        nextAvailableDate.setDate(nextAvailableDate.getDate() + 30);

        return res.status(429).json({
          success: false,
          error: `You can change username once per 30 days. Next available: ${nextAvailableDate.toISOString().split('T')[0]}`
        });
      }
    }

    // Обновляем username
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        username: trimmedUsername,
        lastUsernameChangeAt: new Date()
      }
    });

    res.json({
      success: true,
      data: {
        username: updatedUser.username,
        lastUsernameChange: updatedUser.lastUsernameChangeAt
      }
    });
  } catch (error) {
    console.error('Update username error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update username'
    });
  }
};

// Поиск пользователей
exports.searchUsers = async (req, res) => {
  try {
    const { query } = req.query;

    // Валидация
    if (!query || query.trim() === '') {
      return res.status(400).json({
        success: false,
        error: 'Search query is required'
      });
    }

    const searchTerm = query.trim();

    // Поиск по username (частичное совпадение) или VT-номеру (точное совпадение)
    const users = await prisma.user.findMany({
      where: {
        OR: [
          {
            username: {
              contains: searchTerm,
              mode: 'insensitive' // Регистронезависимый поиск
            }
          },
          {
            vtNumber: searchTerm // Точное совпадение VT-номера
          },
          {
            vtNumber: `VT-${searchTerm}` // Если ввели только цифры
          }
        ]
      },
      select: {
        id: true,
        username: true,
        vtNumber: true,
        matrixUserId: true,
        isPremium: true
        // НЕ возвращаем email, password и другие приватные данные!
      },
      take: 20 // Ограничиваем результаты
    });

    res.json({
      success: true,
      data: {
        users,
        total: users.length
      }
    });
  } catch (error) {
    console.error('Search users error:', error);
    res.status(500).json({
      success: false,
      error: 'Search failed'
    });
  }
};
