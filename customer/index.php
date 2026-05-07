<?php
require_once 'config/database.php';

$owner_id = intval($_GET['id'] ?? 0);

function renderShopStatusMessage(string $message, string $shopName = 'This shop'): void {
    echo '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Shop Unavailable</title>
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
        .closed-sign {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 86px;
            height: 86px;
            border-radius: 24px;
            background: linear-gradient(135deg, #ffb74d, #ff7043);
            color: #fff;
            font-size: 34px;
            font-weight: 800;
            margin-bottom: 18px;
            box-shadow: 0 12px 28px rgba(255, 112, 67, 0.32);
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
            <div class="closed-sign">Zzz</div>
            <h1>' . htmlspecialchars($shopName, ENT_QUOTES, 'UTF-8') . ' is taking a short break</h1>
            <p>' . htmlspecialchars($message, ENT_QUOTES, 'UTF-8') . '</p>
            <div class="closed-note">Please check back later. Fresh orders will open again soon.</div>
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

if (!$owner_id) {
    renderShopStatusMessage('Invalid shop link.');
}

$db = getDb();


// Get owner info
$ownerStmt = $db->prepare("
    SELECT * FROM owners WHERE id = ? AND is_verified = 1
");
$ownerStmt->bind_param("i", $owner_id);
$ownerStmt->execute();
$owner = $ownerStmt->get_result()->fetch_assoc();
$ownerStmt->close();

if (!$owner) {
    die('<h2 style="text-align:center;padding:40px;color:#888">
         Shop not found or not active</h2>');
}

if (!ownerHasActiveLicense($owner) || intval($owner['is_shop_open'] ?? 1) !== 1) {
    $db->close();
    renderShopStatusMessage(
        'The counter is closed right now, so new orders are paused for a little while.',
        $owner['shop_name'] ?? $owner['name'] ?? 'This shop'
    );
}
// $ownerStmt = $db->prepare("
//     SELECT
//         o.*,
//         CASE
//             WHEN o.is_verified != 1 THEN 'unverified'
//             WHEN COALESCE(o.is_shop_open, 1) != 1 THEN 'closed'
//             ELSE 'open'
//         END AS shop_status
//     FROM owners o
//     WHERE o.id = ?
// ");
// $ownerStmt->bind_param("i", $owner_id);
// $ownerStmt->execute();
// $owner = $ownerStmt->get_result()->fetch_assoc();
// $ownerStmt->close();

// if (!$owner) {
//     $db->close();
//     renderShopStatusMessage('Shop not found.');
// }

// if (($owner['shop_status'] ?? 'closed') === 'unverified') {
//     $db->close();
//     renderShopStatusMessage('This shop is not available right now.');
// }

// if (($owner['shop_status'] ?? 'closed') === 'closed') {
//     $db->close();
//     renderShopStatusMessage('This shop is currently closed.');
// }

$productsStmt = $db->prepare("
    SELECT * FROM products
    WHERE owner_id = ? AND status = 'active' AND is_active = 1
    ORDER BY created_at DESC
");
$productsStmt->bind_param("i", $owner_id);
$productsStmt->execute();
$products = $productsStmt->get_result()->fetch_all(MYSQLI_ASSOC);
$productsStmt->close();
$db->close();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
    <title><?= htmlspecialchars($owner['shop_name'] ?? $owner['name']) ?></title>
    <link rel="stylesheet" href="assets/css/style.css">
</head>
<body>

<div class="shop-header">
    <div class="shop-info">
        <?php if ($owner['shop_image']): ?>
            <img src="../api/<?= htmlspecialchars($owner['shop_image']) ?>"
                 class="shop-image" alt="Shop">
        <?php else: ?>
            <div class="shop-image-placeholder">Shop</div>
        <?php endif; ?>
        <div>
            <h1><?= htmlspecialchars($owner['shop_name'] ?? $owner['name']) ?></h1>
            <p><?= htmlspecialchars($owner['shop_location']) ?></p>
        </div>
    </div>
    <div style="display:flex;gap:10px;align-items:center">
        <!-- <a href="order_history.php?id=<?= $owner_id ?>"
           class="btn-outline"
           style="padding:10px 14px;text-decoration:none;white-space:nowrap">
            Order History
        </a> -->
        <button class="cart-btn" onclick="openCart()">
            Cart
            <span class="cart-badge" id="cart-badge"
                  style="display:none">0</span>
        </button>
    </div>
</div>

<div class="products-container">
    <div class="section-title">
        Menu (<?= count($products) ?> items)
    </div>

    <?php if (empty($products)): ?>
        <div class="empty-state">
            <div class="icon">Menu</div>
            <p>No products available yet</p>
        </div>
    <?php else: ?>
        <?php foreach ($products as $product): ?>
        <div class="product-card"
             data-product-id="<?= $product['id'] ?>">

            <?php if ($product['image']): ?>
                <img src="../api/<?= htmlspecialchars($product['image']) ?>"
                     class="product-image" alt="<?= htmlspecialchars($product['name']) ?>">
            <?php else: ?>
                <div class="product-image-placeholder">Item</div>
            <?php endif; ?>

            <div class="product-info">
                <div class="product-name">
                    <?= htmlspecialchars($product['name']) ?>
                </div>
                <?php if ($product['description']): ?>
                    <div class="product-desc">
                        <?= htmlspecialchars($product['description']) ?>
                    </div>
                <?php endif; ?>
                <div class="product-price">
                    Rs. <?= number_format($product['price'], 2) ?>
                </div>
            </div>

            <button class="add-btn"
                    id="add-<?= $product['id'] ?>"
                    onclick="Cart.add(
                        <?= $product['id'] ?>,
                        '<?= addslashes($product['name']) ?>',
                        <?= $product['price'] ?>,
                        {
                            id: <?= $owner_id ?>,
                            name: '<?= addslashes($owner['shop_name'] ?? $owner['name']) ?>'
                        }
                    )">+</button>

            <div class="quantity-control"
                 id="qty-<?= $product['id'] ?>"
                 style="display:none">
                <button class="qty-btn minus"
                        onclick="Cart.remove(<?= $product['id'] ?>)">
                    -
                </button>
                <span class="qty-count"
                      id="qtynum-<?= $product['id'] ?>">0</span>
                <button class="qty-btn plus"
                        onclick="Cart.add(
                            <?= $product['id'] ?>,
                            '<?= addslashes($product['name']) ?>',
                            <?= $product['price'] ?>,
                            {
                                id: <?= $owner_id ?>,
                                name: '<?= addslashes($owner['shop_name'] ?? $owner['name']) ?>'
                            }
                        )">+</button>
            </div>
        </div>
        <?php endforeach; ?>
    <?php endif; ?>
</div>

<div class="modal-overlay" id="cart-modal"
     onclick="if(event.target===this) closeCart()">
    <div class="modal-sheet">
        <div class="modal-handle"></div>
        <div class="modal-title">Your Cart</div>

        <div id="cart-items"></div>

        <div class="cart-total">
            <span>Total</span>
            <span id="cart-total">Rs. 0.00</span>
        </div>

        <button class="btn-primary"
                id="checkout-btn"
                onclick="goToCheckout(<?= $owner_id ?>)"
                disabled>
            Proceed to Checkout ->
        </button>
        <button class="btn-outline" onclick="closeCart()">
            Continue Shopping
        </button>
    </div>
</div>

<div class="toast" id="toast"></div>

<script src="assets/js/cart.js"></script>
<script>
window.currentShop = {
    id: <?= $owner_id ?>,
    name: '<?= addslashes($owner['shop_name'] ?? $owner['name']) ?>'
};

function goToCheckout(ownerId) {
    if (!Cart.canUseShop(window.currentShop)) {
        showToast(
            `You can only checkout items from ${Cart.shop.name}.`
        );
        return;
    }

    const items = Cart.items;
    if (Object.keys(items).length === 0) return;
    const itemsJson = encodeURIComponent(JSON.stringify(items));
    window.location.href =
        `order.php?id=${ownerId}&items=${itemsJson}`;
}
</script>
</body>
</html>
