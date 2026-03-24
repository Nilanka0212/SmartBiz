<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once '../config/database.php';

// ── Bad words ──
$suspiciousKeywords = [
    'cocaine','heroin','meth','weed','marijuana',
    'cannabis','opium','mdma','ecstasy','lsd',
    'crack','ketamine','ganja','hash','hashish',
    'gun','pistol','rifle','bullet','ammo',
    'grenade','explosive','bomb','weapon','firearm',
    'stolen','counterfeit','xxx','adult','porn',
];

$mediumRiskKeywords = [
    'cigarette','tobacco','vape','alcohol',
    'beer','wine','whiskey','liquor',
    'supplement','steroid','prescription',
    'medicine','pill','tablet','capsule','chemical',
];

// ── Check text risk ──
function checkTextRisk($text, $suspicious, $medium) {
    $issues  = [];
    $risk    = 'low';
    $textLow = strtolower($text);

    foreach ($suspicious as $word) {
        if (strpos($textLow, $word) !== false) {
            $issues[] = "High risk keyword: '$word'";
            $risk     = 'high';
        }
    }

    if ($risk !== 'high') {
        foreach ($medium as $word) {
            if (strpos($textLow, $word) !== false) {
                $issues[] = "Medium risk keyword: '$word'";
                $risk     = 'medium';
            }
        }
    }

    return ['risk' => $risk, 'issues' => $issues];
}

// ── Determine final status ──
function determineStatus($textRisk) {
    switch ($textRisk) {
        case 'high':
            return [
                'status'    => 'rejected',
                'is_active' => 0,
                'risk'      => 'high',
                'message'   => 'Product rejected due to policy violation.',
            ];
        case 'medium':
            return [
                'status'    => 'pending',
                'is_active' => 0,
                'risk'      => 'medium',
                'message'   => 'Product sent to admin for review.',
            ];
        default:
            return [
                'status'    => 'active',
                'is_active' => 1,
                'risk'      => 'low',
                'message'   => 'Product approved automatically!',
            ];
    }
}

// ── Get input ──
$owner_id    = trim($_REQUEST['owner_id'] ?? '');
$name        = trim($_REQUEST['name'] ?? '');
$price       = trim($_REQUEST['price'] ?? '');
$description = trim($_REQUEST['description'] ?? '');

if (empty($owner_id) || empty($name) || empty($price)) {
    echo json_encode([
        'success' => false,
        'message' => 'Owner ID, name and price are required'
    ]);
    exit;
}

if (!is_numeric($price) || floatval($price) < 1) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid price'
    ]);
    exit;
}

// ── Handle image upload ──
$image     = null;
$imagePath = null;

if (isset($_FILES['image']) &&
    $_FILES['image']['error'] === 0) {

    $allowedTypes = [
        'image/jpeg','image/jpg',
        'image/png','image/webp'
    ];
    $allowedExt = ['jpg','jpeg','png','webp'];
    $ext        = strtolower(pathinfo(
                  $_FILES['image']['name'],
                  PATHINFO_EXTENSION));

    if (!in_array($_FILES['image']['type'], $allowedTypes)
        || !in_array($ext, $allowedExt)) {
        echo json_encode([
            'success' => false,
            'message' => 'Invalid image format. Use JPG or PNG'
        ]);
        exit;
    }

    if ($_FILES['image']['size'] > 5 * 1024 * 1024) {
        echo json_encode([
            'success' => false,
            'message' => 'Image too large (max 5MB)'
        ]);
        exit;
    }

    $uploadDir = __DIR__ . '/../uploads/products/';
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }

    $filename  = 'product_' . time() . '_' .
                 rand(1000, 9999) . '.' . $ext;
    $imagePath = $uploadDir . $filename;
    $image     = 'uploads/products/' . $filename;

    if (!move_uploaded_file(
            $_FILES['image']['tmp_name'], $imagePath)) {
        echo json_encode([
            'success' => false,
            'message' => 'Failed to upload image'
        ]);
        exit;
    }
}

// ── Run text check ──
$fullText  = $name . ' ' . $description;
$textCheck = checkTextRisk(
    $fullText,
    $suspiciousKeywords,
    $mediumRiskKeywords
);

// ── Get decision ──
$decision = determineStatus($textCheck['risk']);

// ── Delete image if rejected ──
if ($decision['status'] === 'rejected' &&
    $imagePath && file_exists($imagePath)) {
    unlink($imagePath);
    $image = null;
}

// ── Save to database ──
$conn = getConnection();

$stmt = $conn->prepare("
    INSERT INTO products
    (owner_id, name, price, description,
     image, status, is_active)
    VALUES (?, ?, ?, ?, ?, ?, ?)
");

$stmt->bind_param(
    "isdsssi",
    $owner_id,
    $name,
    $price,
    $description,
    $image,
    $decision['status'],
    $decision['is_active']
);

if ($stmt->execute()) {
    $product_id = $conn->insert_id;

    echo json_encode([
        'success'    => true,
        'approved'   => $decision['status'] === 'active',
        'rejected'   => $decision['status'] === 'rejected',
        'status'     => $decision['status'],
        'risk'       => $decision['risk'],
        'message'    => $decision['message'],
        'product_id' => $product_id,
        'issues'     => $textCheck['issues'],
        'labels'     => [],
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $stmt->error
    ]);
}

$stmt->close();
$conn->close();