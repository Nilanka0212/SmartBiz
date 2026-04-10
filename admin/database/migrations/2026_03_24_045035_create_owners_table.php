<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('owners', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('phone')->unique();
            $table->string('nic')->unique();
            $table->string('password');
            $table->string('profile_photo')->nullable();
            $table->string('shop_name')->nullable();
            $table->string('shop_category');
            $table->text('shop_location');
            $table->string('shop_image')->nullable();
            $table->string('language')->default('english');
            $table->string('token')->nullable();
            $table->string('otp', 6)->nullable();
            $table->dateTime('otp_expires_at')->nullable();
            $table->tinyInteger('is_verified')->default(0);
            $table->tinyInteger('is_shop_open')->default(1);
            $table->timestamps();
        });
    }

    public function down(): void {
        Schema::dropIfExists('owners');
    }
};
