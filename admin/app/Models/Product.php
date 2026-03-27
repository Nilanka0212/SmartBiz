<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Product extends Model {
    protected $table    = 'products';
    protected $fillable = [
        'owner_id', 'name', 'price',
        'description', 'image',
        'status', 'is_active',
    ];

    public function owner() {
        return $this->belongsTo(Owner::class);
    }
}