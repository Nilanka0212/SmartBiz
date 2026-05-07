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

$order_id = trim($_REQUEST['order_id'] ?? '');
$owner_id = intval($_REQUEST['owner_id'] ?? 0);
$status   = trim($_REQUEST['status'] ?? '');

$validStatuses = [
    'pending', 'preparing', 'ready',
    'completed', 'cancelled'
];

if (empty($order_id) ||
    $owner_id <= 0 ||
    !in_array($status, $validStatuses)) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid owner ID, order ID, or status'
    ]);
    exit;
}

$conn = getConnection();

$checkStmt = $conn->prepare("
    SELECT id FROM orders
    WHERE id = ? AND owner_id = ?
    LIMIT 1
");
$checkStmt->bind_param("ii", $order_id, $owner_id);
$checkStmt->execute();
$orderExists = $checkStmt->get_result()->num_rows > 0;
$checkStmt->close();

if (!$orderExists) {
    echo json_encode([
        'success' => false,
        'message' => 'Order not found for this owner'
    ]);
    $conn->close();
    exit;
}

$stmt = $conn->prepare("
    UPDATE orders
    SET status = ?
    WHERE id = ? AND owner_id = ?
");
$stmt->bind_param("sii", $status, $order_id, $owner_id);

if ($stmt->execute()) {
    echo json_encode([
        'success' => true,
        'message' => 'Order status updated',
        'status'  => $status,
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Failed: ' . $stmt->error
    ]);
}

$stmt->close();
$conn->close();
