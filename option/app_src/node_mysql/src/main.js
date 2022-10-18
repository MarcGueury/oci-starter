const oracledb = require('oracledb');

async function run() {

  let connection;

  try {
    connection = await oracledb.getConnection({ 
      user:  process.env.DB_USER, 
      password:  process.env.DB_USER, 
      connectionString: process.env.DB_URL  }); // "localhost/xepdb1"
    console.log("Successfully connected to Oracle Database");

    // Now query the rows back
    result = await connection.execute(
      `select deptno, dname, loc from dept`,
      [],
      { resultSet: true, outFormat: oracledb.OUT_FORMAT_OBJECT });

    const rs = result.resultSet;
    let row;

    while ((row = await rs.getRow())) {
      if (row.DONE)
        console.log(row.DESCRIPTION, "is done");
      else
        console.log(row.DESCRIPTION, "is NOT done");
    }
    await rs.close();

  } catch (err) {
    console.error(err);
  } finally {
    if (connection) {
      try {
        await connection.close();
      } catch (err) {
        console.error(err);
      }
    }
  }
}

run();