import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/family_user_provider.dart';

class KontrolOrangTuaScreen extends ConsumerStatefulWidget {
  const KontrolOrangTuaScreen({super.key});

  @override
  ConsumerState<KontrolOrangTuaScreen> createState() =>
      _KontrolOrangTuaScreenState();
}

class _KontrolOrangTuaScreenState extends ConsumerState<KontrolOrangTuaScreen> {
  final _pinController = TextEditingController();
  final _batasWaktuController = TextEditingController();
  bool _isAuthenticated = false;
  bool _notifikasiSolatAktif = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final currentUser = ref.read(familyUserProvider);

    // Cek apakah user sudah login
    if (!currentUser.isLoggedIn || currentUser.user == null) {
      // Jika belum login, tampilkan dialog dan kembali ke halaman sebelumnya
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLoginRequiredDialog();
      });
      return;
    }

    // Jika sudah login, lanjutkan load settings
    _loadKontrolSettings();
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Login Diperlukan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D4C56),
            ),
          ),
          content: const Text(
            'Anda harus login terlebih dahulu untuk mengakses halaman Kontrol Orang Tua.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF0D4C56)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _batasWaktuController.dispose();
    super.dispose();
  }

  Future<void> _loadKontrolSettings() async {
    final currentUser = ref.read(familyUserProvider);

    // Pastikan user sudah login dan memiliki ID
    if (!currentUser.isLoggedIn ||
        currentUser.user == null ||
        currentUser.user!.idPengguna == null) {
      return;
    }

    try {
      final kontrolProvider = ref.read(familyUserProvider.notifier);
      final kontrol = await kontrolProvider.getKontrolOrangTua(
        currentUser.user!.idPengguna!,
      );

      if (kontrol != null && mounted) {
        setState(() {
          _batasWaktuController.text = kontrol.batasWaktuMenit.toString();
          _notifikasiSolatAktif = kontrol.notifikasiSolatAktif;
        });
      }
    } catch (e) {
      print('Error loading kontrol settings: $e');
    }
  }

  Future<void> _authenticateWithPin() async {
    if (_pinController.text.length != 4) {
      _showSnackBar('PIN harus 4 digit');
      return;
    }

    final currentUser = ref.read(familyUserProvider);

    // Validasi login terlebih dahulu
    if (!currentUser.isLoggedIn ||
        currentUser.user == null ||
        currentUser.user!.idPengguna == null) {
      _showSnackBar('Anda harus login terlebih dahulu');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final familyNotifier = ref.read(familyUserProvider.notifier);
      final isValid = await familyNotifier.validatePin(
        currentUser.user!.idPengguna!,
        _pinController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (isValid) {
            _isAuthenticated = true;
            _pinController.clear();
          } else {
            _showSnackBar('PIN salah! Coba lagi.');
            _pinController.clear();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Terjadi kesalahan. Coba lagi.');
      }
    }
  }

  Future<void> _saveSettings() async {
    final currentUser = ref.read(familyUserProvider);

    // Validasi login terlebih dahulu
    if (!currentUser.isLoggedIn ||
        currentUser.user == null ||
        currentUser.user!.idPengguna == null) {
      _showSnackBar('Anda harus login terlebih dahulu');
      return;
    }

    final batasWaktu = int.tryParse(_batasWaktuController.text) ?? 0;

    if (batasWaktu < 0) {
      _showSnackBar('Batas waktu tidak boleh negatif');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final familyNotifier = ref.read(familyUserProvider.notifier);
      final success = await familyNotifier.updateKontrolOrangTua(
        currentUser.user!.idPengguna!,
        batasWaktu,
        _notifikasiSolatAktif,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          _showSnackBar('Pengaturan berhasil disimpan');
        } else {
          _showSnackBar('Gagal menyimpan pengaturan');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Terjadi kesalahan. Coba lagi.');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF0D4C56),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(familyUserProvider);

    // Jika belum login, tampilkan loading atau halaman kosong
    if (!currentUser.isLoggedIn || currentUser.user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D4C56),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D4C56),
      body: Stack(
        children: [
          // Background cloud
          Positioned(
            bottom: -50,
            left: 0,
            right: 0,
            child: Icon(
              Icons.cloud,
              size: 400,
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _isAuthenticated
                        ? _buildControlSettings()
                        : _buildPinEntry(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9D463),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.7),
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Kontrol Orang Tua',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 54), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildPinEntry() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 50),
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF9D463), width: 4),
          ),
          child: Column(
            children: [
              const Icon(Icons.security, size: 64, color: Color(0xFF0D4C56)),
              const SizedBox(height: 20),
              const Text(
                'Masukkan PIN Orang Tua',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D4C56),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'PIN diperlukan untuk mengakses pengaturan kontrol orang tua. Pastikan Anda sudah login ke akun keluarga.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '• • • •',
                  hintStyle: const TextStyle(
                    fontSize: 24,
                    color: Colors.grey,
                    letterSpacing: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF0D4C56),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFFF9D463),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value.length == 4) {
                    _authenticateWithPin();
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _authenticateWithPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D4C56),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Masuk', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingCard(
          'Batas Waktu Bermain',
          'Atur berapa menit anak boleh bermain per hari (0 = tanpa batas)',
          TextField(
            controller: _batasWaktuController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              suffixText: 'menit',
              hintText: '0',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildSettingCard(
          'Notifikasi Solat',
          'Aktifkan pengingat waktu solat untuk anak',
          SwitchListTile(
            value: _notifikasiSolatAktif,
            onChanged: (value) {
              setState(() {
                _notifikasiSolatAktif = value;
              });
            },
            title: Text(_notifikasiSolatAktif ? 'Aktif' : 'Nonaktif'),
            activeColor: const Color(0xFF0D4C56),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF9D463),
              foregroundColor: const Color(0xFF0D4C56),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text(
                    'Simpan Pengaturan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isAuthenticated = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Keluar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard(String title, String description, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFF9D463), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D4C56),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}
