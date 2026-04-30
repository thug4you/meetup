import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/meeting_service.dart';
import '../../../data/models/place.dart';
import '../map/map_picker_screen.dart';
import '../venue/venue_search_screen.dart';

import '../../../data/models/meeting.dart';
import '../../providers/meeting_provider.dart';

class CreateMeetingScreen extends StatefulWidget {
  final Meeting? initialMeeting;

  const CreateMeetingScreen({super.key, this.initialMeeting});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();

  String? _selectedCategory;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late int _duration;
  late int _maxParticipants;
  double? _budget;
  Place? _selectedPlace;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMeeting != null) {
      final m = widget.initialMeeting!;
      _titleController.text = m.title;
      _descriptionController.text = m.description;
      _selectedCategory = m.category;
      _selectedDate = m.startTime;
      _selectedTime = TimeOfDay.fromDateTime(m.startTime);
      _duration = m.durationMinutes;
      _maxParticipants = m.maxParticipants;
      _budget = m.budget;
      _budgetController.text = m.budget?.toStringAsFixed(0) ?? '';
      _selectedPlace = m.place;
    } else {
      _selectedDate = DateTime.now().add(const Duration(hours: 1));
      _selectedTime = TimeOfDay.now();
      _duration = 60;
      _maxParticipants = 5;
      _budget = null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _selectPlace() async {
    final place = await Navigator.push<Place>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialPlace: _selectedPlace,
          initialLatitude: _selectedPlace?.latitude,
          initialLongitude: _selectedPlace?.longitude,
        ),
      ),
    );

    if (place != null) {
      setState(() {
        _selectedPlace = place;
      });
    }
  }

  Future<void> _searchVenue() async {
    final preferences = await _showVenuePreferencesSheet();
    if (preferences == null) {
      return;
    }

    final place = await Navigator.push<Place>(
      context,
      MaterialPageRoute(
        builder: (context) => VenueSearchScreen(
          initialBudgetPerPerson: preferences['budgetPerPerson'] as double?,
          initialParticipants: preferences['participants'] as int?,
          initialRadiusKm: preferences['radiusKm'] as double?,
        ),
      ),
    );

    if (place != null) {
      setState(() {
        _selectedPlace = place;
      });
    }
  }

  Future<void> _createMeeting() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите категорию'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_selectedDate.isBefore(DateTime.now()) && widget.initialMeeting == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нельзя выбрать прошедшее время'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final meetingService = context.read<MeetingService>();
      
      Meeting returnedMeeting;

      if (widget.initialMeeting != null) {
        returnedMeeting = await meetingService.updateMeeting(
          widget.initialMeeting!.id,
          {
            'title': _titleController.text,
            'description': _descriptionController.text,
            'categoryId': _selectedCategory,
            'dateTime': _selectedDate.toIso8601String(),
            'duration': _duration,
            'maxParticipants': _maxParticipants,
            'budget': _budget,
            if (_selectedPlace != null) 'placeId': _selectedPlace!.id,
          },
        );
      } else {
        returnedMeeting = await meetingService.createMeeting(
          title: _titleController.text,
          description: _descriptionController.text,
          category: _selectedCategory!,
          dateTime: _selectedDate,
          duration: _duration,
          maxParticipants: _maxParticipants,
          placeId: _selectedPlace?.id, // Место теперь опциональное
          budget: _budget,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialMeeting != null ? 'Встреча обновлена!' : 'Встреча создана успешно!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, returnedMeeting); // Возвращаем саму встречу
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showVenuePreferencesSheet() async {
    final budgetController = TextEditingController(text: _budgetController.text);
    double radiusKm = 5.0;
    int participants = _maxParticipants;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.dividerColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Параметры заведения', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Подбери место под размер компании и бюджет, а потом уже выбирай заведение.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: budgetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Бюджет на человека, ₽',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Сколько людей идёт: $participants', style: Theme.of(context).textTheme.titleMedium),
                  Slider(
                    value: participants.toDouble(),
                    min: 2,
                    max: 20,
                    divisions: 18,
                    label: '$participants',
                    onChanged: (value) {
                      setModalState(() => participants = value.toInt());
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('Радиус поиска: ${radiusKm.toStringAsFixed(0)} км', style: Theme.of(context).textTheme.titleMedium),
                  Slider(
                    value: radiusKm,
                    min: 1,
                    max: 25,
                    divisions: 24,
                    label: '${radiusKm.toStringAsFixed(0)} км',
                    onChanged: (value) {
                      setModalState(() => radiusKm = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final budgetValue = double.tryParse(budgetController.text.replaceAll(',', '.'));
                        Navigator.pop(context, {
                          'budgetPerPerson': budgetValue,
                          'participants': participants,
                          'radiusKm': radiusKm,
                        });
                      },
                      child: const Text('Продолжить поиск'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    budgetController.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialMeeting != null ? 'Редактировать встречу' : 'Создать встречу'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Название
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название встречи',
                hintText: 'Например: Вечерняя прогулка',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите название';
                }
                if (value.length < 3) {
                  return 'Минимум 3 символа';
                }
                return null;
              },
              maxLength: 100,
            ),

            const SizedBox(height: 16),

            // Категория
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Категория',
                prefixIcon: Icon(Icons.category),
              ),
              items: AppConstants.meetingCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Выберите категорию';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Описание
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                hintText: 'Расскажите о встрече подробнее...',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 500,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Добавьте описание';
                }
                if (value.length < 10) {
                  return 'Минимум 10 символов';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Бюджет на человека, ₽',
                hintText: 'Например: 1200',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              onChanged: (value) {
                _budget = double.tryParse(value.replaceAll(',', '.'));
              },
            ),

            const SizedBox(height: 24),

            // Место — информация о выбранном
            if (_selectedPlace != null) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.place, color: AppTheme.primaryColor),
                  title: Text(
                    _selectedPlace!.name,
                    style: const TextStyle(color: AppTheme.textPrimaryColor),
                  ),
                  subtitle: Text(_selectedPlace!.address),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() => _selectedPlace = null);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Кнопки выбора места
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _searchVenue,
                    icon: const Icon(Icons.search),
                    label: const Text('Поиск заведения'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectPlace,
                    icon: const Icon(Icons.map),
                    label: const Text('Точка на карте'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Дата
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                title: const Text('Дата'),
                subtitle: Text(
                  DateFormat('dd MMMM yyyy', 'ru').format(_selectedDate),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectDate,
              ),
            ),

            const SizedBox(height: 8),

            // Время
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time, color: AppTheme.primaryColor),
                title: const Text('Время'),
                subtitle: Text(_selectedTime.format(context)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectTime,
              ),
            ),

            const SizedBox(height: 16),

            // Продолжительность
            Text(
              'Продолжительность: $_duration мин',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _duration.toDouble(),
              min: 15,
              max: 480,
              divisions: 31,
              label: '$_duration мин',
              onChanged: (value) {
                setState(() => _duration = value.toInt());
              },
            ),

            const SizedBox(height: 16),

            // Количество участников
            Text(
              'Максимум участников: $_maxParticipants',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _maxParticipants.toDouble(),
              min: 2,
              max: 50,
              divisions: 48,
              label: '$_maxParticipants',
              onChanged: (value) {
                setState(() => _maxParticipants = value.toInt());
              },
            ),

            const SizedBox(height: 32),

            // Кнопка создать
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createMeeting,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(widget.initialMeeting != null ? 'Сохранить изменения' : 'Создать встречу'),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
