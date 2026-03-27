@extends('admin.layout')
@section('title', 'Product Approval')
@section('content')

<!-- Status tabs -->
<ul class="nav nav-pills mb-4">
    <li class="nav-item">
        <a class="nav-link {{ $status == 'pending' ? 'active bg-warning text-dark' : '' }}"
           href="/admin/products?status=pending">
            Pending
            <span class="badge bg-danger ms-1">
                {{ $counts['pending'] }}
            </span>
        </a>
    </li>
    <li class="nav-item">
        <a class="nav-link {{ $status == 'active' ? 'active bg-success' : '' }}"
           href="/admin/products?status=active">
            Active
            <span class="badge bg-secondary ms-1">
                {{ $counts['active'] }}
            </span>
        </a>
    </li>
    <li class="nav-item">
        <a class="nav-link {{ $status == 'inactive' ? 'active' : '' }}"
           href="/admin/products?status=inactive">
            Inactive
            <span class="badge bg-secondary ms-1">
                {{ $counts['inactive'] }}
            </span>
        </a>
    </li>
    <li class="nav-item">
        <a class="nav-link {{ $status == 'rejected' ? 'active bg-danger' : '' }}"
           href="/admin/products?status=rejected">
            Rejected
            <span class="badge bg-secondary ms-1">
                {{ $counts['rejected'] }}
            </span>
        </a>
    </li>
</ul>

<div class="row g-4">
    @forelse($products as $product)
    <div class="col-md-6 col-lg-4">
        <div class="card stat-card h-100">
            <!-- Product image -->
            @if($product->image)
                <img src="http://localhost/SmartBiz/api/{{ $product->image }}"
                     class="card-img-top"
                     style="height:180px;object-fit:cover;border-radius:12px 12px 0 0">
            @else
                <div style="height:180px;background:#f8f9fa;
                            display:flex;align-items:center;
                            justify-content:center;
                            border-radius:12px 12px 0 0">
                    <i class="fas fa-image fa-3x text-muted"></i>
                </div>
            @endif

            <div class="card-body">
                <!-- Status badge -->
                <span class="badge badge-{{ $product->status }} mb-2">
                    {{ ucfirst($product->status) }}
                </span>

                <h6 class="fw-bold">{{ $product->name }}</h6>
                <div class="text-warning fw-bold mb-1">
                    Rs. {{ number_format($product->price, 2) }}
                </div>

                @if($product->description)
                    <p class="text-muted small mb-2">
                        {{ Str::limit($product->description, 60) }}
                    </p>
                @endif

                <!-- Owner info -->
                <div class="d-flex align-items-center mb-3 p-2 bg-light rounded">
                    <i class="fas fa-user-circle text-warning me-2"></i>
                    <div>
                        <div class="small fw-semibold">
                            {{ $product->owner->name ?? 'Unknown' }}
                        </div>
                        <div class="small text-muted">
                            {{ $product->owner->shop_name ?? '' }}
                        </div>
                    </div>
                </div>

                <!-- Action buttons -->
                @if($product->status == 'pending')
                <div class="d-flex gap-2">
                    <form method="POST"
                          action="/admin/products/{{ $product->id }}/approve"
                          class="flex-fill">
                        @csrf
                        <button type="submit"
                                class="btn btn-success btn-sm w-100">
                            <i class="fas fa-check me-1"></i>Approve
                        </button>
                    </form>
                    <form method="POST"
                          action="/admin/products/{{ $product->id }}/reject"
                          class="flex-fill">
                        @csrf
                        <button type="submit"
                                class="btn btn-danger btn-sm w-100"
                                onclick="return confirm('Reject this product?')">
                            <i class="fas fa-times me-1"></i>Reject
                        </button>
                    </form>
                </div>
                @endif

                @if($product->status == 'rejected')
                <form method="POST"
                      action="/admin/products/{{ $product->id }}/approve">
                    @csrf
                    <button type="submit"
                            class="btn btn-outline-success btn-sm w-100">
                        <i class="fas fa-redo me-1"></i>Re-approve
                    </button>
                </form>
                @endif
            </div>

            <div class="card-footer bg-white border-0 text-muted small">
                <i class="fas fa-clock me-1"></i>
                {{ \Carbon\Carbon::parse($product->created_at)->diffForHumans() }}
            </div>
        </div>
    </div>
    @empty
    <div class="col-12 text-center py-5">
        <i class="fas fa-box-open fa-4x text-muted mb-3"></i>
        <h5 class="text-muted">No {{ $status }} products</h5>
    </div>
    @endforelse
</div>

<div class="mt-4">
    {{ $products->links() }}
</div>

@endsection