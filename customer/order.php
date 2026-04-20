<?php
require_once 'config/database.php';

$owner_id  = intval($_GET['id'] ?? 0);
$itemsJson = $_GET['items'] ?? '';

if (!$owner_id || !$itemsJson) {
    header('Location: index.php');
    exit;
}

$items = json_decode(urldecode($itemsJson), true);

if (empty($items)) {
    header("Location: index.php?id=$owner_id");
    exit;
}

$db = getDb();

// Get owner
$stmt = $db->prepare("SELECT * FROM owners WHERE id = ?");
$stmt->bind_param("i", $owner_id);
$stmt->execute();
$owner = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$owner) {
    $db->close();
    header('Location: index.php');
    exit;
}

$productIds = array_map('intval', array_keys($items));
$productIds = array_values(array_filter($productIds, fn($id) => $id > 0));

if (empty($productIds)) {
    $db->close();
    header("Location: index.php?id=$owner_id");
    exit;
}

$placeholders = implode(',', array_fill(0, count($productIds), '?'));
$types = str_repeat('i', count($productIds) + 1);
$params = array_merge([$owner_id], $productIds);

$productStmt = $db->prepare("
    SELECT id, name, price
    FROM products
    WHERE owner_id = ? AND id IN ($placeholders)
");
$productStmt->bind_param($types, ...$params);
$productStmt->execute();
$productResult = $productStmt->get_result();

$validProducts = [];
while ($product = $productResult->fetch_assoc()) {
    $validProducts[(int) $product['id']] = $product;
}
$productStmt->close();

if (count($validProducts) !== count($productIds)) {
    $db->close();
    header("Location: index.php?id=$owner_id");
    exit;
}

$normalizedItems = [];
foreach ($items as $productId => $item) {
    $productId = (int) $productId;
    $qty = max(1, intval($item['qty'] ?? 1));
    $product = $validProducts[$productId];

    $normalizedItems[$productId] = [
        'id' => $productId,
        'name' => $product['name'],
        'price' => (float) $product['price'],
        'qty' => $qty,
    ];
}

$items = $normalizedItems;

// Calculate total
$total = array_reduce($items, function($sum, $item) {
    return $sum + ($item['price'] * $item['qty']);
}, 0);

// Handle order submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $customer_name   = trim($_POST['customer_name'] ?? '');
    $customer_phone  = trim($_POST['customer_phone'] ?? '');
    $payment_method  = $_POST['payment_method'] ?? 'cash';
    $note            = trim($_POST['note'] ?? '');
    $items_json      = json_encode($items);

    $stmt = $db->prepare("
        INSERT INTO orders
        (owner_id, customer_name, customer_phone,
         items, total_price, payment_method, payment_status, note, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");
    
    $payment_status = $payment_method === 'online' ? 'pending' : 'paid';
    $status = 'pending';
    
    $stmt->bind_param(
        "isssdssss",
        $owner_id, $customer_name, $customer_phone,
        $items_json, $total, $payment_method, $payment_status, $note, $status
    );

    if ($stmt->execute()) {
        $order_id = $db->insert_id;
        $stmt->close();
        $db->close();

        if ($payment_method === 'online') {
            header("Location: payment.php?order_id=$order_id&clear_shop_id=$owner_id");
        } else {
            header("Location: order_status.php?order_id=$order_id&clear_shop_id=$owner_id");
        }
        exit;
    }
}

$db->close();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Checkout</title>
    <link rel="stylesheet" href="assets/css/style.css">
</head>
<body>

<div class="shop-header">
    <div class="shop-info">
        <a href="index.php?id=<?= $owner_id ?>"
           style="text-decoration:none;color:#333;
                  font-size:20px;margin-right:10px">←</a>
        <div>
            <h1>Checkout</h1>
            <p><?= htmlspecialchars($owner['shop_name'] ?? '') ?></p>
        </div>
    </div>
</div>

<div class="products-container">

    <!-- Order summary -->
    <div class="section-title">Order Summary</div>
    <div style="background:white;border-radius:14px;
                padding:16px;margin-bottom:20px;
                box-shadow:0 2px 8px rgba(0,0,0,0.06)">
        <?php foreach ($items as $item): ?>
        <div class="cart-item">
            <div>
                <div class="cart-item-name">
                    <?= htmlspecialchars($item['name']) ?>
                </div>
                <div style="font-size:12px;color:#888">
                    Rs. <?= $item['price'] ?> × <?= $item['qty'] ?>
                </div>
            </div>
            <div class="cart-item-price">
                Rs. <?= number_format($item['price'] * $item['qty'], 2) ?>
            </div>
        </div>
        <?php endforeach; ?>
        <div class="cart-total">
            <span>Total</span>
            <span>Rs. <?= number_format($total, 2) ?></span>
        </div>
    </div>

    <!-- Customer details form -->
    <div class="section-title">Your Details</div>
    <form method="POST">
        <div style="background:white;border-radius:14px;
                    padding:16px;margin-bottom:20px;
                    box-shadow:0 2px 8px rgba(0,0,0,0.06)">

            <div class="form-group">
                <label>Your Name (Optional)</label>
                <input type="text" name="customer_name"
                       placeholder="Enter your name" required>
            </div>

            <div class="form-group">
                <label>Phone Number (Optional)</label>
                <input type="tel" name="customer_phone"
                       placeholder="Enter phone number" required>
            </div>

            <div class="form-group">
                <label>Special Note (Optional)</label>
                <textarea name="note" rows="2"
                          placeholder="Any special requests..."></textarea>
            </div>
        </div>

        <!-- Payment method -->
        <div class="section-title">Payment Method</div>
        <div style="background:white;border-radius:14px;
                    padding:16px;margin-bottom:20px;
                    box-shadow:0 2px 8px rgba(0,0,0,0.06)">
            <div class="payment-options">
                <div class="payment-option selected"
                     id="cash-option"
                     onclick="selectPayment('cash')">
                    <div class="icon">💵</div>
                    <div class="label">Cash</div>
                </div>
                <div class="payment-option"
                     id="online-option"
                     onclick="selectPayment('online')">
                    <div class="icon">💳</div>
                    <div class="label">Online Pay</div>
                </div>
            </div>
            <input type="hidden" name="payment_method"
                   id="payment_method" value="cash">
        </div>

        <button type="submit" class="btn-primary">
            Place Order 🎉
        </button>
    </form>
</div>

<script>
function selectPayment(method) {
    document.getElementById('payment_method').value = method;
    document.getElementById('cash-option').classList
        .toggle('selected', method === 'cash');
    document.getElementById('online-option').classList
        .toggle('selected', method === 'online');
}
</script>
<script src="assets/js/cart.js"></script>
</body>
</html>
