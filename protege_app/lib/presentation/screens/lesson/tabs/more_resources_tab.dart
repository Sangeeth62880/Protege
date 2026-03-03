import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/resource_models.dart';

/// Tab for displaying additional resources: Books, Q&A, Courses, Docs
class MoreResourcesTab extends StatelessWidget {
  final List<BookResource> books;
  final List<QAResource> questions;
  final List<CourseResource> courses;
  final List<DocResource> docs;

  const MoreResourcesTab({
    super.key,
    this.books = const [],
    this.questions = const [],
    this.courses = const [],
    this.docs = const [],
  });

  bool get isEmpty => books.isEmpty && questions.isEmpty && courses.isEmpty && docs.isEmpty;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_books_outlined, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No additional resources yet.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Books Section
        if (books.isNotEmpty) ...[
          _sectionHeader(context, Icons.menu_book, 'Books', Colors.brown),
          ...books.map((b) => _buildBookCard(context, b)),
          const SizedBox(height: 20),
        ],

        // Courses Section
        if (courses.isNotEmpty) ...[
          _sectionHeader(context, Icons.school, 'Courses', Colors.blue),
          ...courses.map((c) => _buildCourseCard(context, c)),
          const SizedBox(height: 20),
        ],

        // Q&A Section
        if (questions.isNotEmpty) ...[
          _sectionHeader(context, Icons.help_outline, 'Q&A', Colors.orange),
          ...questions.map((q) => _buildQACard(context, q)),
          const SizedBox(height: 20),
        ],

        // Documentation Section
        if (docs.isNotEmpty) ...[
          _sectionHeader(context, Icons.description_outlined, 'Documentation', Colors.teal),
          ...docs.map((d) => _buildDocCard(context, d)),
        ],
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, BookResource book) {
    return _ResourceCard(
      title: book.title,
      subtitle: '${book.author}${book.year != null ? ' · ${book.year}' : ''}',
      url: book.url,
      icon: Icons.menu_book,
      iconColor: Colors.brown,
      coverImage: book.coverImage,
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseResource course) {
    return _ResourceCard(
      title: course.title,
      subtitle: course.workload ?? 'Online Course',
      url: course.url,
      icon: Icons.school,
      iconColor: Colors.blue,
      coverImage: course.coverImage,
    );
  }

  Widget _buildQACard(BuildContext context, QAResource qa) {
    return _ResourceCard(
      title: qa.title,
      subtitle: '${qa.score} votes · ${qa.answerCount} answers',
      url: qa.url,
      icon: Icons.forum_outlined,
      iconColor: Colors.orange,
    );
  }

  Widget _buildDocCard(BuildContext context, DocResource doc) {
    return _ResourceCard(
      title: doc.title,
      subtitle: doc.description.isNotEmpty ? doc.description : 'MDN Web Docs',
      url: doc.url,
      icon: Icons.description_outlined,
      iconColor: Colors.teal,
    );
  }
}

/// Reusable resource card widget
class _ResourceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String url;
  final IconData icon;
  final Color iconColor;
  final String? coverImage;

  const _ResourceCard({
    required this.title,
    required this.subtitle,
    required this.url,
    required this.icon,
    required this.iconColor,
    this.coverImage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          if (url.isNotEmpty) {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover image or icon
              if (coverImage != null && coverImage!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    coverImage!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _iconWidget(),
                  ),
                )
              else
                _iconWidget(),
              const SizedBox(width: 12),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, size: 16, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconWidget() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }
}
