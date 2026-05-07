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

$owner_id = intval($_REQUEST['owner_id'] ?? 0);
$status   = trim($_REQUEST['status']   ?? 'pending');

if ($owner_id <= 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Valid owner ID required'
    ]);
    exit;
}

$conn = getConnection();

// ── Fetch all products for this owner once (id, name, cost_price, sell_price) ──
$prodStmt = $conn->prepare("
    SELECT id, name, cost_price, sell_price, price
    FROM products
    WHERE owner_id = ?
");
$prodStmt->bind_param("i", $owner_id);
$prodStmt->execute();
$prodResult = $prodStmt->get_result();

// Build two lookup maps: by product id and by product name (lowercase)
$productById   = [];
$productByName = [];
while ($p = $prodResult->fetch_assoc()) {
    $productById[$p['id']] = $p;
    $productByName[strtolower(trim($p['name']))] = $p;
}
$prodStmt->close();

// ── Fetch orders ──
$stmt = $conn->prepare("
    SELECT
        o.*,
        ow.shop_name AS order_shop_name,
        ow.name AS order_owner_name
    FROM orders o
    INNER JOIN owners ow ON ow.id = o.owner_id
    WHERE o.owner_id = ? AND o.status = ?
    ORDER BY created_at DESC
");
$stmt->bind_param("is", $owner_id, $status);
$stmt->execute();
$result = $stmt->get_result();
$orders = [];

while ($row = $result->fetch_assoc()) {

    // ── Parse items JSON ──
    $items = [];
    if (!empty($row['items_list'])) {
        $items = (array) json_decode($row['items_list'], true);
    } elseif (!empty($row['items'])) {
        $items = array_values((array) json_decode($row['items'], true));
    }

    // ── Inject cost_price & sell_price into each item ──
    $items = array_map(function($item) use ($productById, $productByName) {

        // Try lookup by product_id first, then by name
        $product = null;
        if (!empty($item['product_id']) && isset($productById[$item['product_id']])) {
            $product = $productById[$item['product_id']];
        } elseif (!empty($item['name'])) {
            $key = strtolower(trim($item['name']));
            if (isset($productByName[$key])) {
                $product = $productByName[$key];
            }
        }

        if ($product) {
            // Use sell_price if set, otherwise fall back to price
            $sell = !empty($product['sell_price']) ? (float)$product['sell_price']
                                                   : (float)$product['price'];
            $cost = !empty($product['cost_price']) ? (float)$product['cost_price'] : 0.0;

            $item['sell_price'] = $sell;
            $item['cost_price'] = $cost;
        } else {
            // No matching product — use item price as sell, 0 as cost
            $item['sell_price'] = (float)($item['price'] ?? 0);
            $item['cost_price'] = 0.0;
        }

        return $item;
    }, $items);

    $row['items_list'] = $items;
    $orders[] = $row;
}

$stmt->close();
$conn->close();

echo json_encode([
    'success' => true,
    'data'    => [
        'orders' => $orders,
        'count'  => count($orders),
    ],
]);
