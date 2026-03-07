require('dotenv').config();

const connectDB = require('./src/config/db');
const UserAccount = require('./src/models/UserAccount');

(async () => {
  try {
    await connectDB(process.env.MONGO_URI);

    const result = await UserAccount.deleteMany({
      role: 'faculty',
      loginId: { $regex: '^FAC-' },
    });

    console.log('Deleted FAC-* faculty accounts:', result.deletedCount);

    const remaining = await UserAccount.find({})
      .sort({ role: 1, loginId: 1 })
      .lean();

    console.log(
      'Remaining accounts:',
      JSON.stringify(
        remaining.map((u) => ({ role: u.role, loginId: u.loginId })),
        null,
        2,
      ),
    );

    process.exit(0);
  } catch (error) {
    console.error('Cleanup failed:', error);
    process.exit(1);
  }
})();
