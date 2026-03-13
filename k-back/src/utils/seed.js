const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

// Генерация случайного пароля
function generatePassword() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let password = '';
  for (let i = 0; i < 10; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return password;
}

async function seed() {
  console.log('🌱 Seeding activation passwords...\n');

  const passwords = [
    {
      password: generatePassword(),
      plan: 'premium',
      duration: 30,
      maxUses: 5
    },
    {
      password: generatePassword(),
      plan: 'premium',
      duration: 0, // Lifetime
      maxUses: 1
    },
    {
      password: generatePassword(),
      plan: 'vpn_only',
      duration: 90,
      maxUses: 10
    },
    {
      password: generatePassword(),
      plan: 'ai_only',
      duration: 30,
      maxUses: 3
    },
    {
      password: generatePassword(),
      plan: 'premium',
      duration: 365,
      maxUses: 1
    }
  ];

  for (const data of passwords) {
    const created = await prisma.activationPassword.create({
      data: {
        ...data,
        createdBy: 'admin'
      }
    });

    const durationText = created.duration === 0 ? 'Lifetime' : `${created.duration} days`;
    
    console.log(`✅ Created: ${created.password}`);
    console.log(`   Plan: ${created.plan}`);
    console.log(`   Duration: ${durationText}`);
    console.log(`   Max Uses: ${created.maxUses}\n`);
  }

  console.log('✅ Seeding completed!\n');
  console.log('📋 Save these passwords for testing!\n');
  
  await prisma.$disconnect();
}

seed().catch((error) => {
  console.error('❌ Seeding failed:', error);
  process.exit(1);
});
