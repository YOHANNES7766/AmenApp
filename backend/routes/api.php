<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;
use App\Http\Controllers\UserProfileController;

Route::middleware(['auth:sanctum'])->get('/user', function (Request $request) {
    return $request->user();
});

Route::middleware(['auth:sanctum'])->post('/logout', function (Request $request) {
    $request->user()->currentAccessToken()->delete();
    return response()->json(['message' => 'Logged out successfully']);
});

// User Profile Routes
Route::middleware(['auth:sanctum'])->group(function () {
    Route::get('/profile', [UserProfileController::class, 'show']);
    Route::put('/profile', [UserProfileController::class, 'update']);
    Route::post('/profile/change-password', [UserProfileController::class, 'changePassword']);
    Route::post('/profile/upload-picture', [UserProfileController::class, 'uploadProfilePicture']);
    Route::post('/profile/update-picture', [UserProfileController::class, 'updateProfilePicture']);
});

Route::middleware(['auth:sanctum', 'admin'])->group(function () {
    Route::get('/admin/dashboard', function (Request $request) {
        return response()->json(['message' => 'Welcome, admin!', 'user' => $request->user()]);
    });
    
    Route::get('/admin/users', function (Request $request) {
        return response()->json(['message' => 'Admin users list', 'users' => \App\Models\User::all()]);
    });
});


Route::get('/test-db', function () {
    try {
        $users = DB::table('users')->get();  // Or any other table
        return response()->json($users);
    } catch (\Exception $e) {
        return response()->json(['error' => $e->getMessage()], 500);
    }
});

Route::get('/test-upload', function () {
    return response()->json(['message' => 'Upload endpoint is accessible']);
});

require __DIR__.'/auth.php';
