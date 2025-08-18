<?php

namespace App\Http\Controllers;

use App\Models\Book;
use Illuminate\Http\Request;

class BookController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $approved = $request->query('approved');
        $page = $request->query('page', 1);
        $perPage = $request->query('per_page', 20);
        $search = $request->query('search');
        $category = $request->query('category');
        $language = $request->query('language');
        
        $query = Book::query();
        
        if ($approved !== null) {
            $query->where('approved', filter_var($approved, FILTER_VALIDATE_BOOLEAN));
        }
        
        if ($search) {
            $query->where(function($q) use ($search) {
                $q->where('title', 'like', '%' . $search . '%')
                  ->orWhere('author', 'like', '%' . $search . '%');
            });
        }
        
        if ($category) {
            $query->where('category', $category);
        }
        
        if ($language) {
            $query->where('language', $language);
        }
        
        $query->orderBy('created_at', 'desc');
        $books = $query->paginate($perPage, ['*'], 'page', $page);
        
        foreach ($books->items() as $book) {
            if ($book->pdf_path) {
                $book->pdf_url = url('/storage/books/' . $book->pdf_path);
            }
            if ($book->epub_path) {
                $book->epub_url = url('/storage/books/' . $book->epub_path);
            }
            if ($book->cover_url && !str_starts_with($book->cover_url, 'http')) {
                $book->cover_url = url($book->cover_url);
            }
        }
        
        return response()->json([
            'data' => $books->items(),
            'current_page' => $books->currentPage(),
            'last_page' => $books->lastPage(),
            'per_page' => $books->perPage(),
            'total' => $books->total(),
            'has_more' => $books->hasMorePages()
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        //
    }

    /**
     * Display the specified resource.
     */
    public function show(Book $book)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Book $book)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Book $book)
    {
        //
    }

    /**
     * Download the specified book file.
     */
    public function download(Request $request, $id)
    {
        $format = $request->query('format', 'pdf');
        $book = Book::findOrFail($id);
        $filePath = $format === 'epub' ? $book->epub_path : $book->pdf_path;
        if (!$filePath) {
            return response()->json(['error' => 'File not found.'], 404);
        }
        $storagePath = storage_path('app/public/books/' . $filePath);
        if (!file_exists($storagePath)) {
            return response()->json(['error' => 'File not found on server.'], 404);
        }
        $mimeType = $format === 'epub' ? 'application/epub+zip' : 'application/pdf';
        return response()->download($storagePath, basename($filePath), ['Content-Type' => $mimeType]);
    }

    /**
     * Approve a book (admin only)
     */
    public function approve($id)
    {
        $book = Book::findOrFail($id);
        $book->approved = true;
        $book->save();
        return response()->json(['message' => 'Book approved']);
    }
}
