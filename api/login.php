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

$input    = json_decode(file_get_contents('php://input'), true);
$phone    = trim($input['phone'] ?? $_REQUEST['phone'] ?? '');
$password = trim($input['password'] ?? $_REQUEST['password'] ?? '');

if (empty($phone) || empty($password)) {
    echo json_encode([
        'success' => false,
        'message' => 'Phone and password are required'
    ]);
    exit;
}

$conn = getConnection();

$stmt = $conn->prepare("SELECT * FROM owners WHERE phone = ?");
$stmt->bind_param("s", $phone);
$stmt->execute();
$result = $stmt->get_result();
$owner  = $result->fetch_assoc();
$stmt->close();

// ── Check phone exists ──
if (!$owner) {
    echo json_encode([
        'success' => false,
        'message' => 'Phone number not registered'
    ]);
    $conn->close();
    exit;
}

// ── Check password ──
if (!password_verify($password, $owner['password'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Incorrect password'
    ]);
    $conn->close();
    exit;
}

// ── Check if verified ──
if ($owner['is_verified'] == 0) {

    // Generate new OTP
    $otp         = strval(rand(100000, 999999));
    $otp_expires = date('Y-m-d H:i:s',
                   strtotime('+10 minutes'));

    // Save new OTP
    $otpStmt = $conn->prepare(
        "UPDATE owners SET otp = ?, otp_expires_at = ? WHERE id = ?"
    );
    $otpStmt->bind_param("ssi", $otp, $otp_expires, $owner['id']);
    $otpStmt->execute();
    $otpStmt->close();
    $conn->close();

    echo json_encode([
        'success'     => false,
        'need_otp'    => true,
        'message'     => 'Phone not verified. OTP sent.',
        'owner_id'    => $owner['id'],
        'phone'       => $owner['phone'],
        'otp'         => $otp, // ← remove in production
    ]);
    exit;
}

// ── Generate new token ──
$token = bin2hex(random_bytes(32));

$update = $conn->prepare(
    "UPDATE owners SET token = ? WHERE id = ?"
);
$update->bind_param("si", $token, $owner['id']);
$update->execute();
$update->close();
$conn->close();

echo json_encode([
    'success' => true,
    'message' => 'Login successful',
    'token'   => $token,
    'owner'   => [
        'id'            => $owner['id'],
        'name'          => $owner['name'],
        'phone'         => $owner['phone'],
        'shop_name'     => $owner['shop_name'],
        'shop_category' => $owner['shop_category'],
        'shop_location' => $owner['shop_location'],
        'profile_photo' => $owner['profile_photo'],
        'shop_image'    => $owner['shop_image'],
        'language'      => $owner['language'],
    ]
]);