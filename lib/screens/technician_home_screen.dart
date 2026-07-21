import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../models/inspection.dart';
import '../models/repair_task.dart';
import '../constants/status_constants.dart';
import 'technician/create_walk_screen.dart';
import 'technician/setup_property_screen.dart';
import 'technician/my_completed_screen.dart';
import 'technician/repair_tasks_screen.dart';
import 'technician/do_inspection_screen.dart';
import 'technician/do_repair_task_screen.dart';
import 'login_screen.dart';

// ─────────────────────────────────────────────────────────────
// TECHNICIAN HOME SHELL – Jobber-style bottom nav with 4 tabs
// ─────────────────────────────────────────────────────────────

class TechnicianHomeScreen extends StatefulWidget {
  final AuthService authService;
  const TechnicianHomeScreen({Key? key, required this.authService})
      : super(key: key);

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  int _selectedIndex = 0;

  static const _tabTitles = [
    'Today',
    'Inspections',
    'Repair Tasks',
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
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    final auth = widget.authService;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.water_drop, color: Theme.of(context).primaryColor, size: 22),
            const SizedBox(width: 8),
            Text(_tabTitles[_selectedIndex]),
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
              index: _selectedIndex,
              children: [
                _TodayTab(authService: auth, onPush: _push),
                _TechInspectionsTab(authService: auth, onPush: _push),
                _TechRepairTasksTab(authService: auth, onPush: _push),
                _TechMoreTab(authService: auth, onPush: _push),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.today_outlined),
              activeIcon: Icon(Icons.today),
              label: 'Today'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Inspections'),
          BottomNavigationBarItem(
              icon: Icon(Icons.construction_outlined),
              activeIcon: Icon(Icons.construction),
              label: 'Repairs'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              activeIcon: Icon(Icons.menu),
              label: 'More'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 0 – TODAY
// ─────────────────────────────────────────────────────────────

class _TodayTab extends StatelessWidget {
  final AuthService authService;
  final void Function(Widget) onPush;

  const _TodayTab(
      {Key? key, required this.authService, required this.onPush})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final storage = authService.storage;
    final currentEmail = authService.currentUser?.email ?? '';
    final name = authService.currentUser?.name ?? 'Technician';

    // My active inspections
    final activeInspections = storage.inspections.values
        .where((i) =>
            i.technicians.contains(currentEmail) &&
            (i.status == InspectionStatus.assigned ||
                i.status == InspectionStatus.inProgress))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // My active repair tasks
    final activeTasks = storage.repairTasks.values
        .where((t) =>
            t.assignedTechnicians.contains(currentEmail) &&
            (t.status == RepairTaskStatus.assigned ||
                t.status == RepairTaskStatus.inProgress))
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

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
        Text("Here's your schedule for today",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 8),

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
                Icon(Icons.info_outline,
                    color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pricing not configured. Contact your manager before starting inspections.',
                    style: TextStyle(
                        fontSize: 13, color: Colors.orange.shade900),
                  ),
                ),
              ],
            ),
          ),

        // Stats row
        Row(
          children: [
            Expanded(
              child: _TechStatCard(
                label: 'Inspections',
                value: activeInspections.length.toString(),
                color: Colors.blue,
                icon: Icons.assignment_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TechStatCard(
                label: 'Repair Tasks',
                value: activeTasks.length.toString(),
                color: const Color(0xFFF57F17),
                icon: Icons.construction_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Active Inspections section
        if (activeInspections.isNotEmpty) ...[
          _SectionHeader(
              'Active Inspections (${activeInspections.length})'),
          const SizedBox(height: 8),
          ...activeInspections.map((insp) {
            final property = storage.properties[insp.propertyId];
            final isInProgress =
                insp.status == InspectionStatus.inProgress;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _InspStatusBadge(insp.status),
                        const Spacer(),
                        Text('Insp. #${insp.id}',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                        property?.address ??
                            'Property #${insp.propertyId}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    if (property?.clientName.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(property!.clientName,
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13)),
                    ],
                    if (property?.notes.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.note, size: 14, color: Colors.amber.shade700),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(property!.notes,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.amber.shade900,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Show "Setup Property" when property has no zones configured
                    if (property != null && property.allZones.isEmpty) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              onPush(SetupPropertyScreen(
                            authService: authService,
                            propertyId: property.id,
                          )),
                          icon: const Icon(Icons.build_circle_outlined, size: 18),
                          label: const Text('Setup Property Details'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0EA5E9),
                            side: const BorderSide(color: Color(0xFF0EA5E9)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            onPush(DoInspectionScreen(
                          authService: authService,
                          inspectionId: insp.id,
                        )),
                        icon: Icon(
                            isInProgress
                                ? Icons.play_arrow
                                : Icons.play_circle_outline,
                            size: 18),
                        label: Text(isInProgress
                            ? 'Continue Inspection'
                            : 'Start Inspection'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isInProgress
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.assignment_outlined,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text('No active inspections',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('You\'re all caught up!',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 12)),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () =>
                      onPush(CreateWalkScreen(authService: authService)),
                  icon: const Icon(Icons.add_location_alt, size: 18),
                  label: const Text('New Property Inspection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Active Repair Tasks section
        if (activeTasks.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionHeader('Repair Tasks (${activeTasks.length})'),
          const SizedBox(height: 8),
          ...activeTasks.map((task) {
            final property = storage.properties[task.propertyId];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TaskStatusBadge(task.status),
                        const Spacer(),
                        Text('Task #${task.id}',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                        property?.address ??
                            'Property #${task.propertyId}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(task.scheduledDate,
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12)),
                        const SizedBox(width: 12),
                        Icon(Icons.build_outlined,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text('${task.repairs.length} items',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            onPush(DoRepairTaskScreen(
                          authService: authService,
                          task: task,
                        )),
                        icon: const Icon(Icons.construction, size: 18),
                        label: const Text('Work on Task'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF57F17),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 1 – INSPECTIONS
// ─────────────────────────────────────────────────────────────

class _TechInspectionsTab extends StatefulWidget {
  final AuthService authService;
  final void Function(Widget) onPush;

  const _TechInspectionsTab(
      {Key? key, required this.authService, required this.onPush})
      : super(key: key);

  @override
  State<_TechInspectionsTab> createState() => _TechInspectionsTabState();
}

class _TechInspectionsTabState extends State<_TechInspectionsTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController _tc;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final email = widget.authService.currentUser?.email ?? '';
    final storage = widget.authService.storage;

    // Filter by current technician
    final assigned = storage.inspections.values
        .where((i) =>
            i.technicians.contains(email) &&
            i.status == InspectionStatus.assigned)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final inProgress = storage.inspections.values
        .where((i) =>
            i.technicians.contains(email) &&
            i.status == InspectionStatus.inProgress)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final completed = storage.inspections.values
        .where((i) =>
            i.technicians.contains(email) &&
            (i.status == InspectionStatus.completed ||
                i.status == InspectionStatus.quoteSent))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: [
        TabBar(
          controller: _tc,
          labelColor: const Color(0xFF0EA5E9),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF0EA5E9),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Assigned'),
                  if (assigned.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _Badge(assigned.length, Colors.blue),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Active'),
                  if (inProgress.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _Badge(inProgress.length, Colors.amber),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Completed'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tc,
            children: [
              _TechInspectionList(
                inspections: assigned,
                storage: storage,
                authService: widget.authService,
                emptyMessage: 'No assigned inspections',
                onPush: widget.onPush,
              ),
              _TechInspectionList(
                inspections: inProgress,
                storage: storage,
                authService: widget.authService,
                emptyMessage: 'No active inspections',
                onPush: widget.onPush,
              ),
              _TechInspectionList(
                inspections: completed,
                storage: storage,
                authService: widget.authService,
                emptyMessage: 'No completed inspections yet',
                onPush: widget.onPush,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TechInspectionList extends StatelessWidget {
  final List<Inspection> inspections;
  final StorageService storage;
  final AuthService authService;
  final String emptyMessage;
  final void Function(Widget) onPush;

  const _TechInspectionList({
    Key? key,
    required this.inspections,
    required this.storage,
    required this.authService,
    required this.emptyMessage,
    required this.onPush,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (inspections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(emptyMessage,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 15)),
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
        final isCompleted = insp.status == InspectionStatus.completed ||
            insp.status == InspectionStatus.quoteSent;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _InspStatusBadge(insp.status),
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
                if (property?.clientName.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(property!.clientName,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13)),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(insp.date,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(width: 12),
                    Icon(Icons.build_outlined,
                        size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('${insp.repairs.length} repairs found',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
                if (!isCompleted) ...[
                  const SizedBox(height: 10),
                  if (property != null && property.allZones.isEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            onPush(SetupPropertyScreen(
                          authService: authService,
                          propertyId: property.id,
                        )),
                        icon: const Icon(Icons.build_circle_outlined, size: 18),
                        label: const Text('Setup Property'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0EA5E9),
                          side: const BorderSide(color: Color(0xFF0EA5E9)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          onPush(DoInspectionScreen(
                        authService: authService,
                        inspectionId: insp.id,
                      )),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: Text(
                          insp.status == InspectionStatus.inProgress
                              ? 'Continue'
                              : 'Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 2 – REPAIR TASKS
// ─────────────────────────────────────────────────────────────

class _TechRepairTasksTab extends StatefulWidget {
  final AuthService authService;
  final void Function(Widget) onPush;

  const _TechRepairTasksTab(
      {Key? key, required this.authService, required this.onPush})
      : super(key: key);

  @override
  State<_TechRepairTasksTab> createState() => _TechRepairTasksTabState();
}

class _TechRepairTasksTabState extends State<_TechRepairTasksTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController _tc;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final email = widget.authService.currentUser?.email ?? '';
    final storage = widget.authService.storage;

    final allMyTasks = storage.repairTasks.values
        .where((t) => t.assignedTechnicians.contains(email))
        .toList();
    final pending = allMyTasks
        .where((t) =>
            t.status == RepairTaskStatus.assigned ||
            t.status == RepairTaskStatus.pending)
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    final inProgress = allMyTasks
        .where((t) => t.status == RepairTaskStatus.inProgress)
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    final completed = allMyTasks
        .where((t) => t.status == RepairTaskStatus.completed)
        .toList()
      ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

    return Column(
      children: [
        TabBar(
          controller: _tc,
          labelColor: const Color(0xFF0EA5E9),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF0EA5E9),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Assigned'),
                  if (pending.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _Badge(pending.length, Colors.blue),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('In Progress'),
                  if (inProgress.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _Badge(inProgress.length, Colors.amber),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Completed'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tc,
            children: [
              _TechTaskList(
                  tasks: pending,
                  storage: storage,
                  authService: widget.authService,
                  emptyMessage: 'No assigned tasks',
                  onPush: widget.onPush),
              _TechTaskList(
                  tasks: inProgress,
                  storage: storage,
                  authService: widget.authService,
                  emptyMessage: 'No tasks in progress',
                  onPush: widget.onPush),
              _TechTaskList(
                  tasks: completed,
                  storage: storage,
                  authService: widget.authService,
                  emptyMessage: 'No completed tasks',
                  onPush: widget.onPush),
            ],
          ),
        ),
      ],
    );
  }
}

class _TechTaskList extends StatelessWidget {
  final List<RepairTask> tasks;
  final StorageService storage;
  final AuthService authService;
  final String emptyMessage;
  final void Function(Widget) onPush;

  const _TechTaskList({
    Key? key,
    required this.tasks,
    required this.storage,
    required this.authService,
    required this.emptyMessage,
    required this.onPush,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(emptyMessage,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (_, i) {
        final task = tasks[i];
        final property = storage.properties[task.propertyId];
        final isCompleted = task.status == RepairTaskStatus.completed;
        final priorityColor = TaskPriority.getColor(task.priority);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TaskStatusBadge(task.status),
                    if (task.priority != TaskPriority.normal) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(task.priority.toUpperCase(),
                            style: TextStyle(
                                color: priorityColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                    const Spacer(),
                    Text('Task #${task.id}',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                    property?.address ??
                        'Property #${task.propertyId}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(task.scheduledDate,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(width: 12),
                    Icon(Icons.build_outlined,
                        size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('${task.repairs.length} items',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
                if (!isCompleted) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          onPush(DoRepairTaskScreen(
                        authService: authService,
                        task: task,
                      )),
                      icon: const Icon(Icons.construction, size: 18),
                      label: const Text('Work on Repairs'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF57F17),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ] else ...[
                  if (task.completedAt != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text('Completed ${_formatDate(task.completedAt!)}',
                            style: const TextStyle(
                                color: Colors.green, fontSize: 12)),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.month}/${d.day}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 3 – MORE
// ─────────────────────────────────────────────────────────────

class _TechMoreTab extends StatelessWidget {
  final AuthService authService;
  final void Function(Widget) onPush;

  const _TechMoreTab(
      {Key? key, required this.authService, required this.onPush})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const _SectionHeader('Inspections'),
        const SizedBox(height: 8),
        _TechNavCard(
          icon: Icons.add_location_alt_outlined,
          label: 'New Property Inspection',
          subtitle: 'Create property and start inspection',
          color: const Color(0xFFE65100),
          onTap: () =>
              onPush(CreateWalkScreen(authService: authService)),
        ),
        _TechNavCard(
          icon: Icons.check_circle_outline,
          label: 'Completed Inspections',
          subtitle: 'Review your finished work',
          color: const Color(0xFF6A1B9A),
          onTap: () =>
              onPush(MyCompletedScreen(authService: authService)),
        ),
        const SizedBox(height: 12),
        const _SectionHeader('Repairs'),
        const SizedBox(height: 8),
        _TechNavCard(
          icon: Icons.construction_outlined,
          label: 'All Repair Tasks',
          subtitle: 'View all assigned repair tasks',
          color: const Color(0xFFF57F17),
          onTap: () =>
              onPush(RepairTasksScreen(authService: authService)),
        ),
      ],
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
    return IconButton(
      icon: _syncing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Icon(enabled ? Icons.cloud_done : Icons.cloud_off,
              color: enabled ? Colors.white : Colors.white54),
      tooltip: enabled ? 'Cloud sync enabled (tap to sync)' : 'Cloud sync disabled',
      onPressed: enabled && !_syncing ? _sync : null,
    );
  }
}

class _TechStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _TechStatCard({
    Key? key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, color: color.withOpacity(0.8))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final Color color;
  const _Badge(this.count, this.color, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text('$count',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _InspStatusBadge extends StatelessWidget {
  final String status;
  const _InspStatusBadge(this.status, {Key? key}) : super(key: key);

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
        label = 'In Review';
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

class _TaskStatusBadge extends StatelessWidget {
  final String status;
  const _TaskStatusBadge(this.status, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = RepairTaskStatus.getColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        RepairTaskStatus.getDisplayName(status),
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: color),
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

class _TechNavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _TechNavCard({
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
                              fontSize: 12,
                              color: Color(0xFF94A3B8))),
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
