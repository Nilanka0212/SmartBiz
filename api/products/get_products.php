<?php
ini_set('display_errors', 0);
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once '../config/database.php';

$owner_id = trim($_REQUEST['owner_id'] ?? '');

if (empty($owner_id)) {
    echo json_encode([
        'success' => false,
        'message' => 'Owner ID is required'
    ]);
    exit;
}

$conn = getConnection();

$stmt = $conn->prepare("
    SELECT * FROM products
    WHERE owner_id = ?
    ORDER BY created_at DESC
");
$stmt->bind_param("i", $owner_id);
$stmt->execute();
$result   = $stmt->get_result();
$products = [];

while ($row = $result->fetch_assoc()) {
    $products[] = $row;
}

$stmt->close();
$conn->close();

echo json_encode([
    'success'  => true,
    'products' => $products,
]);