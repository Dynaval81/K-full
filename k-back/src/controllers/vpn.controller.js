const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

// Получить список VPN серверов
exports.getServers = async (req, res) => {
  try {
    const { purpose, country } = req.query;

    // Строим фильтры
    const where = {
      status: 'active'
    };

    if (purpose) {
      where.purpose = purpose;
    }

    if (country) {
      where.countryCode = country;
    }

    // Получаем серверы
    const servers = await prisma.vpnNode.findMany({
      where,
      orderBy: {
        currentLoad: 'asc' // Сначала менее нагруженные
      },
      select: {
        id: true,
        nodeId: true,
        location: true,
        countryCode: true,
        endpoint: true,
        purpose: true,
        capacity: true,
        currentLoad: true,
        configType: true
      }
    });

    // Добавляем вычисляемые поля
    const serversWithLoad = servers.map(server => ({
      ...server,
      loadPercentage: Math.round((server.currentLoad / server.capacity) * 100),
      isAI: server.purpose === 'auto',
      available: server.currentLoad < server.capacity
    }));

    res.json({
      success: true,
      data: {
        servers: serversWithLoad,
        total: serversWithLoad.length
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Get VPN servers error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'VPN_SERVERS_ERROR',
        message: 'Failed to fetch VPN servers',
        details: error.message
      },
      timestamp: new Date().toISOString()
    });
  }
};

// Получить конфиг конкретного сервера
exports.getConfig = async (req, res) => {
  try {
    const { nodeId } = req.params;
    const { format } = req.query; // 'uri' или 'json'

    const server = await prisma.vpnNode.findUnique({
      where: { nodeId }
    });

    if (!server) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'NODE_NOT_FOUND',
          message: 'VPN node not found'
        }
      });
    }

    if (server.status !== 'active') {
      return res.status(503).json({
        success: false,
        error: {
          code: 'NODE_UNAVAILABLE',
          message: 'VPN node is currently unavailable'
        }
      });
    }

    // Увеличиваем счетчик нагрузки
    await prisma.vpnNode.update({
      where: { nodeId },
      data: { currentLoad: server.currentLoad + 1 }
    });

    // Если запросили JSON формат
    if (format === 'json') {
      // Парсим VLESS URI для извлечения параметров
      const uri = new URL(server.vlessUri.replace('vless://', 'http://'));
      const uuid = uri.username;
      const host = uri.hostname;
      const port = parseInt(uri.port);
      
      const params = new URLSearchParams(uri.search);
      const publicKey = params.get('pbk');
      const serverName = params.get('sni');
      const shortId = params.get('sid');
      const spiderX = params.get('spx');
      const fingerprint = params.get('fp') || 'chrome';

      // Генерируем полный Xray config.json для Android VPN
      const xrayConfig = {
        log: {
          loglevel: "warning"
        },
        inbounds: [{
          port: 10808,
          protocol: "dokodemo-door",
          settings: {
            network: "tcp,udp",
            followRedirect: true
          },
          sniffing: {
            enabled: true,
            destOverride: ["http", "tls", "quic"]
          },
          streamSettings: {
            sockopt: {
              tproxy: "tproxy"
            }
          }
        }],
        outbounds: [{
          protocol: "vless",
          settings: {
            vnext: [{
              address: host,
              port: port,
              users: [{
                id: uuid,
                encryption: "none",
                flow: "xtls-rprx-vision"
              }]
            }]
          },
          streamSettings: {
            network: "tcp",
            security: "reality",
            realitySettings: {
              show: false,
              fingerprint: fingerprint,
              serverName: serverName,
              publicKey: publicKey,
              shortId: shortId,
              spiderX: spiderX
            }
          }
        }],
        routing: {
          domainStrategy: "AsIs",
          rules: []
        }
      };

      return res.json({
        success: true,
        data: {
          nodeId: server.nodeId,
          location: server.location,
          endpoint: server.endpoint,
          configType: "xray-json",
          xrayConfig: xrayConfig
        },
        timestamp: new Date().toISOString()
      });
    }

    // По умолчанию возвращаем URI
    const response = {
      success: true,
      data: {
        nodeId: server.nodeId,
        location: server.location,
        endpoint: server.endpoint,
        configType: server.configType
      },
      timestamp: new Date().toISOString()
    };

    if (server.configType === 'vless' && server.vlessUri) {
      response.data.vlessUri = server.vlessUri;
    }

    if (server.configType === 'singbox' && server.singboxConfig) {
      response.data.singboxConfig = JSON.parse(server.singboxConfig);
    }

    res.json(response);
  } catch (error) {
    console.error('Get VPN config error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'CONFIG_ERROR',
        message: 'Failed to get VPN config'
      }
    });
  }
};
