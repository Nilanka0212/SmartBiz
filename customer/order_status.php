<?php
require_once 'config/database.php';

$order_id = intval($_GET['order_id'] ?? 0);
$clear_shop_id = intval($_GET['clear_shop_id'] ?? 0);

if (!$order_id) {
    die('<h2 style="text-align:center;padding:40px">
         Invalid order</h2>');
}

$db = getDb();

$stmt = $db->prepare("
    SELECT o.*, ow.shop_name, ow.name as owner_name
    FROM orders o
    JOIN owners ow ON o.owner_id = ow.id
    WHERE o.id = ?
");
$stmt->bind_param("i", $order_id);
$stmt->execute();
$order = $stmt->get_result()->fetch_assoc();
$stmt->close();
$db->close();

if (!$order) {
    die('<h2 style="text-align:center;padding:40px">
         Order not found</h2>');
}

$items = json_decode($order['items'], true);

$statusInfo = [
    'pending' => ['icon' => 'Pending', 'label' => 'Order Received', 'msg' => 'Your order has been received!'],
    'preparing' => ['icon' => 'Preparing', 'label' => 'Preparing', 'msg' => 'Your order is being prepared!'],
    'ready' => ['icon' => 'Ready', 'label' => 'Ready!', 'msg' => 'Your order is ready for pickup!'],
    'completed' => ['icon' => 'Done', 'label' => 'Completed', 'msg' => 'Order completed. Thank you!'],
    'cancelled' => ['icon' => 'Cancelled', 'label' => 'Cancelled', 'msg' => 'Your order was cancelled.'],
];

$info = $statusInfo[$order['status']] ?? $statusInfo['pending'];
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Order #<?= $order_id ?></title>
    <link rel="stylesheet" href="assets/css/style.css">
    <meta http-equiv="refresh" content="15">
</head>
<body>

<div class="shop-header">
    <div class="shop-info">
        <div>
            <h1>Order #<?= $order_id ?></h1>
            <p><?= htmlspecialchars($order['shop_name'] ?? '') ?></p>
        </div>
    </div>
</div>

<div class="products-container">
    <div class="status-card">
        <div class="status-icon"><?= $info['icon'] ?></div>
        <span class="status-badge status-<?= $order['status'] ?>">
            <?= $info['label'] ?>
        </span>
        <p style="color:#888;margin-top:8px">
            <?= $info['msg'] ?>
        </p>
        <p style="font-size:12px;color:#bbb;margin-top:8px">
            Auto refreshing every 15 seconds...
        </p>
    </div>

    <div class="section-title">Order Details</div>
    <div style="background:white;border-radius:14px;
                padding:16px;margin-bottom:16px;
                box-shadow:0 2px 8px rgba(0,0,0,0.06)">

        <?php foreach ($items as $item): ?>
        <div class="cart-item">
            <div>
                <div class="cart-item-name">
                    <?= htmlspecialchars($item['name']) ?>
                </div>
                <div style="font-size:12px;color:#888">
                    Qty: <?= $item['qty'] ?>
                </div>
            </div>
            <div class="cart-item-price">
                Rs. <?= number_format($item['price'] * $item['qty'], 2) ?>
            </div>
        </div>
        <?php endforeach; ?>

        <div class="cart-total">
            <span>Total</span>
            <span>Rs. <?= number_format($order['total_price'], 2) ?></span>
        </div>

        <div style="display:flex;justify-content:space-between;
                    padding:8px 0;border-top:1px solid #f0f0f0">
            <span style="color:#888;font-size:14px">Payment</span>
            <span style="font-size:14px;font-weight:600">
                <?= ucfirst($order['payment_method']) ?>
                <?php if ($order['payment_status'] === 'paid'): ?>
                    <span style="color:green">Paid</span>
                <?php else: ?>
                    <span style="color:#ff8c00">Unpaid</span>
                <?php endif; ?>
            </span>
        </div>

        <?php if ($order['note']): ?>
        <div style="margin-top:10px;padding:10px;
                    background:#f8f9fa;border-radius:8px;
                    font-size:13px;color:#666">
            Note: <?= htmlspecialchars($order['note']) ?>
        </div>
        <?php endif; ?>
    </div>

    <!-- <a href="order_history.php?id=<?= intval($order['owner_id']) ?>"
       class="btn-outline"
       style="display:block;text-align:center;
              text-decoration:none;margin-bottom:12px">
        View Order History
    </a> -->

    <a href="index.php?id=<?= $order['owner_id'] ?>"
       class="btn-outline"
       style="display:block;text-align:center;
              text-decoration:none">
        Order Again
    </a>
</div>
<script src="assets/js/cart.js"></script>
<script>
document.addEventListener('DOMContentLoaded', () => {
    OrderHistory.save({
        id: <?= intval($order_id) ?>,
        owner_id: <?= intval($order['owner_id']) ?>,
        shop_name: <?= json_encode($order['shop_name'] ?? '') ?>
    });

    Cart.clearIfMatchesShop(
        <?= $clear_shop_id ?: intval($order['owner_id']) ?>
    );
});
</script>
</body>
</html>
