import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CartHeader extends StatefulWidget {
  const CartHeader({super.key, this.kodeTransaksi, this.kasir});
  final kodeTransaksi;
  final kasir;

  @override
  State<CartHeader> createState() => _CartHeaderState();
}

class _CartHeaderState extends State<CartHeader> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3A7CF5),
            Color(0xFF1D61E7),
            Color(0xFF164CB7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D61E7).withOpacity(0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Kasir: ${widget.kasir}", style: const TextStyle(color: Colors.white)),
          Text(DateFormat('HH:mm:ss dd/MM/yy').format(_currentTime), style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
