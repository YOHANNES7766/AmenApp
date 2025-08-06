<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class UserProfileController extends Controller
{
    /**
     * Get the authenticated user's profile information
     */
    public function show(): JsonResponse
    {
        $user = Auth::user();
        
        // Set default profile picture if none exists
        $profilePicture = $user->profile_picture;
        if (empty($profilePicture)) {
            $profilePicture = null; // Let frontend handle default
        }
        
        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'campus' => $user->campus,
                'department' => $user->department,
                'role' => $user->role,
                'profile_picture' => $profilePicture,
                'email_verified_at' => $user->email_verified_at,
                'created_at' => $user->created_at,
                'updated_at' => $user->updated_at,
            ]
        ]);
    }

    /**
     * Update the authenticated user's profile information
     */
    public function update(Request $request): JsonResponse
    {
        $user = Auth::user();

        $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:20'],
            'campus' => ['sometimes', 'nullable', 'string', 'max:100'],
            'department' => ['sometimes', 'nullable', 'string', 'max:100'],
        ]);

        $user->update($request->only(['name', 'phone', 'campus', 'department']));

        return response()->json([
            'message' => 'Profile updated successfully',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'campus' => $user->campus,
                'department' => $user->department,
                'role' => $user->role,
                'profile_picture' => $user->profile_picture,
                'email_verified_at' => $user->email_verified_at,
                'created_at' => $user->created_at,
                'updated_at' => $user->updated_at,
            ]
        ]);
    }

    /**
     * Upload profile picture
     */
    public function uploadProfilePicture(Request $request): JsonResponse
    {
        try {
            $request->validate([
                'profile_picture' => ['required', 'image', 'mimes:jpeg,png,jpg,gif', 'max:2048'],
            ]);

            $user = Auth::user();
            
            // Ensure storage directory exists
            $storagePath = storage_path('app/public/profile-pictures');
            if (!file_exists($storagePath)) {
                mkdir($storagePath, 0755, true);
            }
            
            // Delete old profile picture if exists
            if ($user->profile_picture) {
                $oldPath = str_replace('/storage/', '', $user->profile_picture);
                if (Storage::disk('public')->exists($oldPath)) {
                    Storage::disk('public')->delete($oldPath);
                }
            }

            // Store the new image
            $path = $request->file('profile_picture')->store('profile-pictures', 'public');
            $imageUrl = Storage::url($path);

            // Ensure the URL is absolute and uses the correct domain
            if (!str_starts_with($imageUrl, 'http')) {
                $imageUrl = url($imageUrl);
            }

            // Verify the file was actually stored
            if (!Storage::disk('public')->exists($path)) {
                throw new \Exception('Failed to store the uploaded file');
            }

            // Check if the file is accessible via web
            $publicPath = public_path('storage/' . $path);
            $fileExists = file_exists($publicPath);
            
            \Log::info('Profile picture upload details', [
                'user_id' => $user->id,
                'image_url' => $imageUrl,
                'path' => $path,
                'file_exists' => Storage::disk('public')->exists($path),
                'public_path' => $publicPath,
                'public_file_exists' => $fileExists,
                'storage_link_exists' => is_link(public_path('storage')),
                'app_url' => config('app.url'),
                'filesystem_url' => config('filesystems.disks.public.url')
            ]);

            // If storage link doesn't exist or file isn't accessible, use base64 fallback
            if (!is_link(public_path('storage')) || !$fileExists) {
                \Log::warning('Storage link not working, using base64 fallback');
                
                // Convert image to base64
                $imageData = base64_encode(file_get_contents($request->file('profile_picture')->getRealPath()));
                $mimeType = $request->file('profile_picture')->getMimeType();
                $base64Url = "data:$mimeType;base64,$imageData";
                
                // Update user's profile picture with base64 data
                $user->update(['profile_picture' => $base64Url]);
                
                return response()->json([
                    'message' => 'Profile picture uploaded successfully (base64)',
                    'image_url' => $base64Url,
                    'debug_info' => [
                        'method' => 'base64',
                        'file_exists' => $fileExists,
                        'storage_link_exists' => is_link(public_path('storage'))
                    ]
                ]);
            }

            // Update user's profile picture
            $user->update(['profile_picture' => $imageUrl]);

            return response()->json([
                'message' => 'Profile picture uploaded successfully',
                'image_url' => $imageUrl,
                'debug_info' => [
                    'method' => 'storage',
                    'file_exists' => $fileExists,
                    'storage_link_exists' => is_link(public_path('storage')),
                    'public_path' => $publicPath
                ]
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            \Log::error('Profile picture validation failed', ['errors' => $e->errors()]);
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            \Log::error('Profile picture upload failed: ' . $e->getMessage(), [
                'user_id' => Auth::id(),
                'file' => $request->file('profile_picture')?->getClientOriginalName()
            ]);
            return response()->json([
                'message' => 'Failed to upload profile picture: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update profile picture URL
     */
    public function updateProfilePicture(Request $request): JsonResponse
    {
        $request->validate([
            'profile_picture' => ['required', 'string', 'url'],
        ]);

        $user = Auth::user();
        $user->update(['profile_picture' => $request->profile_picture]);

        return response()->json([
            'message' => 'Profile picture updated successfully'
        ]);
    }

    /**
     * Change the authenticated user's password
     */
    public function changePassword(Request $request): JsonResponse
    {
        $request->validate([
            'current_password' => ['required', 'string'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        $user = Auth::user();

        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'message' => 'Current password is incorrect'
            ], 400);
        }

        $user->update([
            'password' => Hash::make($request->password)
        ]);

        return response()->json([
            'message' => 'Password changed successfully'
        ]);
    }
} 