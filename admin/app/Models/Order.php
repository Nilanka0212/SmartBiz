<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Order extends Model {
    use HasFactory;

    protected $table = 'orders';
    protected $fillable = [
        'owner_id',
        'customer_name',
        'customer_phone',
        'items',
        'items_list',
        'total_price',
        'payment_method',
        'payment_status',
        'note',
        'status',
    ];

    protected $casts = [
        'items' => 'json',
        'items_list' => 'json',
        'total_price' => 'float',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ── Relationships ──
    public function owner() {
        return $this->belongsTo(Owner::class);
    }

    // ── Status helpers ──
    public function isPending() {
        return $this->status === 'pending';
    }

    public function isPreparing() {
        return $this->status === 'preparing';
    }

    public function isCompleted() {
        return $this->status === 'completed';
    }

    public function isCancelled() {
        return $this->status === 'cancelled';
    }

    // ── Scopes ──
    public function scopePending($query) {
        return $query->where('status', 'pending');
    }

    public function scopePreparing($query) {
        return $query->where('status', 'preparing');
    }

    public function scopeCompleted($query) {
        return $query->where('status', 'completed');
    }

    public function scopeCancelled($query) {
        return $query->where('status', 'cancelled');
    }

    public function scopeActive($query) {
        return $query->whereIn('status', ['pending', 'preparing']);
    }

    public function scopeRecentFirst($query) {
        return $query->orderBy('created_at', 'desc');
    }
}
