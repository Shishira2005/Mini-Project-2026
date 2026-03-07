require('dotenv').config();

const connectDB = require('./src/config/db');
const AdminClassroomSettings = require('./src/models/AdminClassroomSettings');
const UserAccount = require('./src/models/UserAccount');
const { hashPassword } = require('./src/utils/auth');

(async () => {
  try {
    await connectDB(process.env.MONGO_URI);

    const settingsList = await AdminClassroomSettings.find({}).lean();
    if (!settingsList.length) {
      console.log('No AdminClassroomSettings documents found.');
      process.exit(0);
    }

    const repsByLoginId = new Map();

    for (const s of settingsList) {
      const generalAdmission = (s.generalCrAdmission || '').trim();
      if (generalAdmission) {
        repsByLoginId.set(generalAdmission, {
          loginId: generalAdmission,
          name: (s.generalCrName || '').trim() || generalAdmission,
        });
      }

      const ladyAdmission = (s.ladyCrAdmission || '').trim();
      if (ladyAdmission) {
        repsByLoginId.set(ladyAdmission, {
          loginId: ladyAdmission,
          name: (s.ladyCrName || '').trim() || ladyAdmission,
        });
      }
    }

    if (!repsByLoginId.size) {
      console.log('No representative admissions found in settings.');
      process.exit(0);
    }

    const defaultPasswordHash = await hashPassword('LBSCEK');
    let createdCount = 0;

    for (const rep of repsByLoginId.values()) {
      const existing = await UserAccount.findOne({
        role: 'representative',
        loginId: rep.loginId,
      }).exec();

      if (existing) {
        console.log('Existing representative account:', rep.loginId);
        continue;
      }

      await UserAccount.create({
        role: 'representative',
        loginId: rep.loginId,
        name: rep.name,
        passwordHash: defaultPasswordHash,
      });
      console.log('Created representative account:', rep.loginId);
      createdCount += 1;
    }

    console.log('Done. Created', createdCount, 'new representative accounts.');
    process.exit(0);
  } catch (error) {
    console.error('Failed to create representative accounts:', error);
    process.exit(1);
  }
})();
