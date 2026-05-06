<?php
/**
 * Get All Licenses - Admin views all licenses with filtering options
 * GET method
 * Optional query params: status, page, limit
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

$status = $_GET['status'] ?? $_REQUEST['status'] ?? '';
$page   = (int)($_GET['page'] ?? $_REQUEST['page'] ?? 1);
$limit  = (int)($_GET['limit'] ?? $_REQUEST['limit'] ?? 20);
$offset = ($page - 1) * $limit;

$conn = getConnection();

// Build query based on status filter
$whereClause = "";
$params = [];
$types = "";

if (!empty($status)) {
    $whereClause = "WHERE license_status = ?";
    $params[] = $status;
    $types .= "s";
}

// Get total count
$countSql = "SELECT COUNT(*) as total FROM owners $whereClause";
if (!empty($params)) {
    $countStmt = $conn->prepare($countSql);
    $countStmt->bind_param($types, ...$params);
    $countStmt->execute();
    $countResult = $countStmt->get_result();
    $total = $countResult->fetch_assoc()['total'];
    $countStmt->close();
} else {
    $result = $conn->query($countSql);
    $total = $result->fetch_assoc()['total'];
}

// Get license data
$sql = "
    SELECT 
        id, name, phone, shop_name, shop_category,
        license_status,
        license_start_date,
        license_end_date,
        license_amount,
        payment_method,
        transaction_id,
        created_at,
        updated_at
    FROM owners 
    $whereClause
    ORDER BY updated_at DESC
    LIMIT ? OFFSET ?
";

if (!empty($params)) {
    $params[] = $limit;
    $params[] = $offset;
    $types .= "ii";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param($types, ...$params);
    $stmt->execute();
    $result = $stmt->get_result();
} else {
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ii", $limit, $offset);
    $stmt->execute();
    $result = $stmt->get_result();
}

$licenses = [];
while ($row = $result->fetch_assoc()) {
    // Calculate days remaining
    $days_remaining = null;
    $is_expired = false;
    
    if ($row['license_status'] == 'active' && $row['license_end_date']) {
        $end_date = new DateTime($row['license_end_date']);
        $today = new DateTime(date('Y-m-d'));
        $interval = $today->diff($end_date);
        $days_remaining = (int)$interval->format('%r%a');
        
        if ($days_remaining < 0) {
            $is_expired = true;
            $days_remaining = null;
        }
    }
    
    $licenses[] = [
        'owner_id' => $row['id'],
        'owner_name' => $row['name'],
        'phone' => $row['phone'],
        'shop_name' => $row['shop_name'],
        'shop_category' => $row['shop_category'],
        'license_status' => $is_expired ? 'expired' : $row['license_status'],
        'license_start_date' => $row['license_start_date'],
        'license_end_date' => $row['license_end_date'],
        'days_remaining' => $days_remaining,
        'license_amount' => $row['license_amount'],
        'payment_method' => $row['payment_method'],
        'transaction_id' => $row['transaction_id'],
        'created_at' => $row['created_at'],
        'updated_at' => $row['updated_at']
    ];
}
$stmt->close();

echo json_encode([
    'success' => true,
    'data' => $licenses,
    'pagination' => [
        'page' => $page,
        'limit' => $limit,
        'total' => (int)$total,
        'pages' => ceil($total / $limit)
    ]
]);

$conn->close();