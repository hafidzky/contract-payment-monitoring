<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('contracts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users'); // Siapa admin yang input
            $table->foreignId('vendor_id')->constrained('vendors')->onDelete('restrict'); // Dari Layar 1

            $table->string('contract_number')->unique();
            $table->string('title'); // Nama Pekerjaan
            $table->bigInteger('total_value'); // Nilai Kontrak (Rp)

            $table->date('start_date');
            $table->integer('duration_days'); // Durasi (Hari)
            $table->date('end_date'); // Tanggal Selesai (Otomatis dari Flutter)

            $table->string('document_path')->nullable(); // Path file opsional
            $table->enum('status', ['active', 'completed', 'warning'])->default('active');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('contracts');
    }
};