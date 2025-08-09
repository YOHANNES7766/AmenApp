<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('conversations', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_one_id')->index();
            $table->unsignedBigInteger('user_two_id')->index();
            $table->timestamps();

            $table->foreign('user_one_id')
                ->references('id')->on('users')
                ->onUpdate('cascade')
                ->onDelete('cascade');

            $table->foreign('user_two_id')
                ->references('id')->on('users')
                ->onUpdate('cascade')
                ->onDelete('cascade');

            // Optional: Prevent duplicate user pairs (remove if you want to allow multiple conversations between the same pair)
            $table->unique(['user_one_id', 'user_two_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('conversations');
    }
};
