<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Vendor;
use Illuminate\Http\Request;

class VendorController extends Controller
{
    // Memunculkan daftar vendor di layar (Untuk dropdown saat buat kontrak)
    public function index()
    {
        $vendors = Vendor::select('id', 'name')->orderBy('name', 'asc')->get();
        return response()->json(['status' => 'success', 'data' => $vendors], 200);
    }

    // Menambah vendor baru ke database
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|unique:vendors,name|max:255',
        ]);

        $vendor = Vendor::create($request->all());

        return response()->json([
            'status' => 'success',
            'message' => 'Vendor berhasil ditambahkan',
            'data' => $vendor
        ], 201);
    }

    public function destroy($id)
    {
        $vendor = Vendor::find($id);

        if (!$vendor) {
            return response()->json(['message' => 'Vendor tidak ditemukan'], 404);
        }

        // Cek apakah vendor ini sudah punya kontrak. Jika ya, jangan boleh dihapus!
        // Ini perlindungan data integritas.
        if ($vendor->contracts()->count() > 0) {
            return response()->json(['message' => 'Gagal: Vendor ini masih memiliki kontrak aktif'], 400);
        }

        $vendor->delete();

        return response()->json(['status' => 'success', 'message' => 'Vendor berhasil dihapus'], 200);
    }
}
