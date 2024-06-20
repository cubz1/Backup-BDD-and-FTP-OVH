<?php
$db_host = 'localhost'; // À MODIFIÉ !!!
$db_username = 'test'; // À MODIFIÉ !!!
$db_password = 'test'; // À MODIFIÉ !!!
$db_name = 'test'; // À MODIFIÉ !!!

$conn = new mysqli($db_host, $db_username, $db_password, $db_name);

if ($conn->connect_error) {
    die("Base de données non exporté: " . $conn->connect_error);
}

$result = $conn->query("SHOW TABLES");
$tables = array();
while ($row = $result->fetch_array()) {
    $tables[] = $row[0];
}

$sql = "-- Base de données: $db_name\n";
$sql .= "-- --------------------------------------------------------\n";
$sql .= "SET NAMES utf8;\n";
$sql .= "SET FOREIGN_KEY_CHECKS = 0;\n";
foreach ($tables as $table) {
    $result = $conn->query("SHOW CREATE TABLE $table");
    $row = $result->fetch_array();
    $sql .= $row[1] . ";\n\n";

    $result = $conn->query("SELECT * FROM $table");
    while ($row = $result->fetch_assoc()) {
        $sql .= "INSERT INTO $table VALUES (";
        foreach ($row as $field) {
            $sql .= "'" . addslashes($field) . "', ";
        }
        $sql = rtrim($sql, ', ') . ");\n";
    }
    $sql .= "\n";
}
$sql .= "SET FOREIGN_KEY_CHECKS = 1;\n";
$conn->close();
$file_name = $db_name . '.sql';
if (file_exists($file_name)) {
    unlink($file_name);
}
if (file_exists("error_bdd_export.dat")) {
    unlink("error_bdd_export.dat");
}
file_put_contents($file_name, $sql);
if (file_exists($file_name)) {
} else {
    file_put_contents("error_bdd_export.dat", "Erreur : La base de données n'a pas pû s'exportée");
}

?>