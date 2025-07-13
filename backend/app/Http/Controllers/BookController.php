<?php

namespace App\Http\Controllers;

use App\Models\Book;
use Illuminate\Http\Request;

class BookController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $books = Book::all();
        foreach ($books as $book) {
            if ($book->pdf_path) {
                $book->pdf_url = url('/storage/books/' . $book->pdf_path);
            }
            if ($book->epub_path) {
                $book->epub_url = url('/storage/books/' . $book->epub_path);
            }
        }
        return response()->json($books);
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
}
