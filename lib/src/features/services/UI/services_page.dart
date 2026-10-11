import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/bloc/home_bloc.dart';
import '../../home/bloc/home_event.dart';
import '../../home/bloc/home_state.dart';
import '../../home/data/models/home_model.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key, required this.saloonId});

  final String saloonId;

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<HomeBloc>()
        .add(HomeServicesLoadRequested(saloonId: widget.saloonId));
  }

  void _showAddDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<HomeBloc>(),
        child: _ServiceDialog(saloonId: widget.saloonId),
      ),
    );
  }

  void _showEditDialog(SaloonService service) {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<HomeBloc>(),
        child: _ServiceDialog(saloonId: widget.saloonId, existing: service),
      ),
    );
  }

  void _confirmDelete(SaloonService service) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Delete Service',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Delete "${service.name}"? This cannot be undone. To hide it temporarily, use Edit and toggle it inactive.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<HomeBloc>().add(HomeServiceDeleteRequested(
                    saloonId: widget.saloonId,
                    serviceId: service.id,
                  ));
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            );
          }
          if (state is HomeLoaded) {
            final services = state.services;
            if (services.isEmpty) {
              return _EmptyState(onAdd: _showAddDialog);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              itemCount: services.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final service = services[i];
                return _ServiceCard(
                  service: service,
                  isActioning: state.actioningId == service.id,
                  onEdit: () => _showEditDialog(service),
                  onDelete: () => _confirmDelete(service),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.content_cut_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No services yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + to add your first service',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service card
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.isActioning,
    required this.onEdit,
    required this.onDelete,
  });

  final SaloonService service;
  final bool isActioning;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.content_cut_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (!service.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.textHint.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (service.description != null &&
                    service.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    service.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (service.price != null) ...[
                      const Icon(Icons.currency_rupee,
                          size: 13, color: AppColors.primary),
                      Text(
                        service.price!.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (service.durationMinutes != null) ...[
                      const Icon(Icons.timer_outlined,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        '${service.durationMinutes} min',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isActioning)
            const Padding(
              padding: EdgeInsets.only(top: 10, left: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onEdit,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onDelete,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline,
                        size: 18, color: AppColors.error),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / edit dialog
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceDialog extends StatefulWidget {
  const _ServiceDialog({required this.saloonId, this.existing});

  final String saloonId;
  final SaloonService? existing;

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _duration;
  bool _isActive = true;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _name = TextEditingController(text: s?.name ?? '');
    _desc = TextEditingController(text: s?.description ?? '');
    _price = TextEditingController(
        text: s?.price != null ? s!.price!.toStringAsFixed(0) : '');
    _duration =
        TextEditingController(text: s?.durationMinutes?.toString() ?? '');
    _isActive = s?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final price =
        _price.text.trim().isEmpty ? null : double.tryParse(_price.text.trim());
    final duration = _duration.text.trim().isEmpty
        ? null
        : int.tryParse(_duration.text.trim());

    if (_isEdit) {
      context.read<HomeBloc>().add(HomeServiceUpdateRequested(
            saloonId: widget.saloonId,
            serviceId: widget.existing!.id,
            name: _name.text.trim(),
            description:
                _desc.text.trim().isEmpty ? null : _desc.text.trim(),
            price: price,
            durationMinutes: duration,
            isActive: _isActive,
          ));
    } else {
      context.read<HomeBloc>().add(HomeServiceAddRequested(
            saloonId: widget.saloonId,
            name: _name.text.trim(),
            description:
                _desc.text.trim().isEmpty ? null : _desc.text.trim(),
            price: price,
            durationMinutes: duration,
          ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _isEdit ? 'Edit Service' : 'New Service',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Field(
                controller: _name,
                label: 'Name',
                hint: 'e.g. Haircut',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 10),
              _Field(
                controller: _desc,
                label: 'Description (optional)',
                hint: 'Short description',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      controller: _price,
                      label: 'Price (₹)',
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Field(
                      controller: _duration,
                      label: 'Duration (min)',
                      hint: '30',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              if (_isEdit) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isActive,
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withAlpha(120),
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _submit,
          child: Text(_isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text field
// ─────────────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textHint),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      ),
    );
  }
}
