import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/supabase_service.dart';
import '../../../data/services/user_card_repository.dart';

/// Routes to Card Details if claimed, otherwise Get / Claim flow.
Future<void> openMyZepCard(BuildContext context, WidgetRef ref) async {
  if (!SupabaseService.instance.isReady) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Supabase is not configured — add URL and anon key to link a Zep Card.',
        ),
      ),
    );
    context.push('/get-zep-card');
    return;
  }

  final card = await ref.read(userCardProvider.future);
  if (!context.mounted) return;
  if (card != null) {
    context.push('/my-zep-card');
  } else {
    context.push('/get-zep-card');
  }
}
