import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:knoty/constants/palette.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/core/enums/user_role.dart';
import 'package:knoty/l10n/app_localizations.dart';
import 'package:knoty/presentation/widgets/knoty_app_bar.dart';
import 'package:knoty/presentation/widgets/knoty_empty_state.dart';
import 'package:knoty/presentation/widgets/knoty_shimmer.dart';
import 'package:knoty/services/api_service.dart';

// ── Main Screen ───────────────────────────────────────────────────────────────

class VerwaltungScreen extends StatelessWidget {
  const VerwaltungScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthController>().currentUser;
    final role = user?.role ?? UserRole.student;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: KnotyAppBar(title: l10n.verwaltungTitle),
      body: role == UserRole.schoolAdmin
          ? const _SchoolAdminPanel()
          : role == UserRole.superAdmin
              ? const _AppAdminPanel()
              : _AccessDenied(l10n: l10n),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  final AppLocalizations l10n;
  const _AccessDenied({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 56, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              l10n.lockedDefaultTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.lockedDefaultSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

// ── School Admin Panel ────────────────────────────────────────────────────────

class _SchoolAdminPanel extends StatelessWidget {
  const _SchoolAdminPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _AdminTile(
          icon: Icons.person_add_rounded,
          title: l10n.verwaltungActivateUsers,
          subtitle: l10n.verwaltungActivateUsersSubtitle,
          onTap: () {},
        ),
        _AdminTile(
          icon: Icons.vpn_key_rounded,
          title: l10n.verwaltungGenerateCodes,
          subtitle: l10n.verwaltungGenerateCodesSubtitle,
          onTap: () {},
        ),
        _AdminTile(
          icon: Icons.people_rounded,
          title: l10n.verwaltungUserList,
          subtitle: l10n.verwaltungUserListSubtitle,
          onTap: () {},
        ),
      ],
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: KPalette.gold.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: KPalette.gold, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: cs.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: cs.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}

// ── App Admin Panel (tabbed) ──────────────────────────────────────────────────

class _AppAdminPanel extends StatelessWidget {
  const _AppAdminPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Container(
            color: cs.surface,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: KPalette.gold,
              indicatorWeight: 3,
              labelColor: KPalette.gold,
              unselectedLabelColor: cs.onSurfaceVariant,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              dividerColor: cs.outlineVariant.withOpacity(0.4),
              tabs: [
                Tab(text: l10n.adminTabStats),
                Tab(text: l10n.adminTabUsers),
                Tab(text: l10n.adminTabCodes),
                Tab(text: l10n.adminTabSchools),
                Tab(text: l10n.adminTabSettings),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _StatsTab(apiService: ApiService()),
                _UsersTab(apiService: ApiService()),
                _CodesTab(apiService: ApiService()),
                _SchoolsTab(apiService: ApiService()),
                const _SettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Stats ──────────────────────────────────────────────────────────────

class _StatsTab extends StatefulWidget {
  final ApiService apiService;
  const _StatsTab({required this.apiService});

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab>
    with AutomaticKeepAliveClientMixin {
  bool _loading = true;
  Map<String, dynamic> _stats = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    // Mock data — replace with: final res = await widget.apiService.adminGetStats();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _stats = {'users': 142, 'schools': 8, 'pending': 3, 'codes': 47};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      color: KPalette.gold,
      onRefresh: _loadStats,
      child: _loading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: KnotyCardListSkeleton(count: 4),
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.adminTabStats,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _StatCard(
                        icon: Icons.people_rounded,
                        count: _stats['users'] ?? 0,
                        label: l10n.adminStatUsers,
                        iconColor: KPalette.info,
                      ),
                      _StatCard(
                        icon: Icons.school_rounded,
                        count: _stats['schools'] ?? 0,
                        label: l10n.adminStatSchools,
                        iconColor: KPalette.gold,
                      ),
                      _StatCard(
                        icon: Icons.hourglass_top_rounded,
                        count: _stats['pending'] ?? 0,
                        label: l10n.adminStatPending,
                        iconColor: KPalette.warning,
                      ),
                      _StatCard(
                        icon: Icons.vpn_key_rounded,
                        count: _stats['codes'] ?? 0,
                        label: l10n.adminStatCodes,
                        iconColor: KPalette.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color iconColor;

  const _StatCard({
    required this.icon,
    required this.count,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tab 2: Users ──────────────────────────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  final ApiService apiService;
  const _UsersTab({required this.apiService});

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab>
    with AutomaticKeepAliveClientMixin {
  bool _loading = true;
  bool _showPending = true;
  List<Map<String, dynamic>> _pendingUsers = [];
  List<Map<String, dynamic>> _allUsers = [];

  @override
  bool get wantKeepAlive => true;

  // Mock data
  static const _mockPending = [
    {
      'id': 'u1',
      'knotyNumber': 'KN-10421',
      'firstName': 'Emma',
      'lastName': 'Schneider',
      'role': 'student',
      'school': 'Goethe-Schule',
      'status': 'pending',
    },
    {
      'id': 'u2',
      'knotyNumber': 'KN-10422',
      'firstName': 'Leon',
      'lastName': 'Müller',
      'role': 'parent',
      'school': 'Schiller-Gymnasium',
      'status': 'pending',
    },
  ];

  static const _mockAll = [
    {
      'id': 'u3',
      'knotyNumber': 'KN-10100',
      'firstName': 'Anna',
      'lastName': 'Weber',
      'role': 'teacher',
      'school': 'Goethe-Schule',
      'status': 'active',
    },
    {
      'id': 'u4',
      'knotyNumber': 'KN-10200',
      'firstName': 'Max',
      'lastName': 'Fischer',
      'role': 'student',
      'school': 'Schiller-Gymnasium',
      'status': 'active',
    },
    {
      'id': 'u5',
      'knotyNumber': 'KN-10300',
      'firstName': 'Sophie',
      'lastName': 'Koch',
      'role': 'schoolAdmin',
      'school': 'Goethe-Schule',
      'status': 'banned',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    // Mock — replace with API calls
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _pendingUsers = List<Map<String, dynamic>>.from(_mockPending);
      _allUsers = List<Map<String, dynamic>>.from(_mockAll);
      _loading = false;
    });
  }

  Future<void> _approve(String id) async {
    // await widget.apiService.adminApproveUser(id);
    setState(() {
      _pendingUsers.removeWhere((u) => u['id'] == id);
    });
  }

  Future<void> _ban(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _showBanDialog(context, l10n);
    if (!confirmed) return;
    // await widget.apiService.adminBanUser(id);
    setState(() {
      _pendingUsers.removeWhere((u) => u['id'] == id);
      for (var i = 0; i < _allUsers.length; i++) {
        if (_allUsers[i]['id'] == id) {
          _allUsers[i] = {..._allUsers[i], 'status': 'banned'};
        }
      }
    });
  }

  Future<void> _unban(String id) async {
    // await widget.apiService.adminUnbanUser(id);
    setState(() {
      for (var i = 0; i < _allUsers.length; i++) {
        if (_allUsers[i]['id'] == id) {
          _allUsers[i] = {..._allUsers[i], 'status': 'active'};
        }
      }
    });
  }

  Future<bool> _showBanDialog(BuildContext ctx, AppLocalizations l10n) async {
    return await showDialog<bool>(
          context: ctx,
          builder: (dCtx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(l10n.adminConfirmBan,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            content: Text(l10n.adminConfirmBanMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dCtx).pop(false),
                child: Text(l10n.adminCancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade600),
                onPressed: () => Navigator.of(dCtx).pop(true),
                child: Text(l10n.adminConfirm),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final displayList = _showPending ? _pendingUsers : _allUsers;

    return RefreshIndicator(
      color: KPalette.gold,
      onRefresh: _loadUsers,
      child: Column(
        children: [
          // Segment control
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _SegmentControl(
              options: [l10n.adminUsersPending, l10n.adminUsersAll],
              selectedIndex: _showPending ? 0 : 1,
              onChanged: (i) => setState(() => _showPending = i == 0),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: KnotyCardListSkeleton(count: 4),
                  )
                : displayList.isEmpty
                    ? KnotyEmptyState(
                        icon: Icons.people_outline_rounded,
                        title: _showPending
                            ? l10n.adminUsersPending
                            : l10n.adminUsersAll,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: displayList.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final u = displayList[i];
                          return _UserCard(
                            user: u,
                            showActions: _showPending,
                            onApprove: () => _approve(u['id'] as String),
                            onBan: () => _ban(u['id'] as String),
                            onUnban: () => _unban(u['id'] as String),
                            l10n: l10n,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SegmentControl extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentControl({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: selected ? cs.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: cs.shadow.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    options[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? KPalette.gold : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool showActions;
  final VoidCallback onApprove;
  final VoidCallback onBan;
  final VoidCallback onUnban;
  final AppLocalizations l10n;

  const _UserCard({
    required this.user,
    required this.showActions,
    required this.onApprove,
    required this.onBan,
    required this.onUnban,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final role = user['role'] as String? ?? 'student';
    final status = user['status'] as String? ?? 'active';
    final isBanned = status == 'banned';
    final kn = user['knotyNumber'] as String? ?? '';
    final knDigits = kn.startsWith('KN-') ? kn.substring(3) : kn;
    final name =
        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: isBanned
            ? Border.all(color: Colors.red.withOpacity(0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _roleColor(role).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _roleColor(role),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'KN-',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: knDigits,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: KPalette.gold,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user['school'] as String? ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _RoleBadge(role: role),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: l10n.adminApprove,
                    color: Colors.green.shade600,
                    onTap: onApprove,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: l10n.adminBan,
                    color: Colors.red.shade600,
                    outlined: true,
                    onTap: onBan,
                  ),
                ),
              ],
            ),
          ] else if (isBanned) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: _ActionButton(
                label: l10n.adminUnban,
                color: Colors.green.shade600,
                onTap: onUnban,
                compact: true,
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: _ActionButton(
                label: l10n.adminBan,
                color: Colors.red.shade600,
                outlined: true,
                onTap: onBan,
                compact: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'teacher':
        return Colors.blue.shade600;
      case 'parent':
        return Colors.green.shade600;
      case 'schoolAdmin':
        return Colors.purple.shade600;
      case 'appAdmin':
        return Colors.deepOrange.shade600;
      default:
        return KPalette.gold;
    }
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      'teacher' => ('Teacher', Colors.blue.shade600),
      'parent' => ('Parent', Colors.green.shade600),
      'schoolAdmin' => ('S.Admin', Colors.purple.shade600),
      'appAdmin' => ('AppAdmin', Colors.deepOrange.shade600),
      _ => ('Student', KPalette.gold),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;
  final bool compact;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = compact ? 30.0 : 36.0;
    final fontSize = compact ? 12.0 : 13.0;

    if (outlined) {
      return SizedBox(
        height: height,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withOpacity(0.6)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: fontSize, fontWeight: FontWeight.w600)),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: fontSize, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Tab 3: Codes ──────────────────────────────────────────────────────────────

class _CodesTab extends StatefulWidget {
  final ApiService apiService;
  const _CodesTab({required this.apiService});

  @override
  State<_CodesTab> createState() => _CodesTabState();
}

class _CodesTabState extends State<_CodesTab>
    with AutomaticKeepAliveClientMixin {
  bool _loading = true;
  List<Map<String, dynamic>> _codes = [];

  @override
  bool get wantKeepAlive => true;

  static const _mockCodes = [
    {
      'code': 'KNOTY-A1B2-C3D4',
      'school': 'Goethe-Schule',
      'used': false,
    },
    {
      'code': 'KNOTY-E5F6-G7H8',
      'school': 'Schiller-Gymnasium',
      'used': true,
    },
    {
      'code': 'KNOTY-I9J0-K1L2',
      'school': 'Goethe-Schule',
      'used': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  Future<void> _loadCodes() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _codes = List<Map<String, dynamic>>.from(_mockCodes);
      _loading = false;
    });
  }

  Future<void> _deleteCode(String code) async {
    // await widget.apiService.adminDeleteCode(code);
    setState(() => _codes.removeWhere((c) => c['code'] == code));
  }

  Future<void> _showGenerateDialog() async {
    final l10n = AppLocalizations.of(context)!;
    int count = 5;
    final result = await showDialog<int>(
      context: context,
      builder: (dCtx) => _GenerateCodesDialog(
        l10n: l10n,
        initialCount: count,
      ),
    );
    if (result != null && result > 0) {
      // await widget.apiService.adminGenerateCodes(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$result codes generated'),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      await _loadCodes();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      color: KPalette.gold,
      onRefresh: _loadCodes,
      child: Column(
        children: [
          // Header row with generate button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Text(
                  l10n.adminCodesTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _showGenerateDialog,
                  style: FilledButton.styleFrom(
                    backgroundColor: KPalette.gold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.adminCodesGenerate,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: KnotyCardListSkeleton(count: 4),
                  )
                : _codes.isEmpty
                    ? KnotyEmptyState(
                        icon: Icons.vpn_key_outlined,
                        title: l10n.adminCodesEmpty,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _codes.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final c = _codes[i];
                          return _CodeCard(
                            code: c['code'] as String,
                            school: c['school'] as String? ?? '',
                            used: c['used'] as bool? ?? false,
                            onDelete: () =>
                                _deleteCode(c['code'] as String),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  final String code;
  final String school;
  final bool used;
  final VoidCallback onDelete;

  const _CodeCard({
    required this.code,
    required this.school,
    required this.used,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = used ? cs.onSurfaceVariant : KPalette.success;
    final statusBg = used
        ? cs.surfaceContainerHighest
        : KPalette.success.withOpacity(0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: KPalette.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.vpn_key_rounded,
                color: KPalette.gold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  school,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              used ? 'Used' : 'Free',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                color: cs.onSurfaceVariant, size: 20),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

class _GenerateCodesDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final int initialCount;

  const _GenerateCodesDialog({
    required this.l10n,
    required this.initialCount,
  });

  @override
  State<_GenerateCodesDialog> createState() => _GenerateCodesDialogState();
}

class _GenerateCodesDialogState extends State<_GenerateCodesDialog> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.initialCount;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l10n.adminCodesGenerate,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.adminCodesGenerateHint,
              style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CounterButton(
                icon: Icons.remove_rounded,
                onTap: () =>
                    setState(() => _count = (_count - 1).clamp(1, 50)),
              ),
              SizedBox(
                width: 64,
                child: Center(
                  child: Text(
                    '$_count',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
              _CounterButton(
                icon: Icons.add_rounded,
                onTap: () =>
                    setState(() => _count = (_count + 1).clamp(1, 50)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Slider(
            value: _count.toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: KPalette.gold,
            onChanged: (v) => setState(() => _count = v.round()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.adminCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: KPalette.gold),
          onPressed: () => Navigator.of(context).pop(_count),
          child: Text(l10n.adminConfirm,
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CounterButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: cs.onSurface),
      ),
    );
  }
}

// ── Tab 4: Schools ────────────────────────────────────────────────────────────

class _SchoolsTab extends StatefulWidget {
  final ApiService apiService;
  const _SchoolsTab({required this.apiService});

  @override
  State<_SchoolsTab> createState() => _SchoolsTabState();
}

class _SchoolsTabState extends State<_SchoolsTab>
    with AutomaticKeepAliveClientMixin {
  bool _loading = true;
  List<Map<String, dynamic>> _schools = [];

  @override
  bool get wantKeepAlive => true;

  static const _mockSchools = [
    {'id': 's1', 'name': 'Goethe-Schule', 'city': 'Frankfurt', 'userCount': 84},
    {'id': 's2', 'name': 'Schiller-Gymnasium', 'city': 'Munich', 'userCount': 37},
    {'id': 's3', 'name': 'Humboldt-Gesamtschule', 'city': 'Berlin', 'userCount': 21},
  ];

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _schools = List<Map<String, dynamic>>.from(_mockSchools);
      _loading = false;
    });
  }

  Future<void> _showAddSchoolDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dCtx) => _AddSchoolDialog(l10n: l10n),
    );
    if (result != null) {
      // await widget.apiService.adminCreateSchool(result['name']!, result['city']!);
      setState(() {
        _schools.add({
          'id': 'new_${DateTime.now().millisecondsSinceEpoch}',
          'name': result['name']!,
          'city': result['city']!,
          'userCount': 0,
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      color: KPalette.gold,
      onRefresh: _loadSchools,
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Text(
                  l10n.adminSchoolsTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _showAddSchoolDialog,
                  style: FilledButton.styleFrom(
                    backgroundColor: KPalette.gold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.adminSchoolsAdd,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: KnotyCardListSkeleton(count: 4),
                  )
                : _schools.isEmpty
                    ? KnotyEmptyState(
                        icon: Icons.school_outlined,
                        title: l10n.adminSchoolsEmpty,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _schools.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final s = _schools[i];
                          return _SchoolCard(
                            name: s['name'] as String,
                            city: s['city'] as String,
                            userCount: s['userCount'] as int? ?? 0,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SchoolCard extends StatelessWidget {
  final String name;
  final String city;
  final int userCount;

  const _SchoolCard({
    required this.name,
    required this.city,
    required this.userCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: KPalette.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.school_rounded,
                color: KPalette.gold, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  city,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_rounded,
                    size: 13, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '$userCount',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
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

class _AddSchoolDialog extends StatefulWidget {
  final AppLocalizations l10n;
  const _AddSchoolDialog({required this.l10n});

  @override
  State<_AddSchoolDialog> createState() => _AddSchoolDialogState();
}

class _AddSchoolDialogState extends State<_AddSchoolDialog> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l10n.adminSchoolsAdd,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.adminSchoolNameHint,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.adminSchoolNameHint : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cityCtrl,
              decoration: InputDecoration(
                labelText: l10n.adminSchoolCityHint,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.adminSchoolCityHint : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.adminCancel),
        ),
        FilledButton(
          style:
              FilledButton.styleFrom(backgroundColor: KPalette.gold),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameCtrl.text.trim(),
                'city': _cityCtrl.text.trim(),
              });
            }
          },
          child: Text(l10n.adminConfirm,
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ── Tab 5: Settings ───────────────────────────────────────────────────────────

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab>
    with AutomaticKeepAliveClientMixin {
  bool _maintenanceMode = false;
  bool _openRegistration = true;

  @override
  bool get wantKeepAlive => true;

  void _onToggle(String key, bool value) {
    setState(() {
      if (key == 'maintenance') _maintenanceMode = value;
      if (key == 'registration') _openRegistration = value;
    });
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n.adminSettingsSaved),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      color: KPalette.gold,
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.adminSettingsTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _SettingToggleRow(
                    icon: Icons.build_circle_outlined,
                    title: l10n.adminSettingsMaintenance,
                    hint: _maintenanceMode
                        ? l10n.adminSettingsMaintenanceHint
                        : null,
                    hintIsWarning: true,
                    value: _maintenanceMode,
                    onChanged: (v) => _onToggle('maintenance', v),
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: cs.outlineVariant.withOpacity(0.4),
                  ),
                  _SettingToggleRow(
                    icon: Icons.app_registration_rounded,
                    title: l10n.adminSettingsRegistration,
                    hint: l10n.adminSettingsRegistrationHint,
                    hintIsWarning: false,
                    value: _openRegistration,
                    onChanged: (v) => _onToggle('registration', v),
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

class _SettingToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  final bool hintIsWarning;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingToggleRow({
    required this.icon,
    required this.title,
    this.hint,
    required this.hintIsWarning,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hintColor =
        hintIsWarning ? KPalette.warning : cs.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: KPalette.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: KPalette.gold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                if (hint != null && hint!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    hint!,
                    style: TextStyle(
                      fontSize: 12,
                      color: hintColor,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: KPalette.gold,
          ),
        ],
      ),
    );
  }
}
