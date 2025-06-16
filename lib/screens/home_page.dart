import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'package:faceabsensiapp/screens/login_page.dart';
import 'package:faceabsensiapp/screens/qr_scan_screen.dart';
import 'package:faceabsensiapp/screens/camera_screen.dart';
import 'package:faceabsensiapp/models/absensi_history_item.dart';
import 'package:faceabsensiapp/api/absensi_api.dart';
import 'package:faceabsensiapp/api/auth_api.dart';
import 'package:faceabsensiapp/widgets/info_row_widget.dart';
import 'package:faceabsensiapp/main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<dynamic> _mahasiswaList = [];
  List<AbsensiHistoryItem> _absensiHistoryList = [];
  bool _isLoadingData = true;
  String? _errorMessage;
  String? _username;
  String? _userId;
  bool _isFaceEnrolled = false;
  int _selectedIndex = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  final AbsensiApi _absensiApi = AbsensiApi();
  final AuthApi _authApi = AuthApi();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();

    _initializeCamerasAndLoadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamerasAndLoadData() async {
    // Cameras are initialized in main.dart, just ensure they are available
    if (cameras.isEmpty) {
      try {
        cameras = await availableCameras();
      } on CameraException catch (e) {
        print('Error: ${e.code}\nError Message: ${e.description}');
        _showSnackBar('Gagal mengakses kamera: ${e.description}', Colors.red);
      }
    }
    await _loadUserDataAndCheckFaceEnrollment();
    await _fetchMahasiswaData();
    await _fetchAbsensiHistory();
  }

  Future<void> _loadUserDataAndCheckFaceEnrollment() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('user_name') ?? 'User';
      _userId = prefs.getString('user_id');
      _isFaceEnrolled = (prefs.getString('is_face_recorded') == 'yes');
    });

    if (!_isFaceEnrolled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showEnrollFaceDialog();
      });
    }
  }

  Future<void> _fetchMahasiswaData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'Token tidak ditemukan. Silakan login kembali.';
        _isLoadingData = false;
      });
      _showSnackBar('Token tidak ditemukan. Silakan login kembali.', Colors.red);
      _logout();
      return;
    }

    try {
      final data = await _absensiApi.fetchKelasData(token);
      setState(() {
        _mahasiswaList = data;
        _isLoadingData = false;
      });
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (errorMessage.contains('Sesi habis')) {
        _showSnackBar(errorMessage, Colors.red);
        _logout();
        return;
      }
      setState(() {
        _errorMessage = errorMessage;
        _isLoadingData = false;
      });
      _showSnackBar(errorMessage, Colors.red);
    }
  }

  Future<void> _fetchAbsensiHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      return;
    }

    try {
      final history = await _absensiApi.fetchAbsensiHistory(token);
      setState(() {
        _absensiHistoryList = history;
      });
      print('DEBUG_ABSENSI_HISTORY: Riwayat absensi berhasil dimuat: ${_absensiHistoryList.length} item');
    } catch (e) {
      print('DEBUG_ABSENSI_HISTORY: Error memuat riwayat absensi: $e');
    }
  }

  Future<void> _logout() async {
    await _authApi.logout();
    _showSnackBar('Anda telah logout.', Colors.blue);
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        break;
      case 1:
        _showLogoutConfirmation();
        break;
    }
  }

  Future<void> _showLogoutConfirmation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Konfirmasi Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Apakah Anda yakin ingin logout dari aplikasi?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal', style: TextStyle(color: Colors.blueGrey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showKelasEntryConfirmation(Map<String, dynamic> kelas) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('Masuk Kelas ${kelas['nama_kelas']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Apakah Anda ingin masuk ke kelas ${kelas['nama_kelas']}?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal', style: TextStyle(color: Colors.blueGrey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _startQrScan(kelas);
              },
              child: const Text('Ya, Masuk Kelas'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startQrScan(Map<String, dynamic> kelas) async {
    final scannedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrScanScreen(
          onQrScanned: (qrData) {}, // Callback ini bisa kosong atau digunakan untuk logging saja
        ),
      ),
    );

    if (scannedData != null && scannedData is String) {
      try {
        final qrContent = json.decode(scannedData);
        if (qrContent['id'].toString() == kelas['id'].toString()) {
          _showSnackBar('QR Code berhasil dipindai untuk kelas ${kelas['nama_kelas']}!', Colors.green);
          _showAbsensiTypeConfirmation(kelas);
        } else {
          _showSnackBar('QR Code tidak sesuai untuk kelas ini. ID Kelas QR: ${qrContent['id']}, ID Kelas yang dipilih: ${kelas['id']}', Colors.red);
        }
      } catch (e) {
        _showSnackBar('Data QR Code tidak valid atau rusak: $e', Colors.red);
        print('Error parsing QR data: $e');
      }
    } else {
      _showSnackBar('Pemindaian QR Code dibatalkan atau tidak ada data.', Colors.orange);
    }
  }

  Future<void> _showAbsensiTypeConfirmation(Map<String, dynamic> kelas) async {
    if (!_isFaceEnrolled) {
      _showSnackBar('Anda harus merekam wajah terlebih dahulu untuk absen.', Colors.red);
      _showEnrollFaceDialog();
      return;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('Absen ${kelas['nama_kelas']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Pilih jenis absen untuk kelas ${kelas['nama_kelas']}:'),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _checkAndStartAbsensi(kelas, 'masuk');
                  },
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text('Absen Masuk', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _checkAndStartAbsensi(kelas, 'pulang');
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Absen Pulang', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal', style: TextStyle(color: Colors.blueGrey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkAndStartAbsensi(Map<String, dynamic> kelas, String type) async {
    final currentTime = DateTime.now();
    final String absenTimeStr = type == 'masuk'
        ? (kelas['mulai_absen_masuk'] ?? '00:00:00')
        : (kelas['mulai_absen_pulang'] ?? '00:00:00');

    final parts = absenTimeStr.split(':');
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);

    final absensiAllowedTime = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      hour,
      minute,
    );

    bool isTimeValid = false;
    String message = '';

    if (type == 'masuk') {
      if (currentTime.isAfter(absensiAllowedTime) || currentTime.isAtSameMomentAs(absensiAllowedTime)) {
        isTimeValid = true;
      } else {
        message = 'Belum waktunya absen masuk untuk kelas ini. Jam masuk yang diizinkan: ${DateFormat('HH:mm').format(absensiAllowedTime)}.';
      }
    } else { // type == 'pulang'
      if (currentTime.isAfter(absensiAllowedTime) || currentTime.isAtSameMomentAs(absensiAllowedTime)) {
        isTimeValid = true;
      } else {
        message = 'Belum waktunya absen pulang untuk kelas ini. Jam pulang yang diizinkan: ${DateFormat('HH:mm').format(absensiAllowedTime)}.';
      }
    }

    if (isTimeValid) {
      if (cameras.isEmpty) {
        _showSnackBar('Tidak ada kamera tersedia.', Colors.red);
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            camera: cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front,
              orElse: () => cameras[0],
            ),
            onPictureTaken: (imagePath) => _processDetectionAndAbsensi(kelas, type, imagePath),
            isEnrollment: false,
          ),
        ),
      );
    } else {
      _showSnackBar(message, Colors.red);
    }
  }

  Future<void> _processDetectionAndAbsensi(Map<String, dynamic> kelas, String type, String imagePath) async {
    _showSnackBar('Memproses deteksi wajah dan absensi...', Colors.blue);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userId = prefs.getString('user_id');

    if (token == null || token.isEmpty || userId == null) {
      _showSnackBar('Sesi habis atau ID Pengguna tidak ditemukan. Silakan login kembali.', Colors.red);
      _logout();
      return;
    }

    try {
      await _absensiApi.processAbsensi(userId, kelas['id'].toString(), type, imagePath, token);
      _showSnackBar('Absensi berhasil!', Colors.green);
      _fetchMahasiswaData();
      _fetchAbsensiHistory();
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      _showSnackBar(errorMessage, Colors.red);
    }
  }

  Future<void> _showEnrollFaceDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Rekam Wajah Anda', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Untuk dapat menggunakan fitur absensi, Anda perlu merekam wajah Anda terlebih dahulu.', textAlign: TextAlign.center,),
                SizedBox(height: 15),
                Text('Pastikan Anda berada di tempat dengan pencahayaan yang cukup dan posisi wajah Anda jelas terlihat.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _startFaceEnrollment();
              },
              child: const Text('Mulai Rekam Wajah'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startFaceEnrollment() async {
    if (cameras.isEmpty) {
      _showSnackBar('Tidak ada kamera tersedia.', Colors.red);
      return;
    }

    if (_userId == null) {
      _showSnackBar('ID Pengguna tidak ditemukan. Harap login ulang.', Colors.red);
      _logout();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          camera: cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
            orElse: () => cameras[0],
          ),
          onPictureTaken: (imagePath) => _processFaceEnrollment(imagePath),
          isEnrollment: true,
        ),
      ),
    );
  }

  Future<void> _processFaceEnrollment(String imagePath) async {
    _showSnackBar('Mengirim wajah untuk pendaftaran...', Colors.blue);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userId = prefs.getString('user_id');

    if (token == null || token.isEmpty || userId == null) {
      _showSnackBar('Sesi habis atau ID Pengguna tidak ditemukan. Silakan login kembali.', Colors.red);
      _logout();
      return;
    }

    print('DEBUG_FLUTTER: userId dari SharedPreferences: $userId');

    try {
      await _absensiApi.enrollFace(userId, imagePath, token);
      setState(() {
        _isFaceEnrolled = true;
      });
      await prefs.setString('is_face_recorded', 'yes');
      _showSnackBar('Wajah Anda berhasil direkam!', Colors.green);
    } catch (e) {
      print('DEBUG_FLUTTER: Error saat _processFaceEnrollment: $e');
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      _showSnackBar(errorMessage, Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 120,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.lightBlue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade800.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 40.0, left: 24.0, right: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Halo, ${_username ?? 'User'}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Siap untuk absensi hari ini?',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
            child: AnimatedOpacity(
              opacity: _fadeInAnimation.value,
              duration: _animationController.duration!,
              child: const Text(
                'Daftar Kelas Anda',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoadingData
                ? Center(
                    child: CircularProgressIndicator(color: Colors.blue.shade800),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700, size: 80),
                              const SizedBox(height: 20),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _fetchMahasiswaData,
                                icon: const Icon(Icons.replay, color: Colors.white),
                                label: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontSize: 16)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade800,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                                  elevation: 5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _mahasiswaList.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.info_outline, color: Colors.grey.shade400, size: 80),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Tidak ada data kelas yang dapat ditampilkan saat ini.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            itemCount: _mahasiswaList.length,
                            itemBuilder: (context, index) {
                              final mahasiswa = _mahasiswaList[index];

                              final todayAbsen = _absensiHistoryList.firstWhere(
                                (item) => item.idKelas == mahasiswa['id'].toString() &&
                                    item.idMahasiswa == _userId &&
                                    item.tanggal == DateFormat('d MMM yyyy').format(DateTime.now()), // Updated date format
                                orElse: () => AbsensiHistoryItem(
                                  id: '',
                                  tanggal: '',
                                  namaKelas: '',
                                  idKelas: '',
                                  idMahasiswa: '',
                                  statusKehadiran: '',
                                  waktuAbsenMasuk: null,
                                  waktuAbsenPulang: null,
                                ),
                              );

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                elevation: 8,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                shadowColor: Colors.blue.shade100.withOpacity(0.7),
                                child: InkWell(
                                  onTap: () => _showKelasEntryConfirmation(mahasiswa),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mahasiswa['nama_kelas'] ?? 'Nama Kelas Tidak Diketahui',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Divider(color: Colors.black12, thickness: 1),
                                        const SizedBox(height: 10),
                                        InfoRow(Icons.book_outlined, 'Kode Kelas', mahasiswa['kode_kelas']),
                                        const SizedBox(height: 8),
                                        InfoRow(
                                          Icons.access_time,
                                          'Jam Masuk (Hari Ini)',
                                          todayAbsen.waktuAbsenMasuk != null && todayAbsen.waktuAbsenMasuk!.isNotEmpty
                                              ? todayAbsen.waktuAbsenMasuk!
                                              : 'Belum absen',
                                        ),
                                        const SizedBox(height: 8),
                                        InfoRow(
                                          Icons.access_time_filled,
                                          'Jam Pulang (Hari Ini)',
                                          todayAbsen.waktuAbsenPulang != null && todayAbsen.waktuAbsenPulang!.isNotEmpty
                                              ? todayAbsen.waktuAbsenPulang!
                                              : 'Belum absen',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.lock_clock),
            label: 'Absensi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey.shade600,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
