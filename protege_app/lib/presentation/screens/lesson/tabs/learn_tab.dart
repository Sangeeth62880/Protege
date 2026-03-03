import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/lesson_content_model.dart';
import '../../../../data/models/resource_models.dart';

class LearnTab extends StatelessWidget {
  final LessonExplanation explanation;
  final WikipediaResource? wikipedia;

  const LearnTab({
    super.key,
    required this.explanation,
    this.wikipedia,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Wikipedia Overview Card (if available)
        if (wikipedia != null) ...[
          _buildWikipediaCard(context, wikipedia!),
          const SizedBox(height: 20),
        ],

        // Introduction
        _buildSectionTitle(context, 'Introduction'),
        const SizedBox(height: 8),
        Text(
          explanation.introduction,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
        ),
        const SizedBox(height: 24),

        // Key Takeaways
        if (explanation.keyTakeaways.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Key Takeaways',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...explanation.keyTakeaways.map((takeaway) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              takeaway,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Sections
        ...explanation.sections.map((section) => _buildContentSection(context, section)),

        // Summary
        const Divider(height: 32),
        _buildSectionTitle(context, 'Summary'),
        const SizedBox(height: 8),
        Text(
          explanation.summary,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontStyle: FontStyle.italic,
              ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildContentSection(BuildContext context, ContentSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        MarkdownBody(
          data: section.content,
          styleSheet: MarkdownStyleSheet(
            p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
        ),
        if (section.codeExample != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (section.language != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      section.language!.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textOnDark.withValues(alpha: 0.7),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                SelectableText(
                  section.codeExample!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: AppColors.textOnDark,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildWikipediaCard(BuildContext context, WikipediaResource wiki) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/Wikipedia-logo-v2.svg/44px-Wikipedia-logo-v2.svg.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.menu_book_outlined,
                    size: 24,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    wiki.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Wikipedia',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),

          // Summary text
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              wiki.description,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
            ),
          ),

          // Read more link
          if (wiki.url.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: InkWell(
                onTap: () async {
                  final uri = Uri.parse(wiki.url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Read full article on Wikipedia',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
