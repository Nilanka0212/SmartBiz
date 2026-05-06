<?php
/**
 * Deactivate License - Admin deactivates license for an owner
 * POST method
 * Required fields: owner_id
 * Optional: reason
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

$owner_id = trim($input['owner_id'] ?? '');
$reason   = trim($input['reason'] ?? 'Cancelled by admin');
$admin_id = $input['admin_id'] ?? null;

if (empty($owner_id)) {
    echo json_encode([
        'success' => false,
        'message' => 'Owner ID is required'
    ]);
    exit;
}

$conn = getConnection();

// Check if owner exists
$stmt = $conn->prepare("SELECT id, name, phone, license_status FROM owners WHERE id = ?");
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

// Check if owner has active license
if ($owner['license_status'] != 'active') {
    echo json_encode([
        'success' => false,
        'message' => 'Owner does not have an active license'
    ]);
    $conn->close();
    exit;
}

// Deactivate license
$updateStmt = $conn->prepare("
    UPDATE owners 
    SET license_status = 'cancelled',
        license_end_date = NOW(),
        updated_by = ?,
        updated_at = NOW()
    WHERE id = ?
");

$updateStmt->bind_param("ii", $admin_id, $owner_id);

if ($updateStmt->execute()) {
    $updateStmt->close();
    
    echo json_encode([
        'success' => true,
        'message' => 'License deactivated successfully',
        'data' => [
            'owner_id' => $owner_id,
            'owner_name' => $owner['name'],
            'phone' => $owner['phone'],
            'license_status' => 'cancelled',
            'reason' => $reason,
            'deactivated_at' => date('Y-m-d H:i:s')
        ]
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Failed to deactivate license: ' . $updateStmt->error
    ]);
}

$conn->close();