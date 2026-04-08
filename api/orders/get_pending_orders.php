<?php
ini_set('display_errors', 0);
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
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
        'message' => 'Owner ID required'
    ]);
    exit;
}

$conn = getConnection();

$stmt = $conn->prepare("
    SELECT * FROM orders
    WHERE owner_id = ? AND status = 'pending'
    ORDER BY created_at DESC
");
$stmt->bind_param("i", $owner_id);
$stmt->execute();
$result = $stmt->get_result();
$orders = [];

while ($row = $result->fetch_assoc()) {
    // Parse items - prefer items_list if available, fallback to items
    $items = [];
    if (!empty($row['items_list'])) {
        $items = (array) json_decode($row['items_list'], true);
    } elseif (!empty($row['items'])) {
        $items = (array) json_decode($row['items'], true);
        // Convert keyed array to indexed array for consistency
        $items = array_values($items);
    }
    
    $row['items_list'] = $items;
    if (empty($row['items_list'])) {
        $row['items'] = json_decode($row['items'], true);
    }
    
    $orders[] = $row;
}

$stmt->close();
$conn->close();

echo json_encode([
    'success' => true,
    'data' => [
        'orders' => $orders,
        'count' => count($orders),
    ],
]);
