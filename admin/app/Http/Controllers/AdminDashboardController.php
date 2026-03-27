<?php

namespace App\Http\Controllers;

use App\Models\Owner;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Session;

class AdminDashboardController extends Controller {

    // ── Middleware check ──
    private function checkAuth() {
        if (!Session::get('admin')) {
            return redirect('/admin/login');
        }
        return null;
    }

    // ── Dashboard ──
    public function dashboard() {
        if ($r = $this->checkAuth()) return $r;

        $totalOwners    = Owner::count();
        $totalProducts  = Product::count();
        $pendingProducts = Product::where(
                            'status', 'pending')->count();
        $activeProducts = Product::where(
                            'status', 'active')->count();

        // Products by category
        $productsByCategory = Product::select(
            DB::raw('status, COUNT(*) as count'))
            ->groupBy('status')
            ->get();

        // Recent owners
        $recentOwners = Owner::latest()
                            ->take(5)->get();

        return view('admin.dashboard', compact(
            'totalOwners',
            'totalProducts',
            'pendingProducts',
            'activeProducts',
            'productsByCategory',
            'recentOwners'
        ));
    }

    // ── Owners ──
    public function owners() {
        if ($r = $this->checkAuth()) return $r;
        $owners = Owner::withCount('products')
                        ->latest()->paginate(10);
        return view('admin.owners', compact('owners'));
    }

    public function ownerDetail($id) {
        if ($r = $this->checkAuth()) return $r;
        $owner    = Owner::findOrFail($id);
        $products = Product::where('owner_id', $id)
                            ->latest()->get();
        return view('admin.owner_detail',
                    compact('owner', 'products'));
    }

    // ── Products ──
    public function products(Request $request) {
        if ($r = $this->checkAuth()) return $r;

        $status   = $request->get('status', 'pending');
        $products = Product::with('owner')
                    ->where('status', $status)
                    ->latest()
                    ->paginate(10);

        $counts = [
            'pending'  => Product::where(
                'status', 'pending')->count(),
            'active'   => Product::where(
                'status', 'active')->count(),
            'inactive' => Product::where(
                'status', 'inactive')->count(),
            'rejected' => Product::where(
                'status', 'rejected')->count(),
        ];

        return view('admin.products',
                    compact('products', 'status', 'counts'));
    }

    public function approveProduct($id) {
        if ($r = $this->checkAuth()) return $r;

        Product::where('id', $id)->update([
            'status'    => 'active',
            'is_active' => 1,
        ]);

        return back()->with(
            'success', 'Product approved successfully!');
    }

    public function rejectProduct($id) {
        if ($r = $this->checkAuth()) return $r;

        Product::where('id', $id)->update([
            'status'    => 'rejected',
            'is_active' => 0,
        ]);

        return back()->with(
            'success', 'Product rejected!');
    }

    // ── Daily Summary ──
    public function summary() {
        if ($r = $this->checkAuth()) return $r;

        // Owners registered per day (last 7 days)
        $ownerStats = Owner::select(
            DB::raw('DATE(created_at) as date'),
            DB::raw('COUNT(*) as count'))
            ->where('created_at', '>=',
                    now()->subDays(7))
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        // Products added per day (last 7 days)
        $productStats = Product::select(
            DB::raw('DATE(created_at) as date'),
            DB::raw('COUNT(*) as count'))
            ->where('created_at', '>=',
                    now()->subDays(7))
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        // Products by status
        $statusStats = Product::select(
            DB::raw('status'),
            DB::raw('COUNT(*) as count'))
            ->groupBy('status')
            ->get();

        // Top owners by products
        $topOwners = Owner::withCount('products')
                          ->orderBy('products_count', 'desc')
                          ->take(5)
                          ->get();

        return view('admin.summary', compact(
            'ownerStats',
            'productStats',
            'statusStats',
            'topOwners'
        ));
    }
}