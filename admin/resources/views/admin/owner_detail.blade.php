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

<!-- License Details Card -->
<div class="row g-4 mb-4">
    <div class="col-12">
        <div class="card stat-card">
            <div class="card-header bg-white border-0 pt-3 d-flex justify-content-between align-items-center">
                <h6 class="fw-bold mb-0">
                    <i class="fas fa-id-card me-2 text-warning"></i>
                    License Information
                </h6>
                <div class="dropdown">
                    <button class="btn btn-sm dropdown-toggle {{ $owner->license_status === 'active' ? 'btn-success' : ($owner->license_status === 'expired' ? 'btn-danger' : ($owner->license_status === 'cancelled' ? 'btn-secondary' : 'btn-warning')) }}" 
                            type="button" 
                            data-bs-toggle="dropdown" 
                            aria-expanded="false">
                        @if($owner->license_status === 'active')
                            <i class="fas fa-check-circle me-1"></i> Active
                        @elseif($owner->license_status === 'expired')
                            <i class="fas fa-times-circle me-1"></i> Expired
                        @elseif($owner->license_status === 'cancelled')
                            <i class="fas fa-ban me-1"></i> Cancelled
                        @else
                            <i class="fas fa-clock me-1"></i> Pending
                        @endif
                    </button>
                    <ul class="dropdown-menu">
                        <li>
                            <form action="{{ route('admin.license.activate') }}" method="POST" class="license-form" data-owner-id="{{ $owner->id }}">
                                @csrf
                                <input type="hidden" name="owner_id" value="{{ $owner->id }}">
                                <input type="hidden" name="amount" value="1000">
                                <input type="hidden" name="payment_method" value="admin_manual">
                                <input type="hidden" name="transaction_id" value="MANUAL-{{ time() }}">
                                <input type="hidden" name="start_date" value="{{ date('Y-m-d') }}">
                                <input type="hidden" name="end_date" value="{{ date('Y-m-d', strtotime('+1 month')) }}">
                                <button type="submit" class="dropdown-item activate-license-btn">
                                    <i class="fas fa-play me-2 text-success"></i> Activate License
                                </button>
                            </form>
                        </li>
                        @if($owner->license_status === 'active' || $owner->license_status === 'pending')
                        <li>
                            <form action="{{ route('admin.license.deactivate') }}" method="POST" class="license-form" data-owner-id="{{ $owner->id }}">
                                @csrf
                                <input type="hidden" name="owner_id" value="{{ $owner->id }}">
                                <input type="hidden" name="reason" value="Manually deactivated by admin">
                                <button type="submit" class="dropdown-item deactivate-license-btn">
                                    <i class="fas fa-stop me-2 text-danger"></i> Deactivate License
                                </button>
                            </form>
                        </li>
                        @endif
                    </ul>
                </div>
            </div>
            <div class="card-body">
                @if($owner->license_status === 'active' || $owner->license_status === 'expired' || $owner->license_status === 'cancelled')
                    <div class="row g-3">
                        <div class="col-md-3">
                            <div class="border rounded-3 p-3">
                                <div class="text-muted small mb-1">Status</div>
                                <div class="fw-semibold">
                                    @if($owner->license_status === 'active')
                                        <span class="badge bg-success">Active</span>
                                        @if($owner->license_end_date && $owner->license_end_date->gte(now()->toDateString()))
                                            @if($owner->license_end_date->diffInDays(now()) <= 7)
                                                <span class="badge bg-warning text-dark ms-1">Expiring Soon</span>
                                            @endif
                                        @endif
                                    @elseif($owner->license_status === 'expired')
                                        <span class="badge bg-danger">Expired</span>
                                    @elseif($owner->license_status === 'cancelled')
                                        <span class="badge bg-secondary">Cancelled</span>
                                    @else
                                        <span class="badge bg-warning">Pending</span>
                                    @endif
                                </div>
                            </div>
                        </div>
                        <div class="col-md-3">
                            <div class="border rounded-3 p-3">
                                <div class="text-muted small mb-1">Start Date</div>
                                <div class="fw-semibold">{{ $owner->license_start_date ? $owner->license_start_date->format('M d, Y') : 'N/A' }}</div>
                            </div>
                        </div>
                        <div class="col-md-3">
                            <div class="border rounded-3 p-3">
                                <div class="text-muted small mb-1">End Date</div>
                                <div class="fw-semibold">
                                    {{ $owner->license_end_date ? $owner->license_end_date->format('M d, Y') : 'N/A' }}
                                    @if($owner->license_status === 'active' && $owner->license_end_date)
                                        @php
                                            $daysRemaining = $owner->license_end_date->diffInDays(now());
                                        @endphp
                                        @if($daysRemaining > 0)
                                            <span class="badge bg-info ms-2">{{ $daysRemaining }} days left</span>
                                        @else
                                            <span class="badge bg-danger ms-2">Expired</span>
                                        @endif
                                    @endif
                                </div>
                            </div>
                        </div>
                        <div class="col-md-3">
                            <div class="border rounded-3 p-3">
                                <div class="text-muted small mb-1">Amount Paid</div>
                                <div class="fw-semibold">Rs. {{ number_format($owner->license_amount ?? 0, 2) }}</div>
                            </div>
                        </div>
                        <div class="col-md-3">
                            <div class="border rounded-3 p-3">
                                <div class="text-muted small mb-1">Payment Method</div>
                                <div class="fw-semibold">{{ ucfirst($owner->payment_method ?? 'N/A') }}</div>
                            </div>
                        </div>
                        <div class="col-md-3">
                            <div class="border rounded-3 p-3">
                                <div class="text-muted small mb-1">Transaction ID</div>
                                <div class="fw-semibold">{{ $owner->transaction_id ?? 'N/A' }}</div>
                            </div>
                        </div>
                        <div class="col-md-3">
                            <div class="border rounded-3 p-3">
                                <div class="text-muted small mb-1">Activated On</div>
                                <div class="fw-semibold">{{ $owner->created_at ? $owner->created_at->format('M d, Y') : 'N/A' }}</div>
                            </div>
                        </div>
                        <div class="col-md-3">
                            <div class="border rounded-3 p-3">
                                <div class="text-muted small mb-1">Last Updated</div>
                                <div class="fw-semibold">{{ $owner->updated_at ? $owner->updated_at->format('M d, Y') : 'N/A' }}</div>
                            </div>
                        </div>
                    </div>
                @else
                    <div class="text-center py-4">
                        <i class="fas fa-id-card fa-3x text-muted mb-3"></i>
                        <h5 class="text-muted">No License Activated</h5>
                        <p class="text-muted mb-0">This owner does not have an active license yet.</p>
                        <button class="btn btn-success mt-3" data-bs-toggle="modal" data-bs-target="#activateLicenseModal">
                            <i class="fas fa-play me-1"></i> Activate License
                        </button>
                    </div>
                @endif
            </div>
        </div>
    </div>
</div>

<!-- Activate License Modal -->
<div class="modal fade" id="activateLicenseModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Activate License</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form action="{{ route('admin.license.activate') }}" method="POST">
                @csrf
                <div class="modal-body">
                    <input type="hidden" name="owner_id" value="{{ $owner->id }}">
                    
                    <div class="mb-3">
                        <label class="form-label">Amount (Rs.)</label>
                        <input type="number" name="amount" class="form-control" value="1000" required>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Payment Method</label>
                        <select name="payment_method" class="form-select" required>
                            <option value="cash">Cash</option>
                            <option value="bank_transfer">Bank Transfer</option>
                            <option value="mobile_payment">Mobile Payment</option>
                            <option value="admin_manual">Admin Manual</option>
                        </select>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Transaction ID</label>
                        <input type="text" name="transaction_id" class="form-control" placeholder="Optional">
                    </div>
                    
                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label class="form-label">Start Date</label>
                                <input type="date" name="start_date" class="form-control" value="{{ date('Y-m-d') }}" required>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label class="form-label">End Date</label>
                                <input type="date" name="end_date" class="form-control" value="{{ date('Y-m-d', strtotime('+1 month')) }}" required>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-success">Activate License</button>
                </div>
            </form>
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
