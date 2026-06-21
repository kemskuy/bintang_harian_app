class Tugas {
  String nama;
  int poin;
  bool selesai;
  bool diverifikasi;

  Tugas({
    required this.nama,
    required this.poin,
    this.selesai = false,
    this.diverifikasi = false,
  });
}
