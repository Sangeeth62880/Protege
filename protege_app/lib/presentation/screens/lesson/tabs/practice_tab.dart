import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/resource_models.dart';
import '../../../widgets/resources/github_resource_card.dart';

class PracticeTab extends StatelessWidget {
  final List<GithubResource> repositories;

  const PracticeTab({
    super.key,
    required this.repositories,
  });

  @override
  Widget build(BuildContext context) {
    if (repositories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.code, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No practice repositories found.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: repositories.length,
      itemBuilder: (context, index) {
        return GithubResourceCard(repo: repositories[index]);
      },
    );
  }
}
