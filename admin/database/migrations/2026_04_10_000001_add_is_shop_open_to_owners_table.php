<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::table('owners', function (Blueprint $table) {
            $table->tinyInteger('is_shop_open')
                  ->default(1)
                  ->after('is_verified');
        });
    }

    public function down(): void {
        Schema::table('owners', function (Blueprint $table) {
            $table->dropColumn('is_shop_open');
        });
    }
};
