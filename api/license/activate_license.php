<?php
/**
 * Activate License - Admin activates license for an owner
 * POST method
 * Required fields: owner_id, amount, payment_method, transaction_id
 * Optional: start_date (defaults to today), end_date (defaults to +1 month)
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

$input = json_decode(file_get_contents('php://input'), true);

// Get values from input
$owner_id       = trim($input['owner_id'] ?? '');
$amount         = trim($input['amount'] ?? '');
$payment_method = trim($input['payment_method'] ?? '');
$transaction_id = trim($input['transaction_id'] ?? '');
$start_date     = $input['start_date'] ?? date('Y-m-d');
$end_date       = $input['end_date'] ?? date('Y-m-d', strtotime('+1 month'));
$admin_id       = $input['admin_id'] ?? null;

// Validation
if (empty($owner_id) || empty($amount) || empty($payment_method)) {
    echo json_encode([
        'success' => false,
        'message' => 'Owner ID, amount, and payment method are required'
    ]);
    exit;
}

$conn = getConnection();

// Check if owner exists
$stmt = $conn->prepare("SELECT id, name, phone FROM owners WHERE id = ?");
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

// Check if owner already has active license
$checkStmt = $conn->prepare("SELECT id FROM owners WHERE id = ? AND license_status = 'active' AND license_end_date >= ?");
$checkStmt->bind_param("is", $owner_id, date('Y-m-d'));
$checkStmt->execute();
$checkResult = $checkStmt->get_result();
if ($checkResult->num_rows > 0) {
    $checkStmt->close();
    echo json_encode([
        'success' => false,
        'message' => 'Owner already has an active license'
    ]);
    $conn->close();
    exit;
}
$checkStmt->close();

// Activate license
$updateStmt = $conn->prepare("
    UPDATE owners 
    SET license_status = 'active',
        license_start_date = ?,
        license_end_date = ?,
        license_amount = ?,
        payment_method = ?,
        transaction_id = ?,
        updated_by = ?,
        updated_at = NOW()
    WHERE id = ?
");

$updateStmt->bind_param(
    "ssdssii",
    $start_date,
    $end_date,
    $amount,
    $payment_method,
    $transaction_id,
    $admin_id,
    $owner_id
);

if ($updateStmt->execute()) {
    $updateStmt->close();
    
    echo json_encode([
        'success' => true,
        'message' => 'License activated successfully',
        'data' => [
            'owner_id' => $owner_id,
            'owner_name' => $owner['name'],
            'phone' => $owner['phone'],
            'license_status' => 'active',
            'start_date' => $start_date,
            'end_date' => $end_date,
            'amount' => $amount,
            'payment_method' => $payment_method,
            'transaction_id' => $transaction_id
        ]
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Failed to activate license: ' . $updateStmt->error
    ]);
}

$conn->close();