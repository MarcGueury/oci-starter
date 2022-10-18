const express = require('express')
const app = express()
const port = 8080

const mysql = require('mysql2');

app.get('/info', (req, res) => {
    res.send('NodeJS - Express')
})

app.get('/dept', (req, res) => {
    var con = mysql.createConnection({
        host: process.env.DB_URL,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: "db1"
    });

    con.connect(function (err) {
        if (err) throw err;
        con.query("SELECT deptno, dname, loc FROM dept", function (err, result, fields) {
            if (err) throw err;
            console.log(result);
            res.send(result)
        });
    });
})

app.listen(port, () => {
    console.log(`OCI Starter: listening on port ${port}`)
})
