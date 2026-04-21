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

$input = json_decode(file_get_contents('php://input'), true);
$ownerId = intval($input['owner_id'] ?? $_REQUEST['owner_id'] ?? 0);
$itemsRaw = $input['items'] ?? $_REQUEST['items'] ?? '[]';
$customerName = trim($input['customer_name'] ?? $_REQUEST['customer_name'] ?? '');
$customerPhone = trim($input['customer_phone'] ?? $_REQUEST['customer_phone'] ?? '');
$note = trim($input['note'] ?? $_REQUEST['note'] ?? '');
$paymentMethod = trim($input['payment_method'] ?? $_REQUEST['payment_method'] ?? '');

if ($ownerId <= 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Owner ID is required'
    ]);
    exit;
}

$items = is_array($itemsRaw) ? $itemsRaw : json_decode($itemsRaw, true);
if (empty($items) || !is_array($items)) {
    echo json_encode([
        'success' => false,
        'message' => 'At least one product is required'
    ]);
    exit;
}

if (!in_array($paymentMethod, ['cash', 'online'], true)) {
    echo json_encode([
        'success' => false,
        'message' => 'Payment method is required'
    ]);
    exit;
}

$productIds = [];
$quantities = [];

foreach ($items as $item) {
    $productId = intval($item['product_id'] ?? 0);
    $qty = max(1, intval($item['qty'] ?? 1));

    if ($productId <= 0) {
        continue;
    }

    $productIds[] = $productId;
    $quantities[$productId] = ($quantities[$productId] ?? 0) + $qty;
}

if (empty($productIds)) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid product selection'
    ]);
    exit;
}

$productIds = array_values(array_unique($productIds));
$placeholders = implode(',', array_fill(0, count($productIds), '?'));
$types = 'i' . str_repeat('i', count($productIds));
$params = array_merge([$ownerId], $productIds);

$conn = getConnection();

$stmt = $conn->prepare("
    SELECT id, name, price
    FROM products
    WHERE owner_id = ? AND id IN ($placeholders)
");
$stmt->bind_param($types, ...$params);
$stmt->execute();
$result = $stmt->get_result();

$products = [];
while ($row = $result->fetch_assoc()) {
    $products[(int) $row['id']] = $row;
}
$stmt->close();

if (count($products) !== count($productIds)) {
    echo json_encode([
        'success' => false,
        'message' => 'One or more selected products are not available'
    ]);
    $conn->close();
    exit;
}

$orderItems = [];
$total = 0;

foreach ($productIds as $productId) {
    $product = $products[$productId];
    $qty = $quantities[$productId] ?? 1;
    $price = (float) $product['price'];

    $orderItems[] = [
        'id' => $productId,
        'name' => $product['name'],
        'price' => $price,
        'qty' => $qty,
    ];

    $total += $price * $qty;
}

$itemsJson = json_encode($orderItems);
$paymentStatus = $paymentMethod === 'online' ? 'pending' : 'paid';
$status = 'pending';

$insert = $conn->prepare("
    INSERT INTO orders (
        owner_id, customer_name, customer_phone, items,
        total_price, payment_method, payment_status, note, status
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
");
$insert->bind_param(
    "isssdssss",
    $ownerId,
    $customerName,
    $customerPhone,
    $itemsJson,
    $total,
    $paymentMethod,
    $paymentStatus,
    $note,
    $status
);

if ($insert->execute()) {
    echo json_encode([
        'success' => true,
        'message' => 'Order created successfully',
        'order_id' => $conn->insert_id,
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Failed to create order'
    ]);
}

$insert->close();
$conn->close();
