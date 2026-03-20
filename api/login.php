<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

require_once 'config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$input    = json_decode(file_get_contents('php://input'), true);
$phone    = trim($input['phone'] ?? '');
$password = trim($input['password'] ?? '');

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

if (!$owner || !password_verify($password, $owner['password'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid phone or password'
    ]);
    $stmt->close();
    $conn->close();
    exit;
}

// Generate new token
$token = bin2hex(random_bytes(32));

// Update token in database
$update = $conn->prepare("UPDATE owners SET token = ? WHERE id = ?");
$update->bind_param("si", $token, $owner['id']);
$update->execute();
$update->close();

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

$stmt->close();
$conn->close();