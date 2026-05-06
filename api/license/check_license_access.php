<?php
/**
 * Check License Access - Check if owner has valid license (for app use)
 * GET method
 * Required query param: owner_id
 * 
 * This endpoint is called by the mobile app to verify license validity
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

$owner_id = $_GET['owner_id'] ?? $_REQUEST['owner_id'] ?? '';

if (empty($owner_id)) {
    echo json_encode([
        'success' => false,
        'has_access' => false,
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
        license_end_date
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
        'has_access' => false,
        'message' => 'Owner not found'
    ]);
    $conn->close();
    exit;
}

// Check license status
$has_access = false;
$message = '';
$days_remaining = null;

if ($owner['license_status'] == 'active' && $owner['license_end_date']) {
    $end_date = new DateTime($owner['license_end_date']);
    $today = new DateTime(date('Y-m-d'));
    $interval = $today->diff($end_date);
    $days_remaining = (int)$interval->format('%r%a');
    
    if ($days_remaining >= 0) {
        $has_access = true;
        $message = 'License is active';
    } else {
        $message = 'License has expired';
        // Update status to expired
        $updateStmt = $conn->prepare("
            UPDATE owners 
            SET license_status = 'expired',
                updated_at = NOW()
            WHERE id = ? AND license_status = 'active'
        ");
        $updateStmt->bind_param("i", $owner_id);
        $updateStmt->execute();
        $updateStmt->close();
    }
} elseif ($owner['license_status'] == 'pending') {
    $message = 'License not activated. Please contact admin.';
} elseif ($owner['license_status'] == 'expired') {
    $message = 'License has expired. Please contact admin to renew.';
} elseif ($owner['license_status'] == 'cancelled') {
    $message = 'License has been cancelled. Please contact admin.';
} else {
    $message = 'No active license';
}

echo json_encode([
    'success' => $has_access,
    'has_access' => $has_access,
    'owner_id' => $owner_id,
    'owner_name' => $owner['name'],
    'shop_name' => $owner['shop_name'],
    'license_status' => $owner['license_status'],
    'license_end_date' => $owner['license_end_date'],
    'days_remaining' => $days_remaining,
    'message' => $message
]);

$conn->close();