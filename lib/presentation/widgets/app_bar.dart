import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final bool centerTitle;
  final double elevation;

  const CustomAppBar({
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.leading,
    this.bottom,
    this.backgroundColor,
    this.centerTitle = true,
    this.elevation = 0,
    super.key,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = ref.read(navigationServiceProvider);
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      leading: showBackButton && canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: navigationService.pop,
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          : leading,
      actions: actions?.map((action) {
        if (action is IconButton) {
          return IconButton(
            icon: action.icon,
            onPressed: action.onPressed,
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
        return action;
      }).toList(),
      bottom: bottom,
    );
  }
}

class SearchAppBar extends CustomAppBar {
  final TextEditingController searchController;
  final Function(String) onSearch;
  final VoidCallback onClear;
  final String searchHint;

  SearchAppBar({
    required String title,
    required this.searchController,
    required this.onSearch,
    required this.onClear,
    this.searchHint = 'Search...',
    List<Widget>? actions,
    super.key,
  }) : super(
          title: title,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: _SearchBar(
              controller: searchController,
              onSearch: onSearch,
              onClear: onClear,
              hintText: searchHint,
            ),
          ),
          actions: actions,
        );
}

class _SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final VoidCallback onClear;
  final String hintText;

  const _SearchBar({
    required this.controller,
    required this.onSearch,
    required this.onClear,
    required this.hintText,
  });

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        child: TextField(
          controller: widget.controller,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onClear();
                      setState(() {});
                    },
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (value) {
            widget.onSearch(value);
            setState(() {});
          },
        ),
      ),
    );
  }
}

class ActionAppBar extends CustomAppBar {
  final List<AppBarAction> appBarActions;

  ActionAppBar({
    required String title,
    required this.appBarActions,
    bool showBackButton = true,
    Widget? leading,
    super.key,
  }) : super(
          title: title,
          showBackButton: showBackButton,
          leading: leading,
          actions: appBarActions.map((action) => _buildAction(action)).toList(),
        );

  static Widget _buildAction(AppBarAction action) {
    return Builder(
      builder: (context) {
        switch (action.type) {
          case AppBarActionType.icon:
            return IconButton(
              icon: Icon(action.icon),
              onPressed: action.onPressed,
              tooltip: action.tooltip,
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          case AppBarActionType.menu:
            return PopupMenuButton<String>(
              icon: Icon(action.icon ?? Icons.more_vert),
              tooltip: action.tooltip,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              itemBuilder: (context) {
                return action.menuItems!.map((item) {
                  return PopupMenuItem<String>(
                    value: item.value,
                    child: Row(
                      children: [
                        if (item.icon != null) ...[
                          Icon(
                            item.icon,
                            size: 20,
                            color: item.isDestructive
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          item.title,
                          style: TextStyle(
                            color: item.isDestructive
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },
              onSelected: action.onMenuSelected,
            );
        }
      },
    );
  }
}

enum AppBarActionType { icon, menu }

class AppBarAction {
  final AppBarActionType type;
  final IconData? icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final List<AppBarMenuItem>? menuItems;
  final Function(String)? onMenuSelected;

  const AppBarAction.icon({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  })  : type = AppBarActionType.icon,
        menuItems = null,
        onMenuSelected = null;

  const AppBarAction.menu({
    this.icon = Icons.more_vert,
    required this.menuItems,
    required this.onMenuSelected,
    this.tooltip,
  })  : type = AppBarActionType.menu,
        onPressed = null;
}

class AppBarMenuItem {
  final String value;
  final String title;
  final IconData? icon;
  final bool isDestructive;

  const AppBarMenuItem({
    required this.value,
    required this.title,
    this.icon,
    this.isDestructive = false,
  });
}