<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BookNote extends Model
{
    protected $fillable = ['book_id', 'user_id', 'content'];
}
