const prisma = require('../lib/prisma');

// Активация Premium
exports.activatePremium = async (req, res) => {
  try {
    const { password } = req.body;
    const userId = req.user.id;

    // Валидация
    if (!password) {
      return res.status(400).json({
        success: false,
        error: 'Password is required'
      });
    }

    // Находим activation password
    const activationPassword = await prisma.activationPassword.findUnique({
      where: { password }
    });

    if (!activationPassword) {
      return res.status(404).json({
        success: false,
        error: 'Invalid activation password'
      });
    }

    // Проверяем что пароль активен
    if (!activationPassword.isActive) {
      return res.status(400).json({
        success: false,
        error: 'This activation password is no longer active'
      });
    }

    // Проверяем лимит использований
    if (activationPassword.currentUses >= activationPassword.maxUses) {
      return res.status(400).json({
        success: false,
        error: 'This activation password has reached its usage limit'
      });
    }

    // Считаем дату окончания
    let expiresAt = null;
    if (activationPassword.duration > 0) {
      expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + activationPassword.duration);
    }
    // Если duration = 0, значит lifetime (expiresAt остается null)

    // Обновляем пользователя в зависимости от плана
    const updateData = {
      premiumActivatedWith: password
    };

    let features = [];

    if (activationPassword.plan === 'premium') {
      // Premium = все доступы
      updateData.isPremium = true;
      updateData.premiumPlan = 'premium';
      updateData.premiumExpiresAt = expiresAt;
      updateData.hasVpnAccess = true;
      updateData.vpnExpiresAt = expiresAt;
      updateData.hasAiAccess = true;
      updateData.aiExpiresAt = expiresAt;
      features = ['vpn', 'ai', 'unlimited_storage'];
    } else if (activationPassword.plan === 'vpn_only') {
      // Только VPN
      updateData.hasVpnAccess = true;
      updateData.vpnExpiresAt = expiresAt;
      features = ['vpn'];
    } else if (activationPassword.plan === 'ai_only') {
      // Только AI
      updateData.hasAiAccess = true;
      updateData.aiExpiresAt = expiresAt;
      features = ['ai'];
    }

    // Обновляем пользователя
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: updateData
    });

    // Увеличиваем счетчик использований
    await prisma.activationPassword.update({
      where: { password },
      data: {
        currentUses: activationPassword.currentUses + 1
      }
    });

    res.json({
      success: true,
      message: `${activationPassword.plan === 'premium' ? 'Premium' : activationPassword.plan.replace('_', ' ').toUpperCase()} activated successfully!`,
      data: {
        user: {
          isPremium: updatedUser.isPremium,
          hasVpnAccess: updatedUser.hasVpnAccess,
          hasAiAccess: updatedUser.hasAiAccess,
          premiumExpiresAt: updatedUser.premiumExpiresAt,
          vpnExpiresAt: updatedUser.vpnExpiresAt,
          aiExpiresAt: updatedUser.aiExpiresAt,
          features
        }
      }
    });
  } catch (error) {
    console.error('Activate premium error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to activate premium'
    });
  }
};

// Получить статус Premium
exports.getPremiumStatus = async (req, res) => {
  try {
    const user = req.user;

    // Проверяем актуальность premium
    const isPremium = user.isPremium && (!user.premiumExpiresAt || user.premiumExpiresAt > new Date());
    const hasVpn = user.hasVpnAccess && (!user.vpnExpiresAt || user.vpnExpiresAt > new Date());
    const hasAi = user.hasAiAccess && (!user.aiExpiresAt || user.aiExpiresAt > new Date());

    let features = [];
    
    if (isPremium) {
      features = ['vpn', 'ai', 'unlimited_storage'];
    } else {
      if (hasVpn) features.push('vpn');
      if (hasAi) features.push('ai');
    }

    // Считаем дни до окончания
    let daysRemaining = null;
    
    if (isPremium && user.premiumExpiresAt) {
      const diffTime = user.premiumExpiresAt - new Date();
      daysRemaining = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    } else if (hasVpn && user.vpnExpiresAt) {
      const diffTime = user.vpnExpiresAt - new Date();
      daysRemaining = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    } else if (hasAi && user.aiExpiresAt) {
      const diffTime = user.aiExpiresAt - new Date();
      daysRemaining = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    }

    res.json({
      success: true,
      data: {
        isPremium,
        hasVpnAccess: hasVpn,
        hasAiAccess: hasAi,
        premiumExpiresAt: user.premiumExpiresAt,
        vpnExpiresAt: user.vpnExpiresAt,
        aiExpiresAt: user.aiExpiresAt,
        features,
        plan: user.premiumPlan || 'free',
        daysRemaining,
        isLifetime: !user.premiumExpiresAt && !user.vpnExpiresAt && !user.aiExpiresAt && features.length > 0
      }
    });
  } catch (error) {
    console.error('Get premium status error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get premium status'
    });
  }
};
