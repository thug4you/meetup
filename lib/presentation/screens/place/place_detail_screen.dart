import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/place.dart';
import '../../../data/models/place_review.dart';
import '../../../data/models/place_photo.dart';
import '../../../data/services/meeting_service.dart';
import '../../widgets/place_reviews_widget.dart';

class PlaceDetailScreen extends StatefulWidget {
  final Place place;

  const PlaceDetailScreen({super.key, required this.place});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  late MeetingService _meetingService;
  PlaceRating? _rating;
  List<PlaceReview> _reviews = [];
  List<PlacePhoto> _photos = [];
  bool _isLoading = true;
  int _selectedPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _meetingService = context.read<MeetingService>();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final rating = await _meetingService.getPlaceRating(widget.place.id);
      final reviews = await _meetingService.getPlaceReviews(widget.place.id);
      final photos = await _meetingService.getPlacePhotos(widget.place.id);

      setState(() {
        _rating = rating;
        _reviews = reviews;
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Функция поделиться будет добавлена')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: [
            // Галерея фото
            _buildPhotoGallery(),

            // Информация о месте
            _buildPlaceInfo(),

            // Рейтинг и отзывы
            if (_rating != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: PlaceReviewsWidget(
                  rating: _rating!,
                  reviews: _reviews,
                  isLoading: _isLoading,
                  onRefresh: _loadData,
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGallery() {
    if (_photos.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(Icons.image, size: 64, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // Основное фото
        SizedBox(
          height: 250,
          child: Image.network(
            _photos[_selectedPhotoIndex].photoUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image, size: 64),
              );
            },
          ),
        ),

        // Миниатюры
        if (_photos.length > 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: List.generate(
                _photos.length,
                (index) => GestureDetector(
                  onTap: () => setState(() => _selectedPhotoIndex = index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedPhotoIndex == index
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.network(
                        _photos[index].photoUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Информация о фото
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: _photos[_selectedPhotoIndex].userAvatarUrl != null
                    ? NetworkImage(_photos[_selectedPhotoIndex].userAvatarUrl!)
                    : null,
                child: _photos[_selectedPhotoIndex].userAvatarUrl == null
                    ? const Icon(Icons.person, size: 16)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _photos[_selectedPhotoIndex].userName ?? 'Пользователь',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Название и категория
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.place.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.place.category,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Адрес
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.place.address,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Средний чек
          if (widget.place.averageBill != null)
            Row(
              children: [
                const Icon(Icons.payments, size: 18, color: AppTheme.textSecondaryColor),
                const SizedBox(width: 8),
                Text(
                  'Средний чек: ${widget.place.averageBill!.toStringAsFixed(0)}₽',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Кнопка запустить встречу
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, widget.place);
              },
              child: const Text('Выбрать это место'),
            ),
          ),
        ],
      ),
    );
  }
}
