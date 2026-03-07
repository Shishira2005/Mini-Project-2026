require('dotenv').config();

const connectDB = require('./src/config/db');
const UserAccount = require('./src/models/UserAccount');

// Admission numbers to delete (representative accounts)
const ADMISSION_NUMBERS_TO_DELETE = [
  'CS21A017',
  'CS21B022',
  'CS22A001',
];

(async () => {
  try {
    await connectDB(process.env.MONGO_URI);

    const result = await UserAccount.deleteMany({
      role: 'representative',
      loginId: { $in: ADMISSION_NUMBERS_TO_DELETE },
    });

    console.log('Deleted representative accounts:', result.deletedCount);

    const remaining = await UserAccount.find({ role: 'representative' })
      .sort({ loginId: 1 })
      .lean();

    console.log(
      'Remaining representative accounts:',
      JSON.stringify(
        remaining.map((u) => ({ loginId: u.loginId, name: u.name })),
        null,
        2,
      ),
    );

    process.exit(0);
  } catch (error) {
    console.error('Deletion failed:', error);
    process.exit(1);
  }
})();
