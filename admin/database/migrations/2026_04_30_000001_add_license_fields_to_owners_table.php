<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('owners', function (Blueprint $table) {
            $table->enum('license_status', ['active', 'expired', 'cancelled', 'pending'])
                  ->default('pending')
                  ->after('is_verified');
            $table->date('license_start_date')->nullable()->after('license_status');
            $table->date('license_end_date')->nullable()->after('license_start_date');
            $table->decimal('license_amount', 10, 2)->nullable()->after('license_end_date');
            $table->string('payment_method')->nullable()->after('license_amount');
            $table->string('transaction_id')->nullable()->after('payment_method');
            $table->unsignedBigInteger('created_by')->nullable()->after('transaction_id');
            $table->unsignedBigInteger('updated_by')->nullable()->after('created_by');
        });
    }

    public function down(): void
    {
        Schema::table('owners', function (Blueprint $table) {
            $table->dropColumn([
                'license_status',
                'license_start_date',
                'license_end_date',
                'license_amount',
                'payment_method',
                'transaction_id',
                'created_by',
                'updated_by',
            ]);
        });
    }
};