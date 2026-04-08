<?php
require_once 'api/config/database.php';
$conn = getConnection();
$result = $conn->query('SELECT id, customer_name, status, created_at FROM orders ORDER BY created_at DESC LIMIT 5');
while ($row = $result->fetch_assoc()) {
    echo 'Order #' . $row['id'] . ' - ' . $row['customer_name'] . ' - ' . $row['status'] . ' - ' . $row['created_at'] . PHP_EOL;
}
$conn->close();
?>