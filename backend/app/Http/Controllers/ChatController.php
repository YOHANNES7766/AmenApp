<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Message;
use App\Models\Conversation;
use App\Events\MessageSent;

class ChatController extends Controller
{
    /**
     * Get all conversations for the authenticated user
     */
    public function getConversations(Request $request)
    {
        $user = $request->user();

        try {
            $conversations = Conversation::where('user_one_id', $user->id)
                ->orWhere('user_two_id', $user->id)
                ->with([
                    'userOne:id,name,profile_picture',
                    'userTwo:id,name,profile_picture',
                    'lastMessage:id,message,conversation_id,sender_id,created_at'
                ])
                ->orderByDesc('updated_at')
                ->limit(50) // Limit for performance
                ->get()
                ->map(function ($conversation) use ($user) {
                    $otherUser = $conversation->user_one_id === $user->id
                        ? $conversation->userTwo
                        : $conversation->userOne;

                    return [
                        'id'           => $conversation->id,
                        'user_one_id'  => $conversation->user_one_id,
                        'user_two_id'  => $conversation->user_two_id,
                        'user_one'     => $conversation->userOne,
                        'user_two'     => $conversation->userTwo,
                        'last_message' => $conversation->lastMessage,
                        'updated_at'   => $conversation->updated_at->toDateTimeString(),
                    ];
                });

            \Log::info('Fetched conversations', ['count' => $conversations->count(), 'user_id' => $user->id]);
            return response()->json($conversations);
        } catch (\Exception $e) {
            \Log::error('Error fetching conversations', ['error' => $e->getMessage(), 'user_id' => $user->id]);
            return response()->json(['error' => 'Failed to fetch conversations'], 500);
        }
    }

    /**
     * Get all messages for a conversation with other_user info
     */
    public function getMessages(Request $request, $conversationId)
    {
        $user = $request->user();

        try {
            $conversation = Conversation::findOrFail($conversationId);

            // Ensure the user is part of this conversation
            if ($conversation->user_one_id !== $user->id && $conversation->user_two_id !== $user->id) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $messages = Message::where('conversation_id', $conversationId)
                ->with('sender:id,name,profile_picture')
                ->orderBy('created_at', 'asc')
                ->limit(100) // Limit for performance
                ->get()
                ->map(function ($message) {
                    return [
                        'id' => $message->id,
                        'message' => $message->message,
                        'sender_id' => $message->sender_id,
                        'receiver_id' => $message->receiver_id,
                        'conversation_id' => $message->conversation_id,
                        'created_at' => $message->created_at->toDateTimeString(),
                        'sender' => $message->sender,
                    ];
                });

            \Log::info('Fetched messages', ['conversation_id' => $conversationId, 'count' => $messages->count()]);
            return response()->json($messages);
        } catch (\Exception $e) {
            \Log::error('Error fetching messages', ['error' => $e->getMessage(), 'conversation_id' => $conversationId]);
            return response()->json(['error' => 'Failed to fetch messages'], 500);
        }
    }

    /**
     * Send a message and broadcast event
     */
    public function sendMessage(Request $request)
    {
        $request->validate([
            'receiver_id' => 'required|exists:users,id',
            'message'     => 'required|string',
        ]);

        $sender     = $request->user();
        $receiverId = $request->input('receiver_id');
        $text       = $request->input('message');

        // Find or create conversation
        $conversation = Conversation::where(function ($query) use ($sender, $receiverId) {
            $query->where('user_one_id', $sender->id)->where('user_two_id', $receiverId);
        })->orWhere(function ($query) use ($sender, $receiverId) {
            $query->where('user_one_id', $receiverId)->where('user_two_id', $sender->id);
        })->first();

        if (! $conversation) {
            $conversation = Conversation::create([
                'user_one_id' => $sender->id,
                'user_two_id' => $receiverId,
            ]);
        }

        // Create the message
        $message = Message::create([
            'sender_id'       => $sender->id,
            'receiver_id'     => $receiverId,
            'conversation_id' => $conversation->id,
            'message'         => $text,
            'is_read'         => false,
        ]);

        // Update last message for the conversation
        $conversation->last_message_id = $message->id;
        $conversation->save();

        // Load necessary relationships
        $conversation->load(['userOne:id,name,profile_picture', 'userTwo:id,name,profile_picture']);
        $message->load('sender:id,name,profile_picture');

        // Determine other user for the sender
        $otherUser = $conversation->user_one_id === $sender->id
            ? $conversation->userTwo
            : $conversation->userOne;

        // Broadcast to others
        broadcast(new MessageSent($message))->toOthers();

        // Return same format as broadcastWith()
        return response()->json([
            'conversation_id' => $conversation->id,
            'other_user'      => $otherUser,
            'message' => [
                'id'              => $message->id,
                'message'         => $message->message,
                'sender_id'       => $message->sender_id,
                'receiver_id'     => $message->receiver_id,
                'conversation_id' => $message->conversation_id,
                'created_at'      => $message->created_at->toDateTimeString(),
                'sender' => [
                    'id'              => $message->sender->id,
                    'name'            => $message->sender->name,
                    'profile_picture' => $message->sender->profile_picture,
                ],
            ]
        ], 201);
    }

    /**
     * Mark a message as read
     */
    public function markAsRead(Request $request, $messageId)
    {
        $message = Message::findOrFail($messageId);

        if ($message->receiver_id !== $request->user()->id) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $message->is_read = true;
        $message->save();

        return response()->json(['success' => true]);
    }

    /**
     * Get all approved users except self
     */
    public function getApprovedUsers(Request $request)
    {
        $approvedUsers = User::where('approved', true)
            ->where('id', '!=', $request->user()->id)
            ->get(['id', 'name', 'email', 'profile_picture', 'role']);

        return response()->json($approvedUsers);
    }

    /**
     * Get or create 'Saved Messages' self-chat
     */
    public function getSavedMessages(Request $request)
    {
        $user = $request->user();

        $conversation = Conversation::firstOrCreate([
            'user_one_id' => $user->id,
            'user_two_id' => $user->id,
        ]);

        $messages = Message::where('conversation_id', $conversation->id)
            ->orderBy('created_at')
            ->get();

        return response()->json([
            'conversation_id' => $conversation->id,
            'other_user'      => $user, // Self-chat: other_user is the same user
            'messages'        => $messages,
        ]);
    }
}
