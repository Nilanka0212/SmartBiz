<?php
ini_set('display_errors', 0);
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once '../config/database.php';

$product_id = trim($_REQUEST['product_id'] ?? '');
$is_active  = trim($_REQUEST['is_active'] ?? '');

if (empty($product_id)) {
    echo json_encode([
        'success' => false,
        'message' => 'Product ID is required'
    ]);
    exit;
}

$conn = getConnection();

// Check if product is approved
$check = $conn->prepare(
    "SELECT status FROM products WHERE id = ?"
);
$check->bind_param("i", $product_id);
$check->execute();
$result  = $check->get_result();
$product = $result->fetch_assoc();
$check->close();

if ($product['status'] !== 'active' &&
    $product['status'] !== 'inactive') {
    echo json_encode([
        'success' => false,
        'message' => 'Product is pending approval. Cannot toggle.'
    ]);
    $conn->close();
    exit;
}

$new_status    = $is_active == '1' ? 'active' : 'inactive';
$new_is_active = $is_active == '1' ? 1 : 0;

$stmt = $conn->prepare(
    "UPDATE products SET is_active = ?, status = ? WHERE id = ?"
);
$stmt->bind_param("isi", $new_is_active, $new_status, $product_id);

if ($stmt->execute()) {
    echo json_encode([
        'success'   => true,
        'message'   => 'Product status updated',
        'is_active' => $new_is_active,
        'status'    => $new_status,
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Failed to update status'
    ]);
}

$stmt->close();
$conn->close();