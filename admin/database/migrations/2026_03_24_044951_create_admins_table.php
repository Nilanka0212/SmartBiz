<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('admins', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('password');
            $table->timestamps();
        });

        // Insert default admin
        DB::table('admins')->insert([
            'name'     => 'Admin',
            'email'    => 'admin@shopflow.com',
            'password' => bcrypt('password'),
        ]);
    }

    public function down(): void {
        Schema::dropIfExists('admins');
    }
};