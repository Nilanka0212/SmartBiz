<?php

// ── Google Vision API Key ──
define('GOOGLE_VISION_KEY', 'AIzaSyBQm71LJVfSEcZ0kpgU1Isa__u7h2PrbuQ'); // ← replace

// ── Risk levels ──
define('RISK_LOW',    'low');
define('RISK_MEDIUM', 'medium');
define('RISK_HIGH',   'high');

// ── Illegal/suspicious keywords ──
$suspiciousKeywords = [
    // Drugs
    'cocaine', 'heroin', 'meth', 'weed', 'marijuana',
    'cannabis', 'opium', 'mdma', 'ecstasy', 'lsd',
    'crack', 'ketamine', 'ganja', 'hash', 'hashish',

    // Weapons
    'gun', 'pistol', 'rifle', 'bullet', 'ammo',
    'grenade', 'explosive', 'bomb', 'knife', 'blade',
    'sword', 'weapon', 'firearm',

    // Illegal items
    'stolen', 'counterfeit', 'fake id', 'forged',
    'smuggled', 'unlicensed',

    // Adult
    'xxx', 'adult', 'porn', 'nude', 'explicit',

    // Tobacco/alcohol for minors
    'bootleg', 'moonshine', 'underage',
];

// ── Medium risk keywords ──
$mediumRiskKeywords = [
    'cigarette', 'tobacco', 'vape', 'alcohol',
    'beer', 'wine', 'whiskey', 'liquor', 'spirits',
    'supplement', 'steroid', 'hormone', 'prescription',
    'medicine', 'pill', 'tablet', 'capsule',
    'chemical', 'acid', 'solvent',
];

// ── Check text risk level ──
function checkTextRisk($text, $suspiciousKeywords,
                        $mediumRiskKeywords) {
    $textLower = strtolower($text);
    $issues    = [];
    $risk      = RISK_LOW;

    // Check high risk keywords
    foreach ($suspiciousKeywords as $keyword) {
        if (strpos($textLower, $keyword) !== false) {
            $issues[] = "High risk keyword found: '$keyword'";
            $risk     = RISK_HIGH;
        }
    }

    // Check medium risk keywords
    if ($risk !== RISK_HIGH) {
        foreach ($mediumRiskKeywords as $keyword) {
            if (strpos($textLower, $keyword) !== false) {
                $issues[] = "Medium risk keyword: '$keyword'";
                $risk     = RISK_MEDIUM;
            }
        }
    }

    return ['risk' => $risk, 'issues' => $issues];
}

// // ── Check image with Google Vision API ──
// function checkImageWithVision($imagePath) {
//     $result = [
//         'risk'     => RISK_LOW,
//         'issues'   => [],
//         'labels'   => [],
//         'debug'    => [], // ← add this
//     ];

//     if (!$imagePath || !file_exists($imagePath)) {
//         $result['debug'][] = 'No image path provided';
//         return $result;
//     }

//     $imageData   = base64_encode(
//         file_get_contents($imagePath));
//     $requestBody = json_encode([
//         'requests' => [[
//             'image'    => ['content' => $imageData],
//             'features' => [
//                 ['type' => 'SAFE_SEARCH_DETECTION'],
//                 ['type' => 'LABEL_DETECTION',
//                  'maxResults' => 10],
//             ]
//         ]]
//     ]);

//     $curl = curl_init();
//     curl_setopt_array($curl, [
//         CURLOPT_URL            => 'https://vision.googleapis.com/v1/images:annotate?key=' . GOOGLE_VISION_KEY,
//         CURLOPT_RETURNTRANSFER => true,
//         CURLOPT_POST           => true,
//         CURLOPT_POSTFIELDS     => $requestBody,
//         CURLOPT_HTTPHEADER     => [
//             'Content-Type: application/json'
//         ],
//     ]);

//     $response = curl_exec($curl);
//     $error    = curl_error($curl);
//     $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
//     curl_close($curl);

//     // ← Add debug info
//     $result['debug'][] = 'HTTP Code: ' . $httpCode;
//     $result['debug'][] = 'Curl Error: ' . $error;
//     $result['debug'][] = 'Response: ' . substr($response, 0, 500);
// }


    // ... rest of function

// ── Determine final status ──
function determineStatus($textRisk, $imageRisk) {
    // Combine risks
    $risks      = [$textRisk, $imageRisk];
    $finalRisk  = RISK_LOW;

    if (in_array(RISK_HIGH, $risks)) {
        $finalRisk = RISK_HIGH;
    } elseif (in_array(RISK_MEDIUM, $risks)) {
        $finalRisk = RISK_MEDIUM;
    }

    switch ($finalRisk) {
        case RISK_HIGH:
            return [
                'status'   => 'rejected',
                'is_active' => 0,
                'risk'     => RISK_HIGH,
                'message'  => 'Product rejected due to policy violation.',
            ];
        case RISK_MEDIUM:
            return [
                'status'   => 'pending',
                'is_active' => 0,
                'risk'     => RISK_MEDIUM,
                'message'  => 'Product sent to admin for review.',
            ];
        default:
            return [
                'status'   => 'active',
                'is_active' => 1,
                'risk'     => RISK_LOW,
                'message'  => 'Product approved automatically! ✅',
            ];
    }
}