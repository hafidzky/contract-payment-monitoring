<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\Api\V1\DashboardController;
use App\Http\Controllers\Api\V1\VendorController;
use Illuminate\Support\Facades\Route;

// Rute Publik (Pintu Masuk)
Route::post('/login', [AuthController::class, 'login']);

// Rute Dasbor Inti (Jantung Aplikasi)
Route::prefix('v1')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index']);
    Route::get('/vendors', [VendorController::class, 'index']);
    Route::post('/vendors', [VendorController::class, 'store']);
    Route::delete('/vendors/{id}', [VendorController::class, 'destroy']);
    Route::get('/contracts', [\App\Http\Controllers\Api\V1\ContractController::class, 'index']);
    Route::post('/contracts', [\App\Http\Controllers\Api\V1\ContractController::class, 'store']);
});