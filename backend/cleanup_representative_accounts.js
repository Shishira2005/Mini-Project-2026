require('dotenv').config();

const connectDB = require('./src/config/db');
const AdminClassroomSettings = require('./src/models/AdminClassroomSettings');
const UserAccount = require('./src/models/UserAccount');

(async () => {
  try {
    await connectDB(process.env.MONGO_URI);

    // Collect all admission numbers mentioned as general/lady CR
    const settingsList = await AdminClassroomSettings.find({}).lean();

    const allowedAdmissions = new Set();

    for (const s of settingsList) {
      const general = (s.generalCrAdmission || '').trim();
      if (general) {
        allowedAdmissions.add(general);
      }

      const lady = (s.ladyCrAdmission || '').trim();
      if (lady) {
        allowedAdmissions.add(lady);
      }
    }

    console.log('Allowed representative admission numbers from settings:');
    console.log(Array.from(allowedAdmissions.values()));

    // Delete any representative accounts whose loginId is not in the allowed set
    const query = allowedAdmissions.size
      ? { role: 'representative', loginId: { $nin: Array.from(allowedAdmissions.values()) } }
      : { role: 'representative' };

    const result = await UserAccount.deleteMany(query);
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
    console.error('Cleanup failed:', error);
    process.exit(1);
  }
})();
