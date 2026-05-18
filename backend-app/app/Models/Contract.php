<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Contract extends Model
{
    protected $guarded = []; // Izinkan semua kolom diisi massal

    public function vendor()
    {
        return $this->belongsTo(Vendor::class);
    }

    public function payments()
    {
        return $this->hasMany(Payment::class);
    }
}
