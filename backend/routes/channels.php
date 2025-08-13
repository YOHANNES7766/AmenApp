<?php

use Illuminate\Support\Facades\Broadcast;
use App\Models\Conversation;

Broadcast::channel('private-conversation.{conversationId}', function ($user, $conversationId) {
    $conversation = cache()->remember(
        "conversation:{$conversationId}",
        now()->addMinutes(1), // more readable than 60
        fn() => Conversation::find($conversationId)
    );

    if (!$conversation) {
        return false;
    }

    return in_array($user->id, [$conversation->user_one_id, $conversation->user_two_id]);
});
