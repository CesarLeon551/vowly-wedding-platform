import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'invitation_style.dart';

class NavItem {
  const NavItem(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;
}

/// Barra fija superior: monograma a la izquierda, enlaces a las
/// secciones a la derecha (con subrayado en la sección activa). En
/// pantallas angostas los enlaces pasan a un menú lateral.
class InvitationNav extends StatelessWidget {
  const InvitationNav({
    super.key,
    required this.monogram,
    required this.items,
    required this.activeIndex,
    required this.onMenuTap,
  });

  final String monogram;
  final List<NavItem> items;
  final ValueListenable<int> activeIndex;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 1000;

    return Container(
      height: InvitationStyle.navHeight,
      color: InvitationStyle.burgundyDark.withOpacity(0.97),
      padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 20),
      child: Row(
        children: [
          Text(
            monogram,
            style: InvitationStyle.display(26, color: InvitationStyle.ivory)
                .copyWith(letterSpacing: 2),
          ),
          const Spacer(),
          if (isWide)
            ValueListenableBuilder<int>(
              valueListenable: activeIndex,
              builder: (context, active, _) => Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    _NavLink(item: items[i], active: i == active),
                ],
              ),
            )
          else
            IconButton(
              onPressed: onMenuTap,
              tooltip: 'Menú',
              icon: const Icon(Icons.menu, color: InvitationStyle.ivory),
            ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.item, required this.active});

  final NavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.only(bottom: 3),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? InvitationStyle.ivory : Colors.transparent,
              ),
            ),
          ),
          child: Text(
            item.label,
            style: InvitationStyle.body(size: 16, color: InvitationStyle.ivory),
          ),
        ),
      ),
    );
  }
}
