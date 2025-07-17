<?php
echo "=== INFORMACIÓN PHP DEL SERVIDOR WEB ===\n\n";

echo "Archivo php.ini cargado: " . php_ini_loaded_file() . "\n";
echo "Directorio de configuración: " . php_ini_scanned_files() . "\n\n";

echo "Drivers PDO disponibles:\n";
$drivers = PDO::getAvailableDrivers();
if (empty($drivers)) {
    echo "✗ No hay drivers PDO disponibles\n";
} else {
    foreach ($drivers as $driver) {
        echo "✓ $driver\n";
    }
}

echo "\nExtensiones cargadas:\n";
$extensions = get_loaded_extensions();
foreach (['PDO', 'pdo_mysql', 'pdo_sqlite', 'sqlite3', 'mysqlnd'] as $ext) {
    if (in_array($ext, $extensions)) {
        echo "✓ $ext\n";
    } else {
        echo "✗ $ext (no cargada)\n";
    }
}

echo "\nTest de conexión PDO:\n";

// Test SQLite
try {
    $pdo = new PDO('sqlite::memory:');
    echo "✓ PDO SQLite funciona\n";
} catch (Exception $e) {
    echo "✗ PDO SQLite falla: " . $e->getMessage() . "\n";
}

// Test MySQL
try {
    $pdo = new PDO('mysql:host=127.0.0.1;port=3306', 'root', '');
    echo "✓ PDO MySQL funciona\n";
} catch (Exception $e) {
    echo "✗ PDO MySQL falla: " . $e->getMessage() . "\n";
}
?>