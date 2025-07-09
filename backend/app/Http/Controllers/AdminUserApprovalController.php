<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class AdminUserApprovalController extends Controller
{
    // List all users pending approval
    public function pending(): JsonResponse
    {
        $pendingUsers = User::where('approved', false)->get();
        return response()->json($pendingUsers);
    }

    // Approve a user
    public function approve($id): JsonResponse
    {
        $user = User::findOrFail($id);
        $user->approved = true;
        $user->save();
        return response()->json(['message' => 'User approved']);
    }

    // Decline (delete) a user
    public function decline($id): JsonResponse
    {
        $user = User::findOrFail($id);
        $user->delete();
        return response()->json(['message' => 'User declined and deleted']);
    }
} 