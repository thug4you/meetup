import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/meeting.dart';
import '../../../data/services/meeting_service.dart';

class ReviewMeetingScreen extends StatefulWidget {
  final Meeting meeting;

  const ReviewMeetingScreen({super.key, required this.meeting});

  @override
  State<ReviewMeetingScreen> createState() => _ReviewMeetingScreenState();
}

class _ReviewMeetingScreenState extends State<ReviewMeetingScreen> {
  late int _rating;
  final _reviewController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _rating = 5;
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating < 1 || _rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите рейтинг'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final meetingService = context.read<MeetingService>();
      await meetingService.createReview(
        placeId: widget.meeting.place.id,
        rating: _rating,
        text: _reviewController.text.isNotEmpty ? _reviewController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Спасибо за отзыв!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оценить место'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информация о месте
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.meeting.place.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.meeting.place.address,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Рейтинг
            Text(
              'Ваша оценка',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  iconSize: 48,
                  icon: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: () => setState(() => _rating = star),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Текст отзыва
            Text(
              'Ваш отзыв (опционально)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reviewController,
              decoration: const InputDecoration(
                labelText: 'Напишите что-нибудь о месте...',
                hintText: 'Атмосфера, качество, рекомендации...',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 500,
            ),

            const SizedBox(height: 24),

            // Кнопка отправить
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReview,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Отправить отзыв'),
              ),
            ),

            const SizedBox(height: 16),

            // Кнопка пропустить
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Пропустить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
