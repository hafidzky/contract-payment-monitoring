<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        // 1. Hitung Overview Kontrak (Total, Active, Warning, Total Nilai)
        $overview = DB::table('contracts')
            ->selectRaw('
                COUNT(id) as total_contracts,
                SUM(CASE WHEN status = "active" THEN 1 ELSE 0 END) as active_contracts,
                SUM(CASE WHEN status = "warning" THEN 1 ELSE 0 END) as warning_contracts,
                COALESCE(SUM(total_value), 0) as total_nilai
            ')->first();

        // 2. Cari Deadline Bulan Ini
        $currentMonth = Carbon::now()->month;
        $currentYear = Carbon::now()->year;

        $deadlines = DB::table('contracts')
            ->whereMonth('end_date', $currentMonth)
            ->whereYear('end_date', $currentYear)
            ->whereIn('status', ['active', 'warning'])
            ->select('contract_number', 'title', 'end_date')
            ->get();

        // 3. Hitung Persentase Realisasi Pembayaran Bulan Ini
        $payments = DB::table('payments')
            ->whereMonth('due_date', $currentMonth)
            ->whereYear('due_date', $currentYear)
            ->selectRaw('
                COALESCE(SUM(target_amount), 0) as total_target,
                COALESCE(SUM(realized_amount), 0) as total_realized
            ')->first();

        $realizationPercentage = 0;
        if ($payments->total_target > 0) {
            $realizationPercentage = round(($payments->total_realized / $payments->total_target) * 100, 2);
        }

        // Kembalikan Response JSON yang siap dipakai Flutter
        return response()->json([
            'status' => 'success',
            'data' => [
                'overview' => $overview,
                'deadlines_this_month' => $deadlines,
                'realization' => [
                    'period' => Carbon::now()->format('F Y'),
                    'percentage' => $realizationPercentage,
                    'target' => $payments->total_target,
                    'realized' => $payments->total_realized,
                ]
            ]
        ], 200);
    }
}