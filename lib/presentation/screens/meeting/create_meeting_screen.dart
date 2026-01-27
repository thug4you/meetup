import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/meeting_service.dart';
import '../../../data/models/place.dart';
import '../map/map_picker_screen.dart';

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _duration = 60;
  int _maxParticipants = 5;
  Place? _selectedPlace;
  
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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

    setState(() => _isLoading = true);

    try {
      final meetingService = context.read<MeetingService>();
      
      await meetingService.createMeeting(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory!,
        dateTime: _selectedDate,
        duration: _duration,
        maxParticipants: _maxParticipants,
        placeId: _selectedPlace?.id, // Место теперь опциональное
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Встреча создана успешно!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true); // Возвращаем true при успешном создании
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать встречу'),
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

            const SizedBox(height: 24),

            // Место
            Card(
              child: ListTile(
                leading: const Icon(Icons.place, color: AppTheme.primaryColor),
                title: Text(
                  _selectedPlace?.name ?? 'Выбрать место на карте',
                  style: TextStyle(
                    color: _selectedPlace != null ? AppTheme.textPrimaryColor : AppTheme.textHintColor,
                  ),
                ),
                subtitle: _selectedPlace != null
                    ? Text(_selectedPlace!.address)
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectPlace,
              ),
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
                    : const Text('Создать встречу'),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
