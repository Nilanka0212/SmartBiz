@extends('admin.layout')
@section('title', 'Orders')
@section('content')

<div class="mb-4">
    <h3 class="mb-3">
        <i class="fas fa-shopping-cart me-2"></i>Orders Management
    </h3>

    <!-- Filter & Search -->
    <div class="card stat-card mb-4">
        <div class="card-body p-3">
            <form method="GET" action="{{ route('admin.orders') }}" class="row g-3">
                <div class="col-md-6">
                    <input type="text" name="search" class="form-control" 
                           placeholder="Search by order ID, customer name/phone, or shop name"
                           value="{{ $search }}">
                </div>
                <div class="col-md-3">
                    <select name="status" class="form-select">
                        <option value="">All Orders</option>
                        <option value="pending" {{ $status === 'pending' ? 'selected' : '' }}>Pending</option>
                        <option value="preparing" {{ $status === 'preparing' ? 'selected' : '' }}>Preparing</option>
                        <option value="completed" {{ $status === 'completed' ? 'selected' : '' }}>Completed</option>
                        <option value="cancelled" {{ $status === 'cancelled' ? 'selected' : '' }}>Cancelled</option>
                    </select>
                </div>
                <div class="col-md-3">
                    <button type="submit" class="btn btn-warning w-100">
                        <i class="fas fa-search me-2"></i>Filter
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- Order Stats -->
    <div class="row g-3 mb-4">
        <div class="col-md-2">
            <div class="card stat-card h-100 {{ $status === '' ? 'border-warning border-2' : '' }}">
                <div class="card-body text-center">
                    <div class="fs-4 fw-bold text-dark">{{ $counts['all'] }}</div>
                    <div class="text-muted small">All Orders</div>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card stat-card h-100 {{ $status === 'pending' ? 'border-warning border-2' : '' }}">
                <div class="card-body text-center">
                    <div class="fs-4 fw-bold text-warning">{{ $counts['pending'] }}</div>
                    <div class="text-muted small">Pending</div>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card stat-card h-100 {{ $status === 'preparing' ? 'border-info border-2' : '' }}">
                <div class="card-body text-center">
                    <div class="fs-4 fw-bold text-info">{{ $counts['preparing'] }}</div>
                    <div class="text-muted small">Preparing</div>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card stat-card h-100 {{ $status === 'completed' ? 'border-success border-2' : '' }}">
                <div class="card-body text-center">
                    <div class="fs-4 fw-bold text-success">{{ $counts['completed'] }}</div>
                    <div class="text-muted small">Completed</div>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card stat-card h-100 {{ $status === 'cancelled' ? 'border-danger border-2' : '' }}">
                <div class="card-body text-center">
                    <div class="fs-4 fw-bold text-danger">{{ $counts['cancelled'] }}</div>
                    <div class="text-muted small">Cancelled</div>
                </div>
            </div>
        </div>
    </div>

    <!-- Orders Table -->
    <div class="card stat-card">
        <div class="table-responsive">
            <table class="table table-hover mb-0">
                <thead class="table-light">
                    <tr>
                        <th style="width: 80px">Order #</th>
                        <th>Customer</th>
                        <th>Shop</th>
                        <th style="width: 100px">Total</th>
                        <th style="width: 100px">Items</th>
                        <th style="width: 120px">Payment</th>
                        <th style="width: 110px">Status</th>
                        <th style="width: 130px">Created</th>
                    </tr>
                </thead>
                <tbody>
                    @if($orders->count() > 0)
                        @foreach($orders as $order)
                            <tr style="cursor: pointer;" 
                                onclick="showOrderDetails({{ $order->id }}, @json($order->toArray()))">
                                <td><strong>#{{ $order->id }}</strong></td>
                                <td>
                                    <div class="fw-500">
                                        {{ $order->customer_name ?: 'Walk-in' }}
                                    </div>
                                    <div class="text-muted small">
                                        {{ $order->customer_phone ?: 'N/A' }}
                                    </div>
                                </td>
                                <td>
                                    <div class="fw-500">
                                        {{ $order->owner->shop_name ?? $order->owner->name ?? 'N/A' }}
                                    </div>
                                    <div class="text-muted small">
                                        by {{ $order->owner->name ?? 'N/A' }}
                                    </div>
                                </td>
                                <td>
                                    <strong>Rs. {{ number_format($order->total_price, 2) }}</strong>
                                </td>
                                <td>
                                    @php
                                        $itemsCount = 0;
                                        if (is_array($order->items) || is_object($order->items)) {
                                            $itemsCount = count((array)$order->items);
                                        } elseif (is_array($order->items_list)) {
                                            $itemsCount = count($order->items_list);
                                        }
                                    @endphp
                                    <span class="badge bg-secondary">
                                        {{ $itemsCount }} item{{ $itemsCount !== 1 ? 's' : '' }}
                                    </span>
                                </td>
                                <td>
                                    <div class="small">
                                        <span class="badge {{ $order->payment_method === 'online' ? 'bg-info' : 'bg-secondary' }}">
                                            {{ $order->payment_method ? ucfirst($order->payment_method) : 'N/A' }}
                                        </span>
                                    </div>
                                    <div class="text-muted small mt-1">
                                        {{ $order->payment_status ? ucfirst($order->payment_status) : 'Pending' }}
                                    </div>
                                </td>
                                <td>
                                    @php
                                        $statusClass = match($order->status) {
                                            'pending' => 'warning',
                                            'preparing' => 'info',
                                            'completed' => 'success',
                                            'cancelled' => 'danger',
                                            default => 'secondary',
                                        };
                                        $statusIcon = match($order->status) {
                                            'pending' => 'hourglass',
                                            'preparing' => 'chef',
                                            'completed' => 'check-circle',
                                            'cancelled' => 'ban',
                                            default => 'question-circle',
                                        };
                                    @endphp
                                    <span class="badge bg-{{ $statusClass }}">
                                        <i class="fas fa-{{ $statusIcon }} me-1"></i>
                                        {{ ucfirst($order->status) }}
                                    </span>
                                </td>
                                <td class="text-muted small">
                                    {{ $order->created_at ? $order->created_at->format('M d, H:i') : 'N/A' }}
                                </td>
                            </tr>
                        @endforeach
                    @else
                        <tr>
                            <td colspan="8" class="text-center py-4 text-muted">
                                <i class="fas fa-inbox fs-3 mb-2"></i>
                                <div>No orders found</div>
                            </td>
                        </tr>
                    @endif
                </tbody>
            </table>
        </div>
    </div>

    <!-- Pagination -->
    <div class="mt-4">
        {{ $orders->appends(request()->query())->links('pagination::bootstrap-5') }}
    </div>
</div>

<!-- Order Details Modal -->
<div class="modal fade" id="orderModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Order Details</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body" id="orderModalBody">
                <!-- Content will be dynamically loaded -->
            </div>
        </div>
    </div>
</div>

<script>
function showOrderDetails(orderId, orderData) {
    const items = orderData.items_list || orderData.items || [];
    const statusColors = {
        'pending': 'warning',
        'preparing': 'info',
        'completed': 'success',
        'cancelled': 'danger'
    };
    
    let itemsHtml = '';
    if (Array.isArray(items)) {
        itemsHtml = items.map(item => `
            <div class="d-flex justify-content-between py-2 border-bottom">
                <div>
                    <div><strong>${item.name}</strong></div>
                    <div class="text-muted small">Qty: ${item.qty}</div>
                </div>
                <div class="text-end">
                    <div>Rs. ${(item.price * item.qty).toFixed(2)}</div>
                    <div class="text-muted small">@ Rs. ${parseFloat(item.price).toFixed(2)}</div>
                </div>
            </div>
        `).join('');
    }

    const html = `
        <div class="row mb-3">
            <div class="col-md-6">
                <h6 class="text-muted">Order Information</h6>
                <p class="mb-1"><strong>Order ID:</strong> #${orderData.id}</p>
                <p class="mb-1"><strong>Status:</strong> 
                    <span class="badge bg-${statusColors[orderData.status]}">${orderData.status.toUpperCase()}</span>
                </p>
                <p class="mb-0"><strong>Created:</strong> ${new Date(orderData.created_at).toLocaleString()}</p>
            </div>
            <div class="col-md-6">
                <h6 class="text-muted">Payment Information</h6>
                <p class="mb-1"><strong>Method:</strong> ${orderData.payment_method || 'N/A'}</p>
                <p class="mb-1"><strong>Status:</strong> ${orderData.payment_status || 'Pending'}</p>
                <p class="mb-0"><strong>Total:</strong> <strong>Rs. ${parseFloat(orderData.total_price).toFixed(2)}</strong></p>
            </div>
        </div>
        
        <div class="row mb-3">
            <div class="col-md-6">
                <h6 class="text-muted">Customer Information</h6>
                <p class="mb-1"><strong>Name:</strong> ${orderData.customer_name || 'Walk-in Customer'}</p>
                <p class="mb-0"><strong>Phone:</strong> ${orderData.customer_phone || 'Not provided'}</p>
            </div>
            <div class="col-md-6">
                <h6 class="text-muted">Shop Information</h6>
                <p class="mb-1"><strong>Shop:</strong> ${orderData.owner?.shop_name || 'N/A'}</p>
                <p class="mb-0"><strong>Owner:</strong> ${orderData.owner?.name || 'N/A'}</p>
            </div>
        </div>

        <h6 class="text-muted mt-3 mb-2">Order Items</h6>
        <div style="background: #f8f9fa; border-radius: 8px; padding: 12px;">
            ${itemsHtml}
        </div>

        ${orderData.note ? `
            <h6 class="text-muted mt-3 mb-2">Order Note</h6>
            <div style="background: #e7f3ff; border-left: 3px solid #0d6efd; padding: 12px; border-radius: 4px;">
                ${orderData.note}
            </div>
        ` : ''}
    `;

    document.getElementById('orderModalBody').innerHTML = html;
    const modal = new bootstrap.Modal(document.getElementById('orderModal'));
    modal.show();
}
</script>

@endsection
