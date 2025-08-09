<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('sender_id')->index();
            $table->unsignedBigInteger('receiver_id')->index();
            $table->unsignedBigInteger('conversation_id')->nullable()->index();
            $table->text('message');
            $table->boolean('is_read')->default(false);
            $table->timestamps();

            // Optional index for performance when ordering by date
            $table->index('created_at');

            $table->foreign('sender_id')
                ->references('id')->on('users')
                ->onUpdate('cascade')
                ->onDelete('cascade');

            $table->foreign('receiver_id')
                ->references('id')->on('users')
                ->onUpdate('cascade')
                ->onDelete('cascade');

            $table->foreign('conversation_id')
                ->references('id')->on('conversations')
                ->onUpdate('cascade')
                ->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::table('messages', function (Blueprint $table) {
            $table->dropForeign(['sender_id']);
            $table->dropForeign(['receiver_id']);
            $table->dropForeign(['conversation_id']);
            $table->dropIndex(['sender_id']);
            $table->dropIndex(['receiver_id']);
            $table->dropIndex(['conversation_id']);
            $table->dropIndex(['created_at']);
        });

        Schema::dropIfExists('messages');
    }
};
