<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\BookComment;
use Illuminate\Support\Facades\Auth;

class BookCommentController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $bookId = $request->query('book_id');
        if (!$bookId) {
            return response()->json(['error' => 'book_id required'], 400);
        }
        $comments = BookComment::where('book_id', $bookId)->with('user:id,name')->orderBy('created_at')->get();
        return response()->json($comments);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $request->validate([
            'book_id' => 'required|exists:books,id',
            'content' => 'required|string',
        ]);
        $user = Auth::user();
        $comment = BookComment::create([
            'book_id' => $request->book_id,
            'user_id' => $user->id,
            'content' => $request->content,
        ]);
        return response()->json($comment, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        //
    }
}
