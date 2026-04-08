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
$status   = trim($_REQUEST['status'] ?? '');

$validStatuses = [
    'pending', 'preparing', 'ready',
    'completed', 'cancelled'
];

if (empty($order_id) ||
    !in_array($status, $validStatuses)) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid order ID or status'
    ]);
    exit;
}

$conn = getConnection();

$stmt = $conn->prepare("
    UPDATE orders SET status = ? WHERE id = ?
");
$stmt->bind_param("si", $status, $order_id);

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