const fdk = require('@fnproject/fdk');
const mysql = require('mysql2');

fdk.handle(async function() {
    const aDbURL= process.env.DB_URL.split(":");
    var con = await mysql.createConnection({
        host: aDbURL[0],
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: "db1"
    });

    con.connect();
    const [rows] = await conn.execute("SELECT deptno, dname, loc FROM dept");    
    con.end();

    return rows;
})



