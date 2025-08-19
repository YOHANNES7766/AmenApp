<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Book extends Model
{
    protected $fillable = [
        'title',
        'author',
        'category',
        'language',
        'pdf_path',
        'epub_path',
        'description',
        'approved',
        'cover_url',
        'user_id',
    ];
}
