<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BookComment extends Model
{
    protected $fillable = ['book_id', 'user_id', 'content'];
    public function user() { return $this->belongsTo(\App\Models\User::class); }
}
