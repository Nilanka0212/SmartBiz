<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Owner extends Model {
    protected $table    = 'owners';
    protected $fillable = [
        'name', 'phone', 'nic', 'shop_name',
        'shop_category', 'shop_location',
        'profile_photo', 'shop_image',
        'is_verified', 'language',
    ];

    public function products() {
        return $this->hasMany(Product::class);
    }

    public function orders() {
        return $this->hasMany(Order::class);
    }
}
