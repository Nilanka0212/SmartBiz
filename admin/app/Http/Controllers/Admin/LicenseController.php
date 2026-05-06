<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Owner;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Session;

class LicenseController extends Controller
{
    /**
     * Check admin authentication
     */
    private function checkAuth() {
        if (!Session::get('admin')) {
            return redirect('/admin/login');
        }
        return null;
    }

    /**
     * Activate license for an owner
     */
    public function activate(Request $request)
    {
        // Check if it's an API request (JSON) or Web request
        $isApi = $request->wantsJson() || $request->ajax();
        
        if ($r = $this->checkAuth()) {
            if ($isApi) {
                return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
            }
            return $r;
        }

        $validator = Validator::make($request->all(), [
            'owner_id' => 'required|integer|exists:owners,id',
            'amount' => 'required|numeric|min:0',
            'payment_method' => 'required|string|max:50',
            'transaction_id' => 'nullable|string|max:100',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after:start_date',
        ]);

        if ($validator->fails()) {
            if ($isApi) {
                return response()->json([
                    'success' => false,
                    'message' => $validator->errors()->first()
                ], 422);
            }
            return redirect()->back()->with('error', $validator->errors()->first());
        }

        $owner = Owner::find($request->owner_id);

        // Check if owner already has active license
        if ($owner->license_status === 'active' && 
            $owner->license_end_date && 
            $owner->license_end_date->gte(now()->toDateString())) {
            if ($isApi) {
                return response()->json([
                    'success' => false,
                    'message' => 'Owner already has an active license'
                ], 400);
            }
            return redirect()->back()->with('error', 'Owner already has an active license');
        }

        $startDate = $request->start_date ?? now()->toDateString();
        $endDate = $request->end_date ?? now()->addMonth()->toDateString();

        $owner->update([
            'license_status' => 'active',
            'license_start_date' => $startDate,
            'license_end_date' => $endDate,
            'license_amount' => $request->amount,
            'payment_method' => $request->payment_method,
            'transaction_id' => $request->transaction_id,
            'updated_by' => Session::get('admin.id') ?? null,
        ]);

        if ($isApi) {
            return response()->json([
                'success' => true,
                'message' => 'License activated successfully',
                'data' => [
                    'owner_id' => $owner->id,
                    'owner_name' => $owner->name,
                    'phone' => $owner->phone,
                    'license_status' => $owner->license_status,
                    'start_date' => $owner->license_start_date,
                    'end_date' => $owner->license_end_date,
                    'amount' => $owner->license_amount,
                    'payment_method' => $owner->payment_method,
                ]
            ]);
        }

        return redirect()->back()->with('success', 'License activated successfully for ' . $owner->name);
    }

    /**
     * Deactivate license for an owner
     */
    public function deactivate(Request $request)
    {
        // Check if it's an API request (JSON) or Web request
        $isApi = $request->wantsJson() || $request->ajax();
        
        if ($r = $this->checkAuth()) {
            if ($isApi) {
                return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
            }
            return $r;
        }

        $validator = Validator::make($request->all(), [
            'owner_id' => 'required|integer|exists:owners,id',
            'reason' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            if ($isApi) {
                return response()->json([
                    'success' => false,
                    'message' => $validator->errors()->first()
                ], 422);
            }
            return redirect()->back()->with('error', $validator->errors()->first());
        }

        $owner = Owner::find($request->owner_id);

        if ($owner->license_status !== 'active' && $owner->license_status !== 'pending') {
            if ($isApi) {
                return response()->json([
                    'success' => false,
                    'message' => 'Owner does not have an active license'
                ], 400);
            }
            return redirect()->back()->with('error', 'Owner does not have an active license');
        }

        $owner->update([
            'license_status' => 'cancelled',
            'license_end_date' => now()->toDateString(),
            'updated_by' => Session::get('admin.id') ?? null,
        ]);

        if ($isApi) {
            return response()->json([
                'success' => true,
                'message' => 'License deactivated successfully',
                'data' => [
                    'owner_id' => $owner->id,
                    'owner_name' => $owner->name,
                    'license_status' => $owner->license_status,
                ]
            ]);
        }

        return redirect()->back()->with('success', 'License deactivated for ' . $owner->name);
    }

    /**
     * Get license status for an owner
     */
    public function status($ownerId)
    {
        $owner = Owner::find($ownerId);

        if (!$owner) {
            return response()->json([
                'success' => false,
                'message' => 'Owner not found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'owner_id' => $owner->id,
                'owner_name' => $owner->name,
                'phone' => $owner->phone,
                'shop_name' => $owner->shop_name,
                'license_status' => $owner->license_status,
                'license_start_date' => $owner->license_start_date,
                'license_end_date' => $owner->license_end_date,
                'days_remaining' => $owner->days_remaining,
                'is_expiring_soon' => $owner->is_expiring_soon,
                'license_amount' => $owner->license_amount,
                'payment_method' => $owner->payment_method,
            ]
        ]);
    }

    /**
     * Get all licenses with filtering
     */
    public function all(Request $request)
    {
        $query = Owner::query();

        // Filter by license status
        if ($request->has('status') && $request->status) {
            $query->where('license_status', $request->status);
        }

        // Filter by search
        if ($request->has('search') && $request->search) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%")
                  ->orWhere('shop_name', 'like', "%{$search}%");
            });
        }

        $licenses = $query->orderBy('updated_at', 'desc')
            ->paginate($request->limit ?? 20);

        return response()->json([
            'success' => true,
            'data' => $licenses->items(),
            'pagination' => [
                'page' => $licenses->currentPage(),
                'limit' => $licenses->perPage(),
                'total' => $licenses->total(),
                'pages' => $licenses->lastPage()
            ]
        ]);
    }

    /**
     * Check and update expired licenses (can be called by cron)
     */
    public function checkExpired()
    {
        $expired = Owner::where('license_status', 'active')
            ->where('license_end_date', '<', now()->toDateString())
            ->update([
                'license_status' => 'expired',
                'updated_at' => now(),
            ]);

        return response()->json([
            'success' => true,
            'message' => 'License expiry check completed',
            'expired_count' => $expired
        ]);
    }
}