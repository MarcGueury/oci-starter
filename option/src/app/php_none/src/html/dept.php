<?php

class Dept
{
    public $depno;
    public $dname;
    public $loc;
}

// Initialize an array to store the data
$data = array();
$d = new Dept();
$d->deptno = '10';
$d->dname = 'ACCOUNTING';
$d->loc = 'Seoul';
$data[] = $row;
$d = new Dept();
$d->deptno = '20';
$d->dname = 'RESEARCH';
$d->loc = 'Cape Town';
$data[] = $row;$d = new Dept();
$d->deptno = '30';
$d->dname = 'SALES';
$d->loc = 'Brussels';
$data[] = $row;$d = new Dept();
$d->deptno = '40';
$d->dname = 'OPERATIONS';
$d->loc = 'San Francisco';
$data[] = $row;

// Encode the array as JSON and output it
echo json_encode($data);

?>
