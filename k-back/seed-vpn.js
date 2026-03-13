const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding VPN nodes...\n');

  // Создаем тестовые VPN ноды
  await prisma.vpnNode.create({
    data: {
      nodeId: 'pl-01',
      location: 'Poland, Warsaw',
      countryCode: 'PL',
      endpoint: 'vpn-pl.vtalk.io:2053',
      purpose: 'general',
      configType: 'vless',
      vlessUri: 'vless://test-uuid@vpn-pl.vtalk.io:2053?encryption=none&security=reality&type=tcp&flow=xtls-rprx-vision#Vtalk-Poland'
    }
  });

  console.log('✅ Created: pl-01 (Poland, Warsaw)');

  await prisma.vpnNode.create({
    data: {
      nodeId: 'fi-auto',
      location: 'Finland, Helsinki',
      countryCode: 'FI',
      endpoint: 'vpn-fi.vtalk.io:2053',
      purpose: 'auto',
      configType: 'singbox',
      currentLoad: 120,
      singboxConfig: JSON.stringify({
        outbounds: [{
          type: 'vless',
          server: 'vpn-fi.vtalk.io',
          server_port: 2053,
          uuid: 'test-uuid',
          flow: 'xtls-rprx-vision'
        }]
      })
    }
  });

  console.log('✅ Created: fi-auto (Finland, Helsinki - AI mode)');

  await prisma.vpnNode.create({
    data: {
      nodeId: 'ru-reverse',
      location: 'Russia, Moscow',
      countryCode: 'RU',
      endpoint: 'vpn-ru.vtalk.io:2053',
      purpose: 'reverse',
      configType: 'vless',
      currentLoad: 50,
      vlessUri: 'vless://test-uuid@vpn-ru.vtalk.io:2053?encryption=none&security=reality#Vtalk-Russia-Reverse'
    }
  });

  console.log('✅ Created: ru-reverse (Russia, Moscow - Reverse)');

  console.log('\n✅ VPN nodes seeding completed!');
}

main()
  .catch((error) => {
    console.error('❌ Seeding failed:', error);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
