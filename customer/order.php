<?php
require_once 'config/database.php';

$owner_id  = intval($_GET['id'] ?? 0);
$itemsJson = $_GET['items'] ?? '';

function renderShopStatusMessage(string $message, string $shopName = 'This shop'): void {
    echo '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Shop Closed</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <style>
        .closed-wrap {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px;
            background:
                radial-gradient(circle at top left, rgba(255, 167, 38, 0.20), transparent 34%),
                linear-gradient(180deg, #fff8f0 0%, #ffffff 100%);
        }
        .closed-card {
            width: min(440px, 100%);
            background: #fff;
            border: 1px solid rgba(255, 112, 67, 0.16);
            border-radius: 22px;
            box-shadow: 0 18px 45px rgba(40, 24, 12, 0.12);
            padding: 28px 24px;
            text-align: center;
        }
      
        .closed-card h1 {
            margin: 0 0 8px;
            color: #2d2118;
            font-size: 26px;
            line-height: 1.2;
        }
        .closed-card p {
            margin: 0;
            color: #7a6a5f;
            line-height: 1.6;
        }
        .closed-note {
            margin-top: 18px;
            padding: 12px 14px;
            border-radius: 14px;
            background: #fff4e8;
            color: #9a4a14;
            font-size: 14px;
            font-weight: 600;
        }
    </style>
</head>
<body>
    <div class="closed-wrap">
        <div class="closed-card">
           
            <h1>' . htmlspecialchars($shopName, ENT_QUOTES, 'UTF-8') . ' is taking a short break</h1>
            <p>' . htmlspecialchars($message, ENT_QUOTES, 'UTF-8') . '</p>
            <div class="closed-note">Your cart is saved, but new orders are paused for now.</div>
            <a class="btn-outline" style="display:inline-block;margin-top:16px;text-decoration:none;" href="index.php?id=' . intval($_GET['id'] ?? 0) . '">Back to shop</a>
        </div>
    </div>
</body>
</html>';
    exit;
}

function ownerHasActiveLicense(array $owner): bool {
    if (($owner['license_status'] ?? '') !== 'active') {
        return false;
    }

    if (empty($owner['license_end_date'])) {
        return false;
    }

    return strtotime($owner['license_end_date']) >= strtotime(date('Y-m-d'));
}

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

if (!ownerHasActiveLicense($owner) || intval($owner['is_shop_open'] ?? 1) !== 1) {
    $db->close();
    renderShopStatusMessage(
        'The counter is closed right now, so checkout is paused for a little while.',
        $owner['shop_name'] ?? $owner['name'] ?? 'This shop'
    );
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
    WHERE owner_id = ?
      AND status = 'active'
      AND is_active = 1
      AND id IN ($placeholders)
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
    $payment_status  = $payment_method === 'online' ? 'pending' : 'paid';
    $status          = 'pending';

    $db->begin_transaction();

    $ownerLockStmt = $db->prepare("SELECT id FROM owners WHERE id = ? FOR UPDATE");
    $ownerLockStmt->bind_param("i", $owner_id);
    $ownerLockStmt->execute();
    $ownerLockStmt->close();

    $orderNumberStmt = $db->prepare("
        SELECT order_number
        FROM orders
        WHERE owner_id = ? AND order_number IS NOT NULL
        ORDER BY CAST(order_number AS UNSIGNED) DESC, id DESC
        LIMIT 1
    ");
    $orderNumberStmt->bind_param("i", $owner_id);
    $orderNumberStmt->execute();
    $lastOrder = $orderNumberStmt->get_result()->fetch_assoc();
    $orderNumberStmt->close();

    $order_number = (string) (intval($lastOrder['order_number'] ?? 0) + 1);

    $stmt = $db->prepare("
        INSERT INTO orders
        (owner_id, order_number, customer_name, customer_phone,
         items, total_price, payment_method, payment_status, note, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");

    $stmt->bind_param(
        "issssdssss",
        $owner_id, $order_number, $customer_name, $customer_phone,
        $items_json, $total, $payment_method, $payment_status, $note, $status
    );

    if ($stmt->execute()) {
        $order_id = $db->insert_id;
        $stmt->close();
        $db->commit();

        $db->close();

        if ($payment_method === 'online') {
            header("Location: payment.php?order_id=$order_id&clear_shop_id=$owner_id");
        } else {
            header("Location: order_status.php?order_id=$order_id&clear_shop_id=$owner_id");
        }
        exit;
    }

    $stmt->close();
    $db->rollback();
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
