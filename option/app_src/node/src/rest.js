const express = require('express')
const app = express()
const port = 8080

const oracledb = require('oracledb');

app.get('/info', (req, res) => {
    res.send('NodeJS - Express')
})

app.get('/dept', (req, res) => {

    let connection;
    try {
        connection = await oracledb.getConnection({ user: process.env.DB_USER, password: process.env.DB_PASSWORD, connectionString: process.env.DB_HOST });
        // "localhost/xepdb1"
        console.log("Successfully connected to Oracle Database");
        // Now query the rows back
        result = await connection.execute('SELECT deptno, dname, loc FROM dept', [], { resultSet: true, outFormat: oracledb.OUT_FORMAT_OBJECT });
        const rs = result.resultSet;
        let row;
    
        while ((row = await rs.getRow())) {
        if (row.DONE)
            console.log(row.DESCRIPTION, "is done");
        else
            console.log(row.DESCRIPTION, "is NOT done");
        }
        await rs.close();
        res.send( "result");
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
})

app.listen(port, () => {
    console.log(`OCI Starter: listening on port ${port}`)
})

async function run() {
    let connection;
    try {
        connection = await oracledb.getConnection({ user: process.env.DB_USER, password: process.env.DB_PASSWORD, connectionString: process.env.DB_HOST });
        // "localhost/xepdb1"
        console.log("Successfully connected to Oracle Database");
        // Now query the rows back
        result = await connection.execute('SELECT deptno, dname, loc FROM dept', [], { resultSet: true, outFormat: oracledb.OUT_FORMAT_OBJECT });
        const rs = result.resultSet;
        let row;
    
        while ((row = await rs.getRow())) {
        if (row.DONE)
            console.log(row.DESCRIPTION, "is done");
        else
            console.log(row.DESCRIPTION, "is NOT done");
        }
        await rs.close();
        res.send( "result");
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