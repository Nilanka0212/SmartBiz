<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (!Schema::hasColumn('orders', 'order_number')) {
            return;
        }

        $owners = DB::table('orders')
            ->select('owner_id')
            ->distinct()
            ->orderBy('owner_id')
            ->pluck('owner_id');

        foreach ($owners as $ownerId) {
            $orders = DB::table('orders')
                ->where('owner_id', $ownerId)
                ->orderBy('id')
                ->get(['id']);

            $counter = 1;
            foreach ($orders as $order) {
                DB::table('orders')
                    ->where('id', $order->id)
                    ->update(['order_number' => (string) $counter]);
                $counter++;
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Keep owner-facing order numbers intact.
    }
};
