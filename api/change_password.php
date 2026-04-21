<?php
ini_set('display_errors', 0);
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'config/database.php';

$input = json_decode(file_get_contents('php://input'), true);
$ownerId = intval($input['owner_id'] ?? $_REQUEST['owner_id'] ?? 0);
$currentPassword = trim($input['current_password'] ?? $_REQUEST['current_password'] ?? '');
$newPassword = trim($input['new_password'] ?? $_REQUEST['new_password'] ?? '');

if ($ownerId <= 0 || $currentPassword === '' || $newPassword === '') {
    echo json_encode([
        'success' => false,
        'message' => 'Owner ID, current password, and new password are required'
    ]);
    exit;
}

if (strlen($newPassword) < 6) {
    echo json_encode([
        'success' => false,
        'message' => 'New password must be at least 6 characters'
    ]);
    exit;
}

$conn = getConnection();

$stmt = $conn->prepare("SELECT id, password FROM owners WHERE id = ?");
$stmt->bind_param("i", $ownerId);
$stmt->execute();
$result = $stmt->get_result();
$owner = $result->fetch_assoc();
$stmt->close();

if (!$owner) {
    echo json_encode([
        'success' => false,
        'message' => 'Owner account not found'
    ]);
    $conn->close();
    exit;
}

if (!password_verify($currentPassword, $owner['password'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Current password is incorrect'
    ]);
    $conn->close();
    exit;
}

$hashedPassword = password_hash($newPassword, PASSWORD_BCRYPT);
$update = $conn->prepare("UPDATE owners SET password = ? WHERE id = ?");
$update->bind_param("si", $hashedPassword, $ownerId);

if ($update->execute()) {
    echo json_encode([
        'success' => true,
        'message' => 'Password changed successfully'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Failed to update password'
    ]);
}

$update->close();
$conn->close();
