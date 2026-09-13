import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seeding...');

  // 1. Create or Find Demo User
  const passwordHash = await bcrypt.hash('password123', 10);
  const user = await prisma.user.upsert({
    where: { email: 'demo@aifinance.com' },
    update: {},
    create: {
      email: 'demo@aifinance.com',
      passwordHash,
      name: 'Alex Johnson',
    },
  });

  console.log(`👤 Demo user created/found: ${user.email} (${user.id})`);

  // 2. Clear existing categories and expenses for clean seed (optional)
  await prisma.expense.deleteMany({ where: { userId: user.id } });
  await prisma.category.deleteMany({});

  // 3. Create Categories
  const categoryData = [
    { name: 'Food & Dining', icon: 'restaurant_rounded', color: '0xFFFF7043' },
    { name: 'Shopping', icon: 'shopping_bag_outlined', color: '0xFFAB47BC' },
    { name: 'Transportation', icon: 'directions_car_outlined', color: '0xFF42A5F5' },
    { name: 'Entertainment', icon: 'movie_outlined', color: '0xFFEC407A' },
    { name: 'Bills & Utilities', icon: 'receipt_long_outlined', color: '0xFF26A69A' },
    { name: 'Health & Fitness', icon: 'fitness_center_outlined', color: '0xFFFFA726' },
    { name: 'Groceries', icon: 'local_grocery_store_outlined', color: '0xFF66BB6A' },
    { name: 'Travel', icon: 'flight_outlined', color: '0xFF7E57C2' },
  ];

  const categories: Record<string, any> = {};
  for (const cat of categoryData) {
    const created = await prisma.category.create({
      data: cat,
    });
    categories[cat.name] = created;
  }
  console.log(`🏷️ Created ${Object.keys(categories).length} categories.`);

  // 4. Create Sample Expenses
  const now = new Date();
  const daysAgo = (days: number, hour = 14, min = 30) => {
    const d = new Date(now);
    d.setDate(d.getDate() - days);
    d.setHours(hour, min, 0, 0);
    return d;
  };

  const sampleExpenses = [
    {
      merchant: 'Amazon Marketplace',
      amount: 3499.00,
      currency: 'INR',
      date: daysAgo(0, 11, 15),
      notes: 'Noise cancelling headphones',
      categoryId: categories['Shopping'].id,
    },
    {
      merchant: 'Starbucks Coffee',
      amount: 450.00,
      currency: 'INR',
      date: daysAgo(0, 9, 30),
      notes: 'Caramel Macchiato & Croissant',
      categoryId: categories['Food & Dining'].id,
    },
    {
      merchant: 'Uber Ride',
      amount: 320.00,
      currency: 'INR',
      date: daysAgo(1, 18, 45),
      notes: 'Commute back from office',
      categoryId: categories['Transportation'].id,
    },
    {
      merchant: 'Swiggy Gourmet',
      amount: 890.00,
      currency: 'INR',
      date: daysAgo(1, 20, 10),
      notes: 'Weekend dinner with friends',
      categoryId: categories['Food & Dining'].id,
    },
    {
      merchant: 'Whole Foods Market',
      amount: 4820.00,
      currency: 'INR',
      date: daysAgo(2, 16, 0),
      notes: 'Weekly fresh groceries & organic fruit',
      categoryId: categories['Groceries'].id,
    },
    {
      merchant: 'Netflix Subscription',
      amount: 649.00,
      currency: 'INR',
      date: daysAgo(3, 10, 0),
      notes: 'Premium 4K Family plan',
      categoryId: categories['Entertainment'].id,
    },
    {
      merchant: 'Electricity & Water Board',
      amount: 2150.00,
      currency: 'INR',
      date: daysAgo(4, 12, 0),
      notes: 'Monthly utility bill payment',
      categoryId: categories['Bills & Utilities'].id,
    },
    {
      merchant: 'Gold Gym Membership',
      amount: 1500.00,
      currency: 'INR',
      date: daysAgo(5, 8, 0),
      notes: 'Monthly fitness subscription',
      categoryId: categories['Health & Fitness'].id,
    },
    {
      merchant: 'Zara Fashion',
      amount: 4200.00,
      currency: 'INR',
      date: daysAgo(7, 17, 30),
      notes: 'Casual jackets and shirts',
      categoryId: categories['Shopping'].id,
    },
    {
      merchant: 'Shell Petrol Station',
      amount: 1800.00,
      currency: 'INR',
      date: daysAgo(8, 19, 15),
      notes: 'Full tank refuel',
      categoryId: categories['Transportation'].id,
    },
    {
      merchant: 'PVR IMAX Cinemas',
      amount: 750.00,
      currency: 'INR',
      date: daysAgo(10, 21, 0),
      notes: '2 tickets + Popcorn combo',
      categoryId: categories['Entertainment'].id,
    },
    {
      merchant: 'Apollo Pharmacy',
      amount: 680.00,
      currency: 'INR',
      date: daysAgo(12, 14, 20),
      notes: 'Vitamins & first aid supplies',
      categoryId: categories['Health & Fitness'].id,
    },
    {
      merchant: 'IndiGo Airlines',
      amount: 6500.00,
      currency: 'INR',
      date: daysAgo(15, 11, 0),
      notes: 'Roundtrip flight for conference',
      categoryId: categories['Travel'].id,
    },
    {
      merchant: 'Apple iCloud',
      amount: 219.00,
      currency: 'INR',
      date: daysAgo(18, 9, 0),
      notes: '2TB Cloud Storage subscription',
      categoryId: categories['Bills & Utilities'].id,
    },
    {
      merchant: 'Blue Tokai Coffee Roasters',
      amount: 520.00,
      currency: 'INR',
      date: daysAgo(22, 15, 30),
      notes: 'Roasted coffee beans & pour over',
      categoryId: categories['Food & Dining'].id,
    },
  ];

  for (const exp of sampleExpenses) {
    await prisma.expense.create({
      data: {
        userId: user.id,
        ...exp,
      },
    });
  }

  console.log(`💳 Created ${sampleExpenses.length} sample expenses!`);
  console.log('✅ Seeding completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
