<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Contract;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ContractController extends Controller
{
    public function index()
    {
        // Mengambil semua kontrak, diurutkan dari yang terbaru, 
        // BESERTA data vendor dan jadwal terminnya sekaligus.
        $contracts = Contract::with(['vendor', 'payments'])->latest()->get();

        return response()->json([
            'status' => 'success',
            'data' => $contracts
        ], 200);
    }

    public function store(Request $request)
    {
        // 1. Validasi data utama dan format array termin
        $request->validate([
            'vendor_id' => 'required|exists:vendors,id',
            'contract_number' => 'required|string|unique:contracts',
            'title' => 'required|string',
            'total_value' => 'required|numeric',
            'start_date' => 'required|date',
            'duration_days' => 'required|integer',
            'end_date' => 'required|date',

            // Validasi Array Termin dari Flutter
            'termins' => 'required|array|min:1',
            'termins.*.due_date' => 'required|date',
            'termins.*.target_amount' => 'required|numeric',
            'termins.*.description' => 'nullable|string',
        ]);

        // Mulai Transaksi Database Pengaman
        DB::beginTransaction();

        try {
            // 2. Simpan Data Induk Kontrak
            $contract = Contract::create([
                // Karena belum pasang token login di Flutter secara sempurna, kita pakai ID 1 dulu
                'user_id' => 1,

                'vendor_id' => $request->vendor_id,
                'contract_number' => $request->contract_number,
                'title' => $request->title,
                'total_value' => $request->total_value,
                'start_date' => $request->start_date,
                'duration_days' => $request->duration_days,
                'end_date' => $request->end_date,
                // document_path kita lewati dulu di versi JSON ini
            ]);

            // 3. Simpan Anak-Anak Termin (Looping array dari Flutter)
            $terminNumber = 1;
            foreach ($request->termins as $termin) {
                $contract->payments()->create([
                    'termin_number' => $terminNumber,
                    'due_date' => $termin['due_date'],
                    'target_amount' => $termin['target_amount'],
                    'description' => $termin['description'] ?? null,
                ]);
                $terminNumber++;
            }

            // Jika semua lancar, permanenkan ke MySQL
            DB::commit();

            return response()->json([
                'status' => 'success',
                'message' => 'Kontrak dan Jadwal Termin berhasil disimpan',
                'data' => $contract->load('payments') // Kembalikan data beserta relasinya
            ], 201);
        } catch (\Exception $e) {
            // Jika ada yang meledak di tengah jalan, batalkan semua simpanan
            DB::rollBack();
            return response()->json([
                'status' => 'error',
                'message' => 'Gagal menyimpan data kontrak',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
