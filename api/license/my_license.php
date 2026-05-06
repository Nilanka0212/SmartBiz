<?php
/**
 * Get My License - Owner can view their own license status
 * GET method
 * Required header: Authorization (owner_id)
 */

ini_set('display_errors', 0);
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once '../config/database.php';

// Get owner_id from header
$owner_id = $_SERVER['HTTP_AUTHORIZATION'] ?? $_REQUEST['owner_id'] ?? '';

if (empty($owner_id)) {
    echo json_encode([
        'success' => false,
        'message' => 'Owner ID is required'
    ]);
    exit;
}

$conn = getConnection();

$stmt = $conn->prepare("
    SELECT 
        id, name, phone, shop_name,
        license_status,
        license_start_date,
        license_end_date,
        license_amount,
        payment_method,
        transaction_id,
        created_at as license_created_at,
        updated_at as license_updated_at
    FROM owners 
    WHERE id = ?
");

$stmt->bind_param("i", $owner_id);
$stmt->execute();
$result = $stmt->get_result();
$owner = $result->fetch_assoc();
$stmt->close();

if (!$owner) {
    echo json_encode([
        'success' => false,
        'message' => 'Owner not found'
    ]);
    $conn->close();
    exit;
}

// Calculate days remaining
$days_remaining = null;
$is_expired = false;
$is_expiring_soon = false;

if ($owner['license_status'] == 'active' && $owner['license_end_date']) {
    $end_date = new DateTime($owner['license_end_date']);
    $today = new DateTime(date('Y-m-d'));
    $interval = $today->diff($end_date);
    $days_remaining = (int)$interval->format('%r%a');
    
    if ($days_remaining < 0) {
        $is_expired = true;
        $days_remaining = null;
    } elseif ($days_remaining <= 7) {
        $is_expiring_soon = true;
    }
}

$license_status = $owner['license_status'];
if ($is_expired) {
    $license_status = 'expired';
}

echo json_encode([
    'success' => true,
    'data' => [
        'owner_id' => $owner['id'],
        'owner_name' => $owner['name'],
        'phone' => $owner['phone'],
        'shop_name' => $owner['shop_name'],
        'license_status' => $license_status,
        'license_start_date' => $owner['license_start_date'],
        'license_end_date' => $owner['license_end_date'],
        'days_remaining' => $days_remaining,
        'is_expiring_soon' => $is_expiring_soon,
        'is_expired' => $is_expired,
        'license_amount' => $owner['license_amount'],
        'payment_method' => $owner['payment_method'],
        'transaction_id' => $owner['transaction_id'],
        'license_created_at' => $owner['license_created_at'],
        'license_updated_at' => $owner['license_updated_at']
    ],
    'message' => $is_expired ? 'Your license has expired. Please contact admin to renew.' : 
                 ($is_expiring_soon ? 'Your license expires in ' . $days_remaining . ' days. Please renew soon.' : null)
]);

$conn->close();