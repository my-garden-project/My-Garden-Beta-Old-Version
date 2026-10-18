import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_state.dart';
import '../app_theme.dart';
import '../diary/photo_storage.dart';
import '../models.dart';
import '../storage.dart';

class GardenDiaryScreen extends StatelessWidget {
  final String gardenId;

  const GardenDiaryScreen({super.key, required this.gardenId});

  @override
  Widget build(BuildContext context) {
    final state = InheritedAppState.of(context).state;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final garden = state.gardens.firstWhere((item) => item.id == gardenId);
        final entries = state.diaryEntries
            .where((entry) => entry.gardenId == gardenId)
            .toList()
          ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Щоденник городу',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
            children: [
              _DiaryIntro(gardenName: garden.name),
              const SizedBox(height: 16),
              if (entries.isEmpty)
                const _EmptyDiary()
              else
                for (final entry in entries) ...[
                  _DiaryCard(
                    entry: entry,
                    crop: state.crops
                        .where((crop) => crop.id == entry.cropId)
                        .firstOrNull,
                    onEdit: () => _openEditor(context, entry),
                    onDelete: () => _delete(context, state, entry),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
          floatingActionButton: MediaQuery.sizeOf(context).width < 390
              ? FloatingActionButton.small(
                  key: const Key('add-diary-entry'),
                  tooltip: 'Додати фото або нотатку про рослини та врожай',
                  onPressed: () => _openEditor(context, null),
                  child: const Icon(Icons.add_a_photo_outlined),
                )
              : FloatingActionButton.extended(
                  key: const Key('add-diary-entry'),
                  tooltip: 'Додати фото або нотатку про рослини та врожай',
                  onPressed: () => _openEditor(context, null),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Додати запис'),
                ),
        );
      },
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    GardenDiaryEntry? entry,
  ) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _DiaryEntryEditor(
          gardenId: gardenId,
          existing: entry,
        ),
      );

  Future<void> _delete(
    BuildContext context,
    AppState state,
    GardenDiaryEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Видалити запис?'),
        content: const Text(
          'Нотатка та локальне фото будуть видалені з цього пристрою.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await state.deleteDiaryEntry(entry.id);
      await DiaryPhotoStorage().delete(entry.photoPath);
    } on StorageWriteException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не вдалося видалити запис.')),
      );
    }
  }
}

class _DiaryIntro extends StatelessWidget {
  final String gardenName;

  const _DiaryIntro({required this.gardenName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF6E6), Color(0xFFF8FBF5)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD2E6CC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_stories_outlined, color: AppColors.primary),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Історія росту й врожаю',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$gardenName: фіксуйте посів, сходи, догляд, проблеми та врожай. '
            'Запис можна прив’язати до культури й клітинки сітки.',
            style: const TextStyle(height: 1.4),
          ),
          const SizedBox(height: 8),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, size: 18),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Фото залишаються на пристрої. Для майбутнього каталогу '
                  'потрібно окремо дозволити конкретний знімок.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyDiary extends StatelessWidget {
  const _EmptyDiary();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(
            Icons.photo_camera_back_outlined,
            size: 68,
            color: AppColors.primary.withValues(alpha: 0.75),
          ),
          const SizedBox(height: 14),
          const Text(
            'Першого запису ще немає',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          const Text(
            'Почніть зі світлини посадки, сходів або врожаю.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  final GardenDiaryEntry entry;
  final Crop? crop;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DiaryCard({
    required this.entry,
    required this.crop,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final path = entry.photoPath;
    final hasPhoto = path != null && File(path).existsSync();
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPhoto)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: AppColors.softGreen,
                  child: Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.softGreen,
                  foregroundColor: AppColors.primary,
                  child: Icon(_diaryIcon(entry.type)),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diaryEntryTypeLabel(entry.type),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _entryDetails(entry, crop),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (entry.note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(entry.note),
                      ],
                      if (entry.shareForResearch || entry.shareForCatalog) ...[
                        const SizedBox(height: 9),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (entry.shareForResearch)
                              const Chip(
                                avatar: Icon(Icons.science_outlined, size: 17),
                                label: Text('Для дослідження'),
                              ),
                            if (entry.shareForCatalog)
                              const Chip(
                                avatar: Icon(
                                    Icons.collections_bookmark_outlined,
                                    size: 17),
                                label: Text('Для каталогу'),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Дії із записом',
                  onSelected: (value) =>
                      value == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Редагувати')),
                    PopupMenuItem(value: 'delete', child: Text('Видалити')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _entryDetails(GardenDiaryEntry entry, Crop? crop) {
    final date = '${entry.capturedAt.day.toString().padLeft(2, '0')}.'
        '${entry.capturedAt.month.toString().padLeft(2, '0')}.'
        '${entry.capturedAt.year}';
    final parts = <String>[date];
    if (crop != null) parts.add(crop.name);
    if (entry.row != null) {
      parts.add('клітинка ${_columnName(entry.col!)}${entry.row! + 1}');
    }
    return parts.join(' • ');
  }
}

class _DiaryEntryEditor extends StatefulWidget {
  final String gardenId;
  final GardenDiaryEntry? existing;

  const _DiaryEntryEditor({required this.gardenId, this.existing});

  @override
  State<_DiaryEntryEditor> createState() => _DiaryEntryEditorState();
}

class _DiaryEntryEditorState extends State<_DiaryEntryEditor> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _photos = DiaryPhotoStorage();
  late DateTime _date;
  late DiaryEntryType _type;
  String? _cropId;
  int? _row;
  int? _col;
  XFile? _pickedPhoto;
  bool _removeExistingPhoto = false;
  bool _shareForResearch = false;
  bool _shareForCatalog = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _date = existing?.capturedAt ?? DateTime.now();
    _type = existing?.type ?? DiaryEntryType.growth;
    _cropId = existing?.cropId;
    _row = existing?.row;
    _col = existing?.col;
    _shareForResearch = existing?.shareForResearch ?? false;
    _shareForCatalog = existing?.shareForCatalog ?? false;
    _noteController.text = existing?.note ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _hasPhoto =>
      _pickedPhoto != null ||
      (!_removeExistingPhoto && widget.existing?.photoPath != null);

  @override
  Widget build(BuildContext context) {
    final state = InheritedAppState.of(context).state;
    final garden =
        state.gardens.firstWhere((item) => item.id == widget.gardenId);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 8, 18, 18 + bottom),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.existing == null
                        ? 'Новий запис'
                        : 'Редагувати запис',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Закрити',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<DiaryEntryType>(
              key: const Key('diary-entry-type'),
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Етап / подія'),
              items: DiaryEntryType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(diaryEntryTypeLabel(type)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _cropId,
              decoration: const InputDecoration(labelText: 'Культура'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Не прив’язувати'),
                ),
                ...state.crops.map(
                  (crop) => DropdownMenuItem<String?>(
                    value: crop.id,
                    child: Text(crop.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _cropId = value),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _row,
                    decoration: const InputDecoration(labelText: 'Ряд'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('—'),
                      ),
                      for (var row = 0; row < garden.rows; row++)
                        DropdownMenuItem<int?>(
                          value: row,
                          child: Text('${row + 1}'),
                        ),
                    ],
                    onChanged: (value) => setState(() {
                      _row = value;
                      if (value == null) _col = null;
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _col,
                    decoration: const InputDecoration(labelText: 'Стовпець'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('—'),
                      ),
                      for (var col = 0; col < garden.cols; col++)
                        DropdownMenuItem<int?>(
                          value: col,
                          child: Text(_columnName(col)),
                        ),
                    ],
                    onChanged: _row == null
                        ? null
                        : (value) => setState(() => _col = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Дата спостереження'),
              subtitle: Text(
                '${_date.day.toString().padLeft(2, '0')}.'
                '${_date.month.toString().padLeft(2, '0')}.${_date.year}',
              ),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDate,
            ),
            TextFormField(
              key: const Key('diary-entry-note'),
              controller: _noteController,
              minLines: 2,
              maxLines: 5,
              maxLength: 800,
              decoration: const InputDecoration(
                labelText: 'Що змінилося?',
                hintText: 'Наприклад: зібрано 3 кг томатів, листя здорове…',
              ),
            ),
            const SizedBox(height: 8),
            _PhotoChooser(
              path: _pickedPhoto?.path ??
                  (_removeExistingPhoto ? null : widget.existing?.photoPath),
              onCamera: () => _pickPhoto(ImageSource.camera),
              onGallery: () => _pickPhoto(ImageSource.gallery),
              onRemove: _hasPhoto
                  ? () => setState(() {
                        _pickedPhoto = null;
                        _removeExistingPhoto = true;
                        _shareForCatalog = false;
                      })
                  : null,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8F2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Позначити для дослідження'),
                    subtitle: Text(
                      state.researchConsent
                          ? 'Добровільно; фактичне передавання ще не увімкнене'
                          : 'Спочатку увімкніть згоду в Профілі',
                    ),
                    value: state.researchConsent && _shareForResearch,
                    onChanged: state.researchConsent
                        ? (value) => setState(() => _shareForResearch = value)
                        : null,
                  ),
                  SwitchListTile(
                    title: const Text('Запропонувати фото для каталогу'),
                    subtitle: Text(
                      !state.catalogPhotoLicense
                          ? 'Спочатку увімкніть окремий дозвіл у Профілі'
                          : !_hasPhoto
                              ? 'Спочатку додайте фото'
                              : 'Лише цей вибраний кадр; авторство лишається вашим',
                    ),
                    value: state.catalogPhotoLicense &&
                        _hasPhoto &&
                        _shareForCatalog,
                    onChanged: state.catalogPhotoLicense && _hasPhoto
                        ? (value) => setState(() => _shareForCatalog = value)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('save-diary-entry'),
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Збереження…' : 'Зберегти запис'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final photo = await _photos.pick(source);
      if (photo == null || !mounted) return;
      setState(() {
        _pickedPhoto = photo;
        _removeExistingPhoto = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Камера недоступна. У симуляторі скористайтеся галереєю.'
                : 'Не вдалося відкрити галерею.',
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (_row != null && _col == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Оберіть стовпець клітинки.')),
      );
      return;
    }
    setState(() => _saving = true);
    final state = InheritedAppState.of(context).state;
    final id = widget.existing?.id ?? generateId();
    final oldPath = widget.existing?.photoPath;
    String? newPath = _removeExistingPhoto ? null : oldPath;
    String? justSavedPath;
    try {
      if (_pickedPhoto != null) {
        justSavedPath = await _photos.persist(_pickedPhoto!, id);
        newPath = justSavedPath;
      }
      final entry = GardenDiaryEntry(
        id: id,
        gardenId: widget.gardenId,
        capturedAt: _date,
        type: _type,
        note: _noteController.text.trim(),
        cropId: _cropId,
        row: _row,
        col: _col,
        photoPath: newPath,
        shareForResearch: state.researchConsent && _shareForResearch,
        shareForCatalog:
            state.catalogPhotoLicense && newPath != null && _shareForCatalog,
      );
      await state.saveDiaryEntry(entry);
      if ((oldPath != null && oldPath != newPath) ||
          (_removeExistingPhoto && oldPath != null)) {
        await _photos.delete(oldPath);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (justSavedPath != null && justSavedPath != oldPath) {
        await _photos.delete(justSavedPath);
      }
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не вдалося зберегти запис.')),
      );
    }
  }
}

class _PhotoChooser extends StatelessWidget {
  final String? path;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback? onRemove;

  const _PhotoChooser({
    required this.path,
    required this.onCamera,
    required this.onGallery,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = path != null && File(path!).existsSync();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasPhoto) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.file(File(path!), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Камера'),
              ),
              OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Галерея'),
              ),
              if (onRemove != null)
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Прибрати'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Фото зменшується до 1600 px і стискається для економії пам’яті.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

IconData _diaryIcon(DiaryEntryType type) => switch (type) {
      DiaryEntryType.sowing => Icons.grass_outlined,
      DiaryEntryType.sprout => Icons.spa_outlined,
      DiaryEntryType.growth => Icons.eco_outlined,
      DiaryEntryType.issue => Icons.pest_control_outlined,
      DiaryEntryType.treatment => Icons.health_and_safety_outlined,
      DiaryEntryType.harvest => Icons.shopping_basket_outlined,
      DiaryEntryType.note => Icons.edit_note_outlined,
    };

String _columnName(int index) {
  var value = index + 1;
  var result = '';
  while (value > 0) {
    value--;
    result = String.fromCharCode(65 + value % 26) + result;
    value ~/= 26;
  }
  return result;
}
