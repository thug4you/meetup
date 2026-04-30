import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/place_review.dart';

class PlaceReviewsWidget extends StatelessWidget {
  final PlaceRating rating;
  final List<PlaceReview> reviews;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const PlaceReviewsWidget({
    super.key,
    required this.rating,
    required this.reviews,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Общий рейтинг
        _buildRatingSummary(context),

        if (reviews.isEmpty) ...[
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Отзывов ещё нет',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 24),
          // Список отзывов
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, index) => _buildReviewCard(context, reviews[index]),
          ),
        ],
      ],
    );
  }

  Widget _buildRatingSummary(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Большой рейтинг
                Column(
                  children: [
                    Text(
                      rating.averageRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    _buildStars(rating.averageRating, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      '${rating.totalReviews} отзыв${_pluralize(rating.totalReviews)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                  ],
                ),

                const SizedBox(width: 32),

                // Распределение по звёздам
                Expanded(
                  child: Column(
                    children: List.generate(5, (index) {
                      final starCount = 5 - index;
                      final count = rating.distribution[starCount] ?? 0;
                      final percentage = rating.totalReviews > 0
                          ? (count / rating.totalReviews * 100).toStringAsFixed(0)
                          : '0';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text('$starCount★', style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: rating.totalReviews > 0 ? count / rating.totalReviews : 0,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$percentage%',
                              style: const TextStyle(fontSize: 11),
                              textAlign: TextAlign.right,
                              widthFactor: 1,
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, PlaceReview review) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Автор и рейтинг
          Row(
            children: [
              // Аватар
              CircleAvatar(
                radius: 20,
                backgroundImage: review.userAvatarUrl != null
                    ? NetworkImage(review.userAvatarUrl!)
                    : null,
                child: review.userAvatarUrl == null
                    ? Icon(Icons.person, size: 20, color: AppTheme.primaryColor)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName ?? 'Пользователь',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    _buildStars(review.rating.toDouble(), size: 14),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Текст отзыва
          if (review.text != null && review.text!.isNotEmpty) ...[
            Text(
              review.text!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
          ],

          // Дата
          Text(
            _formatDate(review.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStars(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final star = index + 1;
        return Icon(
          star <= rating.ceil() && index < rating ? Icons.star : Icons.star_border,
          color: AppTheme.primaryColor,
          size: size,
        );
      }),
    );
  }

  String _pluralize(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return '';
    } else if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
      return 'а';
    } else {
      return 'ов';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0 && date.day == now.day) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks нед. назад';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months мес. назад';
    } else {
      return '${(difference.inDays / 365).floor()} лет назад';
    }
  }
}
