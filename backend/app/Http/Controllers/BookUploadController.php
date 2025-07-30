<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Book;
use Illuminate\Support\Facades\Storage;

class BookUploadController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'author' => 'required|string|max:255',
            'category' => 'nullable|string|max:255',
            'language' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'pdf' => 'nullable|file|mimes:pdf|max:20480',
            'epub' => 'nullable|file|mimes:epub|max:20480',
            'cover' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:4096',
        ]);

        $pdfPath = null;
        $epubPath = null;
        $coverUrl = null;
        if ($request->hasFile('pdf')) {
            $pdfPath = $request->file('pdf')->store('books', 'public');
        }
        if ($request->hasFile('epub')) {
            $epubPath = $request->file('epub')->store('books', 'public');
        }
        if ($request->hasFile('cover')) {
            $coverPath = $request->file('cover')->store('covers', 'public');
            $coverUrl = '/storage/' . $coverPath;
        }

        $book = Book::create([
            'title' => $request->title,
            'author' => $request->author,
            'category' => $request->category,
            'language' => $request->language,
            'description' => $request->description,
            'pdf_path' => $pdfPath,
            'epub_path' => $epubPath,
            'approved' => false,
            'cover_url' => $coverUrl,
        ]);

        return response()->json($book, 201);
    }
}
