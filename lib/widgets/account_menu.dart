import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import 'dialogs.dart';

enum _AccountAction { orders, adminOrders, categories, signOut }

class AccountMenu extends ConsumerWidget {
  const AccountMenu({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authControllerProvider).signOut();
    } catch (error) {
      if (context.mounted) showErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final isAdmin = profile?.isAdmin ?? false;

    return PopupMenuButton<_AccountAction>(
      tooltip: 'Account',
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (action) {
        switch (action) {
          case _AccountAction.orders:
            context.push('/orders');
          case _AccountAction.adminOrders:
            context.push('/admin/orders');
          case _AccountAction.categories:
            context.push('/admin/categories');
          case _AccountAction.signOut:
            _signOut(context, ref);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<_AccountAction>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile?.displayName ?? 'Signed in',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (profile?.email != null) Text(profile!.email!),
              const SizedBox(height: 4),
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(isAdmin ? 'Admin' : 'Customer'),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        if (isAdmin) ...const [
          PopupMenuItem(
            value: _AccountAction.adminOrders,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.receipt_long_outlined),
              title: Text('Manage Orders'),
            ),
          ),
          PopupMenuItem(
            value: _AccountAction.categories,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.category_outlined),
              title: Text('Categories'),
            ),
          ),
        ] else
          const PopupMenuItem(
            value: _AccountAction.orders,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.receipt_long_outlined),
              title: Text('My Orders'),
            ),
          ),
        const PopupMenuItem(
          value: _AccountAction.signOut,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('Sign Out'),
          ),
        ),
      ],
    );
  }
}
