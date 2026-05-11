import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name  = 'Hapis Pacar Hyein';
  String _email = 'hapis@pelindo.co.id';
  final String _role  = 'Administrator';
  String _phone = '+62 812-3456-7890';
  Uint8List? _avatarBytes; 

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop   = screenWidth > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isDesktop
          ? _buildDesktopLayout()
          : _buildMobileLayout(),
    );
  }

  // ─── DESKTOP LAYOUT ───────────────────────────────────────────
  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Profil Saya',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kolom kiri — info profil
                  Expanded(flex: 2, child: _buildProfileCard()),
                  const SizedBox(width: 24),
                  // Kolom kanan — menu aksi
                  Expanded(flex: 3, child: _buildActionColumn()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionColumn() {
    return Column(
      children: [
        _buildMenuCard(
          icon:    Icons.person_outline,
          title:   'Edit Profil',
          subtitle: 'Ubah nama, email, dan nomor telepon',
          color:   AppColors.primary,
          onTap:   _showEditProfileDialog,
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          icon:    Icons.lock_outline,
          title:   'Ubah Password',
          subtitle: 'Perbarui kata sandi akun Anda',
          color:   Colors.teal,
          onTap:   _showChangePasswordDialog,
        ),
        const SizedBox(height: 24),
        _buildLogoutButton(),
      ],
    );
  }

  // ─── MOBILE LAYOUT ───
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMobileHeader(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoRow(Icons.email_outlined, 'Email', _email),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone_outlined, 'Telepon', _phone),
                const SizedBox(height: 24),
                _buildMenuCard(
                  icon:    Icons.person_outline,
                  title:   'Edit Profil',
                  subtitle: 'Ubah nama, email, dan nomor telepon',
                  color:   AppColors.primary,
                  onTap:   _showEditProfileDialog,
                ),
                const SizedBox(height: 12),
                _buildMenuCard(
                  icon:    Icons.lock_outline,
                  title:   'Ubah Password',
                  subtitle: 'Perbarui kata sandi akun Anda',
                  color:   Colors.teal,
                  onTap:   _showChangePasswordDialog,
                ),
                const SizedBox(height: 24),
                _buildLogoutButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF002753), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _buildAvatar(radius: 44),
          const SizedBox(height: 14),
          Text(_name,
            style: const TextStyle(color: Colors.white, fontSize: 20,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_role.toUpperCase(),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11, letterSpacing: 2)),
        ],
      ),
    );
  }

  // ─── SHARED WIDGETS ───────────────────────────────────────────
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildAvatar(radius: 48),
          const SizedBox(height: 16),
          Text(_name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
              color: AppColors.primary)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_role,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.primary)),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.email_outlined, 'Email', _email),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.phone_outlined, 'Telepon', _phone),
        ],
      ),
    );
  }

  Widget _buildAvatar({required double radius}) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: _avatarBytes != null
              ? MemoryImage(_avatarBytes!) // ← tampilkan foto yang dipilih
              : null,
          child: _avatarBytes == null
              ? Icon(Icons.person, size: radius, color: AppColors.primary.withValues(alpha: 0.5))
              : null,
        ),
        Positioned(
          bottom: 0, right: 0,
          child: GestureDetector(
            onTap: _pickPhoto, // ← klik untuk ganti foto
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4)],
              ),
              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: Colors.black87)),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showLogoutDialog,
        icon: const Icon(Icons.logout, size: 18, color: Colors.red),
        label: const Text('Logout',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: Colors.red.shade200),
        ),
      ),
    );
  }

  // ─── DIALOG EDIT PROFILE ──────────────────────────────────────
  void _showEditProfileDialog() {
    final nameCtrl  = TextEditingController(text: _name);
    final emailCtrl = TextEditingController(text: _email);
    final phoneCtrl = TextEditingController(text: _phone);
    final formKey   = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header dialog
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person_outline,
                          color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Edit Profil',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Field nama
                  _dialogLabel('Nama Lengkap'),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: _dialogInputDecoration('Masukkan nama lengkap', Icons.person_outline),
                    validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // Field email
                  _dialogLabel('Email'),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _dialogInputDecoration('Masukkan email', Icons.email_outlined),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email wajib diisi';
                      if (!v.contains('@')) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Field telepon
                  _dialogLabel('Nomor Telepon'),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _dialogInputDecoration('Masukkan nomor telepon', Icons.phone_outlined),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Nomor telepon wajib diisi';

                      final clean = v.replaceAll(RegExp(r'[\s\-()]'), '');
                      
                      final validPattern = RegExp(r'^(\+62|62|0)[8][1-9][0-9]{7,11}$');
                      if (!validPattern.hasMatch(clean)) {
                        return 'Format tidak valid (contoh: 08xx-xxxx-xxxx)';
                      }
                      
                      final digitsOnly = clean.replaceAll('+', '');
                      if (digitsOnly.length < 10 || digitsOnly.length > 14) {
                        return 'Nomor telepon Indonesia 10-14 digit';
                      }
                      
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Tombol aksi
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text('Batal',
                            style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            setState(() {
                              _name  = nameCtrl.text.trim();
                              _email = emailCtrl.text.trim();
                              _phone = phoneCtrl.text.trim();
                            });
                            Navigator.pop(ctx);
                            _showSnackbar('Profil berhasil diperbarui', Colors.green);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text('Simpan',
                            style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── DIALOG CHANGE PASSWORD ───────────────────────────────────
  void _showChangePasswordDialog() {
    final oldPassCtrl     = TextEditingController();
    final newPassCtrl     = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final formKey         = GlobalKey<FormState>();

    // State visibility password — pakai StatefulBuilder
    bool showOld     = false;
    bool showNew     = false;
    bool showConfirm = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.lock_outline,
                            color: Colors.teal, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text('Ubah Password',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Password lama
                    _dialogLabel('Password Saat Ini'),
                    TextFormField(
                      controller: oldPassCtrl,
                      obscureText: !showOld,
                      decoration: _dialogInputDecoration(
                        'Masukkan password lama', Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(showOld
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                            size: 20, color: Colors.grey),
                          onPressed: () => setDialogState(() => showOld = !showOld),
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Password lama wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // Password baru
                    _dialogLabel('Password Baru'),
                    TextFormField(
                      controller: newPassCtrl,
                      obscureText: !showNew,
                      decoration: _dialogInputDecoration(
                        'Minimal 8 karakter', Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(showNew
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                            size: 20, color: Colors.grey),
                          onPressed: () => setDialogState(() => showNew = !showNew),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password baru wajib diisi';
                        if (v.length < 8) return 'Minimal 8 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Konfirmasi password
                    _dialogLabel('Konfirmasi Password Baru'),
                    TextFormField(
                      controller: confirmPassCtrl,
                      obscureText: !showConfirm,
                      decoration: _dialogInputDecoration(
                        'Ulangi password baru', Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(showConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                            size: 20, color: Colors.grey),
                          onPressed: () => setDialogState(() => showConfirm = !showConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
                        if (v != newPassCtrl.text) return 'Password tidak cocok';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Tombol aksi
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: const Text('Batal',
                              style: TextStyle(color: Colors.grey)
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;
                              Navigator.pop(ctx);
                                // TODO: Hubungkan ke API backend saat tersedia
                                // Contoh: await AuthService.changePassword(oldPass, newPass);
                              _showSnackbar( 'Fitur ini akan aktif setelah terhubung ke server.', Colors.orange);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: const Text('Simpan',
                              style: TextStyle(color: Colors.white,
                                fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── DIALOG LOGOUT ────────────────────────────────────────────
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.logout, color: Colors.red.shade600, size: 32),
                ),
                const SizedBox(height: 16),
                const Text('Logout',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Apakah Anda yakin ingin keluar dari aplikasi?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login', (route) => false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Logout',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────
  Widget _dialogLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
          color: Colors.black87)),
    );
  }

  InputDecoration _dialogInputDecoration(String hint, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: Colors.grey),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8F9FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() => _avatarBytes = bytes);
      _showSnackbar('Foto profil berhasil diperbarui', Colors.green);
    } catch (e) {
      _showSnackbar('Gagal memilih foto', Colors.red);
    }
  }
}