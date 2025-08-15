// mongo/init/00-replica-init.js
(function () {
  try {
    if (rs.status().ok === 1) quit(0);
  } catch (e) {}
  rs.initiate({
    _id: 'rs0',
    members: [{ _id: 0, host: 'localhost:27017' }],
  });
  for (let i = 0; i < 60; i++) {
    try {
      if (rs.status().myState === 1) break;
    } catch (e) {}
    sleep(1000);
  }
})();
