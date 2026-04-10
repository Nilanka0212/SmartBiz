<?php
session_start();
require_once 'config/database.php';

$owner_id = intval($_GET['id'] ?? 0);
$owner = null;
$customerPhone = trim($_SESSION['customer_history_phone'] ?? '');
$customerName = trim($_SESSION['customer_history_name'] ?? '');

if ($owner_id > 0) {
    $db = getDb();
    $stmt = $db->prepare("
        SELECT id, shop_name, name
        FROM owners
        WHERE id = ? AND is_verified = 1
    ");
    $stmt->bind_param("i", $owner_id);
    $stmt->execute();
    $owner = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    $db->close();
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Order History</title>
    <link rel="stylesheet" href="assets/css/style.css">
</head>
<body>
<div class="shop-header">
    <div class="shop-info">
        <a href="<?= $owner_id ? 'index.php?id=' . $owner_id : 'javascript:history.back()' ?>"
           style="text-decoration:none;color:#333;font-size:20px;margin-right:10px">←</a>
        <div>
            <h1>Order History</h1>
            <p><?= htmlspecialchars($owner['shop_name'] ?? $owner['name'] ?? 'Your previous orders') ?></p>
        </div>
    </div>
</div>

<div class="products-container">
    <div id="history-empty" class="empty-state" style="display:none">
        <div class="icon">📋</div>
        <p>No previous orders found</p>
    </div>
    <div id="history-list"></div>
</div>

<script src="assets/js/cart.js"></script>
<script>
const ownerId = <?= $owner_id ?>;
const customerPhone = <?= json_encode($customerPhone) ?>;
const customerName = <?= json_encode($customerName) ?>;

function escapeHtml(value) {
    return String(value || '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}

function getStatusMeta(status) {
    const map = {
        pending: { label: 'Order Received', color: '#ff8c00' },
        preparing: { label: 'Preparing', color: '#3b82f6' },
        ready: { label: 'Ready', color: '#10b981' },
        completed: { label: 'Completed', color: '#16a34a' },
        cancelled: { label: 'Cancelled', color: '#dc2626' }
    };

    return map[status] || map.pending;
}

function renderOrders(orders) {
    const list = document.getElementById('history-list');
    const empty = document.getElementById('history-empty');

    if (!orders.length) {
        empty.style.display = 'block';
        list.innerHTML = '';
        return;
    }

    empty.style.display = 'none';
    list.innerHTML = orders.map(order => {
        const meta = getStatusMeta(order.status);
        const items = Array.isArray(order.items_list) ? order.items_list : [];
        const itemCount = items.reduce((sum, item) =>
            sum + Number(item.qty || 0), 0
        );

        return `
            <a href="order_status.php?order_id=${order.id}"
               style="display:block;text-decoration:none;color:inherit">
                <div style="background:white;border-radius:14px;padding:16px;margin-bottom:14px;box-shadow:0 2px 8px rgba(0,0,0,0.06)">
                    <div style="display:flex;justify-content:space-between;align-items:flex-start;gap:12px">
                        <div>
                            <div style="font-size:16px;font-weight:700;margin-bottom:4px">
                                Order #${order.id}
                            </div>
                            <div style="font-size:13px;color:#888">
                                ${escapeHtml(order.shop_name || order.owner_name || '')}
                            </div>
                        </div>
                        <span style="background:${meta.color};color:white;padding:6px 10px;border-radius:999px;font-size:12px;font-weight:700">
                            ${meta.label}
                        </span>
                    </div>
                    <div style="display:flex;justify-content:space-between;margin-top:14px;font-size:14px">
                        <span style="color:#666">${itemCount} item(s)</span>
                        <span style="font-weight:700;color:#ff8c00">
                            Rs. ${Number(order.total_price || 0).toFixed(2)}
                        </span>
                    </div>
                    <div style="margin-top:10px;font-size:12px;color:#888">
                        ${escapeHtml(order.created_at || '')}
                    </div>
                </div>
            </a>
        `;
    }).join('');
}

async function loadHistory() {
    if (customerPhone) {
        const response = await fetch(
            `../api/orders/get_order_history.php?owner_id=${ownerId}&customer_phone=${encodeURIComponent(customerPhone)}`
        );
        const payload = await response.json();
        renderOrders(payload?.data?.orders || []);
        return;
    }

    const savedOrders = OrderHistory.getByShop(ownerId);

    if (!savedOrders.length) {
        renderOrders([]);
        return;
    }

    const orderIds = savedOrders.map(order => order.id).join(',');
    const response = await fetch(
        `../api/orders/get_order_history.php?order_ids=${encodeURIComponent(orderIds)}&owner_id=${ownerId}`
    );
    const payload = await response.json();
    renderOrders(payload?.data?.orders || []);
}

document.addEventListener('DOMContentLoaded', async () => {
    try {
        await loadHistory();
    } catch (error) {
        renderOrders([]);
    }
});
</script>
</body>
</html>
