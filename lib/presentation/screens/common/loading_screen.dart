import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';

class LoadingScreen extends ConsumerWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repositoryState = ref.watch(repositoryStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (repositoryState.status == RepositoryStatus.initializing)
                const CircularProgressIndicator(),
              if (repositoryState.status == RepositoryStatus.error)
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
              const SizedBox(height: 16),
              Text(
                switch (repositoryState.status) {
                  RepositoryStatus.uninitialized => 'Starting up...',
                  RepositoryStatus.initializing => 'Initializing database...',
                  RepositoryStatus.error => 'Initialization failed',
                  RepositoryStatus.initialized => 'Ready!',
                },
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (repositoryState.error != null) ...[  
                const SizedBox(height: 8),
                Text(
                  repositoryState.error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (repositoryState.status == RepositoryStatus.error) ...[  
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.read(repositoryStateProvider.notifier).retry();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}