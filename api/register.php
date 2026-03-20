<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'config/database.php';

// Accept both POST and GET for testing
$method = $_SERVER['REQUEST_METHOD'];

// Get data from POST or GET
$name          = trim($_REQUEST['name'] ?? '');
$phone         = trim($_REQUEST['phone'] ?? '');
$nic           = trim($_REQUEST['nic'] ?? '');
$password      = trim($_REQUEST['password'] ?? '');
$shop_category = trim($_REQUEST['shop_category'] ?? '');
$shop_location = trim($_REQUEST['shop_location'] ?? '');
$shop_name     = trim($_REQUEST['shop_name'] ?? '');
$language      = trim($_REQUEST['language'] ?? 'english');

// Validate required fields
if (empty($name) || empty($phone) || empty($nic) ||
    empty($password) || empty($shop_category) || empty($shop_location)) {
    echo json_encode([
        'success' => false,
        'message' => 'All required fields must be filled',
        'received' => [
            'name'          => $name,
            'phone'         => $phone,
            'nic'           => $nic,
            'shop_category' => $shop_category,
            'shop_location' => $shop_location,
        ]
    ]);
    exit;
}

$conn = getConnection();

// Check if phone or NIC already exists
$check = $conn->prepare("SELECT id FROM owners WHERE phone = ? OR nic = ?");
$check->bind_param("ss", $phone, $nic);
$check->execute();
$check->store_result();

if ($check->num_rows > 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Phone or NIC already registered'
    ]);
    $check->close();
    $conn->close();
    exit;
}
$check->close();

// Handle profile photo upload
$profile_photo = null;
if (isset($_FILES['profile_photo']) && $_FILES['profile_photo']['error'] === 0) {
    $uploadDir = __DIR__ . '/uploads/profile_photos/';
    if (!is_dir($uploadDir)) mkdir($uploadDir, 0777, true);
    $ext           = pathinfo($_FILES['profile_photo']['name'], PATHINFO_EXTENSION);
    $filename      = 'profile_' . time() . '_' . rand(1000, 9999) . '.' . $ext;
    $profile_photo = 'uploads/profile_photos/' . $filename;
    move_uploaded_file($_FILES['profile_photo']['tmp_name'], $uploadDir . $filename);
}

// Handle shop image upload
$shop_image = null;
if (isset($_FILES['shop_image']) && $_FILES['shop_image']['error'] === 0) {
    $uploadDir = __DIR__ . '/uploads/shop_images/';
    if (!is_dir($uploadDir)) mkdir($uploadDir, 0777, true);
    $ext        = pathinfo($_FILES['shop_image']['name'], PATHINFO_EXTENSION);
    $filename   = 'shop_' . time() . '_' . rand(1000, 9999) . '.' . $ext;
    $shop_image = 'uploads/shop_images/' . $filename;
    move_uploaded_file($_FILES['shop_image']['tmp_name'], $uploadDir . $filename);
}

// Hash password
$hashedPassword = password_hash($password, PASSWORD_BCRYPT);

// Generate token
$token = bin2hex(random_bytes(32));

// Insert into database
$stmt = $conn->prepare("
    INSERT INTO owners
    (name, phone, nic, password, profile_photo, shop_name,
     shop_category, shop_location, shop_image, language, token)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
");

$stmt->bind_param(
    "sssssssssss",
    $name, $phone, $nic, $hashedPassword,
    $profile_photo, $shop_name, $shop_category,
    $shop_location, $shop_image, $language, $token
);

if ($stmt->execute()) {
    $owner_id = $conn->insert_id;
    echo json_encode([
        'success' => true,
        'message' => 'Registration successful',
        'token'   => $token,
        'owner'   => [
            'id'            => $owner_id,
            'name'          => $name,
            'phone'         => $phone,
            'shop_name'     => $shop_name,
            'shop_category' => $shop_category,
            'shop_location' => $shop_location,
            'language'      => $language,
        ]
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Registration failed: ' . $stmt->error
    ]);
}

$stmt->close();
$conn->close();