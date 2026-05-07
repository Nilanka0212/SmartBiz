<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->string('order_number', 20)->nullable()->after('id')->index();
            $table->unique(['owner_id', 'order_number'], 'orders_owner_order_number_unique');
        });

        // Generate order numbers separately for each owner.
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
        Schema::table('orders', function (Blueprint $table) {
            $table->dropUnique('orders_owner_order_number_unique');
            $table->dropColumn('order_number');
        });
    }
};
