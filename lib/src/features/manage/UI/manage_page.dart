import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart' show AuthAuthenticated;
import '../bloc/manage_bloc.dart';
import '../bloc/manage_event.dart';
import '../bloc/manage_state.dart';
import '../data/models/manage_model.dart';

// ─── Page ─────────────────────────────────────────────────────────────────────

class ManagePage extends StatefulWidget {
  const ManagePage({super.key});

  @override
  State<ManagePage> createState() => _ManagePageState();
}

class _ManagePageState extends State<ManagePage> {
  late String _saloonId;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated && auth.user.saloons.isNotEmpty) {
      _saloonId = auth.user.saloons.first.id;
    } else {
      _saloonId = '';
    }
    _load();
  }

  void _load() {
    if (_saloonId.isEmpty) return;
    context
        .read<ManageBloc>()
        .add(ManageLoadRequested(saloonId: _saloonId));
  }

  void _handleRoleChange(SaloonMember member, BarberRole newRole) {
    context.read<ManageBloc>().add(ManageRoleChangeRequested(
          saloonId: _saloonId,
          barberId: member.id,
          role: newRole,
        ));
  }

  void _handleRemove(SaloonMember member) {
    context.read<ManageBloc>().add(ManageRemoveRequested(
          saloonId: _saloonId,
          barberId: member.id,
        ));
  }

  String? get _currentUserId {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) return auth.user.id;
    return null;
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
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('Manage Team'),
        centerTitle: false,
      ),
      body: BlocConsumer<ManageBloc, ManageState>(
        listener: (context, state) {
          if (state is ManageActionSuccess) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
          } else if (state is ManageActionError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
          }
        },
        builder: (context, state) {
          if (state is ManageInitial || state is ManageLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is ManageError) {
            return _ErrorView(message: state.message, onRetry: _load);
          }

          final members = switch (state) {
            ManageLoaded(members: var m) => m,
            ManageActionLoading(members: var m) => m,
            ManageActionSuccess(members: var m) => m,
            ManageActionError(members: var m) => m,
            _ => <SaloonMember>[],
          };
          final actingId = state is ManageActionLoading ? state.actingId : null;
          final currentUserId = _currentUserId;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => _load(),
            child: members.isEmpty
                ? _EmptyView(onRetry: _load)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final member = members[i];
                      final isSelf = member.id == currentUserId;
                      final isActing = actingId == member.id;
                      return _MemberCard(
                        member: member,
                        isSelf: isSelf,
                        isActing: isActing,
                        onPromote: isSelf || member.isPrimaryOwner
                            ? null
                            : member.role == BarberRole.barber
                                ? () => _confirmRoleChange(
                                    context, member, BarberRole.owner)
                                : null,
                        onDemote: isSelf || member.isPrimaryOwner
                            ? null
                            : member.role == BarberRole.owner
                                ? () => _confirmRoleChange(
                                    context, member, BarberRole.barber)
                                : null,
                        onRemove: isSelf || member.isPrimaryOwner
                            ? null
                            : () => _confirmRemove(context, member),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Future<void> _confirmRoleChange(
    BuildContext context,
    SaloonMember member,
    BarberRole newRole,
  ) async {
    final promoting = newRole == BarberRole.owner;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          promoting ? 'Promote to Co-Owner?' : 'Demote to Barber?',
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
        content: Text(
          promoting
              ? '${member.name} will be able to manage the saloon as a co-owner.'
              : '${member.name} will lose management access and return to the barber role.',
          style: const TextStyle(
              fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              promoting ? 'Promote' : 'Demote',
              style: TextStyle(
                color: promoting ? AppColors.primary : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _handleRoleChange(member, newRole);
    }
  }

  Future<void> _confirmRemove(
      BuildContext context, SaloonMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Remove from Saloon?',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
        content: Text(
          '${member.name} will be removed from the saloon. This cannot be undone.',
          style: const TextStyle(
              fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _handleRemove(member);
    }
  }
}

// ─── Member card ──────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.isSelf,
    required this.isActing,
    this.onPromote,
    this.onDemote,
    this.onRemove,
  });

  final SaloonMember member;
  final bool isSelf;
  final bool isActing;
  final VoidCallback? onPromote;
  final VoidCallback? onDemote;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isOwnerRole = member.role == BarberRole.owner;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: isActing
          ? const SizedBox(
              height: 56,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isOwnerRole
                            ? AppColors.primary.withAlpha(18)
                            : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: isOwnerRole
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name + phone
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  member.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelf) ...[
                                const SizedBox(width: 6),
                                _Chip(
                                  label: 'You',
                                  color: AppColors.primary,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            member.phone,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),

                    // Role badge
                    _RoleBadge(
                      role: member.role,
                      isPrimary: member.isPrimaryOwner,
                    ),
                  ],
                ),

                // Join date
                if (member.joinedAt != null) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppColors.textHint),
                      const SizedBox(width: 5),
                      Text(
                        'Joined ${_formatDate(member.joinedAt!)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ],

                // Action buttons
                if (onPromote != null ||
                    onDemote != null ||
                    onRemove != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (onPromote != null)
                        _ActionButton(
                          label: 'Make Co-Owner',
                          icon: Icons.arrow_upward_rounded,
                          color: AppColors.primary,
                          onTap: onPromote!,
                        ),
                      if (onDemote != null)
                        _ActionButton(
                          label: 'Demote',
                          icon: Icons.arrow_downward_rounded,
                          color: AppColors.textSecondary,
                          onTap: onDemote!,
                        ),
                      const Spacer(),
                      if (onRemove != null)
                        _ActionButton(
                          label: 'Remove',
                          icon: Icons.person_remove_outlined,
                          color: AppColors.error,
                          onTap: onRemove!,
                        ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Role badge ───────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role, required this.isPrimary});

  final BarberRole role;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final isOwner = role == BarberRole.owner;
    final label =
        isPrimary ? 'Owner' : (isOwner ? 'Co-Owner' : 'Barber');
    final color =
        isOwner ? AppColors.primary : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(isOwner ? 20 : 14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─── Small chip ───────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color),
      ),
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty / error views ──────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              const Icon(Icons.group_off_outlined,
                  size: 48, color: AppColors.textHint),
              const SizedBox(height: 16),
              const Text(
                'No team members found',
                style: TextStyle(
                    fontSize: 15, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 40),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
