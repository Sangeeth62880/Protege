import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/resource_models.dart';
import '../../../widgets/resources/article_resource_card.dart';

class ArticlesTab extends StatelessWidget {
  final List<ArticleResource> articles;

  const ArticlesTab({
    super.key,
    required this.articles,
  });

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.article_outlined, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No articles available yet.',
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
      itemCount: articles.length,
      itemBuilder: (context, index) {
        return ArticleResourceCard(article: articles[index]);
      },
    );
  }
}
