import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import '../services/league_service.dart';
import '../widgets/app_dialogs.dart';

class LeagueScoringEditScreen extends StatefulWidget {
  final Map<String, dynamic> league;

  const LeagueScoringEditScreen({super.key, required this.league});

  @override
  State<LeagueScoringEditScreen> createState() => _LeagueScoringEditScreenState();
}

class _LeagueScoringEditScreenState extends State<LeagueScoringEditScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _scoring;
  bool _isSaving = false;

  final List<String> _categories = [
    'PASSING', 'RUSHING', 'RECEIVING', 'KICKING', 'DEFENSE', 'SPECIAL TEAMS', 'SPECIAL TEAMS PLAYER', 'MISCELLANEOUS', 'BONUSES', 'IDP'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    
    // Initialize scoring from league data or defaults
    final dynamic existingRaw = widget.league['scoringSettings'];
    _scoring = existingRaw is Map ? Map<String, dynamic>.from(existingRaw) : {};
    
    // Ensure all categories exist
    for (var cat in _categories) {
      _scoring[cat] ??= {};
    }

    _initializeDefaults();
  }

  void _initializeDefaults() {
    // Helper to merge defaults without losing existing custom values
    Map<String, dynamic> merge(String category, Map<String, dynamic> defaults) {
      final dynamic existingRaw = _scoring[category];
      final Map existing = existingRaw is Map ? Map.from(existingRaw) : {};
      return {...defaults, ...existing};
    }

    // PASSING
    _scoring['PASSING'] = merge('PASSING', {
      'Passing Yards': 25.0,
      'Passing TD': 4.0,
      'Passing 1st Down': 0.0,
      '2-Pt Conversion': 2.0,
      'Pass Intercepted': -1.0,
      'Pick 6 Thrown': -1.0,
      'Pass Completed': 0.0,
      'Incomplete Pass': 0.0,
      'Pass Attempts': 0.0,
      'QB Sacked': 0.0,
      '40+ Yard Completion Bonus': 0.0,
      '40+ Yard Pass TD Bonus': 0.0,
      '50+ Yard Pass TD Bonus': 0.0,
    });
    
    // RUSHING
    _scoring['RUSHING'] = merge('RUSHING', {
      'Rushing Yards': 10.0,
      'Rushing TD': 6.0,
      'Rushing 1st Down': 0.0,
      '2-Pt Conversion': 2.0,
      'Rush Attempts': 0.0,
      '40+ Yard Rush Bonus': 0.0,
      '40+ Yard Rush TD Bonus': 0.0,
      '50+ Yard Rush TD Bonus': 0.0,
    });

    // RECEIVING
    _scoring['RECEIVING'] = merge('RECEIVING', {
      'Reception': 1.0,
      'Receiving Yards': 10.0,
      'Receiving TD': 6.0,
      'Receiving 1st Down': 0.0,
      '2-Pt Conversion': 2.0,
      '40+ Yard Reception Bonus': 0.0,
      '40+ Yard Reception TD Bonus': 0.0,
      '50+ Yard Reception TD Bonus': 0.0,
    });

    // KICKING
    _scoring['KICKING'] = merge('KICKING', {
      'FG Made 0-39': 3.0,
      'FG Made 40-49': 4.0,
      'FG Made 50+': 5.0,
      'PAT Made': 1.0,
      'FG Missed 0-39': -1.0,
      'PAT Missed': -1.0,
    });

    // DEFENSE
    _scoring['DEFENSE'] = merge('DEFENSE', {
      'Defense TD': 6.0,
      'Points Allowed 0': 10.0,
      'Points Allowed 1-6': 7.0,
      'Points Allowed 7-13': 4.0,
      'Points Allowed 14-20': 1.0,
      'Points Allowed 21-27': 0.0,
      'Points Allowed 28-34': -1.0,
      'Points Allowed 35+': -4.0,
      'Sacks': 1.0,
      'Interceptions': 2.0,
      'Fumble Recovery': 2.0,
      'Safety': 2.0,
      'Forced Fumble': 1.0,
      'Blocked Kick': 2.0,
    });

    // SPECIAL TEAMS
    _scoring['SPECIAL TEAMS'] = merge('SPECIAL TEAMS', {
      'Special teams td': 6.0,
      'Special Teams Forced Fumble': 1.0,
      'Special Teams Fumble Recovery': 1.0,
      'Special Teams Solo Tackle': 0.0,
      'Punt Return Yards': 10.0,
      'Kick Return Yards': 10.0,
    });

    // SPECIAL TEAMS PLAYER
    _scoring['SPECIAL TEAMS PLAYER'] = merge('SPECIAL TEAMS PLAYER', {
      'Special teams player td': 6.0,
      'Special Teams Player Forced Fumble': 1.0,
      'Special Teams Player Fumble Recovery': 1.0,
      'Special Teams Player Solo Tackle': 0.0,
      'Player Punt Return Yards': 10.0,
      'Player Kick Return Yards': 10.0,
    });

    // MISCELLANEOUS
    _scoring['MISCELLANEOUS'] = merge('MISCELLANEOUS', {
      'Fumble': 0.0,
      'Fumble Lost': -2.0,
      'Fumble Recovery TD': 6.0,
    });

    // BONUSES
    _scoring['BONUSES'] = merge('BONUSES', {
      '100-199 Yard Rushing Game': 0.0,
      '200+ Yard Rushing Game': 0.0,
      '100-199 Yard Receiving Game': 0.0,
      '200+ Yard Receiving Game': 0.0,
      '300-399 Yard Passing Game': 0.0,
      '400+ Yard Passing Game': 0.0,
      '100-199 Combined Rush + Rec Yards': 0.0,
      '200+ Combined Rush + Rec Yards': 0.0,
      '25+ pass completions': 0.0,
      '20+ carries': 0.0,
      '1st Down Bonus - RB': 0.0,
      '1st Down Bonus - WR': 0.0,
      '1st Down Bonus - TE': 0.0,
      '1st Down Bonus - QB': 0.0,
    });

    // IDP
    _scoring['IDP'] = merge('IDP', {
      'IDP TD': 6.0,
      'Sack': 2.0,
      'Sack Yards': 10.0,
      'Hit on QB': 1.0,
      'Tackle': 1.0,
      'Solo Tackle': 1.0,
      'Assisted Tackle': 0.5,
      'Tackle For Loss': 1.0,
      'Blocked Punt, PAT or FG': 2.0,
      'Interception': 3.0,
      'INT Return Yards': 10.0,
      'Forced Fumble': 2.0,
      'Fumble Recovery': 2.0,
      'Fumble Return Yards': 10.0,
      'Pass Defended': 1.0,
      'Safety': 2.0,
      '10+ Tackle Bonus': 0.0,
      '2+ Sack Bonus': 0.0,
      '3+ Pass Defended Bonus': 0.0,
      '50+ Yard Interception Return TD Bonus': 0.0,
      '50+ Yard Fumble Return TD Bonus': 0.0,
    });
  }

  void _applyPreset(String name) {
    setState(() {
      if (name == 'ESPN') {
        _scoring['RECEIVING']['Reception'] = 1.0;
        _scoring['PASSING']['Passing TD'] = 4.0;
        _scoring['PASSING']['Pass Intercepted'] = -2.0;
      } else if (name == 'YAHOO') {
        _scoring['RECEIVING']['Reception'] = 0.5;
        _scoring['PASSING']['Passing TD'] = 4.0;
        _scoring['PASSING']['Pass Intercepted'] = -1.0;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name scoring preset applied')));
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      await LeagueService.updateLeagueSettings(widget.league['id'], {
        'scoringSettings': _scoring,
        'hasCustomScoring': true,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scoring settings updated successfully'), backgroundColor: AppColors.accentCyan),
        );
      }
    } catch (e) {
      if (mounted) AppDialogs.showPremiumErrorDialog(context, message: e.toString());
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
          'Scoring Settings',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
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
      body: Column(
        children: [
          _buildCategoryTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((cat) => _buildCategoryList(cat)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 44.h,
      margin: EdgeInsets.symmetric(vertical: 16.h),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: AppColors.accentCyan.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.h),
          border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
        ),
        labelColor: AppColors.accentCyan,
        unselectedLabelColor: Colors.white38,
        labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.symmetric(horizontal: 24.w),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: _categories.map((cat) => Tab(text: cat)).toList(),
      ),
    );
  }

  Widget _buildCategoryList(String category) {
    final dynamic rulesRaw = _scoring[category];
    final Map<String, dynamic> rules = rulesRaw is Map ? Map<String, dynamic>.from(rulesRaw) : {};
    final items = rules.keys.toList();

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      itemCount: items.length + 2, // Rules + Presets + Reset
      itemBuilder: (context, index) {
        if (index < items.length) {
          final rule = items[index];
          final val = rules[rule];
          return _buildScoringInput(category, rule, val);
        } else if (index == items.length) {
          return _buildPresets();
        } else {
          return _buildResetSection();
        }
      },
    );
  }

  Widget _buildScoringInput(String category, String rule, dynamic value) {
    final bool isYardage = rule.contains('Yards');
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        rule, 
                        style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.help_outline, color: Colors.white12, size: 14.w),
                  ],
                ),
              ),
              Container(
                width: 70.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8.h),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: TextField(
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  style: TextStyle(color: AppColors.accentCyan, fontSize: 14.sp, fontWeight: FontWeight.bold),
                  onChanged: (val) {
                    setState(() {
                      _scoring[category][rule] = double.tryParse(val) ?? 0.0;
                    });
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: value.toString(),
                    hintStyle: const TextStyle(color: Colors.white24),
                  ),
                ),
              ),
            ],
          ),
          if (isYardage) ...[
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CONVERSION RATE',
                  style: TextStyle(color: Colors.white24, fontSize: 9.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '1 pt every ${value.toString()} yds',
                      style: TextStyle(color: AppColors.accentCyan.withOpacity(0.6), fontSize: 11.sp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '+${(1.0 / (double.tryParse(value.toString()) ?? 1.0)).toStringAsFixed(2)} per yard',
                      style: TextStyle(color: Colors.white24, fontSize: 10.sp),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32.h),
          child: Text(
            'POPULAR PRESETS',
            style: TextStyle(color: AppColors.accentCyan, fontSize: 11.sp, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ),
        Row(
          children: [
            _buildPresetCard('ESPN', 'Default to ESPN scoring settings'),
            SizedBox(width: 16.w),
            _buildPresetCard('YAHOO', 'Default to Yahoo scoring settings'),
          ],
        ),
        SizedBox(height: 48.h),
      ],
    );
  }

  Widget _buildPresetCard(String name, String desc) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _applyPreset(name),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.h),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900)),
              SizedBox(height: 8.h),
              Text(desc, style: TextStyle(color: Colors.white38, fontSize: 10.sp, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetSection() {
    return Padding(
      padding: EdgeInsets.only(bottom: 64.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reset', style: TextStyle(color: Colors.orangeAccent, fontSize: 16.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 4.h),
              Text('Reset to default scoring settings.', style: TextStyle(color: Colors.white24, fontSize: 11.sp)),
            ],
          ),
          IconButton(
            onPressed: () {
              setState(() => _initializeDefaults());
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scoring reset to defaults')));
            },
            icon: Icon(Icons.refresh, color: Colors.white38, size: 24.w),
          ),
        ],
      ),
    );
  }
}
