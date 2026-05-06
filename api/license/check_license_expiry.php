<?php
/**
 * License Expiry Checker - Run daily via cron job to update expired licenses
 * 
 * This script automatically:
 * 1. Sets license_status to 'expired' for expired active licenses
 * 2. Can notify owners before expiry (optional)
 * 
 * Run via cron: 0 0 * * * php /path/to/check_license_expiry.php
 */

ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once __DIR__ . '/config/database.php';

echo "[" . date('Y-m-d H:i:s') . "] Starting license expiry check...\n";

$conn = getConnection();

// Find all active licenses that have expired
$stmt = $conn->prepare("
    SELECT id, name, phone, shop_name, license_end_date 
    FROM owners 
    WHERE license_status = 'active' 
    AND license_end_date < CURDATE()
");

$stmt->execute();
$result = $stmt->get_result();

$expiredCount = 0;
$updatedOwners = [];

while ($row = $result->fetch_assoc()) {
    // Update status to expired
    $updateStmt = $conn->prepare("
        UPDATE owners 
        SET license_status = 'expired',
            updated_at = NOW()
        WHERE id = ?
    ");
    $updateStmt->bind_param("i", $row['id']);
    $updateStmt->execute();
    $updateStmt->close();
    
    $expiredCount++;
    $updatedOwners[] = [
        'id' => $row['id'],
        'name' => $row['name'],
        'phone' => $row['phone'],
        'shop_name' => $row['shop_name'],
        'expired_date' => $row['license_end_date']
    ];
    
    echo "  - Expired: {$row['name']} ({$row['shop_name']}) - Phone: {$row['phone']}\n";
}

$stmt->close();

// Find licenses expiring in next 7 days (for notification)
$notifyStmt = $conn->prepare("
    SELECT id, name, phone, shop_name, license_end_date 
    FROM owners 
    WHERE license_status = 'active' 
    AND license_end_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
");

$notifyStmt->execute();
$notifyResult = $notifyStmt->get_result();

$expiringSoonCount = 0;
$expiringOwners = [];

while ($row = $notifyResult->fetch_assoc()) {
    $expiringSoonCount++;
    $expiringOwners[] = [
        'id' => $row['id'],
        'name' => $row['name'],
        'phone' => $row['phone'],
        'shop_name' => $row['shop_name'],
        'expiry_date' => $row['license_end_date']
    ];
    
    echo "  - Expiring Soon: {$row['name']} ({$row['shop_name']}) - Expires: {$row['license_end_date']}\n";
}

$notifyStmt->close();

$conn->close();

echo "\n[" . date('Y-m-d H:i:s') . "] License expiry check complete.\n";
echo "  - Expired licenses: $expiredCount\n";
echo "  - Expiring soon (within 7 days): $expiringSoonCount\n";

// Return JSON for API calls
if (php_sapi_name() !== 'cli') {
    header('Content-Type: application/json');
    echo json_encode([
        'success' => true,
        'checked_at' => date('Y-m-d H:i:s'),
        'expired_count' => $expiredCount,
        'expiring_soon_count' => $expiringSoonCount,
        'expired_owners' => $updatedOwners,
        'expiring_soon_owners' => $expiringOwners
    ]);
}