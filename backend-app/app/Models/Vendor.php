<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Vendor extends Model
{
    use HasFactory;

    // Mengizinkan kolom-kolom ini diisi secara massal
    protected $fillable = [
        'name'
    ];

    public function contracts()
    {
        return $this->hasMany(Contract::class);
    }
}
