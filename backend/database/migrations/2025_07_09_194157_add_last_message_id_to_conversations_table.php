<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('conversations', function (Blueprint $table) {
            $table->unsignedBigInteger('last_message_id')->nullable()->after('user_two_id')->index();
            $table->foreign('last_message_id')
                ->references('id')->on('messages')
                ->onUpdate('cascade')
                ->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::table('conversations', function (Blueprint $table) {
            $table->dropForeign(['last_message_id']);
            $table->dropIndex(['last_message_id']); // Drop the index explicitly
            $table->dropColumn('last_message_id');
        });
    }
};
