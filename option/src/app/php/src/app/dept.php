
<?php

// Very simple loader
function loadConfig( $vars = array() ) {
    foreach( $vars as $v ) {
        define( $v, get_cfg_var( "app.cfg.$v" ) );
    }
}

// Then call :
$cfg = array( 'DB_URL', 'DB_USER', 'DB_PASSWORD' );
loadConfig( $cfg );

// $conn = oci_connect('hr', 'welcome', 'localhost/XE');
$conn = oci_connect( $DB_USER, $DB_PASSWORD, $DB_URL);
if (!$conn) {
    $e = oci_error();
    trigger_error(htmlentities($e['message'], ENT_QUOTES), E_USER_ERROR);
}

// Prepare the statement
$stid = oci_parse($conn, 'SELECT deptno, dname, loc FROM dept');
if (!$stid) {
    $e = oci_error($conn);
    trigger_error(htmlentities($e['message'], ENT_QUOTES), E_USER_ERROR);
}

// Perform the logic of the query
$r = oci_execute($stid);
if (!$r) {
    $e = oci_error($stid);
    trigger_error(htmlentities($e['message'], ENT_QUOTES), E_USER_ERROR);
}

// Initialize an array to store the data
$data = array();

while ($row = oci_fetch_array($stid, OCI_ASSOC+OCI_RETURN_NULLS)) {
    foreach ($row as $item) {
        $data[] = $row;
    }
}
// Encode the array as JSON and output it
echo json_encode($data);

oci_free_statement($stid);
oci_close($conn);
?>
