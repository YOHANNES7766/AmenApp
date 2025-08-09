<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;
use App\Models\Message;

class MessageSent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $message;
    public $conversationId;

    /**
     * Create a new event instance.
     */
    public function __construct(Message $message)
    {
        $this->message = $message;
        $this->conversationId = $message->conversation_id;
    }

    /**
     * The channel the event should broadcast on.
     */
    public function broadcastOn(): Channel
    {
        return new PrivateChannel('conversation.' . $this->conversationId);
    }

    /**
     * The name of the event.
     */
    public function broadcastAs(): string
    {
        return 'MessageSent';
    }

    /**
     * The data to broadcast.
     */
    public function broadcastWith(): array
    {
        return [
            'message' => [
                'id' => $this->message->id,
                'text' => $this->message->text,
                'sender_id' => $this->message->sender_id,
                'receiver_id' => $this->message->receiver_id,
                'conversation_id' => $this->message->conversation_id,
                'created_at' => $this->message->created_at->toDateTimeString(),
            ]
        ];
    }
}
