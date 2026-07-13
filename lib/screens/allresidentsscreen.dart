import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/resident_service.dart';
import '../widgets/mainlayout.dart';
import 'pull_to_refresh.dart';

class AllresidentSscreen extends StatefulWidget {
  const AllresidentSscreen({super.key});

  @override
  State<AllresidentSscreen> createState() => _AllresidentSscreenState();
}

class _AllresidentSscreenState extends State<AllresidentSscreen> {
  final _residentFormKey = GlobalKey<FormState>();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController residentIdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController parentPhoneController = TextEditingController();
  final TextEditingController rollNoController = TextEditingController();
  final TextEditingController courseController = TextEditingController();
  final TextEditingController collegeController = TextEditingController();
  final TextEditingController bloodGroupController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController roomNoController = TextEditingController();
  final TextEditingController bedNoController = TextEditingController();

  bool isLoading = true;
  bool isActive = true;

  String selectedFilterBlock = 'All Blocks';
  String selectedStatus = 'All Status';
  String selectedBlock = 'A';
  String selectedFeeStatus = 'paid';
  String selectedAttendance = 'present';

  DateTime? selectedCheckInDate = DateTime.now();
  DateTime? selectedCheckOutDate;

  List<Map<String, dynamic>> residents = [];
  List<Map<String, dynamic>> filteredResidents = [];
  Map<String, dynamic>? selectedResident;

  static const Color _primary = Color(0xff635BFF);
  static const Color _secondary = Color(0xff22C55E);
  static const Color _success = Color(0xff16A34A);
  static const Color _warning = Color(0xffF59E0B);
  static const Color _danger = Color(0xffEF4444);
  static const Color _info = Color(0xff2563EB);

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    residentIdController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    parentPhoneController.dispose();
    rollNoController.dispose();
    courseController.dispose();
    collegeController.dispose();
    bloodGroupController.dispose();
    addressController.dispose();
    roomNoController.dispose();
    bedNoController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      if (mounted) setState(() => isLoading = true);

      final response = await ResidentService.getResidents();
      final data = response['data'];

      final loadedResidents = data is List
          ? data
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        residents = loadedResidents;
        filteredResidents = _buildFilteredResidents(loadedResidents);
        selectedResident = _resolveSelectedResident();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnack(e.toString(), isError: true);
    }
  }

  List<Map<String, dynamic>> _buildFilteredResidents(
    List<Map<String, dynamic>> source,
  ) {
    final search = searchController.text.trim().toLowerCase();

    return source.where((resident) {
      final block = _text(resident['block']).trim();
      final attendance = _attendanceValue(resident).toLowerCase();

      final blockMatch = selectedFilterBlock == 'All Blocks'
          ? true
          : block == selectedFilterBlock;

      final statusMatch = selectedStatus == 'All Status'
          ? true
          : attendance == selectedStatus.toLowerCase();

      final searchableText = [
        resident['name'],
        resident['residentId'],
        resident['roomNo'],
        resident['bedNo'],
        resident['phone'],
        resident['parentPhone'],
        resident['email'],
        resident['rollNo'],
        resident['course'],
        resident['college'],
        resident['bloodGroup'],
        resident['address'],
      ].map((e) => _text(e).toLowerCase()).join(' ');

      return blockMatch && statusMatch && searchableText.contains(search);
    }).toList();
  }

  void applyFilters() {
    setState(() {
      filteredResidents = _buildFilteredResidents(residents);
      selectedResident = _resolveSelectedResident();
    });
  }

  Map<String, dynamic>? _resolveSelectedResident() {
    if (filteredResidents.isEmpty) return null;

    final currentId = selectedResident?['_id']?.toString();
    if (currentId != null && currentId.isNotEmpty) {
      for (final resident in filteredResidents) {
        if (resident['_id']?.toString() == currentId) return resident;
      }
    }

    return filteredResidents.first;
  }

  Future<void> _deleteResident(String id) async {
    try {
      await ResidentService.deleteResident(id);

      if (!mounted) return;
      _showSnack('Resident deleted successfully');
      await loadData();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _updateAttendance(String id, String status) async {
    try {
      await ResidentService.updateAttendance(id, {'attendanceStatus': status});

      if (!mounted) return;
      _showSnack('Attendance updated');
      await loadData();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _updateFeeStatus(String id, String status) async {
    try {
      await ResidentService.updateFeeStatus(id, {'feeStatus': status});

      if (!mounted) return;
      _showSnack('Fee status updated');
      await loadData();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<bool> _saveResident(Map<String, dynamic>? resident) async {
    final isValid = _residentFormKey.currentState?.validate() ?? false;
    if (!isValid) return false;

    try {
      final body = {
        'residentId': residentIdController.text.trim(),
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'parentPhone': parentPhoneController.text.trim(),
        'rollNo': rollNoController.text.trim(),
        'course': courseController.text.trim(),
        'college': collegeController.text.trim(),
        'bloodGroup': bloodGroupController.text.trim(),
        'address': addressController.text.trim(),
        'block': selectedBlock.trim(),
        'roomNo': roomNoController.text.trim(),
        'bedNo': bedNoController.text.trim(),
        'checkInDate': selectedCheckInDate?.toIso8601String(),
        'checkOutDate': selectedCheckOutDate?.toIso8601String(),
        'feeStatus': selectedFeeStatus,
        'attendanceStatus': selectedAttendance,
        'isActive': isActive,
      };

      if (resident == null) {
        await ResidentService.createResident(body);
        if (!mounted) return true;
        _showSnack('Resident created successfully');
      } else {
        await ResidentService.updateResident(_text(resident['_id']), body);
        if (!mounted) return true;
        _showSnack('Resident updated successfully');
      }

      await loadData();
      return true;
    } catch (e) {
      if (!mounted) return false;
      _showSnack(e.toString(), isError: true);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'All Residents',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 720;
          final isDesktop = width >= 1120;

          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primary.withValues(alpha: 0.08),
                  Theme.of(context).colorScheme.surface,
                  _secondary.withValues(alpha: 0.06),
                ],
              ),
            ),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : PullToRefresh(
                    onRefresh: loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(isMobile ? 16 : 28),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1420),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _header(isMobile),
                              const SizedBox(height: 22),
                              _summarySection(isMobile),
                              const SizedBox(height: 22),
                              _filterPanel(isMobile),
                              const SizedBox(height: 24),
                              if (filteredResidents.isEmpty)
                                _emptyState()
                              else if (isDesktop)
                                _desktopResidentsView()
                              else
                                _responsiveCardsView(width),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _header(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff635BFF), Color(0xff7C6FFF), Color(0xff9F97FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Residents',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage hostelers, room assignments, attendance & fees',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showResidentDialog(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Resident'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Residents',
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage hostelers, room assignments, attendance & fees',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                FilledButton.icon(
                  onPressed: () => _showResidentDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Resident'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _summarySection(bool isMobile) {
    final total = residents.length;
    final inside = residents
        .where((r) => _attendanceValue(r) == 'present')
        .length;
    final outside = residents
        .where((r) => _attendanceValue(r) == 'outside')
        .length;
    final pendingFee = residents.where((r) => _feeValue(r) == 'pending').length;

    final cards = [
      _SummaryData('Total Residents', '$total', Icons.groups_rounded, _primary),
      _SummaryData(
        'Inside Hostel',
        '$inside',
        Icons.verified_rounded,
        _success,
      ),
      _SummaryData(
        'Outside / Leave',
        '${outside + (total - inside - outside)}',
        Icons.logout_rounded,
        _warning,
      ),
      _SummaryData(
        'Fee Pending',
        '$pendingFee',
        Icons.account_balance_wallet_rounded,
        _danger,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = isMobile
            ? 2
            : constraints.maxWidth >= 1100
            ? 4
            : 2;
        final spacing = isMobile ? 10.0 : 14.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(width: itemWidth, child: _summaryCard(card)),
              )
              .toList(),
        );
      },
    );
  }

  Widget _summaryCard(_SummaryData data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(
                data.icon,
                color: data.color,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: data.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _mutedTextColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterPanel(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              children: [
                _searchField(),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _blockFilter()),
                    const SizedBox(width: 10),
                    Expanded(child: _statusFilter()),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 2, child: _searchField()),
                const SizedBox(width: 16),
                Expanded(child: _blockFilter()),
                const SizedBox(width: 16),
                Expanded(child: _statusFilter()),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  tooltip: 'Refresh',
                  onPressed: loadData,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: searchController,
      onChanged: (_) => applyFilters(),
      decoration: _inputDecoration(
        'Search by name, id, room, phone, parent no...',
        icon: Icons.search_rounded,
        suffix: searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  searchController.clear();
                  applyFilters();
                },
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }

  Widget _blockFilter() {
    return DropdownButtonFormField<String>(
      initialValue: selectedFilterBlock,
      decoration: _inputDecoration('Block'),
      items: const [
        DropdownMenuItem(value: 'All Blocks', child: Text('All Blocks')),
        DropdownMenuItem(value: 'A', child: Text('Block A')),
        DropdownMenuItem(value: 'B', child: Text('Block B')),
        DropdownMenuItem(value: 'C', child: Text('Block C')),
      ],
      onChanged: (value) {
        if (value == null) return;
        selectedFilterBlock = value;
        applyFilters();
      },
    );
  }

  Widget _statusFilter() {
    return DropdownButtonFormField<String>(
      initialValue: selectedStatus,
      decoration: _inputDecoration('Status'),
      items: const [
        DropdownMenuItem(value: 'All Status', child: Text('All Status')),
        DropdownMenuItem(value: 'present', child: Text('Inside')),
        DropdownMenuItem(value: 'outside', child: Text('Outside')),
        DropdownMenuItem(value: 'leave', child: Text('Leave')),
      ],
      onChanged: (value) {
        if (value == null) return;
        selectedStatus = value;
        applyFilters();
      },
    );
  }

  Widget _desktopResidentsView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: _residentListPanel()),
        const SizedBox(width: 20),
        Expanded(
          flex: 4,
          child: selectedResident == null
              ? _emptyDetailPanel()
              : _residentDetailPanel(selectedResident!, showClose: false),
        ),
      ],
    );
  }

  Widget _residentListPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  _tableHeader('Resident', flex: 4),
                  _tableHeader('Room Location', flex: 3),
                  _tableHeader('Academic Group', flex: 3),
                  _tableHeader('Live Status', flex: 2),
                  _tableHeader('Review', flex: 1, alignEnd: true),
                ],
              ),
            ),
            ...filteredResidents.map(_residentTableRow),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(String text, {required int flex, bool alignEnd = false}) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: _mutedTextColor(context),
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _residentTableRow(Map<String, dynamic> resident) {
    final isSelected =
        selectedResident?['_id']?.toString() == resident['_id']?.toString();
    final status = _attendanceValue(resident);
    final statusColor = _statusColor(status);

    return InkWell(
      onTap: () => setState(() => selectedResident = resident),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected
              ? _primary.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? _primary : Colors.transparent,
              width: 3,
            ),
            bottom: BorderSide(color: _borderColor(context), width: 0.7),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  _avatar(resident, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _text(resident['name'], '-'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _text(resident['residentId'], '-'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _mutedTextColor(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: _twoLine(
                '${_text(resident['block'], '-')} - Room ${_text(resident['roomNo'], '-')}',
                'Bed ${_text(resident['bedNo'], '-')}',
              ),
            ),
            Expanded(
              flex: 3,
              child: _twoLine(
                _text(resident['course'], '-'),
                _text(resident['college'], '-'),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _chip(_attendanceLabel(status), statusColor, dot: true),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: isSelected ? _primary : _mutedTextColor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _responsiveCardsView(double width) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 880 ? 2 : 1;
        final spacing = 16.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: filteredResidents
              .map(
                (resident) => SizedBox(
                  width: cardWidth,
                  child: _residentMobileCard(resident),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _residentMobileCard(Map<String, dynamic> resident) {
    final status = _attendanceValue(resident);
    final fee = _feeValue(resident);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(resident, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(resident['name'], '-'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_text(resident['residentId'], '-')}  •  Roll: ${_text(resident['rollNo'], '-')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _mutedTextColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _chip(_attendanceLabel(status), _statusColor(status), dot: true),
            ],
          ),
          const SizedBox(height: 18),
          _miniInfoGrid([
            _InfoItem(
              Icons.meeting_room_rounded,
              'Block',
              _text(resident['block'], '-'),
            ),
            _InfoItem(
              Icons.bed_rounded,
              'Room / Bed',
              '${_text(resident['roomNo'], '-')} / ${_text(resident['bedNo'], '-')}',
            ),
            _InfoItem(
              Icons.school_rounded,
              'Course',
              _text(resident['course'], '-'),
            ),
            _InfoItem(
              Icons.account_balance_rounded,
              'College',
              _text(resident['college'], '-'),
            ),
            _InfoItem(Icons.payments_rounded, 'Fee', _capitalize(fee)),
            _InfoItem(
              Icons.bloodtype_rounded,
              'Blood',
              _text(resident['bloodGroup'], '-'),
            ),
          ]),
          const SizedBox(height: 16),
          _sectionTitle(Icons.contact_phone_rounded, 'Contact Registry'),
          const SizedBox(height: 12),
          _detailLine(
            Icons.phone_android_rounded,
            'Student',
            _text(resident['phone'], '-'),
          ),
          _detailLine(
            Icons.family_restroom_rounded,
            'Parent No',
            _text(resident['parentPhone'], '-'),
          ),
          _detailLine(
            Icons.email_rounded,
            'Email',
            _text(resident['email'], '-'),
          ),
          _detailLine(
            Icons.location_on_rounded,
            'Address',
            _text(resident['address'], '-'),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openResidentDetails(resident),
                  icon: const Icon(Icons.visibility_rounded),
                  label: const Text('View'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showResidentDialog(resident: resident),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _residentDetailPanel(
    Map<String, dynamic> resident, {
    required bool showClose,
  }) {
    final status = _attendanceValue(resident);
    final fee = _feeValue(resident);

    return _glassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primary.withValues(alpha: 0.13),
                    _secondary.withValues(alpha: 0.07),
                  ],
                ),
              ),
              child: Row(
                children: [
                  _avatar(resident, size: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _text(resident['name'], '-'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 5,
                          children: [
                            Text(
                              _text(resident['residentId'], '-'),
                              style: TextStyle(
                                color: _mutedTextColor(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            _chip(
                              _text(resident['bloodGroup'], 'BG -'),
                              _danger,
                              dense: true,
                            ),
                            _chip(
                              _boolValue(resident['isActive'])
                                  ? 'Active'
                                  : 'Inactive',
                              _boolValue(resident['isActive'])
                                  ? _success
                                  : _danger,
                              dense: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (showClose)
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(Icons.hotel_rounded, 'Room Assignment'),
                  const SizedBox(height: 10),
                  _miniInfoGrid([
                    _InfoItem(
                      Icons.apartment_rounded,
                      'Block',
                      _text(resident['block'], '-'),
                    ),
                    _InfoItem(
                      Icons.meeting_room_rounded,
                      'Room No',
                      _text(resident['roomNo'], '-'),
                    ),
                    _InfoItem(
                      Icons.bed_rounded,
                      'Bed Config',
                      _text(resident['bedNo'], '-'),
                    ),
                  ], columns: 3),
                  const SizedBox(height: 18),
                  _sectionTitle(
                    Icons.payments_rounded,
                    'Financial & Live Status',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: fee,
                          decoration: _inputDecoration('Fee Status'),
                          items: const [
                            DropdownMenuItem(
                              value: 'paid',
                              child: Text('Paid'),
                            ),
                            DropdownMenuItem(
                              value: 'pending',
                              child: Text('Pending'),
                            ),
                            DropdownMenuItem(
                              value: 'partial',
                              child: Text('Partial'),
                            ),
                          ],
                          onChanged: (value) async {
                            if (value == null) return;
                            await _updateFeeStatus(
                              _text(resident['_id']),
                              value,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: _inputDecoration('Attendance'),
                          items: const [
                            DropdownMenuItem(
                              value: 'present',
                              child: Text('Inside'),
                            ),
                            DropdownMenuItem(
                              value: 'outside',
                              child: Text('Outside'),
                            ),
                            DropdownMenuItem(
                              value: 'leave',
                              child: Text('Leave'),
                            ),
                          ],
                          onChanged: (value) async {
                            if (value == null) return;
                            await _updateAttendance(
                              _text(resident['_id']),
                              value,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _sectionTitle(
                    Icons.contact_phone_rounded,
                    'Contact Registry',
                  ),
                  const SizedBox(height: 10),
                  _detailLine(
                    Icons.phone_android_rounded,
                    'Student',
                    _text(resident['phone'], '-'),
                  ),
                  _detailLine(
                    Icons.family_restroom_rounded,
                    'Parent No',
                    _text(resident['parentPhone'], '-'),
                  ),
                  _detailLine(
                    Icons.email_rounded,
                    'Email',
                    _text(resident['email'], '-'),
                  ),
                  _detailLine(
                    Icons.location_on_rounded,
                    'Address',
                    _text(resident['address'], '-'),
                  ),
                  const SizedBox(height: 18),
                  _sectionTitle(Icons.school_rounded, 'Academic Details'),
                  const SizedBox(height: 10),
                  _miniInfoGrid([
                    _InfoItem(
                      Icons.confirmation_number_rounded,
                      'Roll No',
                      _text(resident['rollNo'], '-'),
                    ),
                    _InfoItem(
                      Icons.menu_book_rounded,
                      'Course',
                      _text(resident['course'], '-'),
                    ),
                    _InfoItem(
                      Icons.account_balance_rounded,
                      'College',
                      _text(resident['college'], '-'),
                    ),
                  ], columns: 3),
                  const SizedBox(height: 18),
                  _sectionTitle(Icons.calendar_month_rounded, 'Stay Details'),
                  const SizedBox(height: 10),
                  _miniInfoGrid([
                    _InfoItem(
                      Icons.login_rounded,
                      'Check In',
                      _formatDate(resident['checkInDate']),
                    ),
                    _InfoItem(
                      Icons.logout_rounded,
                      'Check Out',
                      _formatDate(resident['checkOutDate']),
                    ),
                  ], columns: 2),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showResidentDialog(resident: resident),
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _danger,
                            side: BorderSide(
                              color: _danger.withValues(alpha: 0.45),
                            ),
                          ),
                          onPressed: () => _confirmDelete(resident),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyDetailPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_rounded,
            size: 56,
            color: _mutedTextColor(context),
          ),
          const SizedBox(height: 14),
          Text(
            'Select a resident',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Resident details will appear here.',
            style: TextStyle(
              color: _mutedTextColor(context),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: _primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No residents found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search, block, or status filters.',
              style: TextStyle(
                color: _mutedTextColor(context),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openResidentDetails(Map<String, dynamic> resident) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1120) {
      setState(() => selectedResident = resident);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.55,
          maxChildSize: 0.94,
          builder: (_, controller) {
            return Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(26),
              ),
              child: SingleChildScrollView(
                controller: controller,
                padding: EdgeInsets.zero,
                child: _residentDetailPanel(resident, showClose: true),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Map<String, dynamic> resident) {
    final name = _text(resident['name'], 'this resident');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Delete Resident'),
          content: Text('Are you sure you want to delete $name?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _danger),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _deleteResident(_text(resident['_id']));
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showResidentDialog({Map<String, dynamic>? resident}) {
    _fillForm(resident);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            final size = MediaQuery.sizeOf(context);
            final dialogWidth = size.width < 720 ? size.width * 0.94 : 920.0;
            final dialogHeight = size.height * 0.88;

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 18,
              ),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              titlePadding: EdgeInsets.zero,
              contentPadding: EdgeInsets.zero,
              actionsPadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.fromLTRB(22, 20, 14, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primary.withValues(alpha: 0.14),
                      _secondary.withValues(alpha: 0.08),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        resident == null
                            ? Icons.person_add_alt_1_rounded
                            : Icons.edit_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resident == null ? 'Add Resident' : 'Edit Resident',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Complete resident profile, contact, room, and hostel status.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: _mutedTextColor(context)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              content: SizedBox(
                width: dialogWidth,
                height: dialogHeight,
                child: Form(
                  key: _residentFormKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumn = constraints.maxWidth >= 680;
                        final fieldWidth = twoColumn
                            ? (constraints.maxWidth - 14) / 2
                            : constraints.maxWidth;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _formSectionTitle(
                              Icons.badge_rounded,
                              'Basic Information',
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 14,
                              runSpacing: 14,
                              children: [
                                _formFieldBox(
                                  fieldWidth,
                                  _formTextField(
                                    residentIdController,
                                    'Resident ID',
                                    icon: Icons.confirmation_number_rounded,
                                    required: true,
                                  ),
                                ),
                                _formFieldBox(
                                  fieldWidth,
                                  _formTextField(
                                    nameController,
                                    'Full Name',
                                    icon: Icons.person_rounded,
                                    required: true,
                                  ),
                                ),
                                _formFieldBox(
                                  fieldWidth,
                                  _formTextField(
                                    rollNoController,
                                    'Roll No',
                                    icon: Icons.numbers_rounded,
                                  ),
                                ),
                                _formFieldBox(
                                  fieldWidth,
                                  _formTextField(
                                    bloodGroupController,
                                    'Blood Group',
                                    icon: Icons.bloodtype_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            _formSectionTitle(
                              Icons.contact_phone_rounded,
                              'Contact Details',
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 14,
                              runSpacing: 14,
                              children: [
                                _formFieldBox(
                                  fieldWidth,
                                  _formTextField(
                                    phoneController,
                                    'Student Phone',
                                    icon: Icons.phone_android_rounded,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                ),
                                _formFieldBox(
                                  fieldWidth,
                                  _formTextField(
                                    parentPhoneController,
                                    'Parent Phone',
                                    icon: Icons.family_restroom_rounded,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                ),
                                _formFieldBox(
                                  constraints.maxWidth,
                                  _formTextField(
                                    emailController,
                                    'Email',
                                    icon: Icons.email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      final text = value?.trim() ?? '';
                                      if (text.isEmpty) return null;
                                      final ok = RegExp(
                                        r'^[^@]+@[^@]+\.[^@]+$',
                                      ).hasMatch(text);
                                      return ok ? null : 'Enter valid email';
                                    },
                                  ),
                                ),
                                _formFieldBox(
                                  constraints.maxWidth,
                                  _formTextField(
                                    addressController,
                                    'Full Address',
                                    icon: Icons.location_on_rounded,
                                    maxLines: 3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            _formSectionTitle(
                              Icons.school_rounded,
                              'Academic Details',
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 14,
                              runSpacing: 14,
                              children: [
                                _formFieldBox(
                                  fieldWidth,
                                  _formTextField(
                                    courseController,
                                    'Course',
                                    icon: Icons.menu_book_rounded,
                                  ),
                                ),
                                _formFieldBox(
                                  fieldWidth,
                                  _formTextField(
                                    collegeController,
                                    'College',
                                    icon: Icons.account_balance_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            _formSectionTitle(
                              Icons.hotel_rounded,
                              'Room & Hostel Status',
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 14,
                              runSpacing: 14,
                              children: [
                                _formFieldBox(
                                  fieldWidth,
                                  _blockDropdown(dialogSetState),
                                ),
                                _formFieldBox(
                                  fieldWidth,
                                  _formTextField(
                                    roomNoController,
                                    'Room No',
                                    icon: Icons.meeting_room_rounded,
                                  ),
                                ),
                                _formFieldBox(
                                  fieldWidth,
                                  _formTextField(
                                    bedNoController,
                                    'Bed No',
                                    icon: Icons.bed_rounded,
                                  ),
                                ),
                                _formFieldBox(
                                  fieldWidth,
                                  _feeDropdown(dialogSetState),
                                ),
                                _formFieldBox(
                                  fieldWidth,
                                  _attendanceDropdown(dialogSetState),
                                ),
                                _formFieldBox(
                                  fieldWidth,
                                  _dateField(
                                    label: 'Check In Date',
                                    date: selectedCheckInDate,
                                    icon: Icons.login_rounded,
                                    onPick: (date) => dialogSetState(
                                      () => selectedCheckInDate = date,
                                    ),
                                  ),
                                ),
                                _formFieldBox(
                                  fieldWidth,
                                  _dateField(
                                    label: 'Check Out Date',
                                    date: selectedCheckOutDate,
                                    icon: Icons.logout_rounded,
                                    allowClear: true,
                                    onPick: (date) => dialogSetState(
                                      () => selectedCheckOutDate = date,
                                    ),
                                  ),
                                ),
                                _formFieldBox(
                                  constraints.maxWidth,
                                  SwitchListTile.adaptive(
                                    value: isActive,
                                    onChanged: (value) =>
                                        dialogSetState(() => isActive = value),
                                    title: const Text('Resident Active'),
                                    subtitle: const Text(
                                      'Turn off if resident is inactive or moved out.',
                                    ),
                                    secondary: const Icon(
                                      Icons.verified_user_rounded,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                        color: _borderColor(context),
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              actions: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: _borderColor(context)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: () async {
                          final saved = await _saveResident(resident);
                          if (saved && dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                        icon: Icon(
                          resident == null
                              ? Icons.add_rounded
                              : Icons.check_rounded,
                        ),
                        label: Text(
                          resident == null
                              ? 'Create Resident'
                              : 'Update Resident',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _fillForm(Map<String, dynamic>? resident) {
    residentIdController.text = _text(resident?['residentId']);
    nameController.text = _text(resident?['name']);
    emailController.text = _text(resident?['email']);
    phoneController.text = _text(resident?['phone']);
    parentPhoneController.text = _text(resident?['parentPhone']);
    rollNoController.text = _text(resident?['rollNo']);
    courseController.text = _text(resident?['course']);
    collegeController.text = _text(resident?['college']);
    bloodGroupController.text = _text(resident?['bloodGroup']);
    addressController.text = _text(resident?['address']);
    roomNoController.text = _text(resident?['roomNo']);
    bedNoController.text = _text(resident?['bedNo']);

    selectedBlock = _safeBlock(resident?['block']);
    selectedFeeStatus = _safeFee(_text(resident?['feeStatus'], 'paid'));
    selectedAttendance = _safeAttendance(
      _text(resident?['attendanceStatus'], 'present'),
    );
    isActive = _boolValue(resident?['isActive']);
    selectedCheckInDate =
        _parseDate(resident?['checkInDate']) ?? DateTime.now();
    selectedCheckOutDate = _parseDate(resident?['checkOutDate']);
  }

  Widget _formFieldBox(double width, Widget child) {
    return SizedBox(width: width, child: child);
  }

  Widget _formTextField(
    TextEditingController controller,
    String label, {
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator:
          validator ??
          (value) {
            if (!required) return null;
            return (value == null || value.trim().isEmpty)
                ? '$label is required'
                : null;
          },
      decoration: _inputDecoration(label, icon: icon),
    );
  }

  Widget _blockDropdown(StateSetter dialogSetState) {
    return DropdownButtonFormField<String>(
      initialValue: selectedBlock,
      decoration: _inputDecoration('Block', icon: Icons.apartment_rounded),
      items: const [
        DropdownMenuItem(value: 'A', child: Text('Block A')),
        DropdownMenuItem(value: 'B', child: Text('Block B')),
        DropdownMenuItem(value: 'C', child: Text('Block C')),
      ],
      onChanged: (value) {
        if (value == null) return;
        dialogSetState(() => selectedBlock = value);
      },
    );
  }

  Widget _feeDropdown(StateSetter dialogSetState) {
    return DropdownButtonFormField<String>(
      initialValue: selectedFeeStatus,
      decoration: _inputDecoration('Fee Status', icon: Icons.payments_rounded),
      items: const [
        DropdownMenuItem(value: 'paid', child: Text('Paid')),
        DropdownMenuItem(value: 'pending', child: Text('Pending')),
        DropdownMenuItem(value: 'partial', child: Text('Partial')),
      ],
      onChanged: (value) {
        if (value == null) return;
        dialogSetState(() => selectedFeeStatus = value);
      },
    );
  }

  Widget _attendanceDropdown(StateSetter dialogSetState) {
    return DropdownButtonFormField<String>(
      initialValue: selectedAttendance,
      decoration: _inputDecoration(
        'Attendance',
        icon: Icons.fact_check_rounded,
      ),
      items: const [
        DropdownMenuItem(value: 'present', child: Text('Inside')),
        DropdownMenuItem(value: 'outside', child: Text('Outside')),
        DropdownMenuItem(value: 'leave', child: Text('Leave')),
      ],
      onChanged: (value) {
        if (value == null) return;
        dialogSetState(() => selectedAttendance = value);
      },
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? date,
    required IconData icon,
    required ValueChanged<DateTime?> onPick,
    bool allowClear = false,
  }) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(
        text: date == null ? '' : _formatShortDate(date),
      ),
      decoration: _inputDecoration(
        label,
        icon: icon,
        suffix: allowClear && date != null
            ? IconButton(
                onPressed: () => onPick(null),
                icon: const Icon(Icons.close_rounded),
              )
            : const Icon(Icons.calendar_month_rounded),
      ),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? now,
          firstDate: DateTime(now.year - 10),
          lastDate: DateTime(now.year + 10),
        );
        if (picked != null) onPick(picked);
      },
    );
  }

  Widget _miniInfoGrid(List<_InfoItem> items, {int? columns}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actualColumns = columns ?? (constraints.maxWidth > 420 ? 2 : 1);
        final spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (actualColumns - 1)) /
            actualColumns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.035),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _borderColor(context)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.icon, size: 18, color: _primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: _mutedTextColor(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.value,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _detailLine(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _mutedTextColor(context)),
          const SizedBox(width: 10),
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: TextStyle(
                color: _mutedTextColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _primary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: _primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }

  Widget _formSectionTitle(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: _sectionTitle(icon, title),
    );
  }

  Widget _twoLine(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _mutedTextColor(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _avatar(Map<String, dynamic> resident, {double size = 52}) {
    final name = _text(resident['name'], 'R');
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts.first.characters.first}${parts.last.characters.first}'
        : name.characters.first;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, Color(0xff8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.28,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _chip(
    String label,
    Color color, {
    bool dot = false,
    bool dense = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    final theme = Theme.of(context);

    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.88 : 0.92,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.20 : 0.06,
            ),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    IconData? icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      labelStyle: TextStyle(
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? _danger : null,
      ),
    );
  }

  Color _borderColor(BuildContext context) {
    return Theme.of(context).dividerColor.withValues(alpha: 0.18);
  }

  Color _mutedTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white70 : const Color(0xff64748B);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return _success;
      case 'outside':
        return _warning;
      case 'leave':
        return _info;
      default:
        return _info;
    }
  }

  String _attendanceLabel(String status) {
    switch (status) {
      case 'present':
        return 'Inside';
      case 'outside':
        return 'Outside';
      case 'leave':
        return 'Leave';
      default:
        return _capitalize(status);
    }
  }

  String _attendanceValue(Map<String, dynamic> resident) {
    return _safeAttendance(_text(resident['attendanceStatus'], 'present'));
  }

  String _feeValue(Map<String, dynamic> resident) {
    return _safeFee(_text(resident['feeStatus'], 'pending'));
  }

  String _safeBlock(dynamic value) {
    final text = _text(value, 'A').trim();
    return ['A', 'B', 'C'].contains(text) ? text : 'A';
  }

  String _safeFee(String value) {
    final text = value.trim().toLowerCase();
    return ['paid', 'pending', 'partial'].contains(text) ? text : 'pending';
  }

  String _safeAttendance(String value) {
    final text = value.trim().toLowerCase();
    return ['present', 'outside', 'leave'].contains(text) ? text : 'present';
  }

  bool _boolValue(dynamic value) {
    if (value is bool) return value;
    if (value == null) return true;
    return value.toString().toLowerCase() == 'true';
  }

  String _text(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }

  DateTime? _parseDate(dynamic value) {
    final text = _text(value);
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return DateTime.tryParse(text);
  }

  String _formatDate(dynamic value) {
    final date = value is DateTime ? value : _parseDate(value);
    if (date == null) return '-';
    return _formatShortDate(date);
  }

  String _formatShortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _SummaryData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryData(this.title, this.value, this.icon, this.color);
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem(this.icon, this.label, this.value);
}
