import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/responsive_helper.dart';
import '../core/colors.dart';
import '../services/league_service.dart';
import '../widgets/app_dialogs.dart';

class LeagueSettingsEditScreen extends StatefulWidget {
  final Map<String, dynamic> league;

  const LeagueSettingsEditScreen({super.key, required this.league});

  @override
  State<LeagueSettingsEditScreen> createState() => _LeagueSettingsEditScreenState();
}

class _LeagueSettingsEditScreenState extends State<LeagueSettingsEditScreen> {
  late TextEditingController _nameController;
  late String _selectedType;
  late int _selectedSize;
  late String _lineupType;
  late String _waiverOrder;
  late String _afterGamesWaivers;
  late String _waiverDuration;
  late bool _customDailyWaivers;
  late String _tradeReviewTime;
  late bool _tradeVetoes;
  late String _tradeDeadline;
  late int _irSlots;
  late String _autoSubs;
  late int _maxKeepers;
  late String _keepersDeadline;
  late bool _draftPickTrading;
  late bool _medianGame;
  late bool _preventBenchDrop;
  late bool _lockFreeAgents;
  late bool _overrideCapacity;
  late bool _disableInviteLinks;
  late bool _autoRenew;
  late int _draftRounds;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final dynamic settingsRaw = widget.league['settings'];
    final settings = settingsRaw is Map ? Map<String, dynamic>.from(settingsRaw) : {};
    
    _nameController = TextEditingController(text: widget.league['name'] ?? '');
    _selectedType = (widget.league['leagueType'] ?? 'DYNASTY').toString().toUpperCase();
    
    final rawMax = widget.league['maxMembers'];
    _selectedSize = rawMax is num ? rawMax.toInt() : int.tryParse(rawMax?.toString() ?? '10') ?? 10;
    
    _lineupType = (settings['lineupType'] ?? 'CLASSIC').toString().toUpperCase();
    _waiverOrder = (settings['waiverOrder'] ?? 'ROLLING WAIVERS').toString().toUpperCase();
    _afterGamesWaivers = (settings['afterGamesWaivers'] ?? '12PM WED').toString().toUpperCase();
    _waiverDuration = (settings['waiverDuration'] ?? '2 DAYS').toString().toUpperCase();
    _customDailyWaivers = settings['customDailyWaivers'] ?? false;
    _tradeReviewTime = (settings['tradeReviewTime'] ?? '2 DAYS').toString().toUpperCase();
    _tradeVetoes = settings['tradeVetoes'] ?? false;
    _tradeDeadline = (settings['tradeDeadline'] ?? 'WEEK 6').toString().toUpperCase();
    _irSlots = settings['irSlots'] as int? ?? 4;
    _autoSubs = (settings['autoSubs'] ?? 'OFF').toString().toUpperCase();
    _maxKeepers = settings['maxKeepers'] as int? ?? 1;
    _keepersDeadline = (settings['keepersDeadline'] ?? '1 WEEK').toString().toUpperCase();
    _draftPickTrading = settings['draftPickTrading'] ?? true;
    _medianGame = settings['medianGame'] ?? false;
    _preventBenchDrop = settings['preventBenchDrop'] ?? false;
    _lockFreeAgents = settings['lockFreeAgents'] ?? false;
    _overrideCapacity = settings['overrideCapacity'] ?? false;
    _disableInviteLinks = settings['disableInviteLinks'] ?? false;
    _autoRenew = settings['autoRenew'] ?? false;
    _draftRounds = settings['draftRounds'] as int? ?? 4;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final updateData = {
        'name': _nameController.text.trim(),
        'leagueType': _selectedType,
        'maxMembers': _selectedSize,
        'settings': {
          'lineupType': _lineupType,
          'waiverOrder': _waiverOrder,
          'afterGamesWaivers': _afterGamesWaivers,
          'waiverDuration': _waiverDuration,
          'customDailyWaivers': _customDailyWaivers,
          'tradeReviewTime': _tradeReviewTime,
          'tradeVetoes': _tradeVetoes,
          'tradeDeadline': _tradeDeadline,
          'irSlots': _irSlots,
          'autoSubs': _autoSubs,
          'maxKeepers': _maxKeepers,
          'keepersDeadline': _keepersDeadline,
          'draftPickTrading': _draftPickTrading,
          'medianGame': _medianGame,
          'preventBenchDrop': _preventBenchDrop,
          'lockFreeAgents': _lockFreeAgents,
          'overrideCapacity': _overrideCapacity,
          'disableInviteLinks': _disableInviteLinks,
          'autoRenew': _autoRenew,
          'draftRounds': _draftRounds,
        }
      };

      await LeagueService.updateLeagueSettings(widget.league['id'], updateData);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully'), backgroundColor: AppColors.accentCyan),
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showPremiumErrorDialog(context, message: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'GENERAL SETTINGS',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.only(right: 20), child: CircularProgressIndicator(color: AppColors.accentCyan)))
          else
            TextButton(
              onPressed: _saveChanges,
              child: Text('SAVE', style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 14.sp)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('GENERAL'),
            _buildTextField('LEAGUE NAME', _nameController),
            _buildOptionGroup<String>(
              label: 'LEAGUE TYPE',
              value: _selectedType,
              options: ['REDRAFT', 'KEEPER', 'DYNASTY'],
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            _buildOptionGroup<int>(
              label: 'TEAM SIZE',
              value: _selectedSize,
              options: [4, 6, 8, 10, 12, 14, 16, 18, 20],
              onChanged: (val) => setState(() => _selectedSize = val!),
            ),
            _buildOptionGroup<String>(
              label: 'LINEUP TYPE',
              value: _lineupType,
              options: ['CLASSIC', 'BEST BALL'],
              onChanged: (val) => setState(() => _lineupType = val!),
            ),

            _buildSectionHeader('WAIVERS'),
            _buildOptionGroup<String>(
              label: 'WAIVER ORDER',
              value: _waiverOrder,
              options: ['ROLLING WAIVERS', 'REVERSE STANDINGS', 'FAAB BIDDINGS'],
              onChanged: (val) => setState(() => _waiverOrder = val!),
            ),
            _buildOptionGroup<String>(
              label: 'AFTER GAMES WAIVERS CLEAR',
              value: _afterGamesWaivers,
              options: ['NONE', '12PM TUE', '12PM WED', '12PM THU'],
              onChanged: (val) => setState(() => _afterGamesWaivers = val!),
            ),
            _buildOptionGroup<String>(
              label: 'TIME PLAYERS ON WAIVERS AFTER DROP',
              value: _waiverDuration,
              options: ['NONE', '1 DAY', '2 DAYS', '3 DAYS'],
              onChanged: (val) => setState(() => _waiverDuration = val!),
            ),
            _buildSwitch('ALLOW CUSTOM DAILY WAIVERS', _customDailyWaivers, (val) => setState(() => _customDailyWaivers = val)),

            _buildSectionHeader('TRADES'),
            _buildOptionGroup<String>(
              label: 'TIME TO REVIEW PENDING TRADES',
              value: _tradeReviewTime,
              options: ['NONE', '1 DAY', '2 DAYS', '3 DAYS'],
              onChanged: (val) => setState(() => _tradeReviewTime = val!),
            ),
            _buildSwitch('ALLOW TRADE VETOES', _tradeVetoes, (val) => setState(() => _tradeVetoes = val)),
            _buildOptionGroup<String>(
              label: 'TRADE DEADLINE',
              value: _tradeDeadline,
              options: ['NONE', 'WEEK 9', 'WEEK 10', 'WEEK 11', 'WEEK 12', 'WEEK 13', 'WEEK 14'],
              onChanged: (val) => setState(() => _tradeDeadline = val!),
            ),
            _buildSwitch('ALLOW DRAFT PICK TRADING', _draftPickTrading, (val) => setState(() => _draftPickTrading = val)),

            _buildSectionHeader('ROSTER'),
            _buildOptionGroup<int>(
              label: 'INJURED RESERVE SLOTS',
              value: _irSlots,
              options: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
              onChanged: (val) => setState(() => _irSlots = val!),
            ),
            _buildOptionGroup<String>(
              label: 'PLAYER AUTO SUBS',
              value: _autoSubs,
              options: ['OFF', '1', '2', '3'],
              onChanged: (val) => setState(() => _autoSubs = val!),
            ),
            _buildOptionGroup<int>(
              label: 'MAX KEEPERS',
              value: _maxKeepers,
              options: List.generate(20, (i) => i + 1),
              onChanged: (val) => setState(() => _maxKeepers = val!),
            ),
            _buildOptionGroup<String>(
              label: 'KEEPERS DEADLINE PRIOR TO DRAFT',
              value: _keepersDeadline,
              options: ['NONE', '1 DAY', '2 DAY', '3 DAY', '1 WEEK', '2 WEEK', '1 MONTH'],
              onChanged: (val) => setState(() => _keepersDeadline = val!),
            ),
            _buildOptionGroup<int>(
              label: 'DRAFT ROUNDS',
              value: _draftRounds,
              options: List.generate(20, (i) => i + 1),
              onChanged: (val) => setState(() => _draftRounds = val!),
            ),

            _buildSectionHeader('ADVANCED'),
            _buildSwitch('GAME EACH WEEK AGAINST LEAGUE MEDIAN', _medianGame, (val) => setState(() => _medianGame = val)),
            _buildSwitch('PREVENT BENCH DROPS AFTER GAME STARTS', _preventBenchDrop, (val) => setState(() => _preventBenchDrop = val)),
            _buildSwitch('LOCK ALL FREE AGENT & WAIVER MOVES', _lockFreeAgents, (val) => setState(() => _lockFreeAgents = val)),
            _buildSwitch('OVERRIDE LEAGUE INVITE CAPACITY', _overrideCapacity, (val) => setState(() => _overrideCapacity = val)),
            _buildSwitch('DISABLE LEAGUE INVITE LINKS', _disableInviteLinks, (val) => setState(() => _disableInviteLinks = val)),
            _buildSwitch('AUTO RENEW LEAGUE', _autoRenew, (val) => setState(() => _autoRenew = val)),
            
            SizedBox(height: 32.h),
            _buildLeagueIdSection(),
            SizedBox(height: 48.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 32.h, bottom: 16.h),
      child: Text(
        title,
        style: TextStyle(color: AppColors.accentCyan, fontSize: 12.sp, fontWeight: FontWeight.w900, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white24, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          SizedBox(height: 12.h),
          TextField(
            controller: controller,
            style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.h), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionGroup<T>({
    required String label,
    required T value,
    required List<T> options,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white24, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.h),
            ),
            child: Column(
              children: options.map((opt) {
                final isSelected = opt == value;
                return ListTile(
                  dense: true,
                  title: Text(
                    opt.toString(),
                    style: TextStyle(
                      color: isSelected ? AppColors.accentCyan : Colors.white70,
                      fontSize: 13.sp,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                    ),
                  ),
                  trailing: isSelected ? Icon(Icons.check_circle, color: AppColors.accentCyan, size: 20.w) : null,
                  onTap: () => onChanged(opt),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.h),
      ),
      child: SwitchListTile(
        activeColor: AppColors.accentCyan,
        title: Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 13.sp, fontWeight: FontWeight.w500),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildLeagueIdSection() {
    final leagueId = widget.league['id'] ?? 'Unknown';
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LEAGUE ID', style: TextStyle(color: Colors.white24, fontSize: 10.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  leagueId,
                  style: TextStyle(color: Colors.white70, fontSize: 13.sp, fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy_rounded, color: AppColors.accentCyan, size: 20.w),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: leagueId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('League ID copied to clipboard'), behavior: SnackBarBehavior.floating),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
