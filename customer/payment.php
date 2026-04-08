<?php
require_once 'config/database.php';

$order_id = intval($_GET['order_id'] ?? 0);
$clear_shop_id = intval($_GET['clear_shop_id'] ?? 0);

if (!$order_id) {
    header('Location: index.php');
    exit;
}

$db = getDb();
$stmt = $db->prepare("SELECT * FROM orders WHERE id = ?");
$stmt->bind_param("i", $order_id);
$stmt->execute();
$order = $stmt->get_result()->fetch_assoc();
$stmt->close();

// Simulate payment confirmation
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $updateStmt = $db->prepare("
        UPDATE orders SET payment_status = 'paid' WHERE id = ?
    ");
    $updateStmt->bind_param("i", $order_id);
    $updateStmt->execute();
    $updateStmt->close();
    $db->close();
    header("Location: order_status.php?order_id=$order_id&clear_shop_id=$clear_shop_id");
    exit;
}

$db->close();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment</title>
    <link rel="stylesheet" href="assets/css/style.css">
</head>
<body>

<div class="shop-header">
    <div class="shop-info">
        <div>
            <h1>💳 Payment</h1>
            <p>Order #<?= $order_id ?></p>
        </div>
    </div>
</div>

<div class="products-container">

    <div style="background:white;border-radius:14px;
                padding:24px;text-align:center;
                box-shadow:0 2px 8px rgba(0,0,0,0.06);
                margin-bottom:20px">
        <div style="font-size:48px;margin-bottom:12px">💳</div>
        <h3 style="margin-bottom:8px">Amount to Pay</h3>
        <div style="font-size:32px;font-weight:700;
                    color:#ff8c00;margin-bottom:20px">
            Rs. <?= number_format($order['total_price'], 2) ?>
        </div>

        <!-- Payment QR placeholder -->
        <div style="background:#f8f9fa;border-radius:12px;
                    padding:30px;margin-bottom:20px">
            <div style="font-size:60px">📱</div>
            <p style="color:#888;margin-top:8px;font-size:14px">
                Scan QR code to pay<br>
                (Payment gateway integration here)
            </p>
        </div>

        <p style="color:#888;font-size:13px;margin-bottom:20px">
            After payment, click confirm below
        </p>
    </div>

    <form method="POST">
        <button type="submit" class="btn-primary">
            ✅ Confirm Payment
        </button>
    </form>

    <a href="order_status.php?order_id=<?= $order_id ?>&clear_shop_id=<?= $clear_shop_id ?>"
       style="display:block;text-align:center;
              margin-top:14px;color:#888;font-size:14px;
              text-decoration:none">
        Pay later (Cash)
    </a>
</div>
<script src="assets/js/cart.js"></script>
<script>
document.addEventListener('DOMContentLoaded', () => {
    Cart.clearIfMatchesShop(<?= $clear_shop_id ?>);
});
</script>
</body>
</html>
