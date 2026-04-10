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

$orderIdsRaw = trim($_GET['order_ids'] ?? '');
$ownerId = intval($_GET['owner_id'] ?? 0);
$customerPhone = trim($_GET['customer_phone'] ?? '');

if ($customerPhone === '' && $orderIdsRaw === '') {
    echo json_encode([
        'success' => true,
        'data' => [
            'orders' => [],
            'count' => 0,
        ],
    ]);
    exit;
}

$conn = getConnection();

if ($customerPhone !== '') {
    $sql = "
        SELECT o.*, ow.shop_name, ow.name AS owner_name
        FROM orders o
        JOIN owners ow ON o.owner_id = ow.id
        WHERE o.customer_phone = ?
    ";
    $types = 's';
    $params = [$customerPhone];

    if ($ownerId > 0) {
        $sql .= " AND o.owner_id = ?";
        $types .= 'i';
        $params[] = $ownerId;
    }

    $sql .= " ORDER BY o.created_at DESC";
} else {
    $orderIds = array_values(array_unique(array_filter(array_map(
        'intval',
        explode(',', $orderIdsRaw)
    ), fn($id) => $id > 0)));

    if (empty($orderIds)) {
        echo json_encode([
            'success' => true,
            'data' => [
                'orders' => [],
                'count' => 0,
            ],
        ]);
        exit;
    }

    $placeholders = implode(',', array_fill(0, count($orderIds), '?'));
    $types = str_repeat('i', count($orderIds));
    $params = $orderIds;

    $sql = "
        SELECT o.*, ow.shop_name, ow.name AS owner_name
        FROM orders o
        JOIN owners ow ON o.owner_id = ow.id
        WHERE o.id IN ($placeholders)
    ";

    if ($ownerId > 0) {
        $sql .= " AND o.owner_id = ?";
        $types .= 'i';
        $params[] = $ownerId;
    }

    $sql .= " ORDER BY o.created_at DESC";
}

$stmt = $conn->prepare($sql);
$stmt->bind_param($types, ...$params);
$stmt->execute();
$result = $stmt->get_result();

$orders = [];
while ($row = $result->fetch_assoc()) {
    $items = [];

    if (!empty($row['items_list'])) {
        $items = (array) json_decode($row['items_list'], true);
    } elseif (!empty($row['items'])) {
        $items = (array) json_decode($row['items'], true);
        $items = array_values($items);
    }

    $row['items_list'] = $items;
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
