@extends('admin.layout')
@section('title', 'Owner Management')
@section('content')

<div class="card stat-card">
    <div class="card-header bg-white border-0 pt-3 d-flex justify-content-between">
        <h6 class="fw-bold mb-0">
            <i class="fas fa-users me-2 text-warning"></i>
            All Owners ({{ $owners->total() }})
        </h6>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover mb-0">
                <thead class="table-light">
                    <tr>
                        <th>#</th>
                        <th>Owner</th>
                        <th>Shop</th>
                        <th>Category</th>
                        <th>Location</th>
                        <th>Verified</th>
                        <th>Products</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($owners as $owner)
                    <tr>
                        <td class="text-muted">{{ $owner->id }}</td>
                        <td>
                            <div class="d-flex align-items-center">
                                @if($owner->profile_photo)
                                    <img src="http://localhost/SmartBiz/api/{{ $owner->profile_photo }}"
                                         class="rounded-circle me-2"
                                         width="36" height="36"
                                         style="object-fit:cover">
                                @else
                                    <div style="width:36px;height:36px;
                                                background:#fff3cd;border-radius:50%;
                                                display:flex;align-items:center;
                                                justify-content:center"
                                         class="me-2">
                                        <i class="fas fa-user text-warning"></i>
                                    </div>
                                @endif
                                <div>
                                    <div class="fw-semibold">{{ $owner->name }}</div>
                                    <small class="text-muted">{{ $owner->phone }}</small>
                                </div>
                            </div>
                        </td>
                        <td>{{ $owner->shop_name ?? 'N/A' }}</td>
                        <td>
                            <span class="badge bg-warning text-dark">
                                {{ $owner->shop_category }}
                            </span>
                        </td>
                        <td class="text-muted small">
                            {{ Str::limit($owner->shop_location, 20) }}
                        </td>
                        <td>
                            @if($owner->is_verified)
                                <span class="badge bg-success">Verified</span>
                            @else
                                <span class="badge bg-danger">Unverified</span>
                            @endif
                        </td>
                        <td>
                            <span class="badge bg-primary">
                                {{ $owner->products_count }}
                            </span>
                        </td>
                        <td>
                            <a href="{{ route('admin.owner.detail', $owner->id) }}"
                               class="btn btn-sm btn-outline-warning">
                                <i class="fas fa-eye"></i> View
                            </a>
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
        <div class="p-3">
            {{ $owners->links() }}
        </div>
    </div>
</div>

@endsection
