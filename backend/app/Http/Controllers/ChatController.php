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
            ->with(['userOne', 'userTwo', 'lastMessage'])
            ->orderByDesc('updated_at')
            ->get();
        return response()->json($conversations);
    }

    // Get all messages for a conversation
    public function getMessages(Request $request, $conversationId)
    {
        $conversation = Conversation::with(['messages.sender', 'messages.receiver'])
            ->findOrFail($conversationId);
        return response()->json($conversation->messages()->orderBy('created_at')->get());
    }

    // Send a message (creates conversation if needed)
    public function sendMessage(Request $request)
    {
        $request->validate([
            'receiver_id' => 'required|exists:users,id',
            'message' => 'required|string',
        ]);
        $sender = $request->user();
        $receiverId = $request->input('receiver_id');
        $messageText = $request->input('message');

        // Find or create conversation
        $conversation = Conversation::where(function ($q) use ($sender, $receiverId) {
            $q->where('user_one_id', $sender->id)->where('user_two_id', $receiverId);
        })->orWhere(function ($q) use ($sender, $receiverId) {
            $q->where('user_one_id', $receiverId)->where('user_two_id', $sender->id);
        })->first();

        if (!$conversation) {
            $conversation = Conversation::create([
                'user_one_id' => $sender->id,
                'user_two_id' => $receiverId,
            ]);
        }

        // Create message
        $message = Message::create([
            'sender_id' => $sender->id,
            'receiver_id' => $receiverId,
            'conversation_id' => $conversation->id,
            'message' => $messageText,
            'is_read' => false,
        ]);

        // Update last_message_id
        $conversation->last_message_id = $message->id;
        $conversation->save();

        // Broadcast event for real-time
        broadcast(new MessageSent($message))->toOthers();

        return response()->json($message, 201);
    }

    // Mark a message as read
    public function markAsRead(Request $request, $messageId)
    {
        $message = Message::findOrFail($messageId);
        $user = $request->user();
        if ($message->receiver_id !== $user->id) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }
        $message->is_read = true;
        $message->save();
        return response()->json(['success' => true]);
    }

    // Get all approved users except the authenticated user
    public function getApprovedUsers(Request $request)
    {
        $user = $request->user();
        $approvedUsers = User::where('approved', true)
            ->where('id', '!=', $user->id)
            ->get(['id', 'name', 'email', 'profile_picture', 'role']);
        return response()->json($approvedUsers);
    }

    // Get or create the 'Saved Messages' (self-chat) conversation for the authenticated user
    public function getSavedMessages(Request $request)
    {
        $user = $request->user();
        // Find or create a conversation where both user_one_id and user_two_id are the same
        $conversation = Conversation::firstOrCreate(
            [
                'user_one_id' => $user->id,
                'user_two_id' => $user->id,
            ]
        );
        // Get messages for this conversation
        $messages = Message::where('conversation_id', $conversation->id)
            ->orderBy('created_at')
            ->get();
        return response()->json([
            'conversation_id' => $conversation->id,
            'messages' => $messages,
        ]);
    }
}
