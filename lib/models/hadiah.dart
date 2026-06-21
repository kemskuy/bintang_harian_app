import 'package:flutter/material.dart';

class Hadiah {
  String nama;
  int hargaPoin;
  bool sudahDitebus;

  Hadiah({
    required this.nama,
    required this.hargaPoin,
    this.sudahDitebus = false,
  });
}
