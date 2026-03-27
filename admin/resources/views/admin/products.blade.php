@extends('admin.layout')
@section('title', 'Product Approval')
@section('content')

<!-- Status tabs -->
<ul class="nav nav-pills mb-4">
    <li class="nav-item">
        <a class="nav-link {{ $status == 'pending' ? 'active bg-warning text-dark' : 'text-dark' }}"
           href="/admin/products?status=pending">
            <i class="fas fa-clock me-1"></i>Pending
            @if($counts['pending'] > 0)
                <span class="badge bg-danger ms-1">
                    {{ $counts['pending'] }}
                </span>
            @endif
        </a>
    </li>
    <li class="nav-item">
        <a class="nav-link {{ $status == 'active' ? 'active bg-success' : 'text-dark' }}"
           href="/admin/products?status=active">
            <i class="fas fa-check-circle me-1"></i>Active
            <span class="badge bg-secondary ms-1">
                {{ $counts['active'] }}
            </span>
        </a>
    </li>
    <li class="nav-item">
        <a class="nav-link {{ $status == 'inactive' ? 'active' : 'text-dark' }}"
           href="/admin/products?status=inactive">
            <i class="fas fa-pause-circle me-1"></i>Inactive
            <span class="badge bg-secondary ms-1">
                {{ $counts['inactive'] }}
            </span>
        </a>
    </li>
    <li class="nav-item">
        <a class="nav-link {{ $status == 'rejected' ? 'active bg-danger' : 'text-dark' }}"
           href="/admin/products?status=rejected">
            <i class="fas fa-times-circle me-1"></i>Rejected
            <span class="badge bg-secondary ms-1">
                {{ $counts['rejected'] }}
            </span>
        </a>
    </li>
</ul>

<!-- Search -->
<div class="card stat-card mb-4">
    <div class="card-body py-2">
        <form method="GET" action="/admin/products">
            <input type="hidden" name="status"
                   value="{{ $status }}">
            <div class="input-group">
                <span class="input-group-text bg-white">
                    <i class="fas fa-search text-muted"></i>
                </span>
                <input type="text" name="search"
                       class="form-control border-start-0"
                       placeholder="Search owner name or shop..."
                       value="{{ $search }}">
                <button type="submit"
                        class="btn btn-warning text-dark">
                    Search
                </button>
                @if($search)
                    <a href="/admin/products?status={{ $status }}"
                       class="btn btn-outline-secondary">
                        Clear
                    </a>
                @endif
            </div>
        </form>
    </div>
</div>

<!-- Owners with their products -->
@forelse($owners as $owner)
<div class="card stat-card mb-4">
    <!-- Owner header -->
    <div class="card-header bg-white border-bottom py-3">
        <div class="d-flex align-items-center
                    justify-content-between">
            <div class="d-flex align-items-center">
                <!-- Owner photo -->
                @if($owner->profile_photo)
                    <img src="http://localhost/SmartBiz/api/{{ $owner->profile_photo }}"
                         class="rounded-circle me-3"
                         width="45" height="45"
                         style="object-fit:cover;
                                border:2px solid #ff8c00">
                @else
                    <div style="width:45px;height:45px;
                                background:#fff3cd;
                                border-radius:50%;
                                display:flex;
                                align-items:center;
                                justify-content:center;
                                border:2px solid #ff8c00"
                         class="me-3">
                        <i class="fas fa-user text-warning"></i>
                    </div>
                @endif

                <div>
                    <div class="fw-bold fs-6">
                        {{ $owner->name }}
                    </div>
                    <div class="text-muted small">
                        <i class="fas fa-store me-1"></i>
                        {{ $owner->shop_name ?? 'No shop name' }}
                        &nbsp;·&nbsp;
                        <i class="fas fa-phone me-1"></i>
                        {{ $owner->phone }}
                        &nbsp;·&nbsp;
                        <span class="badge bg-warning text-dark">
                            {{ $owner->shop_category }}
                        </span>
                    </div>
                </div>
            </div>

            <div class="d-flex align-items-center gap-2">
                <!-- Product count badge -->
                <span class="badge bg-warning text-dark fs-6 px-3 py-2">
                    {{ $owner->products->count() }}
                    {{ Str::plural('product', $owner->products->count()) }}
                </span>
                <!-- View owner link -->
                <a href="/admin/owners/{{ $owner->id }}"
                   class="btn btn-sm btn-outline-warning">
                    <i class="fas fa-eye me-1"></i>
                    View Owner
                </a>
            </div>
        </div>
    </div>

    <!-- Products grid -->
    <div class="card-body">
        <div class="row g-3">
            @foreach($owner->products as $product)
            <div class="col-md-6 col-lg-4 col-xl-3">
                <div class="card h-100 border"
                     style="border-radius:12px;overflow:hidden">

                    <!-- Product image -->
                    @if($product->image)
                        <img src="http://localhost/SmartBiz/api/{{ $product->image }}"
                             style="height:140px;
                                    object-fit:cover"
                             class="card-img-top">
                    @else
                        <div style="height:140px;
                                    background:#f8f9fa;
                                    display:flex;
                                    align-items:center;
                                    justify-content:center">
                            <i class="fas fa-image fa-2x text-muted"></i>
                        </div>
                    @endif

                    <div class="card-body p-3">
                        <!-- Status badge -->
                        <span class="badge mb-2
                            {{ $product->status == 'active' ? 'bg-success' :
                              ($product->status == 'pending' ? 'bg-warning text-dark' :
                              ($product->status == 'rejected' ? 'bg-danger' : 'bg-secondary')) }}">
                            {{ ucfirst($product->status) }}
                        </span>

                        <!-- Product name -->
                        <h6 class="fw-bold mb-1">
                            {{ $product->name }}
                        </h6>

                        <!-- Price -->
                        <div class="text-warning fw-bold mb-1">
                            Rs. {{ number_format($product->price, 2) }}
                        </div>

                        <!-- Description -->
                        @if($product->description)
                            <p class="text-muted small mb-2"
                               style="font-size:11px">
                                {{ Str::limit($product->description, 50) }}
                            </p>
                        @endif

                        <!-- Date -->
                        <div class="text-muted"
                             style="font-size:11px">
                            <i class="fas fa-clock me-1"></i>
                            {{ \Carbon\Carbon::parse($product->created_at)->diffForHumans() }}
                        </div>
                    </div>

                    <!-- Action buttons -->
                    @if($product->status == 'pending')
                    <div class="card-footer bg-white p-2">
                        <div class="d-flex gap-2">
                            <form method="POST"
                                  action="/admin/products/{{ $product->id }}/approve"
                                  class="flex-fill">
                                @csrf
                                <button type="submit"
                                        class="btn btn-success btn-sm w-100">
                                    <i class="fas fa-check me-1"></i>
                                    Approve
                                </button>
                            </form>
                            <form method="POST"
                                  action="/admin/products/{{ $product->id }}/reject"
                                  class="flex-fill">
                                @csrf
                                <button type="submit"
                                        class="btn btn-danger btn-sm w-100"
                                        onclick="return confirm('Reject this product?')">
                                    <i class="fas fa-times me-1"></i>
                                    Reject
                                </button>
                            </form>
                        </div>
                    </div>
                    @endif

                    @if($product->status == 'rejected')
                    <div class="card-footer bg-white p-2">
                        <form method="POST"
                              action="/admin/products/{{ $product->id }}/approve">
                            @csrf
                            <button type="submit"
                                    class="btn btn-outline-success btn-sm w-100">
                                <i class="fas fa-redo me-1"></i>
                                Re-approve
                            </button>
                        </form>
                    </div>
                    @endif

                </div>
            </div>
            @endforeach
        </div>
    </div>
</div>
@empty
<div class="text-center py-5">
    <i class="fas fa-box-open fa-4x text-muted mb-3"></i>
    <h5 class="text-muted">
        No {{ $status }} products found
    </h5>
    @if($search)
        <p class="text-muted">
            No results for "{{ $search }}"
        </p>
    @endif
</div>
@endforelse

<!-- Pagination -->
<div class="mt-4">
    {{ $owners->appends(['status' => $status, 'search' => $search])->links() }}
</div>

@endsection