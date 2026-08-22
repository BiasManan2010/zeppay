import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/semiconductor_repository.dart';

/// Resolves an NFC tag id to a chip detail route.
class ChipNfcRouteScreen extends ConsumerStatefulWidget {
  const ChipNfcRouteScreen({super.key, required this.nfcId});

  final String nfcId;

  @override
  ConsumerState<ChipNfcRouteScreen> createState() => _ChipNfcRouteScreenState();
}

class _ChipNfcRouteScreenState extends ConsumerState<ChipNfcRouteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    try {
      final chipId = await SemiconductorRepository.instance
          .chipIdForNfcTag(widget.nfcId);
      if (!mounted) return;
      if (chipId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unknown chip batch tag')),
        );
        context.go('/inventory-overview');
        return;
      }
      context.replace('/chip/$chipId?nfc=1');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not resolve tag: $e')),
      );
      context.go('/inventory-overview');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
