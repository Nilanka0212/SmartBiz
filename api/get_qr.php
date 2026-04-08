<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$owner_id = intval($_REQUEST['owner_id'] ?? 0);

if (!$owner_id) {
    echo json_encode(['success' => false]);
    exit;
}

// Shop URL
$shopUrl = "http://192.168.1.17/SmartBiz/customer/index.php?id=$owner_id";

// Generate QR using free API
$qrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=" . urlencode($shopUrl);

echo json_encode([
    'success'  => true,
    'shop_url' => $shopUrl,
    'qr_url'   => $qrUrl,
]);
