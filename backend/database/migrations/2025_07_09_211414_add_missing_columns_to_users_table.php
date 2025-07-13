<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
//            $table->string('phone')->nullable()->after('password'); // Removed to avoid duplicate
//            $table->string('campus')->nullable()->after('phone'); // Removed to avoid duplicate
//            $table->string('department')->nullable()->after('campus'); // Removed to avoid duplicate
//            $table->string('role')->default('user')->after('department'); // Removed to avoid duplicate
//            $table->boolean('approved')->default(false)->after('role'); // Removed to avoid duplicate
//            $table->string('profile_picture')->nullable()->after('approved'); // Removed to avoid duplicate
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['phone', 'campus', 'department', 'role', 'approved', 'profile_picture']);
        });
    }
};
