(function () {
  const admin = db.getSiblingDB('admin');
  const rootUser = process.env.MONGO_INITDB_ROOT_USERNAME || 'mongo';
  const rootPass =
    process.env.MONGO_INITDB_ROOT_PASSWORD || 'change_me_admin_pw';
    
  try {
    admin.createUser({
      user: rootUser,
      pwd: rootPass,
      roles: [{ role: 'root', db: 'admin' }],
    });
  } catch (e) {}

  const appDb = process.env.MONGO_DB_NAME || 'appdb';
  const appUser = process.env.MONGO_APP_USERNAME || 'appuser';
  const appPass =
    process.env.MONGO_APP_PASSWORD || 'super_secret_password_change_me';

  const dbh = db.getSiblingDB(appDb);
  
  try {
    dbh.createUser({
      user: appUser,
      pwd: appPass,
      roles: [{ role: 'readWrite', db: appDb }],
    });
  } catch (e) {}
})();
