import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/dashboard_service.dart';
import '../api/complaint_service.dart';
import '../api/visitor_service.dart';
import '../widgets/mainlayout.dart';

import 'allresidentsscreen.dart';
import 'announcementscreen.dart';
import 'complaints&helpscreen.dart';
import 'feescollectionscreen.dart';
import 'liveattendancescreen.dart';
import 'pull_to_refresh.dart';
import 'registrationreqestsscreen.dart';
import 'roles&permissionsscreens.dart';
import 'rooms&inventoryscreen.dart';
import 'usermanagementscreen.dart';
import 'visitorapprovalsscreen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<String> permissions = [];

  Map<String, dynamic> dashboardData = {};
  List<dynamic> recentAttendance = [];
  List<dynamic> recentVisitors = [];
  List<dynamic> recentAnnouncements = [];
  List<dynamic> recentComplaints = [];

  bool isLoading = true;
  String? errorMessage;
  String? processingVisitorId;

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  Future<void> _initDashboard() async {
    await loadPermissions();
    await loadDashboard();
  }

  Future<void> loadPermissions() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      permissions = prefs.getStringList("permissions") ?? [];
    });
  }

  Future<void> loadDashboard() async {
    try {
      if (mounted && dashboardData.isEmpty) {
        setState(() {
          isLoading = true;
          errorMessage = null;
        });
      }

      final stats = await DashboardService.getDashboardStats();
      final attendance = await DashboardService.getRecentAttendance();
      final visitors = await DashboardService.getRecentVisitors();
      final announcements = await DashboardService.getRecentAnnouncements();
      final complaints = await ComplaintService.getComplaints();

      if (!mounted) return;

      setState(() {
        dashboardData = Map<String, dynamic>.from(stats["data"] ?? {});
        recentAttendance = _extractList(attendance).take(4).toList();
        recentVisitors = _extractList(visitors).take(4).toList();
        recentAnnouncements = _extractList(announcements).take(4).toList();
        recentComplaints = _sortByDate(_extractList(complaints)).take(4).toList();
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = "Something went wrong while loading dashboard data.";
      });
    }
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;

    if (response is Map) {
      final possibleKeys = [
        "data",
        "items",
        "records",
        "results",
        "complaints",
        "visitors",
        "announcements",
        "attendance",
      ];

      for (final key in possibleKeys) {
        final value = response[key];
        if (value is List) return value;
      }
    }

    return [];
  }

  List<dynamic> _sortByDate(List<dynamic> list) {
    final copied = List<dynamic>.from(list);

    copied.sort((a, b) {
      final aDate = DateTime.tryParse(_pick(a, [
        "createdAt",
        "created_at",
        "date",
        "submittedAt",
      ]));
      final bDate = DateTime.tryParse(_pick(b, [
        "createdAt",
        "created_at",
        "date",
        "submittedAt",
      ]));

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    return copied;
  }

  Future<void> approveVisitor(String visitorId) async {
    if (visitorId.isEmpty) return;

    try {
      setState(() {
        processingVisitorId = visitorId;
      });

      await VisitorService.approveVisitor(visitorId);
      await loadDashboard();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Visitor approved successfully")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Visitor approval failed")),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        processingVisitorId = null;
      });
    }
  }

  Future<void> cancelVisitor(String visitorId) async {
    if (visitorId.isEmpty) return;

    try {
      setState(() {
        processingVisitorId = visitorId;
      });

      await VisitorService.rejectVisitor(
        visitorId,
        {
          "reason": "Cancelled from dashboard",
        },
      );

      await loadDashboard();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Visitor cancelled successfully")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Visitor cancel failed")),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        processingVisitorId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Dashboard",
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : PullToRefresh(
        onRefresh: loadDashboard,
        child: Container(
          color: const Color(0xffF6F8FC),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final padding = screenWidth < 600 ? 14.0 : 24.0;

              return SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _DashboardHeader(),
                        const SizedBox(height: 18),

                        if (errorMessage != null)
                          _ErrorCard(
                            message: errorMessage!,
                            onRetry: loadDashboard,
                          ),

                        if (!hasPermission("manage_dashboard"))
                          const _EmptyStateCard(
                            icon: Icons.lock_outline_rounded,
                            title: "No Dashboard Access",
                            message:
                            "You do not have permission to view this dashboard.",
                          )
              else ...[
              _buildKpiCards(),
              const SizedBox(height: 20),

              if (hasPermission("manage_attendance")) ...[
              _buildAttendanceCards(),
              const SizedBox(height: 20),
              ],

              _ResponsiveSectionWrap(
              children: [
              if (hasPermission("manage_visitors")) _buildVisitorsCards(),
              _buildRecentComplaintCards(),
              if (hasPermission("manage_announcements")) _buildAnnouncementCards(),
              ],
              ),

              const SizedBox(height: 20),

              _buildQuickActions(),
              ],

                        ],

                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCards() {
    final cards = [
      _KpiData(
        title: "Total Students",
        value: _value("totalResidents"),
        subtitle: "Registered residents",
        icon: Icons.groups_rounded,
        color: const Color(0xff2563EB),
      ),
      _KpiData(
        title: "Vacant Rooms",
        value: _value("availableRooms"),
        subtitle: "Available rooms",
        icon: Icons.meeting_room_rounded,
        color: const Color(0xff4F46E5),
      ),
      _KpiData(
        title: "Pending Complaints",
        value: _value("pendingComplaints"),
        subtitle: "Need action",
        icon: Icons.report_problem_rounded,
        color: const Color(0xffDC2626),
      ),
      _KpiData(
        title: "Today Visitors",
        value: _value("todayVisitors"),
        subtitle: "Visitor entries",
        icon: Icons.badge_rounded,
        color: const Color(0xffEA580C),
      ),
    ];

    return _ResponsiveWrap(
      minItemWidth: 240,
      spacing: 14,
      children: cards.map((item) {
        return _DecoratedKpiCard(data: item);
      }).toList(),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickActionData(
        title: "Residents",
        icon: Icons.groups_rounded,
        color: const Color(0xff2563EB),
        screen: const AllresidentSscreen(),
      ),
      _QuickActionData(
        title: "Registration",
        icon: Icons.app_registration_rounded,
        color: const Color(0xff7C3AED),
        screen: const RegistrationReqestsScreen(),
      ),
      _QuickActionData(
        title: "Attendance",
        icon: Icons.how_to_reg_rounded,
        color: const Color(0xff059669),
        screen: const LiveAttendanceScreen(),
      ),
      _QuickActionData(
        title: "Visitors",
        icon: Icons.badge_rounded,
        color: const Color(0xffEA580C),
        screen: const VisitorApprovalsScreen(),
      ),
      _QuickActionData(
        title: "Complaints",
        icon: Icons.support_agent_rounded,
        color: const Color(0xffDC2626),
        screen: const ComplaintsAndHelpscreen(),
      ),
      _QuickActionData(
        title: "Rooms",
        icon: Icons.meeting_room_rounded,
        color: const Color(0xff0891B2),
        screen: const RoomsAndInventoryscreen(),
      ),
      _QuickActionData(
        title: "Fees",
        icon: Icons.payments_rounded,
        color: const Color(0xffCA8A04),
        screen: const FeesCollectionScreen(),
      ),
      _QuickActionData(
        title: "Announce",
        icon: Icons.campaign_rounded,
        color: const Color(0xff2563EB),
        screen: const AnnouncementScreen(),
      ),
      _QuickActionData(
        title: "Users",
        icon: Icons.manage_accounts_rounded,
        color: const Color(0xff475569),
        screen: const UsermanAgementScreen(),
      ),
      _QuickActionData(
        title: "Roles",
        icon: Icons.admin_panel_settings_rounded,
        color: const Color(0xff9333EA),
        screen: const RolesAndPermissionsScreens(),
      ),
    ];

    return _SectionCard(
      title: "Quick Actions",
      subtitle: "Open important modules quickly",
      icon: Icons.flash_on_rounded,
      actionText: "Refresh",
      onAction: loadDashboard,
      child: _ResponsiveWrap(
        minItemWidth: 130,
        spacing: 12,
        children: actions.map((action) {
          return _QuickActionCard(
            data: action,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => action.screen,
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttendanceCards() {
    return _SectionCard(
      title: "Live Attendance",
      subtitle: "Recent student check-in and check-out details",
      icon: Icons.how_to_reg_rounded,
      actionText: "View All",
      onAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LiveAttendanceScreen(),
          ),
        );
      },
      child: recentAttendance.isEmpty
          ? const _EmptyStateCard(
        icon: Icons.event_busy_rounded,
        title: "No Attendance Found",
        message: "Recent attendance records will appear here.",
      )
          : _ResponsiveWrap(
        minItemWidth: 245,
        spacing: 12,
        children: recentAttendance.take(4).map((item) {
          return _AttendanceCard(
            studentName: _pick(item, ["studentName", "name", "residentName"]),
            roomNo: _pick(item, ["roomNo", "room", "roomNumber"]),
            checkIn: _formatTime(_pick(item, ["checkIn", "check_in"])),
            checkOut: _formatTime(_pick(item, ["checkOut", "check_out"])),
            status: _pick(item, ["status"]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVisitorsCards() {
    return _SectionCard(
      title: "Recent Visitors",
      subtitle: "Approve or cancel visitor requests",
      icon: Icons.people_alt_rounded,
      actionText: "View All",
      onAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VisitorApprovalsScreen(),
          ),
        );
      },
      child: recentVisitors.isEmpty
          ? const _EmptyStateCard(
        icon: Icons.person_off_rounded,
        title: "No Visitors Found",
        message: "Visitor details will appear here.",
      )
          : Column(
        children: recentVisitors.take(4).map<Widget>((visitor) {
          final visitorId = _idOf(visitor);
          final status = _pick(visitor, ["status"]);

          return _VisitorCard(
            visitorName: _pick(visitor, ["visitorName", "name"]),
            studentName: _pick(visitor, ["studentName", "residentName"]),
            roomNo: _pick(visitor, ["roomNo", "room", "roomNumber"]),
            status: status,
            isLoading: processingVisitorId == visitorId,
            canTakeAction: visitorId.isNotEmpty &&
                !_isClosedVisitorStatus(status),
            onApprove: () => approveVisitor(visitorId),
            onCancel: () => cancelVisitor(visitorId),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentComplaintCards() {
    return _SectionCard(
      title: "Recent Complaints",
      subtitle: "Latest complaint and help requests",
      icon: Icons.support_agent_rounded,
      actionText: "View All",
      onAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ComplaintsAndHelpscreen(),
          ),
        );
      },
      child: recentComplaints.isEmpty
          ? const _EmptyStateCard(
        icon: Icons.mark_chat_unread_outlined,
        title: "No Complaints Found",
        message: "Recent complaint records will appear here.",
      )
          : Column(
        children: recentComplaints.take(4).map<Widget>((item) {
          return _ComplaintCard(
            title: _pick(
              item,
              ["title", "subject", "complaintTitle", "category"],
              fallback: "Complaint",
            ),
            description: _pick(
              item,
              ["description", "message", "details", "complaint"],
              fallback: "No description available",
            ),
            studentName: _pick(
              item,
              ["studentName", "residentName", "createdBy", "name"],
            ),
            roomNo: _pick(item, ["roomNo", "room", "roomNumber"]),
            status: _pick(item, ["status"], fallback: "pending"),
            priority: _pick(item, ["priority"], fallback: "--"),
            date: _formatDate(
              _pick(item, ["createdAt", "created_at", "date", "submittedAt"]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAnnouncementCards() {
    return _SectionCard(
      title: "Announcements",
      subtitle: "Important hostel updates",
      icon: Icons.campaign_rounded,
      actionText: "View All",
      onAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AnnouncementScreen(),
          ),
        );
      },
      child: recentAnnouncements.isEmpty
          ? const _EmptyStateCard(
        icon: Icons.notifications_none_rounded,
        title: "No Announcements",
        message: "Latest announcements will appear here.",
      )
          : Column(
        children: recentAnnouncements.take(4).map<Widget>((item) {
          return _AnnouncementCard(
            title: _pick(item, ["title"]),
            message: _pick(item, ["message", "description"]),
            category: _pick(item, ["category"]),
            priority: _pick(item, ["priority"]),
            isActive: item is Map && item["isActive"] == true,
          );
        }).toList(),
      ),
    );
  }

  String _value(String key) {
    final value = dashboardData[key];
    if (value == null) return "0";
    return value.toString();
  }

  String _pick(
      dynamic item,
      List<String> keys, {
        String fallback = "--",
      }) {
    if (item is! Map) return fallback;

    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return fallback;
  }

  String _idOf(dynamic item) {
    return _pick(
      item,
      ["_id", "id", "visitorId", "visitor_id"],
      fallback: "",
    );
  }

  bool _isClosedVisitorStatus(String status) {
    final value = status.toLowerCase();

    return value == "approved" ||
        value == "rejected" ||
        value == "cancelled" ||
        value == "canceled" ||
        value == "checkedout" ||
        value == "checked_out" ||
        value == "completed";
  }

  String _formatTime(dynamic value) {
    if (value == null) return "--";

    final text = value.toString().trim();
    if (text.isEmpty || text == "--") return "--";

    final dateTime = DateTime.tryParse(text);

    if (dateTime != null) {
      final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
      final minute = dateTime.minute.toString().padLeft(2, "0");
      final suffix = dateTime.hour >= 12 ? "PM" : "AM";
      return "$hour:$minute $suffix";
    }

    return text;
  }

  String _formatDate(dynamic value) {
    if (value == null) return "--";

    final text = value.toString().trim();
    if (text.isEmpty || text == "--") return "--";

    final dateTime = DateTime.tryParse(text);

    if (dateTime == null) return text;

    final day = dateTime.day.toString().padLeft(2, "0");
    final month = dateTime.month.toString().padLeft(2, "0");
    final year = dateTime.year.toString();

    return "$day/$month/$year";
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff1E40AF),
            Color(0xff2563EB),
            Color(0xff38BDF8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff2563EB).withOpacity(.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            top: -28,
            child: Container(
              height: 105,
              width: 105,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 42,
            bottom: -40,
            child: Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hostel Overview",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Track rooms, students, visitors, complaints and updates.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _QuickActionData {
  final String title;
  final IconData icon;
  final Color color;
  final Widget screen;

  const _QuickActionData({
    required this.title,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

class _ResponsiveWrap extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  const _ResponsiveWrap({
    required this.children,
    required this.minItemWidth,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int count = (width / minItemWidth).floor();

        if (count < 1) count = 1;
        if (count > children.length) count = children.length;

        final itemWidth = count == 1
            ? width
            : (width - ((count - 1) * spacing)) / count;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

class _ResponsiveSectionWrap extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveSectionWrap({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 20.0;
        final width = constraints.maxWidth;
        final twoColumn = width >= 900;
        final itemWidth = twoColumn ? (width - spacing) / 2 : width;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

class _DecoratedKpiCard extends StatelessWidget {
  final _KpiData data;

  const _DecoratedKpiCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            data.color,
            Color.lerp(data.color, Colors.white, .22)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(.22),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -24,
            child: Container(
              height: 92,
              width: 92,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.13),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 22,
            bottom: -30,
            child: Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.20),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        data.icon,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        "Live",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String actionText;
  final VoidCallback onAction;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionText,
    required this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: const Color(0xff2563EB).withOpacity(.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xff2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xff111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onAction,
                child: Text(actionText),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData data;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffF9FAFB),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 124,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xffEEF2F7)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: data.color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  data.icon,
                  color: data.color,
                  size: 23,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Text(
                  data.title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff111827),
                    fontSize: 12,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final String studentName;
  final String roomNo;
  final String checkIn;
  final String checkOut;
  final String status;

  const _AttendanceCard({
    required this.studentName,
    required this.roomNo,
    required this.checkIn,
    required this.checkOut,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InitialAvatar(
                text: studentName,
                color: const Color(0xff2563EB),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff111827),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.bed_rounded,
            label: "Room",
            value: roomNo,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniInfoBox(
                  label: "Check In",
                  value: checkIn,
                  icon: Icons.login_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniInfoBox(
                  label: "Check Out",
                  value: checkOut,
                  icon: Icons.logout_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisitorCard extends StatelessWidget {
  final String visitorName;
  final String studentName;
  final String roomNo;
  final String status;
  final bool isLoading;
  final bool canTakeAction;
  final VoidCallback onApprove;
  final VoidCallback onCancel;

  const _VisitorCard({
    required this.visitorName,
    required this.studentName,
    required this.roomNo,
    required this.status,
    required this.isLoading,
    required this.canTakeAction,
    required this.onApprove,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              _InitialAvatar(
                text: visitorName,
                color: const Color(0xffEA580C),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visitorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff111827),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "$studentName • Room $roomNo",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: status),
            ],
          ),
          if (canTakeAction) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : onCancel,
                    icon: isLoading
                        ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.close_rounded, size: 18),
                    label: const Text("Cancel"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xffDC2626),
                      side: const BorderSide(color: Color(0xffFECACA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : onApprove,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text("Approve"),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final String title;
  final String description;
  final String studentName;
  final String roomNo;
  final String status;
  final String priority;
  final String date;

  const _ComplaintCard({
    required this.title,
    required this.description,
    required this.studentName,
    required this.roomNo,
    required this.status,
    required this.priority,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(
                icon: Icons.support_agent_rounded,
                color: const Color(0xffDC2626),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff111827),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff6B7280),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (studentName != "--")
                _SmallPill(
                  text: studentName,
                  icon: Icons.person_rounded,
                ),
              if (roomNo != "--")
                _SmallPill(
                  text: "Room $roomNo",
                  icon: Icons.bed_rounded,
                ),
              if (priority != "--")
                _SmallPill(
                  text: priority,
                  icon: Icons.flag_rounded,
                ),
              if (date != "--")
                _SmallPill(
                  text: date,
                  icon: Icons.calendar_month_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final String title;
  final String message;
  final String category;
  final String priority;
  final bool isActive;

  const _AnnouncementCard({
    required this.title,
    required this.message,
    required this.category,
    required this.priority,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(
                icon: Icons.campaign_rounded,
                color: const Color(0xff2563EB),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff111827),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isActive
                    ? const Color(0xff16A34A)
                    : const Color(0xffDC2626),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff6B7280),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (category != "--")
                _SmallPill(
                  text: category,
                  icon: Icons.category_rounded,
                ),
              if (priority != "--")
                _SmallPill(
                  text: priority,
                  icon: Icons.flag_rounded,
                ),
              _SmallPill(
                text: isActive ? "Active" : "Inactive",
                icon: isActive ? Icons.check_rounded : Icons.close_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;

  const _SoftCard({
    required this.child,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffEEF2F7)),
      ),
      child: child,
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: color,
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String text;
  final Color color;

  const _InitialAvatar({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final initial = text.trim().isEmpty || text == "--"
        ? "?"
        : text.trim().substring(0, 1).toUpperCase();

    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    Color textColor = const Color(0xff6B7280);
    Color background = const Color(0xffF3F4F6);

    if (normalized == "present" ||
        normalized == "approved" ||
        normalized == "active" ||
        normalized == "resolved" ||
        normalized == "completed") {
      textColor = const Color(0xff15803D);
      background = const Color(0xffDCFCE7);
    } else if (normalized == "pending" ||
        normalized == "open" ||
        normalized == "in progress" ||
        normalized == "in_progress") {
      textColor = const Color(0xffC2410C);
      background = const Color(0xffFFEDD5);
    } else if (normalized == "absent" ||
        normalized == "rejected" ||
        normalized == "cancelled" ||
        normalized == "canceled" ||
        normalized == "inactive") {
      textColor = const Color(0xffB91C1C);
      background = const Color(0xffFEE2E2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status == "--" ? "Unknown" : status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: const Color(0xff6B7280),
        ),
        const SizedBox(width: 6),
        Text(
          "$label: ",
          style: const TextStyle(
            color: Color(0xff6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff111827),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniInfoBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniInfoBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: const Color(0xff2563EB),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff6B7280),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff111827),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
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

class _SmallPill extends StatelessWidget {
  final String text;
  final IconData icon;

  const _SmallPill({
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: const Color(0xff2563EB),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xff2563EB),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffEEF2F7)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color: const Color(0xff9CA3AF),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xff111827),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff6B7280),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffFEF2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xffDC2626),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xffB91C1C),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}