<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('owner_id');
            $table->string('name');
            $table->decimal('price', 10, 2);
            $table->text('description')->nullable();
            $table->string('image')->nullable();
            $table->enum('status', [
                'pending', 'active',
                'inactive', 'rejected'
            ])->default('pending');
            $table->tinyInteger('is_active')->default(0);
            $table->timestamps();
            $table->foreign('owner_id')
                  ->references('id')
                  ->on('owners');
        });
    }

    public function down(): void {
        Schema::dropIfExists('products');
    }
};