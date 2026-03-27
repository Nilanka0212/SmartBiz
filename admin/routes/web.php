<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminAuthController;
use App\Http\Controllers\AdminDashboardController;

// ── Redirect root to admin login ──
Route::get('/', function () {
    return redirect('/admin/login');
});

// ── Auth routes ──
Route::get('/admin/login',
    [AdminAuthController::class, 'showLogin'])
    ->name('admin.login');

Route::post('/admin/login',
    [AdminAuthController::class, 'login']);

Route::get('/admin/logout',
    [AdminAuthController::class, 'logout'])
    ->name('admin.logout');

// ── Dashboard routes ──
Route::get('/admin/dashboard',
    [AdminDashboardController::class, 'dashboard'])
    ->name('admin.dashboard');

Route::get('/admin/owners',
    [AdminDashboardController::class, 'owners'])
    ->name('admin.owners');

Route::get('/admin/owners/{id}',
    [AdminDashboardController::class, 'ownerDetail'])
    ->name('admin.owner.detail');

Route::get('/admin/products',
    [AdminDashboardController::class, 'products'])
    ->name('admin.products');

Route::post('/admin/products/{id}/approve',
    [AdminDashboardController::class, 'approveProduct'])
    ->name('admin.product.approve');

Route::post('/admin/products/{id}/reject',
    [AdminDashboardController::class, 'rejectProduct'])
    ->name('admin.product.reject');

Route::get('/admin/summary',
    [AdminDashboardController::class, 'summary'])
    ->name('admin.summary');