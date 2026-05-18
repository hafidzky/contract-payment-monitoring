<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            // cascade: Jika kontrak dihapus, semua terminnya ikut terhapus
            $table->foreignId('contract_id')->constrained('contracts')->onDelete('cascade');

            $table->integer('termin_number'); // Termin 1, 2, dst.
            $table->date('due_date'); // Jatuh Tempo
            $table->bigInteger('target_amount'); // Nominal (Rp)
            $table->text('description')->nullable(); // Keterangan

            $table->bigInteger('realized_amount')->default(0); // Uang yang sudah benar-benar dibayar nanti
            $table->enum('status', ['pending', 'paid', 'late'])->default('pending');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
