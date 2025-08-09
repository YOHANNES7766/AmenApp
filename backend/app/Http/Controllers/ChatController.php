<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Message;
use App\Models\Conversation;
use Illuminate\Support\Facades\Auth;
use App\Events\MessageSent;

class ChatController extends Controller
{
    // Get all conversations for the authenticated user
    public function getConversations(Request $request)
    {
        $user = $request->user();

        $conversations = Conversation::where('user_one_id', $user->id)
            ->orWhere('user_two_id', $user->id)
            ->with([
                'userOne:id,name,profile_picture',
                'userTwo:id,name,profile_picture',
                'lastMessage:id,message,conversation_id,sender_id,created_at'
            ])
            ->orderByDesc('updated_at')
            ->get();

        return response()->json($conversations);
    }

    // Get all messages for a conversation
    public function getMessages(Request $request, $conversationId)
    {
        $conversation = Conversation::with([
            'messages' => function ($query) {
                $query->with('sender:id,name,profile_picture', 'receiver:id,name,profile_picture')
                      ->orderBy('created_at');
            }
        ])->findOrFail($conversationId);

        return response()->json($conversation->messages);
    }

    // Send a message
    public function sendMessage(Request $request)
    {
        $request->validate([
            'receiver_id' => 'required|exists:users,id',
            'message' => 'required|string',
        ]);

        $sender = $request->user();
        $receiverId = $request->input('receiver_id');
        $text = $request->input('message');

        // Find or create conversation
        $conversation = Conversation::where(function ($query) use ($sender, $receiverId) {
            $query->where('user_one_id', $sender->id)->where('user_two_id', $receiverId);
        })->orWhere(function ($query) use ($sender, $receiverId) {
            $query->where('user_one_id', $receiverId)->where('user_two_id', $sender->id);
        })->first();

        if (!$conversation) {
            $conversation = Conversation::create([
                'user_one_id' => $sender->id,
                'user_two_id' => $receiverId,
            ]);
        }

        // Create the message
        $message = Message::create([
            'sender_id' => $sender->id,
            'receiver_id' => $receiverId,
            'conversation_id' => $conversation->id,
            'message' => $text,
            'is_read' => false,
        ]);

        // Update conversation with latest message
        $conversation->last_message_id = $message->id;
        $conversation->updated_at = now();
        $conversation->save();

        // Broadcast message event (Pusher)
        broadcast(new MessageSent($message->load('sender:id,name,profile_picture')))->toOthers();

        return response()->json($message, 201);
    }

    // Mark a message as read
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

    // Get all approved users (excluding self)
    public function getApprovedUsers(Request $request)
    {
        $approvedUsers = User::where('approved', true)
            ->where('id', '!=', $request->user()->id)
            ->get(['id', 'name', 'email', 'profile_picture', 'role']);

        return response()->json($approvedUsers);
    }

    // Self-chat: Get/create 'Saved Messages' conversation
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
            'messages' => $messages,
        ]);
    }
}
