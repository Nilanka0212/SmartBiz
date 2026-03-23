<?php
ini_set('display_errors', 0);
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'config/database.php';

$owner_id = trim($_REQUEST['owner_id'] ?? '');
$otp      = trim($_REQUEST['otp'] ?? '');

if (empty($owner_id) || empty($otp)) {
    echo json_encode([
        'success' => false,
        'message' => 'Owner ID and OTP are required'
    ]);
    exit;
}

$conn = getConnection();

// Get owner OTP
$stmt = $conn->prepare(
    "SELECT otp, otp_expires_at, token FROM owners WHERE id = ?"
);
$stmt->bind_param("i", $owner_id);
$stmt->execute();
$result = $stmt->get_result();
$owner  = $result->fetch_assoc();
$stmt->close();

if (!$owner) {
    echo json_encode([
        'success' => false,
        'message' => 'Owner not found'
    ]);
    $conn->close();
    exit;
}

// Check OTP expired
if (strtotime($owner['otp_expires_at']) < time()) {
    echo json_encode([
        'success' => false,
        'message' => 'OTP has expired. Please register again.'
    ]);
    $conn->close();
    exit;
}

// Check OTP matches
if ($owner['otp'] !== $otp) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid OTP. Please try again.'
    ]);
    $conn->close();
    exit;
}

// Mark owner as verified
$verify = $conn->prepare(
    "UPDATE owners SET is_verified = 1, otp = NULL WHERE id = ?"
);
$verify->bind_param("i", $owner_id);
$verify->execute();
$verify->close();

// Get full owner data
$owner_stmt = $conn->prepare(
    "SELECT * FROM owners WHERE id = ?"
);
$owner_stmt->bind_param("i", $owner_id);
$owner_stmt->execute();
$owner_result = $owner_stmt->get_result();
$owner_data   = $owner_result->fetch_assoc();
$owner_stmt->close();
$conn->close();

echo json_encode([
    'success' => true,
    'message' => 'Phone verified successfully!',
    'token'   => $owner_data['token'],
    'owner'   => [
        'id'            => $owner_data['id'],
        'name'          => $owner_data['name'],
        'phone'         => $owner_data['phone'],
        'shop_name'     => $owner_data['shop_name'],
        'shop_category' => $owner_data['shop_category'],
        'shop_location' => $owner_data['shop_location'],
        'language'      => $owner_data['language'],
    ]
]);