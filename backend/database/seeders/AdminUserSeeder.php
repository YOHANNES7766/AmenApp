<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    public function run()
    {
        User::updateOrCreate(
            ['email' => 'admin@example.com'],
            [
                'name' => 'Admin',
                'password' => Hash::make('adminpassword'),
                'role' => 'admin',
                'approved' => true,
                'campus' => 'MAIN CAMPUS',
                'department' => 'SWE',
            ]
        );
    }
}
