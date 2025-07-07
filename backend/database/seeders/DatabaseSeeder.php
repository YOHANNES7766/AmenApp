<?php

namespace Database\Seeders;

use App\Models\User;
// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // User::factory(10)->create();

        User::factory()->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
        ]);

        // Create a new test user for mobile testing
        User::create([
            'name' => 'Mobile Test User',
            'email' => 'mobile@test.com',
            'password' => \Illuminate\Support\Facades\Hash::make('mobile123'),
            'role' => 'user',
        ]);
    }
}
