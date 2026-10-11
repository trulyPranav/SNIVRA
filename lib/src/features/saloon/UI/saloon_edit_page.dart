import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../data/models/salon_photo_model.dart';
import '../data/repository/saloon_repo.dart';

class SaloonEditPage extends StatefulWidget {
  const SaloonEditPage({
    super.key,
    required this.saloonRepository,
    required this.saloonId,
    required this.saloonName,
  });

  final SaloonRepository saloonRepository;
  final String saloonId;
  final String saloonName;

  @override
  State<SaloonEditPage> createState() => _SaloonEditPageState();
}

class _SaloonEditPageState extends State<SaloonEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _locationNameController = TextEditingController();

  double? _lat;
  double? _lng;
  TimeOfDay _openingTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 18, minute: 0);
  bool _locating = false;
  bool _saving = false;

  List<SalonPhoto> _photos = [];
  bool _photosLoading = true;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.saloonName);
    _loadPhotos();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationNameController.dispose();
    super.dispose();
  }

  Future<void> _loadPhotos() async {
    try {
      final photos = await widget.saloonRepository.fetchPhotos(
        saloonId: widget.saloonId,
      );
      if (mounted) {
        setState(() {
          _photos = photos;
          _photosLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _photosLoading = false);
    }
  }

  Future<void> _addPhoto() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      var bytes = await picked.readAsBytes();
      bytes = await _compressToUnder5MB(bytes);

      final photo = await widget.saloonRepository.uploadPhoto(
        saloonId: widget.saloonId,
        imageBytes: bytes,
        fileName: picked.name,
        displayOrder: _photos.length,
      );

      if (mounted) setState(() => _photos = [..._photos, photo]);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapSaloonApiException(e).message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not upload photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _deletePhoto(String photoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Remove this photo from the gallery?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await widget.saloonRepository.deletePhoto(
        saloonId: widget.saloonId,
        photoId: photoId,
      );
      if (mounted) {
        setState(() => _photos = _photos.where((p) => p.id != photoId).toList());
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapSaloonApiException(e).message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete photo: $e')),
      );
    }
  }

  Future<Uint8List> _compressToUnder5MB(Uint8List bytes) async {
    const maxBytes = 5 * 1024 * 1024;
    if (bytes.length <= maxBytes) return bytes;

    for (final quality in [70, 55, 40, 25]) {
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      if (compressed.length <= maxBytes) return compressed;
    }

    throw Exception(
      'Image is too large to compress under 5 MB. Please choose a smaller image.',
    );
  }

  Future<void> _getLocation() async {
    setState(() => _locating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission denied. Enable it in device settings.',
              ),
            ),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickOpeningTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _openingTime,
      initialEntryMode: TimePickerEntryMode.dial,
    );
    if (picked != null && mounted) {
      setState(() => _openingTime = picked);
    }
  }

  Future<void> _pickClosingTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _closingTime,
      initialEntryMode: TimePickerEntryMode.dial,
    );
    if (picked != null && mounted) {
      setState(() => _closingTime = picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int _toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fetch the current location.')),
      );
      return;
    }
    if (_toMinutes(_closingTime) <= _toMinutes(_openingTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Closing time must be later than opening time.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.saloonRepository.updateSaloon(
        saloonId: widget.saloonId,
        name: _nameController.text.trim(),
        lat: _lat!,
        lng: _lng!,
        locationName: _locationNameController.text.trim().isEmpty
            ? null
            : _locationNameController.text.trim(),
        openingTime: '${_formatTime(_openingTime)}:00',
        closingTime: '${_formatTime(_closingTime)}:00',
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.read<AuthBloc>().add(const AuthUserRefreshRequested());
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Saloon details updated.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapSaloonApiException(e).message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update saloon: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text('Edit Saloon'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EditorHeader(
              saloonName: widget.saloonName,
              saloonId: widget.saloonId,
            ),
            const SizedBox(height: 16),
            _GallerySection(
              photos: _photos,
              isLoading: _photosLoading,
              isUploading: _uploadingPhoto,
              onAdd: _addPhoto,
              onDelete: _deletePhoto,
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SheetField(
                    controller: _nameController,
                    label: 'Saloon Name',
                    hint: 'e.g. Elite Barber Shop',
                    icon: Icons.storefront_outlined,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                  ),
                  const SizedBox(height: 14),
                  _SheetField(
                    controller: _locationNameController,
                    label: 'Location Name',
                    hint: 'e.g. Bandra West, Mumbai',
                    icon: Icons.place_outlined,
                    validator: null,
                  ),
                  const SizedBox(height: 14),
                  _ActionField(
                    label: 'Location Coordinates',
                    subtitle: _lat != null && _lng != null
                        ? '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}'
                        : 'No coordinates selected yet',
                    icon: _lat != null
                        ? Icons.my_location_rounded
                        : Icons.location_searching_rounded,
                    isLoading: _locating,
                    actionLabel:
                        _lat != null ? 'Refresh Location' : 'Use Current Location',
                    onTap: _getLocation,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeField(
                          label: 'Opening Time',
                          value: _formatTime(_openingTime),
                          icon: Icons.wb_sunny_outlined,
                          onTap: _pickOpeningTime,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimeField(
                          label: 'Closing Time',
                          value: _formatTime(_closingTime),
                          icon: Icons.nights_stay_outlined,
                          onTap: _pickClosingTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Gallery section
// ──────────────────────────────────────────────────────────────────────────────

class _GallerySection extends StatelessWidget {
  const _GallerySection({
    required this.photos,
    required this.isLoading,
    required this.isUploading,
    required this.onAdd,
    required this.onDelete,
  });

  final List<SalonPhoto> photos;
  final bool isLoading;
  final bool isUploading;
  final VoidCallback onAdd;
  final void Function(String photoId) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gallery Photos',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isLoading)
                Text(
                  '${photos.length} photo${photos.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (isLoading)
            const SizedBox(
              height: 90,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...photos.map(
                    (photo) => _PhotoTile(
                      key: ValueKey(photo.id),
                      photo: photo,
                      onDelete: () => onDelete(photo.id),
                    ),
                  ),
                  _AddPhotoTile(
                    onTap: isUploading ? null : onAdd,
                    isUploading: isUploading,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({super.key, required this.photo, required this.onDelete});

  final SalonPhoto photo;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              photo.photoUrl,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 90,
                height: 90,
                color: AppColors.surfaceVariant,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({this.onTap, required this.isUploading});

  final VoidCallback? onTap;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isUploading ? AppColors.textHint : AppColors.primary,
            width: 1.5,
          ),
          color: AppColors.primary.withAlpha(10),
        ),
        child: isUploading
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add Photo',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Existing helper widgets
// ──────────────────────────────────────────────────────────────────────────────

class _EditorHeader extends StatelessWidget {
  const _EditorHeader({required this.saloonName, required this.saloonId});

  final String saloonName;
  final String saloonId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  saloonName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Update profile, location, and operating hours.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionField extends StatelessWidget {
  const _ActionField({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
    required this.isLoading,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: AppColors.textHint, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isLoading ? null : onTap,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.location_on_outlined, size: 18),
            label: Text(actionLabel),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.divider),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, color: AppColors.textHint, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.edit_outlined,
                    color: AppColors.textHint, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),
    );
  }
}
