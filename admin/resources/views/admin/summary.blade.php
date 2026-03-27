@extends('admin.layout')
@section('title', 'Daily Summary')
@section('content')

<div class="row g-4 mb-4">
    <!-- Status summary -->
    @foreach($statusStats as $stat)
    <div class="col-md-3">
        <div class="card stat-card">
            <div class="card-body text-center">
                <div class="fs-2 fw-bold
                    {{ $stat->status == 'active' ? 'text-success' :
                      ($stat->status == 'pending' ? 'text-warning' :
                      ($stat->status == 'rejected' ? 'text-danger' : 'text-secondary')) }}">
                    {{ $stat->count }}
                </div>
                <div class="text-muted">
                    {{ ucfirst($stat->status) }} Products
                </div>
            </div>
        </div>
    </div>
    @endforeach
</div>

<div class="row g-4">
    <!-- Owners chart -->
    <div class="col-md-6">
        <div class="card stat-card">
            <div class="card-header bg-white border-0 pt-3">
                <h6 class="fw-bold mb-0">
                    <i class="fas fa-users me-2 text-warning"></i>
                    New Owners (Last 7 Days)
                </h6>
            </div>
            <div class="card-body">
                <canvas id="ownersChart"></canvas>
            </div>
        </div>
    </div>

    <!-- Products chart -->
    <div class="col-md-6">
        <div class="card stat-card">
            <div class="card-header bg-white border-0 pt-3">
                <h6 class="fw-bold mb-0">
                    <i class="fas fa-box me-2 text-warning"></i>
                    New Products (Last 7 Days)
                </h6>
            </div>
            <div class="card-body">
                <canvas id="productsChart"></canvas>
            </div>
        </div>
    </div>

    <!-- Top owners -->
    <div class="col-md-12">
        <div class="card stat-card">
            <div class="card-header bg-white border-0 pt-3">
                <h6 class="fw-bold mb-0">
                    <i class="fas fa-trophy me-2 text-warning"></i>
                    Top Owners by Products
                </h6>
            </div>
            <div class="card-body p-0">
                <table class="table table-hover mb-0">
                    <thead class="table-light">
                        <tr>
                            <th>Rank</th>
                            <th>Owner</th>
                            <th>Shop</th>
                            <th>Products</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($topOwners as $i => $owner)
                        <tr>
                            <td>
                                @if($i == 0)
                                    <i class="fas fa-trophy text-warning"></i>
                                @elseif($i == 1)
                                    <i class="fas fa-trophy text-secondary"></i>
                                @elseif($i == 2)
                                    <i class="fas fa-trophy text-danger"></i>
                                @else
                                    {{ $i + 1 }}
                                @endif
                            </td>
                            <td class="fw-semibold">
                                {{ $owner->name }}
                            </td>
                            <td class="text-muted">
                                {{ $owner->shop_name ?? 'N/A' }}
                            </td>
                            <td>
                                <span class="badge bg-warning text-dark">
                                    {{ $owner->products_count }} products
                                </span>
                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

@endsection

@section('scripts')
<script>
// Owners chart
new Chart(document.getElementById('ownersChart'), {
    type: 'bar',
    data: {
        labels: [
            @foreach($ownerStats as $stat)
                '{{ $stat->date }}',
            @endforeach
        ],
        datasets: [{
            label: 'New Owners',
            data: [
                @foreach($ownerStats as $stat)
                    {{ $stat->count }},
                @endforeach
            ],
            backgroundColor: 'rgba(255,140,0,0.7)',
            borderRadius: 6,
        }]
    },
    options: {
        responsive: true,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true } }
    }
});

// Products chart
new Chart(document.getElementById('productsChart'), {
    type: 'line',
    data: {
        labels: [
            @foreach($productStats as $stat)
                '{{ $stat->date }}',
            @endforeach
        ],
        datasets: [{
            label: 'New Products',
            data: [
                @foreach($productStats as $stat)
                    {{ $stat->count }},
                @endforeach
            ],
            borderColor: '#ff8c00',
            backgroundColor: 'rgba(255,140,0,0.1)',
            tension: 0.4,
            fill: true,
        }]
    },
    options: {
        responsive: true,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true } }
    }
});
</script>
@endsection