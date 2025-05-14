import 'package:flutter/material.dart';

class GmailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GmailAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const TextField(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search mail',
            border: InputBorder.none,
            contentPadding: EdgeInsets.only(top: 12),
          ),
        ),
      ),
      actions: [
        CircleAvatar(
          backgroundColor: Colors.orange[800],
          child: const Text('A', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
