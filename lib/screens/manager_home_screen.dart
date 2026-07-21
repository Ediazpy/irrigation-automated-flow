import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../services/quote_service.dart';
import '../models/quote.dart';
import '../models/property.dart';
import '../models/inspection.dart';
import '../models/repair_task.dart';
import '../constants/status_constants.dart';
import 'manager/repair_items_screen.dart';
import 'manager/create_property_screen.dart';
import 'manager/edit_property_screen.dart';
import 'manager/monthly_dashboard_screen.dart';
import 'manager/review_inspection_detail_screen.dart';
import 'manager/users_screen.dart';
import 'manager/monthly_report_screen.dart';
import 'manager/to_schedule_screen.dart';
import 'manager/repair_tasks_list_screen.dart';
import 'manager/company_settings_screen.dart';
import 'manager/custom_quote_screen.dart';
import 'manager/schedule_repair_screen.dart';
import 'manager/send_quote_screen.dart';
import 'manager/clients_screen.dart';
import 'manager/invoices_screen.dart';
import 'manager/schedule_client_screen.dart';
import 'technician/do_inspection_screen.dart';
import 'technician/create_walk_screen.dart';
import 'login_screen.dart';

// ─────────────────────────────────────────────────────────────
// MANAGER HOME SHELL – Jobber-style bottom nav with 5 tabs
// ─────────────────────────────────────────────────────────────

class ManagerHomeScreen extends StatefulWidget {
  final AuthService authService;
  const ManagerHomeScreen({Key? key, required this.authService})
      : super(key: key);

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  int _selectedIndex = 0;

  // Jobber-style: Home, Schedule, (FAB), Clients, More
  static const _tabTitles = [
    'Home',
    'Schedule',
    '', // placeholder for FAB
    'Clients',
    'More',
  ];

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.authService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (_) =>
                        LoginScreen(authService: widget.authService)),
                (route) => false,
              );
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen))
        .then((_) => setState(() {}));
  }

  void _showCreateMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Quick Create',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _CreateMenuItem(
                icon: Icons.person_add,
                label: 'Schedule New Client',
                subtitle: 'Add client info and assign a tech visit',
                onTap: () { Navigator.pop(context); _push(ScheduleClientScreen(authService: widget.authService)); },
              ),
              _CreateMenuItem(
                icon: Icons.edit_note,
                label: 'Custom Quote',
                subtitle: 'Create a quote with custom line items',
                onTap: () { Navigator.pop(context); _push(CustomQuoteScreen(authService: widget.authService)); },
              ),
              _CreateMenuItem(
                icon: Icons.receipt_long,
                label: 'Invoice',
                subtitle: 'View and manage invoices',
                onTap: () { Navigator.pop(context); _push(InvoicesScreen(authService: widget.authService)); },
              ),
              _CreateMenuItem(
                icon: Icons.calendar_month,
                label: 'Schedule Inspections',
                subtitle: 'Assign technicians to existing properties',
                onTap: () { Navigator.pop(context); _push(MonthlyDashboardScreen(authService: widget.authService)); },
              ),
              _CreateMenuItem(
                icon: Icons.home_work,
                label: 'New Property',
                subtitle: 'Add a property with full details',
                onTap: () { Navigator.pop(context); _push(CreatePropertyScreen(authService: widget.authService)); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.authService;
    // Map tab index: 0=Home, 1=Schedule, 2=skip(FAB), 3=Clients, 4=More
    final bodyIndex = _selectedIndex >= 2 ? _selectedIndex - 1 : _selectedIndex;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.water_drop, color: Theme.of(context).primaryColor, size: 22),
            const SizedBox(width: 8),
            Text(_tabTitles[_selectedIndex].isNotEmpty
                ? _tabTitles[_selectedIndex]
                : 'Home'),
          ],
        ),
        actions: [
          _SyncIndicator(storage: auth.storage),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: IndexedStack(
              index: bodyIndex,
              children: [
                _DashboardTab(authService: auth, onNavigateTab: (i) => setState(() => _selectedIndex = i), onPush: _push),
                _ScheduleTab(authService: auth, onPush: _push),
                _ClientsTab(authService: auth, onPush: _push),
                _MoreTab(authService: auth, onPush: _push),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMenu,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          if (i == 2) {
            _showCreateMenu();
            return;
          }
          setState(() => _selectedIndex = i);
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Schedule'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline, size: 32),
              activeIcon: Icon(Icons.add_circle, size: 32),
              label: ''),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outlined),
              activeIcon: Icon(Icons.people),
              label: 'Clients'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              activeIcon: Icon(Icons.menu),
              label: 'More'),
        ],
      ),
    );
  }
}

class _CreateMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _CreateMenuItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor, size: 22),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 0 – DASHBOARD
// ─────────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  final AuthService authService;
  final void Function(int) onNavigateTab;
  final void Function(Widget) onPush;

  const _DashboardTab(
      {Key? key,
      required this.authService,
      required this.onNavigateTab,
      required this.onPush})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final storage = authService.storage;
    final name = authService.currentUser?.name ?? 'Manager';
    final pendingReview = storage.inspections.values
        .where((i) => i.status == InspectionStatus.review)
        .length;
    final awaitingApproval = storage.quotes.values
        .where((q) =>
            q.status == QuoteStatus.sent || q.status == QuoteStatus.viewed)
        .length;
    final activeTasks = storage.repairTasks.values
        .where((t) =>
            t.status == RepairTaskStatus.assigned ||
            t.status == RepairTaskStatus.inProgress)
        .length;
    final currentEmail = authService.currentUser?.email ?? '';
    final myActiveInspections = storage.inspections.values
        .where((i) =>
            i.technicians.contains(currentEmail) &&
            (i.status == InspectionStatus.assigned ||
                i.status == InspectionStatus.inProgress))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Derived counts for "Action Required"
    final approvedQuotes = storage.quotes.values
        .where((q) => q.status == QuoteStatus.approved)
        .length;
    final totalProperties = storage.properties.length;
    final dueToSchedule = storage.inspections.values
        .where((i) => i.status == InspectionStatus.due)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        // Greeting
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text('Hello, $name',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700)),
        ),
        Text("Here's what's happening today",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),

        const SizedBox(height: 16),

        // Pricing Alert
        if (!storage.hasPricesConfigured)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Repair item prices not configured. Set prices before inspections begin.',
                    style: TextStyle(
                        fontSize: 13, color: Colors.orange.shade900),
                  ),
                ),
                TextButton(
                  onPressed: () => onPush(
                      RepairItemsScreen(authService: authService)),
                  child: const Text('Set Up'),
                ),
              ],
            ),
          ),

        // Recurring inspections that came due — schedule them
        if (dueToSchedule > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onPush(ToScheduleScreen(authService: authService)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepOrange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_available,
                          color: Colors.deepOrange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$dueToSchedule inspection${dueToSchedule == 1 ? '' : 's'} due — tap to schedule',
                          style: TextStyle(
                            color: Colors.deepOrange.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Stats Row (Jobber "Business Health" style)
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Pending\nReview',
                value: pendingReview.toString(),
                color: Colors.orange,
                icon: Icons.rate_review_outlined,
                onTap: () => onNavigateTab(1), // Schedule tab
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Awaiting\nApproval',
                value: awaitingApproval.toString(),
                color: const Color(0xFF0EA5E9),
                icon: Icons.pending_actions_outlined,
                onTap: () => onPush(_QuotesFullScreen(authService: authService)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Active\nTasks',
                value: activeTasks.toString(),
                color: const Color(0xFF059669),
                icon: Icons.construction_outlined,
                onTap: () =>
                    onPush(RepairTasksListScreen(authService: authService)),
              ),
            ),
          ],
        ),

        // Action Required (Jobber-style priority list)
        if (pendingReview > 0 || approvedQuotes > 0 || activeTasks > 0 || myActiveInspections.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionHeader('ACTION REQUIRED'),
          const SizedBox(height: 8),
          if (pendingReview > 0)
            _ActionRequiredCard(
              icon: Icons.rate_review,
              iconColor: Colors.orange,
              title: '$pendingReview inspection${pendingReview > 1 ? 's' : ''} to review',
              subtitle: 'Review and send quotes to clients',
              onTap: () => onNavigateTab(1), // Schedule tab
            ),
          if (approvedQuotes > 0)
            _ActionRequiredCard(
              icon: Icons.check_circle,
              iconColor: const Color(0xFF059669),
              title: '$approvedQuotes approved quote${approvedQuotes > 1 ? 's' : ''} ready',
              subtitle: 'Schedule repairs for approved quotes',
              onTap: () => onPush(_QuotesFullScreen(authService: authService)),
            ),
          if (storage.getTotalOutstanding() > 0)
            _ActionRequiredCard(
              icon: Icons.payments,
              iconColor: Colors.orange,
              title: '\$${storage.getTotalOutstanding().toStringAsFixed(2)} outstanding',
              subtitle: '${storage.getUnpaidInvoices().length} unpaid invoices',
              onTap: () => onPush(InvoicesScreen(authService: authService)),
            ),
        ],

        // My Active Field Work (if manager has inspections)
        if (myActiveInspections.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionHeader('MY FIELD WORK (${myActiveInspections.length})'),
          const SizedBox(height: 8),
          ...myActiveInspections.take(2).map((insp) {
            final prop = storage.properties[insp.propertyId];
            final isInProgress = insp.status == InspectionStatus.inProgress;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: isInProgress ? Colors.green.shade200 : Colors.blue.shade100),
              ),
              child: ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: isInProgress ? Colors.green.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isInProgress ? Icons.play_arrow : Icons.assignment_ind,
                    color: isInProgress ? Colors.green : Colors.blue,
                    size: 22,
                  ),
                ),
                title: Text(prop?.address ?? 'Property #${insp.propertyId}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(isInProgress ? 'In Progress' : 'Assigned to you'),
                trailing: TextButton(
                  onPressed: () => onPush(DoInspectionScreen(
                    authService: authService, inspectionId: insp.id,
                  )),
                  child: Text(isInProgress ? 'Continue' : 'Start'),
                ),
              ),
            );
          }).toList(),
        ],

        const SizedBox(height: 20),
        const _SectionHeader('QUICK ACTIONS'),
        const SizedBox(height: 8),

        // Quick Actions — compact grid
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.home_work_outlined,
                label: 'Properties ($totalProperties)',
                color: const Color(0xFF0277BD),
                onTap: () => onPush(_PropertiesFullScreen(authService: authService)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.receipt_long_outlined,
                label: 'Quotes',
                color: const Color(0xFF7C3AED),
                onTap: () => onPush(_QuotesFullScreen(authService: authService)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.calendar_month_outlined,
                label: 'Schedule',
                color: const Color(0xFF1565C0),
                onTap: () => onNavigateTab(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.edit_note_outlined,
                label: 'Custom Quote',
                color: const Color(0xFF4527A0),
                onTap: () =>
                    onPush(CustomQuoteScreen(authService: authService)),
              ),
            ),
          ],
        ),

        // Recent pending reviews (quick access)
        if (pendingReview > 0) ...[
          const SizedBox(height: 20),
          const _SectionHeader('PENDING REVIEWS'),
          const SizedBox(height: 8),
          ..._buildPendingReviewCards(context, storage),
        ],
      ],
    );
  }

  List<Widget> _buildPendingReviewCards(
      BuildContext context, StorageService storage) {
    final pending = storage.inspections.values
        .where((i) => i.status == InspectionStatus.review)
        .take(3)
        .toList();
    return pending.map((insp) {
      final property = storage.properties[insp.propertyId];
      final techNames = insp.technicians
          .map((e) => storage.users[e]?.name ?? e)
          .join(', ');
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.rate_review,
                color: Colors.orange.shade700, size: 22),
          ),
          title: Text(property?.address ?? 'Property #${insp.propertyId}',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text('Tech: $techNames',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          trailing: TextButton(
            onPressed: () => onPush(ReviewInspectionDetailScreen(
              authService: authService,
              inspectionId: insp.id,
              inspection: insp,
            )),
            child: const Text('Review'),
          ),
        ),
      );
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 1 – PROPERTIES
// ─────────────────────────────────────────────────────────────

class _PropertiesTab extends StatefulWidget {
  final AuthService authService;
  final void Function(Widget) onPush;
  const _PropertiesTab(
      {Key? key, required this.authService, required this.onPush})
      : super(key: key);

  @override
  State<_PropertiesTab> createState() => _PropertiesTabState();
}

class _PropertiesTabState extends State<_PropertiesTab>
    with AutomaticKeepAliveClientMixin {
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final storage = widget.authService.storage;
    var properties = storage.properties.values.toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      properties = properties
          .where((p) =>
              p.address.toLowerCase().contains(q) ||
              p.clientName.toLowerCase().contains(q))
          .toList();
    }
    properties.sort((a, b) => a.address.compareTo(b.address));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search properties or clients…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        if (properties.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_work_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No properties yet\nTap + to add one'
                        : 'No results for "$_searchQuery"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 15),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: properties.length,
                itemBuilder: (_, i) =>
                    _PropertyCard(
                      property: properties[i],
                      authService: widget.authService,
                      onEdit: () => widget.onPush(EditPropertyScreen(
                        authService: widget.authService,
                        property: properties[i],
                      )),
                      onRefresh: () => setState(() {}),
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final Property property;
  final AuthService authService;
  final VoidCallback onEdit;
  final VoidCallback onRefresh;

  const _PropertyCard({
    Key? key,
    required this.property,
    required this.authService,
    required this.onEdit,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final storage = authService.storage;
    final zoneCount = property.allZones.length;
    final inspections = storage.inspections.values
        .where((i) => i.propertyId == property.id)
        .toList();
    final activeInspection = inspections.firstWhere(
      (i) =>
          i.status == InspectionStatus.assigned ||
          i.status == InspectionStatus.inProgress ||
          i.status == InspectionStatus.review,
      orElse: () => Inspection(
          id: -1,
          propertyId: -1,
          technicians: [],
          date: '',
          status: '',
          repairs: [],
          totalCost: 0),
    );
    final hasActive = activeInspection.id != -1;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.home_work,
                  color: Color(0xFF2E7D32), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(property.address,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1A2332))),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (property.clientName.isNotEmpty) ...[
                        Icon(Icons.person,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text(property.clientName,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12)),
                        const SizedBox(width: 8),
                      ],
                      Icon(Icons.water_drop_outlined,
                          size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Text('$zoneCount zones',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                  if (hasActive) ...[
                    const SizedBox(height: 4),
                    _StatusBadge(activeInspection.status),
                  ],
                ],
              ),
            ),
            IconButton(
              icon:
                  const Icon(Icons.edit_outlined, color: Color(0xFF0EA5E9)),
              onPressed: onEdit,
              tooltip: 'Edit Property',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB – SCHEDULE (Jobber-style: inspections + calendar)
// ─────────────────────────────────────────────────────────────

class _ScheduleTab extends StatefulWidget {
  final AuthService authService;
  final void Function(Widget) onPush;
  const _ScheduleTab(
      {Key? key, required this.authService, required this.onPush})
      : super(key: key);

  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController _tc;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final storage = widget.authService.storage;
    final reviewCount = storage.inspections.values
        .where((i) => i.status == InspectionStatus.review)
        .length;

    return Column(
      children: [
        // Calendar shortcut banner
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: InkWell(
            onTap: () =>
                widget.onPush(MonthlyDashboardScreen(authService: widget.authService)),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month, color: Theme.of(context).primaryColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Monthly Calendar & Scheduling',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Theme.of(context).primaryColor)),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      color: Theme.of(context).primaryColor, size: 14),
                ],
              ),
            ),
          ),
        ),
        TabBar(
          controller: _tc,
          isScrollable: true,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Review'),
                  if (reviewCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$reviewCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Active'),
            const Tab(text: 'Upcoming'),
            const Tab(text: 'History'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tc,
            children: [
              _InspectionList(
                  authService: widget.authService,
                  statuses: const [InspectionStatus.review],
                  emptyMessage: 'No inspections pending review',
                  emptyIcon: Icons.rate_review_outlined,
                  onPush: widget.onPush),
              _InspectionList(
                  authService: widget.authService,
                  statuses: const [
                    InspectionStatus.assigned,
                    InspectionStatus.inProgress
                  ],
                  emptyMessage: 'No active inspections',
                  emptyIcon: Icons.assignment_outlined,
                  onPush: widget.onPush),
              _UpcomingScheduleContent(
                  authService: widget.authService,
                  onPush: widget.onPush),
              _InspectionList(
                  authService: widget.authService,
                  statuses: const [
                    InspectionStatus.completed,
                    InspectionStatus.quoteSent
                  ],
                  emptyMessage: 'No completed inspections',
                  emptyIcon: Icons.check_circle_outline,
                  onPush: widget.onPush,
                  onRefresh: () => setState(() {})),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB – CLIENTS (inline client list with search)
// ─────────────────────────────────────────────────────────────

class _ClientsTab extends StatefulWidget {
  final AuthService authService;
  final void Function(Widget) onPush;
  const _ClientsTab(
      {Key? key, required this.authService, required this.onPush})
      : super(key: key);

  @override
  State<_ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<_ClientsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Delegate to the full ClientsScreen, embedded in tab
    return ClientsScreen(authService: widget.authService, embedded: true);
  }
}

// ─────────────────────────────────────────────────────────────
// LEGACY – _InspectionsTab (kept for reference/reuse)
// ─────────────────────────────────────────────────────────────

class _InspectionsTab extends StatefulWidget {
  final AuthService authService;
  final void Function(Widget) onPush;
  const _InspectionsTab(
      {Key? key, required this.authService, required this.onPush})
      : super(key: key);

  @override
  State<_InspectionsTab> createState() => _InspectionsTabState();
}

class _InspectionsTabState extends State<_InspectionsTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController _tc;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final storage = widget.authService.storage;
    final reviewCount = storage.inspections.values
        .where((i) => i.status == InspectionStatus.review)
        .length;

    return Column(
      children: [
        TabBar(
          controller: _tc,
          labelColor: const Color(0xFF0EA5E9),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF0EA5E9),
          isScrollable: true,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Review'),
                  if (reviewCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$reviewCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Active'),
            const Tab(text: 'Schedule'),
            const Tab(text: 'History'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tc,
            children: [
              _InspectionList(
                  authService: widget.authService,
                  statuses: const [InspectionStatus.review],
                  emptyMessage: 'No inspections pending review',
                  emptyIcon: Icons.rate_review_outlined,
                  onPush: widget.onPush),
              _InspectionList(
                  authService: widget.authService,
                  statuses: const [
                    InspectionStatus.assigned,
                    InspectionStatus.inProgress
                  ],
                  emptyMessage: 'No active inspections',
                  emptyIcon: Icons.assignment_outlined,
                  onPush: widget.onPush),
              _ScheduleTabContent(
                  authService: widget.authService,
                  onPush: widget.onPush),
              _InspectionList(
                  authService: widget.authService,
                  statuses: const [
                    InspectionStatus.completed,
                    InspectionStatus.quoteSent
                  ],
                  emptyMessage: 'No completed inspections',
                  emptyIcon: Icons.check_circle_outline,
                  onPush: widget.onPush,
                  onRefresh: () => setState(() {})),
            ],
          ),
        ),
      ],
    );
  }
}

class _InspectionList extends StatelessWidget {
  final AuthService authService;
  final List<String> statuses;
  final String emptyMessage;
  final IconData emptyIcon;
  final void Function(Widget) onPush;
  final VoidCallback? onRefresh;

  const _InspectionList({
    Key? key,
    required this.authService,
    required this.statuses,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onPush,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final storage = authService.storage;
    final inspections = storage.inspections.values
        .where((i) => statuses.contains(i.status))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (inspections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(emptyMessage,
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: inspections.length,
      itemBuilder: (_, i) {
        final insp = inspections[i];
        final property = storage.properties[insp.propertyId];
        final techNames = insp.technicians
            .map((e) => storage.users[e]?.name ?? e)
            .join(', ');
        final isReview = insp.status == InspectionStatus.review;
        final isActive = insp.status == InspectionStatus.assigned ||
            insp.status == InspectionStatus.inProgress;
        final isCompleted = insp.status == InspectionStatus.completed ||
            insp.status == InspectionStatus.quoteSent;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: isReview
                ? () => onPush(ReviewInspectionDetailScreen(
                      authService: authService,
                      inspectionId: insp.id,
                      inspection: insp,
                    ))
                : isActive
                    ? () => onPush(DoInspectionScreen(
                          authService: authService,
                          inspectionId: insp.id,
                        ))
                    : null,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatusBadge(insp.status),
                      const Spacer(),
                      Text('Insp. #${insp.id}',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                      property?.address ??
                          'Property #${insp.propertyId}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(techNames.isNotEmpty
                              ? techNames
                              : 'Unassigned',
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12))),
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(insp.date,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                  // Review → "Review & Send Quote"
                  if (isReview) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 6),
                        ),
                        onPressed: () =>
                            onPush(ReviewInspectionDetailScreen(
                          authService: authService,
                          inspectionId: insp.id,
                          inspection: insp,
                        )),
                        child: const Text('Review & Send Quote'),
                      ),
                    ),
                  ],
                  // Active → "Start / Continue Walk"
                  if (isActive) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: insp.status == InspectionStatus.inProgress
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        icon: Icon(
                          insp.status == InspectionStatus.inProgress
                              ? Icons.play_arrow
                              : Icons.play_circle_outline,
                          size: 18,
                        ),
                        onPressed: () => onPush(DoInspectionScreen(
                          authService: authService,
                          inspectionId: insp.id,
                        )),
                        label: Text(insp.status == InspectionStatus.inProgress
                            ? 'Continue Walk'
                            : 'Start Walk'),
                      ),
                    ),
                  ],
                  // Completed → "Reopen"
                  if (isCompleted) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        icon: const Icon(Icons.replay, size: 18),
                        onPressed: () => _reopenInspection(context, insp),
                        label: const Text('Reopen for Editing'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _reopenInspection(BuildContext context, Inspection insp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reopen Inspection'),
        content: Text(
          'Reopen Inspection #${insp.id} for editing? '
          'This will set it back to In Progress so the technician (or you) can make changes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final storage = authService.storage;
              final updated = insp.copyWith(status: InspectionStatus.inProgress);
              storage.inspections[insp.id] = updated;
              storage.saveData();
              onRefresh?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Inspection reopened'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Reopen'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTabContent extends StatelessWidget {
  final AuthService authService;
  final void Function(Widget) onPush;
  const _ScheduleTabContent(
      {Key? key, required this.authService, required this.onPush})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final storage = authService.storage;
    final assigned = storage.inspections.values
        .where((i) => i.status == InspectionStatus.assigned)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Calendar view shortcut
        InkWell(
          onTap: () =>
              onPush(MonthlyDashboardScreen(authService: authService)),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month,
                    color: Colors.white, size: 28),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly Schedule',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      SizedBox(height: 2),
                      Text('View calendar & assign inspections',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white54, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Bulk schedule shortcut
        InkWell(
          onTap: () =>
              onPush(MonthlyDashboardScreen(authService: authService)),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.playlist_add_check,
                      color: Color(0xFFE65100), size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assign Inspections',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('Assign technicians to properties',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: Colors.grey.shade400),
              ],
            ),
          ),
        ),

        if (assigned.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionHeader('Upcoming Assigned'),
          const SizedBox(height: 8),
          ...assigned.take(5).map((insp) {
            final property =
                storage.properties[insp.propertyId];
            final techNames = insp.technicians
                .map((e) => storage.users[e]?.name ?? e)
                .join(', ');
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.assignment_ind,
                      color: Colors.blue.shade700, size: 20),
                ),
                title: Text(
                    property?.address ??
                        'Property #${insp.propertyId}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text(techNames.isNotEmpty
                    ? techNames
                    : 'Unassigned'),
                trailing: Text(insp.date,
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12)),
              ),
            );
          }).toList(),
        ],
      ],
    );
  }
}

class _UpcomingScheduleContent extends StatelessWidget {
  final AuthService authService;
  final void Function(Widget) onPush;
  const _UpcomingScheduleContent(
      {Key? key, required this.authService, required this.onPush})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final storage = authService.storage;
    final assigned = storage.inspections.values
        .where((i) => i.status == InspectionStatus.assigned)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (assigned.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No upcoming inspections',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => onPush(MonthlyDashboardScreen(authService: authService)),
              icon: const Icon(Icons.add),
              label: const Text('Schedule Inspections'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assigned.length,
      itemBuilder: (_, i) {
        final insp = assigned[i];
        final property = storage.properties[insp.propertyId];
        final techNames = insp.technicians
            .map((e) => storage.users[e]?.name ?? e)
            .join(', ');
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.assignment_ind,
                  color: Colors.blue.shade700, size: 20),
            ),
            title: Text(
                property?.address ?? 'Property #${insp.propertyId}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text(techNames.isNotEmpty ? techNames : 'Unassigned'),
            trailing: Text(insp.date,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB – QUOTES (inline, no separate screen push)
// ─────────────────────────────────────────────────────────────

class _QuotesTab extends StatefulWidget {
  final AuthService authService;
  final void Function(Widget) onPush;
  const _QuotesTab(
      {Key? key, required this.authService, required this.onPush})
      : super(key: key);

  @override
  State<_QuotesTab> createState() => _QuotesTabState();
}

class _QuotesTabState extends State<_QuotesTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController _tc;
  String _searchQuery = '';
  StreamSubscription<Map<int, Quote>>? _sub;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 4, vsync: this);
    _subscribeToQuotes();
  }

  void _subscribeToQuotes() {
    if (!widget.authService.storage.firestoreSyncEnabled) return;
    _sub = FirestoreService().watchQuotes().listen(
      (data) {
        if (!mounted) return;
        widget.authService.storage.quotes
          ..clear()
          ..addAll(data);
        setState(() {});
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tc.dispose();
    super.dispose();
  }

  List<Quote> _filtered(String? status) {
    var list =
        widget.authService.storage.quotes.values.toList();
    if (status != null) {
      list = list.where((q) => q.status == status).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((quote) {
        final prop = widget.authService.storage
            .properties[quote.propertyId];
        return (prop?.address.toLowerCase().contains(q) ?? false) ||
            (prop?.clientName.toLowerCase().contains(q) ?? false) ||
            quote.id.toString().contains(q);
      }).toList();
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        TabBar(
          controller: _tc,
          labelColor: const Color(0xFF0EA5E9),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF0EA5E9),
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Sent'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by address, client, or quote #',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tc,
            children: [
              _buildQuoteList(null),
              _buildQuoteList(QuoteStatus.sent),
              _buildQuoteList(QuoteStatus.approved),
              _buildQuoteList(QuoteStatus.rejected),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteList(String? status) {
    final quotes = _filtered(status);
    if (quotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
                status == null
                    ? 'No quotes yet'
                    : 'No ${QuoteStatus.getDisplayName(status)} quotes',
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 15)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        if (widget.authService.storage.firestoreSyncEnabled) {
          await widget.authService.storage.downloadFromFirestore();
        }
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quotes.length,
        itemBuilder: (_, i) =>
            _QuoteCard(
              quote: quotes[i],
              authService: widget.authService,
              onPush: widget.onPush,
              onRefresh: () => setState(() {}),
            ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final Quote quote;
  final AuthService authService;
  final void Function(Widget) onPush;
  final VoidCallback onRefresh;

  const _QuoteCard({
    Key? key,
    required this.quote,
    required this.authService,
    required this.onPush,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final property =
        authService.storage.properties[quote.propertyId];
    final statusColor = QuoteStatus.getColor(quote.status);
    final isApproved = quote.status == QuoteStatus.approved;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: isApproved
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Colors.green, width: 1.5))
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _QuoteStatusBadge(quote.status),
                  const Spacer(),
                  Text('Quote #${quote.id}',
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                          fontSize: 13)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        property?.address ??
                            'Unknown Property',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                ],
              ),
              if (property?.clientName.isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.person,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(property!.clientName,
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13)),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '\$${quote.totalCost.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor),
                  ),
                  const Spacer(),
                  if (isApproved &&
                      quote.clientSignature != null) ...[
                    const Icon(Icons.draw,
                        size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    const Text('Signed',
                        style: TextStyle(
                            color: Colors.green, fontSize: 12)),
                  ],
                ],
              ),
              // Action buttons per status
              if (isApproved) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final prop = authService
                          .storage.properties[quote.propertyId];
                      if (prop != null) {
                        onPush(ScheduleRepairScreen(
                          authService: authService,
                          quote: quote,
                          property: prop,
                        ));
                      }
                    },
                    icon: const Icon(Icons.calendar_month, size: 16),
                    label: const Text('Schedule Repairs'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final property =
        authService.storage.properties[quote.propertyId];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scroll) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Text('Quote #${quote.id}',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _QuoteStatusBadge(quote.status),
                ],
              ),
            ),
            const Divider(height: 20),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.all(16),
                children: [
                  _DetailRow(
                      'Property',
                      property?.address ?? 'Unknown'),
                  if (property?.clientName.isNotEmpty == true)
                    _DetailRow('Client', property!.clientName),
                  _DetailRow('Created',
                      QuoteService.formatDateTime(quote.createdAt)),
                  if (quote.sentAt != null)
                    _DetailRow('Sent',
                        QuoteService.formatDateTime(quote.sentAt)),
                  if (quote.viewedAt != null)
                    _DetailRow('Viewed',
                        QuoteService.formatDateTime(quote.viewedAt)),
                  const SizedBox(height: 16),
                  const Text('Items',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 8),
                  ...quote.lineItems.map((item) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(
                                    '${item.quantity}x ${item.displayDescription}'
                                    '${item.zoneNumber != null ? ' (Z${item.zoneNumber})' : ''}')),
                            Text(
                                '\$${item.totalPrice.toStringAsFixed(2)}'),
                          ],
                        ),
                      )),
                  const Divider(height: 20),
                  _TotalRow('Subtotal', quote.materialsCost),
                  if (quote.laborCost > 0)
                    _TotalRow('Labor', quote.laborCost),
                  if (quote.discount > 0)
                    _TotalRow('Discount', -quote.discount),
                  if (quote.tax > 0) _TotalRow('Tax', quote.tax),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text(
                          '\$${quote.totalCost.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(ctx).primaryColor)),
                    ],
                  ),
                  if (quote.clientNotes?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    const Text('Client Notes',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius:
                              BorderRadius.circular(8)),
                      child: Text(quote.clientNotes!),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Approved: schedule repairs
                  if (quote.status == QuoteStatus.approved) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (property != null) {
                          onPush(ScheduleRepairScreen(
                            authService: authService,
                            quote: quote,
                            property: property,
                          ));
                        }
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Schedule Repairs'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.all(14)),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Sent/Viewed: edit, resend, void
                  if (quote.status == QuoteStatus.sent ||
                      quote.status == QuoteStatus.viewed) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (property != null) {
                          onPush(SendQuoteScreen(
                            authService: authService,
                            property: property,
                            existingQuote: quote,
                          ));
                        }
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit & Resend Quote'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(ctx).primaryColor,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.all(14)),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _resendQuote(context,
                            quote, property);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Resend Quote'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding:
                              const EdgeInsets.all(14)),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _voidQuote(context, quote);
                      },
                      icon: const Icon(Icons.block),
                      label: const Text('Void Quote'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(
                              color: Colors.red),
                          padding:
                              const EdgeInsets.all(14)),
                    ),
                  ],

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _voidQuote(BuildContext context, Quote q) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void Quote'),
        content: Text(
            'Void Quote #${q.id}? This will cancel the quote and the client link will no longer work.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              final storage = authService.storage;
              storage.quotes[q.id] =
                  q.copyWith(status: QuoteStatus.expired);
              storage.saveData();
              onRefresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Quote voided'),
                    backgroundColor: Colors.orange),
              );
            },
            child: const Text('Void Quote'),
          ),
        ],
      ),
    );
  }

  Future<void> _resendQuote(BuildContext context, Quote q,
      Property? property) async {
    final storage = authService.storage;
    final updated = q.copyWith(
      sentAt: DateTime.now().toIso8601String(),
    );
    storage.quotes[q.id] = updated;
    storage.saveData();
    onRefresh();

    final quoteUrl = QuoteService.generateQuoteUrl(updated.accessToken);
    final emailMsg = property != null
        ? QuoteService.formatQuoteMessage(
            quote: updated, property: property, quoteUrl: quoteUrl)
        : 'View your quote: $quoteUrl';
    final smsMsg = property != null
        ? QuoteService.formatSmsMessage(
            quote: updated, property: property, quoteUrl: quoteUrl)
        : 'View your quote: $quoteUrl';

    final emailCtrl = TextEditingController(text: property?.clientEmail ?? '');
    final phoneCtrl = TextEditingController(text: property?.clientPhone ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Resend Quote #${q.id}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Client Email',
                prefixIcon: Icon(Icons.email_outlined),
                hintText: 'Enter email address',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Client Phone',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: 'Enter phone number',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final email = emailCtrl.text.trim();
                if (email.isEmpty) return;
                Navigator.pop(context);
                final subject = Uri.encodeComponent(
                    'Quote #${q.id} from ${q.companyName}');
                final body = Uri.encodeComponent(emailMsg);
                final uri = Uri.parse(
                    'mailto:$email?subject=$subject&body=$body');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              icon: const Icon(Icons.email),
              label: const Text('Send via Email'),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(14)),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final phone = phoneCtrl.text.trim();
                if (phone.isEmpty) return;
                Navigator.pop(context);
                final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
                final body = Uri.encodeComponent(smsMsg);
                final uri = Uri.parse('sms:$cleanPhone?body=$body');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              icon: const Icon(Icons.sms),
              label: const Text('Send via Text'),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(14)),
            ),
          ],
        ),
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────
// TAB 4 – MORE
// ─────────────────────────────────────────────────────────────

class _MoreTab extends StatelessWidget {
  final AuthService authService;
  final void Function(Widget) onPush;
  const _MoreTab(
      {Key? key, required this.authService, required this.onPush})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const _SectionHeader('Properties & Inspections'),
        const SizedBox(height: 8),
        _NavCard(
          icon: Icons.home_work_outlined,
          label: 'Properties',
          subtitle: 'View and manage all properties',
          color: const Color(0xFF0277BD),
          onTap: () =>
              onPush(_PropertiesFullScreen(authService: authService)),
        ),
        _NavCard(
          icon: Icons.receipt_long_outlined,
          label: 'Quotes',
          subtitle: 'All quotes and approvals',
          color: const Color(0xFF7C3AED),
          onTap: () =>
              onPush(_QuotesFullScreen(authService: authService)),
        ),
        _NavCard(
          icon: Icons.receipt_outlined,
          label: 'Invoices',
          subtitle: 'Billing, payments, and records',
          color: const Color(0xFF059669),
          onTap: () =>
              onPush(InvoicesScreen(authService: authService)),
        ),
        _NavCard(
          icon: Icons.add_location_alt_outlined,
          label: 'New Property Walk',
          subtitle: 'Create property and start inspection',
          color: const Color(0xFF2E7D32),
          onTap: () =>
              onPush(CreateWalkScreen(authService: authService)),
        ),
        const SizedBox(height: 12),
        const _SectionHeader('Work'),
        const SizedBox(height: 8),
        _NavCard(
          icon: Icons.construction_outlined,
          label: 'Repair Tasks',
          subtitle: 'Track approved repair work',
          color: const Color(0xFFF57F17),
          onTap: () =>
              onPush(RepairTasksListScreen(authService: authService)),
        ),
        _NavCard(
          icon: Icons.build_outlined,
          label: 'Repair Items & Pricing',
          subtitle: 'Configure parts and pricing',
          color: const Color(0xFF1565C0),
          onTap: () =>
              onPush(RepairItemsScreen(authService: authService)),
        ),
        _NavCard(
          icon: Icons.edit_note_outlined,
          label: 'Custom Quote',
          subtitle: 'Create a quote with custom line items',
          color: const Color(0xFF7C3AED),
          onTap: () =>
              onPush(CustomQuoteScreen(authService: authService)),
        ),
        const SizedBox(height: 12),
        const _SectionHeader('Admin'),
        const SizedBox(height: 8),
        _NavCard(
          icon: Icons.people_outline,
          label: 'Team Members',
          subtitle: 'Manage technicians and managers',
          color: const Color(0xFF283593),
          onTap: () => onPush(UsersScreen(authService: authService)),
        ),
        _NavCard(
          icon: Icons.assessment_outlined,
          label: 'Monthly Reports',
          subtitle: 'Performance and billing reports',
          color: const Color(0xFF00838F),
          onTap: () =>
              onPush(MonthlyReportScreen(authService: authService)),
        ),
        _NavCard(
          icon: Icons.settings_outlined,
          label: 'Settings',
          subtitle: 'Company profile and configuration',
          color: const Color(0xFF455A64),
          onTap: () =>
              onPush(CompanySettingsScreen(authService: authService)),
        ),
      ],
    );
  }
}

// Full-screen wrappers for Properties and Quotes (accessed from More tab)
class _PropertiesFullScreen extends StatefulWidget {
  final AuthService authService;
  const _PropertiesFullScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<_PropertiesFullScreen> createState() => _PropertiesFullScreenState();
}

class _PropertiesFullScreenState extends State<_PropertiesFullScreen> {
  void _push(Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen))
        .then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Properties')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _push(CreatePropertyScreen(authService: widget.authService)),
        icon: const Icon(Icons.add),
        label: const Text('New Property'),
      ),
      body: _PropertiesTab(authService: widget.authService, onPush: _push),
    );
  }
}

class _QuotesFullScreen extends StatefulWidget {
  final AuthService authService;
  const _QuotesFullScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<_QuotesFullScreen> createState() => _QuotesFullScreenState();
}

class _QuotesFullScreenState extends State<_QuotesFullScreen> {
  void _push(Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen))
        .then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quotes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _push(CustomQuoteScreen(authService: widget.authService)),
        icon: const Icon(Icons.add),
        label: const Text('Custom Quote'),
      ),
      body: _QuotesTab(authService: widget.authService, onPush: _push),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED HELPER WIDGETS
// ─────────────────────────────────────────────────────────────

class _SyncIndicator extends StatefulWidget {
  final StorageService storage;
  const _SyncIndicator({Key? key, required this.storage}) : super(key: key);

  @override
  State<_SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<_SyncIndicator> {
  bool _syncing = false;

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      await widget.storage.uploadToFirestore();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Data synced to cloud'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Sync failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.storage.firestoreSyncEnabled;
    final primary = Theme.of(context).primaryColor;
    return IconButton(
      icon: _syncing
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: primary))
          : Icon(enabled ? Icons.cloud_done : Icons.cloud_off,
              color: enabled ? primary : Colors.grey.shade400),
      tooltip: enabled
          ? 'Cloud sync enabled (tap to sync)'
          : 'Cloud sync disabled',
      onPressed: enabled && !_syncing ? _sync : null,
    );
  }
}

class _ActionRequiredCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionRequiredCard({
    Key? key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatCard({
    Key? key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: color.withOpacity(0.8))),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              Icon(Icons.chevron_right,
                  color: Colors.grey.shade300, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NavCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A2332))),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey.shade300, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 0.8));
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = InspectionStatus.getColor(status);
    final icon = InspectionStatus.getIcon(status);
    String label;
    switch (status) {
      case InspectionStatus.assigned:
        label = 'Assigned';
        break;
      case InspectionStatus.inProgress:
        label = 'In Progress';
        break;
      case InspectionStatus.review:
        label = 'Needs Review';
        break;
      case InspectionStatus.quoteSent:
        label = 'Quote Sent';
        break;
      case InspectionStatus.completed:
        label = 'Completed';
        break;
      default:
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}

class _QuoteStatusBadge extends StatelessWidget {
  final String status;
  const _QuoteStatusBadge(this.status, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = QuoteStatus.getColor(status);
    final icon = QuoteStatus.getIcon(status);
    final label = QuoteStatus.getDisplayName(status);
    final isApproved = status == QuoteStatus.approved;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 13,
              color: isApproved ? Colors.white : color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isApproved ? Colors.white : color)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  const _TotalRow(this.label, this.value, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade600)),
          Text('\$${value.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}
