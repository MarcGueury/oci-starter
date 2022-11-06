import React, { useState } from "react";
import AppBar from '@mui/material/AppBar';
import Box from '@mui/material/Box';
import Toolbar from '@mui/material/Toolbar';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import IconButton from '@mui/material/IconButton';
import MenuIcon from '@mui/icons-material/Menu';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import Container from '@mui/material/Container';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';

function createData(deptno: string, dname: string, loc: string) {
    return { deptno, dname, loc };
}

var rows: { deptno: string, dname: string, loc: string }[] = [
    // createData('1', 'IT', 'Gembloux')
];
var [ row2, setRows ] = useState([{ deptno: "", dname: "", loc: "" }]);

// Load the REST URL 
function loadRest() {
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function () {
        if (this.readyState == 4 && this.status == 200) {
            var json = document.getElementById("json");
            if (json != null) {
                json.innerHTML = this.responseText;
            }
            // Replacing the whole array is needed to refresh the component
            var r = []
            let jsonValue = JSON.parse(this.responseText);
            for (var i = 0; i < jsonValue.length; i++) {
                r.push(createData(jsonValue[i].deptno, jsonValue[i].dname, jsonValue[i].loc));
            }
            // setRows( jsonValue );
        }
    };
    // xhttp.open("GET", "http://starter.oracloud.be/app/dept", true);
    xhttp.open("GET", "dept.json", true);
    xhttp.send();

    var xhttp2 = new XMLHttpRequest();
    xhttp2.onreadystatechange = function () {
        if (this.readyState == 4 && this.status == 200) {
            var info = document.getElementById("info");
            if (info != null) {
                info.innerHTML = this.responseText;
            }
        }
    };
    // xhttp2.open("GET", "http://starter.oracloud.be/app/info", true);
    xhttp2.open("GET", "info.txt", true);
    xhttp2.send();
}

export default function ButtonAppBar() {
    return (
        <div>
            <Box sx={{ flexGrow: 1 }}>
                <AppBar position="static">
                    <Toolbar>
                        <IconButton
                            size="large"
                            edge="start"
                            color="inherit"
                            aria-label="menu"
                            sx={{ mr: 2 }}
                        >
                            <MenuIcon />
                        </IconButton>
                        <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
                            OCI Starter
                        </Typography>
                        <Button color="inherit">ReactJS</Button>
                    </Toolbar>
                </AppBar>
            </Box>
            <Container maxWidth="sm">
                <br></br>
                <Typography variant="h3">Sample</Typography>
                <br></br>
                <Typography variant="h5">Rest Result</Typography>
                <div id="json"></div>
                <br></br>
                <Typography variant="h5">Department Table</Typography>

                <Table sx={{ minWidth: 650 }} size="small" aria-label="a dense table">
                    <TableHead>
                        <TableRow>
                            <TableCell align="right">Number</TableCell>
                            <TableCell align="right">Name</TableCell>
                            <TableCell align="right">Location</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {row2.map((row) => (
                            <TableRow
                                key={row.deptno}
                                sx={{ '&:last-child td, &:last-child th': { border: 0 } }}
                            >
                                <TableCell align="right">{row.deptno}</TableCell>
                                <TableCell align="right">{row.dname}</TableCell>
                                <TableCell align="right">{row.loc}</TableCell>
                            </TableRow>
                        ))}
                    </TableBody>
                </Table>
                <br></br>
                <Typography variant="h5">Rest Info</Typography>
                <div id="info"></div>
            </Container>
        </div>
    );
}

loadRest();