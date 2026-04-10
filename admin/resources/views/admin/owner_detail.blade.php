@extends('admin.layout')
@section('title', 'Owner Details')
@section('content')

<div class="d-flex justify-content-between align-items-center mb-3">
    <div>
        <h4 class="fw-bold mb-1">{{ $owner->shop_name ?? 'Shop Details' }}</h4>
        <p class="text-muted mb-0">Owner and shop summary with current business totals</p>
    </div>
    <a href="{{ route('admin.owners') }}" class="btn btn-outline-secondary">
        <i class="fas fa-arrow-left me-1"></i> Back to Owners
    </a>
</div>

<div class="row g-4 mb-4">
    <div class="col-md-4">
        <div class="card stat-card h-100">
            <div class="card-body text-center p-4">
                @if($owner->profile_photo)
                    <img src="http://localhost/SmartBiz/api/{{ $owner->profile_photo }}"
                         alt="{{ $owner->name }}"
                         class="rounded-circle mb-3"
                         width="96" height="96"
                         style="object-fit:cover">
                @else
                    <div class="mx-auto mb-3 rounded-circle bg-warning-subtle d-flex align-items-center justify-content-center"
                         style="width:96px;height:96px;">
                        <i class="fas fa-user fa-2x text-warning"></i>
                    </div>
                @endif
                <h5 class="fw-bold mb-1">{{ $owner->name }}</h5>
                <p class="text-muted mb-2">{{ $owner->phone }}</p>
                @if($owner->is_verified)
                    <span class="badge bg-success">Verified Owner</span>
                @else
                    <span class="badge bg-danger">Unverified Owner</span>
                @endif
            </div>
        </div>
    </div>

    <div class="col-md-8">
        <div class="card stat-card h-100">
            <div class="card-body p-4">
                <div class="row g-3">
                    <div class="col-md-6">
                        <div class="border rounded-3 p-3 h-100">
                            <div class="text-muted small mb-1">Shop Name</div>
                            <div class="fw-semibold">{{ $owner->shop_name ?? 'N/A' }}</div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="border rounded-3 p-3 h-100">
                            <div class="text-muted small mb-1">Shop Category</div>
                            <div class="fw-semibold">{{ $owner->shop_category ?? 'N/A' }}</div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="border rounded-3 p-3 h-100">
                            <div class="text-muted small mb-1">NIC</div>
                            <div class="fw-semibold">{{ $owner->nic ?? 'N/A' }}</div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="border rounded-3 p-3 h-100">
                            <div class="text-muted small mb-1">Language</div>
                            <div class="fw-semibold">{{ ucfirst($owner->language ?? 'n/a') }}</div>
                        </div>
                    </div>
                    <div class="col-12">
                        <div class="border rounded-3 p-3">
                            <div class="text-muted small mb-1">Shop Location</div>
                            <div class="fw-semibold">{{ $owner->shop_location ?? 'N/A' }}</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="row g-4 mb-4">
    <div class="col-md-4">
        <div class="card stat-card border-0 h-100">
            <div class="card-body">
                <div class="text-muted small text-uppercase">Total Products</div>
                <div class="display-6 fw-bold text-primary">{{ $owner->products_count }}</div>
                <div class="text-muted">Products added by this owner</div>
            </div>
        </div>
    </div>
    <div class="col-md-4">
        <div class="card stat-card border-0 h-100">
            <div class="card-body">
                <div class="text-muted small text-uppercase">Total Orders</div>
                <div class="display-6 fw-bold text-info">{{ $owner->orders_count }}</div>
                <div class="text-muted">Orders received so far</div>
            </div>
        </div>
    </div>
    <div class="col-md-4">
        <div class="card stat-card border-0 h-100">
            <div class="card-body">
                <div class="text-muted small text-uppercase">Completed Orders</div>
                <div class="display-6 fw-bold text-success">{{ $owner->completed_orders_count }}</div>
                <div class="text-muted">Completed until now</div>
            </div>
        </div>
    </div>
</div>

<div class="card stat-card">
    <div class="card-header bg-white border-0 pt-3 d-flex justify-content-between align-items-center">
        <h6 class="fw-bold mb-0">
            <i class="fas fa-box me-2 text-warning"></i>
            Product List
        </h6>
        <span class="badge bg-primary">{{ $products->count() }} items</span>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover mb-0">
                <thead class="table-light">
                    <tr>
                        <th>#</th>
                        <th>Product Name</th>
                        <th>Price</th>
                        <th>Status</th>
                        <th>Added On</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($products as $product)
                        <tr>
                            <td class="text-muted">{{ $product->id }}</td>
                            <td class="fw-semibold">{{ $product->name }}</td>
                            <td>Rs. {{ number_format($product->price, 2) }}</td>
                            <td>
                                @php
                                    $statusClasses = [
                                        'active' => 'bg-success',
                                        'pending' => 'bg-warning text-dark',
                                        'inactive' => 'bg-secondary',
                                        'rejected' => 'bg-danger',
                                    ];
                                @endphp
                                <span class="badge {{ $statusClasses[$product->status] ?? 'bg-dark' }}">
                                    {{ ucfirst($product->status) }}
                                </span>
                            </td>
                            <td class="text-muted">
                                {{ optional($product->created_at)->format('Y-m-d h:i A') ?? 'N/A' }}
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="text-center text-muted py-4">
                                No products found for this owner.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>

@endsection
