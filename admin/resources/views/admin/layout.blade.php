<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ShopFlow Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <style>
        body { background: #f8f9fa; }
        .sidebar {
            width: 250px;
            min-height: 100vh;
            background: linear-gradient(180deg, #ff8c00, #e65c00);
            position: fixed;
            top: 0; left: 0;
            padding-top: 20px;
            z-index: 100;
        }
        .sidebar .brand {
            color: white;
            font-size: 22px;
            font-weight: bold;
            padding: 15px 20px 25px;
            border-bottom: 1px solid rgba(255,255,255,0.2);
        }
        .sidebar .nav-link {
            color: rgba(255,255,255,0.85);
            padding: 12px 20px;
            border-radius: 8px;
            margin: 2px 10px;
            transition: all 0.2s;
        }
        .sidebar .nav-link:hover,
        .sidebar .nav-link.active {
            background: rgba(255,255,255,0.2);
            color: white;
        }
        .sidebar .nav-link i {
            width: 20px;
            margin-right: 10px;
        }
        .main-content {
            margin-left: 250px;
            padding: 20px;
        }
        .topbar {
            background: white;
            padding: 15px 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .stat-card {
            border-radius: 12px;
            border: none;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
        }
        .badge-pending  { background: #ff8c00; }
        .badge-active   { background: #28a745; }
        .badge-rejected { background: #dc3545; }
        .badge-inactive { background: #6c757d; }
    </style>
</head>
<body>

<!-- Sidebar -->
<div class="sidebar">
    <div class="brand">
        <i class="fas fa-store me-2"></i>SmartBiz
        <div style="font-size:12px;opacity:0.7;font-weight:normal">
            Admin Panel
        </div>
    </div>
    <nav class="nav flex-column mt-3">
        <a href="/admin/dashboard"
           class="nav-link {{ request()->is('admin/dashboard') ? 'active' : '' }}">
            <i class="fas fa-home"></i> Dashboard
        </a>
        <a href="/admin/owners"
           class="nav-link {{ request()->is('admin/owners*') ? 'active' : '' }}">
            <i class="fas fa-users"></i> Owners
        </a>
        <a href="/admin/products"
           class="nav-link {{ request()->is('admin/products*') ? 'active' : '' }}">
            <i class="fas fa-box"></i> Products
            @php
                $pending = \App\Models\Product::where('status','pending')->count();
            @endphp
            @if($pending > 0)
                <span class="badge bg-danger ms-1">
                    {{ $pending }}
                </span>
            @endif
        </a>
        <a href="/admin/orders"
           class="nav-link {{ request()->is('admin/orders*') ? 'active' : '' }}">
            <i class="fas fa-shopping-cart"></i> Orders
            @php
                $pendingOrders = \App\Models\Order::where('status','pending')->count();
            @endphp
            @if($pendingOrders > 0)
                <span class="badge bg-danger ms-1">
                    {{ $pendingOrders }}
                </span>
            @endif
        </a>
        <a href="/admin/summary"
           class="nav-link {{ request()->is('admin/summary*') ? 'active' : '' }}">
            <i class="fas fa-chart-bar"></i> Summary
        </a>
        <hr style="border-color:rgba(255,255,255,0.2);margin:10px">
        <a href="/admin/logout" class="nav-link">
            <i class="fas fa-sign-out-alt"></i> Logout
        </a>
    </nav>
</div>

<!-- Main Content -->
<div class="main-content">
    <!-- Top bar -->
    <div class="topbar">
        <h5 class="mb-0 fw-bold">@yield('title')</h5>
        <div>
            <i class="fas fa-user-shield me-2 text-warning"></i>
            <strong>{{ session('admin')->name ?? 'Admin' }}</strong>
        </div>
    </div>

    @if(session('success'))
        <div class="alert alert-success alert-dismissible fade show">
            {{ session('success') }}
            <button type="button" class="btn-close"
                    data-bs-dismiss="alert"></button>
        </div>
    @endif

    @yield('content')
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
@yield('scripts')
</body>
</html>