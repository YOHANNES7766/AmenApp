<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;
use App\Http\Controllers\UserProfileController;
use App\Http\Controllers\BookController;
use App\Http\Controllers\BookCommentController;
use App\Http\Controllers\BookNoteController;

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

    // Admin approval endpoints
    Route::get('/admin/pending-users', [\App\Http\Controllers\AdminUserApprovalController::class, 'pending']);
    Route::post('/admin/approve-user/{id}', [\App\Http\Controllers\AdminUserApprovalController::class, 'approve']);
    Route::delete('/admin/decline-user/{id}', [\App\Http\Controllers\AdminUserApprovalController::class, 'decline']);
});

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/chat/conversations', [\App\Http\Controllers\ChatController::class, 'getConversations']);
    Route::get('/chat/messages/{conversation}', [\App\Http\Controllers\ChatController::class, 'getMessages']);
    Route::post('/chat/send', [\App\Http\Controllers\ChatController::class, 'sendMessage']);
    Route::post('/chat/read/{message}', [\App\Http\Controllers\ChatController::class, 'markAsRead']);
    Route::get('/chat/approved-users', [\App\Http\Controllers\ChatController::class, 'getApprovedUsers']);
    Route::get('/chat/saved-messages', [\App\Http\Controllers\ChatController::class, 'getSavedMessages']);
    
    // Broadcasting authentication for mobile app
    Route::post('/broadcasting/auth', function (Illuminate\Http\Request $request) {
        return \Illuminate\Support\Facades\Broadcast::auth($request);
    });
});

// Book routes (protected)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/books', [BookController::class, 'index']);
    Route::post('/books/upload', [BookController::class, 'upload']);
    Route::get('/books/{id}/download', [BookController::class, 'download']);
});

// Public route for serving uploaded files
Route::get('/storage/{path}', [BookController::class, 'serveFile'])->where('path', '.*');

Route::middleware(['auth:sanctum', 'admin'])->group(function () {
    Route::patch('/books/{id}/approve', [\App\Http\Controllers\BookController::class, 'approve']);
});

// Book comments and notes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/book-comments', [BookCommentController::class, 'index']); // ?book_id=ID
    Route::post('/book-comments', [BookCommentController::class, 'store']);
    Route::get('/book-notes/{book}', [BookNoteController::class, 'show']);
    Route::post('/book-notes', [BookNoteController::class, 'store']);
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
