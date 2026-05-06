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
        // License fields
        'license_status', 'license_start_date', 'license_end_date',
        'license_amount', 'payment_method', 'transaction_id',
        'created_by', 'updated_by',
    ];

    protected $casts = [
        'license_start_date' => 'date',
        'license_end_date' => 'date',
        'license_amount' => 'decimal:2',
    ];

    /**
     * Check if owner has active license
     */
    public function hasActiveLicense(): bool
    {
        return $this->license_status === 'active' 
            && $this->license_end_date 
            && $this->license_end_date->gte(now()->toDateString());
    }

    /**
     * Get days remaining on license
     */
    public function getDaysRemainingAttribute(): ?int
    {
        if (!$this->license_end_date || $this->license_status !== 'active') {
            return null;
        }

        $days = now()->diffInDays($this->license_end_date, false);
        return $days >= 0 ? $days : null;
    }

    /**
     * Check if license is expiring soon (within 7 days)
     */
    public function getIsExpiringSoonAttribute(): bool
    {
        return $this->license_status === 'active' 
            && $this->days_remaining !== null 
            && $this->days_remaining <= 7;
    }

    public function products() {
        return $this->hasMany(Product::class);
    }

    public function orders() {
        return $this->hasMany(Order::class);
    }
}
