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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
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