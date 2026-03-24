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
                'message'   => 'Product updated and approved!',
            ];
    }
}

$product_id  = trim($_REQUEST['product_id'] ?? '');
$name        = trim($_REQUEST['name'] ?? '');
$price       = trim($_REQUEST['price'] ?? '');
$description = trim($_REQUEST['description'] ?? '');

if (empty($product_id) || empty($name) || empty($price)) {
    echo json_encode([
        'success' => false,
        'message' => 'Product ID, name and price required'
    ]);
    exit;
}

$conn = getConnection();

// ── Get existing image ──
$imgStmt = $conn->prepare(
    "SELECT image FROM products WHERE id = ?"
);
$imgStmt->bind_param("i", $product_id);
$imgStmt->execute();
$imgResult = $imgStmt->get_result();
$imgRow    = $imgResult->fetch_assoc();
$imgStmt->close();

$image    = $imgRow['image'] ?? null;
$newImage = false;

// ── Handle new image upload ──
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

    if (in_array($_FILES['image']['type'], $allowedTypes)
        && in_array($ext, $allowedExt)
        && $_FILES['image']['size'] <= 5 * 1024 * 1024) {

        $uploadDir = __DIR__ . '/../uploads/products/';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }

        $filename = 'product_' . time() . '_' .
                    rand(1000, 9999) . '.' . $ext;
        $newPath  = $uploadDir . $filename;

        if (move_uploaded_file(
                $_FILES['image']['tmp_name'], $newPath)) {
            $image    = 'uploads/products/' . $filename;
            $newImage = true;
        }
    }
}

// ── Run text check ──
$fullText  = $name . ' ' . $description;
$textCheck = checkTextRisk(
    $fullText,
    $suspiciousKeywords,
    $mediumRiskKeywords
);

$decision = determineStatus($textCheck['risk']);

// ── Delete new image if rejected ──
if ($decision['status'] === 'rejected' && $newImage) {
    $uploadDir = __DIR__ . '/../uploads/products/';
    $filename  = basename($image);
    if (file_exists($uploadDir . $filename)) {
        unlink($uploadDir . $filename);
    }
    // Restore old image
    $image = $imgRow['image'] ?? null;
}

// ── Update database ──
if ($image) {
    $stmt = $conn->prepare("
        UPDATE products
        SET name=?, price=?, description=?,
            image=?, status=?, is_active=?
        WHERE id=?
    ");
    $stmt->bind_param(
        "sdsssi i",
        $name, $price, $description,
        $image, $decision['status'],
        $decision['is_active'], $product_id
    );
} else {
    $stmt = $conn->prepare("
        UPDATE products
        SET name=?, price=?, description=?,
            status=?, is_active=?
        WHERE id=?
    ");
    $stmt->bind_param(
        "sdssii",
        $name, $price, $description,
        $decision['status'],
        $decision['is_active'], $product_id
    );
}

if ($stmt->execute()) {
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
        'message' => 'Failed: ' . $stmt->error
    ]);
}

$stmt->close();
$conn->close();