<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    private string $indexName = 'orders_owner_order_number_unique';

    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (!Schema::hasColumn('orders', 'order_number')) {
            return;
        }

        if ($this->indexExists()) {
            return;
        }

        Schema::table('orders', function (Blueprint $table) {
            $table->unique(['owner_id', 'order_number'], $this->indexName);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (!$this->indexExists()) {
            return;
        }

        Schema::table('orders', function (Blueprint $table) {
            $table->dropUnique($this->indexName);
        });
    }

    private function indexExists(): bool
    {
        $database = DB::getDatabaseName();

        return DB::table('information_schema.STATISTICS')
            ->where('TABLE_SCHEMA', $database)
            ->where('TABLE_NAME', 'orders')
            ->where('INDEX_NAME', $this->indexName)
            ->exists();
    }
};
