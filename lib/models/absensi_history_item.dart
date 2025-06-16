class AbsensiHistoryItem {
  final String id;
  final String tanggal;
  final String namaKelas;
  final String idKelas;
  final String idMahasiswa;
  final String? waktuAbsenMasuk;
  final String? waktuAbsenPulang;
  final String statusKehadiran;

  AbsensiHistoryItem({
    required this.id,
    required this.tanggal,
    required this.namaKelas,
    required this.idKelas,
    required this.idMahasiswa,
    this.waktuAbsenMasuk,
    this.waktuAbsenPulang,
    required this.statusKehadiran,
  });

  factory AbsensiHistoryItem.fromJson(Map<String, dynamic> json) {
    return AbsensiHistoryItem(
      id: json['id'].toString(),
      tanggal: json['tanggal'],
      namaKelas: json['nama_kelas'],
      idMahasiswa: json['id_mahasiswa'].toString(),
      idKelas: json['id_kelas'].toString(),
      waktuAbsenMasuk: json['waktu_absen_masuk'],
      waktuAbsenPulang: json['waktu_absen_pulang'],
      statusKehadiran: json['status_kehadiran'],
    );
  }
}
