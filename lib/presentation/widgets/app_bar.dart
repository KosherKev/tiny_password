import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.leading,
    this.bottom,
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
      title: Text(title),
      centerTitle: true,
      leading: showBackButton && canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: navigationService.pop,
            )
          : leading,
      actions: actions,
      bottom: bottom,
      elevation: bottom != null ? 4 : 0,
    );
  }
}

class SearchAppBar extends CustomAppBar {
  final TextEditingController searchController;
  final Function(String) onSearch;
  final VoidCallback onClear;

  SearchAppBar({
    required String title,
    required this.searchController,
    required this.onSearch,
    required this.onClear,
    List<Widget>? actions,
    super.key,
  }) : super(
          title: title,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: onClear,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  filled: true,
                ),
                onChanged: onSearch,
              ),
            ),
          ),
          actions: actions,
        );
}