@extends('admin.layout')
@section('title', 'Dashboard')
@section('content')

<div class="row g-4 mb-4">
    <!-- Stat cards -->
    <div class="col-md-3">
        <div class="card stat-card h-100">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="text-muted small">Total Owners</div>
                        <div class="fs-2 fw-bold text-warning">
                            {{ $totalOwners }}
                        </div>
                    </div>
                    <div style="width:50px;height:50px;background:#fff3cd;
                                border-radius:12px;display:flex;
                                align-items:center;justify-content:center">
                        <i class="fas fa-users text-warning fa-lg"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card stat-card h-100">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="text-muted small">Total Products</div>
                        <div class="fs-2 fw-bold text-primary">
                            {{ $totalProducts }}
                        </div>
                    </div>
                    <div style="width:50px;height:50px;background:#cfe2ff;
                                border-radius:12px;display:flex;
                                align-items:center;justify-content:center">
                        <i class="fas fa-box text-primary fa-lg"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card stat-card h-100">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="text-muted small">Pending Approval</div>
                        <div class="fs-2 fw-bold text-danger">
                            {{ $pendingProducts }}
                        </div>
                    </div>
                    <div style="width:50px;height:50px;background:#f8d7da;
                                border-radius:12px;display:flex;
                                align-items:center;justify-content:center">
                        <i class="fas fa-clock text-danger fa-lg"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <!-- <div class="col-md-3">
        <div class="card stat-card h-100">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="text-muted small">Active Products</div>
                        <div class="fs-2 fw-bold text-success">
                            {{ $activeProducts }}
                        </div>
                    </div>
                    <div style="width:50px;height:50px;background:#d1e7dd;
                                border-radius:12px;display:flex;
                                align-items:center;justify-content:center">
                        <i class="fas fa-check-circle text-success fa-lg"></i>
                    </div>
                </div>
            </div>
        </div>
    </div> -->
    <div class="col-md-3">
        <div class="card stat-card h-100">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="text-muted small">Total Orders</div>
                        <div class="fs-2 fw-bold text-info">
                            {{ $totalOrders }}
                        </div>
                    </div>
                    <div style="width:50px;height:50px;background:#cfe2ff;
                                border-radius:12px;display:flex;
                                align-items:center;justify-content:center">
                        <i class="fas fa-shopping-cart text-info fa-lg"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <!-- <div class="col-md-3">
        <div class="card stat-card h-100">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="text-muted small">Pending Orders</div>
                        <div class="fs-2 fw-bold text-warning">
                            {{ $pendingOrders }}
                        </div>
                    </div>
                    <div style="width:50px;height:50px;background:#fff3cd;
                                border-radius:12px;display:flex;
                                align-items:center;justify-content:center">
                        <i class="fas fa-hourglass-end text-warning fa-lg"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card stat-card h-100">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="text-muted small">Preparing Orders</div>
                        <div class="fs-2 fw-bold" style="color: #0dcaf0;">
                            {{ $preparingOrders }}
                        </div>
                    </div>
                    <div style="width:50px;height:50px;background:#d1ecf1;
                                border-radius:12px;display:flex;
                                align-items:center;justify-content:center">
                        <i class="fas fa-utensils" style="color: #0dcaf0;" class="fa-lg"></i>
                    </div>
                </div>
            </div>
        </div> -->
</div>

<div class="row g-4">
    <!-- Recent Owners -->
    <div class="col-md-7">
        <div class="card stat-card">
            <div class="card-header bg-white border-0 pt-3">
                <h6 class="fw-bold mb-0">
                    <i class="fas fa-users me-2 text-warning"></i>
                    Recent Owners
                </h6>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead class="table-light">
                            <tr>
                                <th>Owner</th>
                                <th>Shop</th>
                                <th>Category</th>
                                <th>Joined</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($recentOwners as $owner)
                            <tr>
                                <td>
                                    <div class="fw-semibold">
                                        {{ $owner->name }}
                                    </div>
                                    <small class="text-muted">
                                        {{ $owner->phone }}
                                    </small>
                                </td>
                                <td>{{ $owner->shop_name ?? 'N/A' }}</td>
                                <td>
                                    <span class="badge bg-warning text-dark">
                                        {{ $owner->shop_category }}
                                    </span>
                                </td>
                                <td class="text-muted small">
                                    {{ \Carbon\Carbon::parse($owner->created_at)->diffForHumans() }}
                                </td>
                            </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- Product Status Chart -->
    <div class="col-md-5">
        <div class="card stat-card h-100">
            <div class="card-header bg-white border-0 pt-3">
                <h6 class="fw-bold mb-0">
                    <i class="fas fa-chart-pie me-2 text-warning"></i>
                    Product Status
                </h6>
            </div>
            <div class="card-body d-flex align-items-center">
                <canvas id="productChart"></canvas>
            </div>
        </div>
    </div>
</div>

<!-- Recent Orders -->
<div class="row g-4 mt-2">
    <div class="col-12">
        <div class="card stat-card">
            <div class="card-header bg-white border-0 pt-3">
                <div class="d-flex justify-content-between align-items-center">
                    <h6 class="fw-bold mb-0">
                        <i class="fas fa-shopping-cart me-2 text-info"></i>
                        Recent Orders
                    </h6>
                    <a href="{{ route('admin.orders') }}" class="btn btn-sm btn-outline-info">
                        View All <i class="fas fa-arrow-right ms-1"></i>
                    </a>
                </div>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead class="table-light">
                            <tr>
                                <th style="width: 60px">Order #</th>
                                <th>Customer</th>
                                <th>Shop</th>
                                <th style="width: 90px">Total</th>
                                <th style="width: 90px">Status</th>
                                <th style="width: 110px">Created</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($recentOrders as $order)
                            <tr>
                                <td><strong>#{{ $order->id }}</strong></td>
                                <td>
                                    <div class="fw-semibold">
                                        {{ $order->customer_name ?: 'Walk-in' }}
                                    </div>
                                    <small class="text-muted">
                                        {{ $order->customer_phone ?: 'N/A' }}
                                    </small>
                                </td>
                                <td>
                                    {{ $order->owner->shop_name ?? $order->owner->name ?? 'N/A' }}
                                </td>
                                <td><strong>Rs. {{ number_format($order->total_price, 2) }}</strong></td>
                                <td>
                                    @php
                                        $statusClass = match($order->status) {
                                            'pending' => 'warning',
                                            'preparing' => 'info',
                                            'completed' => 'success',
                                            'cancelled' => 'danger',
                                            default => 'secondary',
                                        };
                                    @endphp
                                    <span class="badge bg-{{ $statusClass }}">
                                        {{ ucfirst($order->status) }}
                                    </span>
                                </td>
                                <td class="text-muted small">
                                    {{ $order->created_at?->format('M d, H:i') ?? 'N/A' }}
                                </td>
                            </tr>
                            @empty
                            <tr>
                                <td colspan="6" class="text-center py-4 text-muted">
                                    No orders yet
                                </td>
                            </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>

@endsection

@section('scripts')
<script>
const ctx = document.getElementById('productChart');
new Chart(ctx, {
    type: 'doughnut',
    data: {
        labels: [
            @foreach($productsByCategory as $p)
                '{{ ucfirst($p->status) }}',
            @endforeach
        ],
        datasets: [{
            data: [
                @foreach($productsByCategory as $p)
                    {{ $p->count }},
                @endforeach
            ],
            backgroundColor: [
                '#28a745', '#ffc107',
                '#dc3545', '#6c757d'
            ],
        }]
    },
    options: {
        responsive: true,
        plugins: {
            legend: { position: 'bottom' }
        }
    }
});
</script>
@endsection