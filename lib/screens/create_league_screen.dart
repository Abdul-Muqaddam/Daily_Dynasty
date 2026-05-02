import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/colors.dart';
import '../../core/responsive_helper.dart';
import '../../services/league_service.dart';
import '../../widgets/app_dialogs.dart';

class CreateLeagueScreen extends StatefulWidget {
  const CreateLeagueScreen({super.key});

  @override
  State<CreateLeagueScreen> createState() => _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends State<CreateLeagueScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();

  int _currentStep = 0;
  int _maxMembers = 10;
  String _leagueType = 'redraft';
  String _draftType = 'snake';
  String _scoringType = 'standard';
  String _selectedTier = 'Rookie';
  List<String> _unlockedTiers = ['Rookie'];
  bool _allowPublicJoin = false;
  bool _isLoading = false;

  // Result after creation
  String? _createdLeagueId;
  String? _createdJoinCode;

  // Animation
  late AnimationController _codeAnimController;
  late Animation<double> _codeAnim;

  @override
  void initState() {
    super.initState();
    _codeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _codeAnim = CurvedAnimation(
      parent: _codeAnimController,
      curve: Curves.elasticOut,
    );
    _fetchUnlockedTiers();
  }

  Future<void> _fetchUnlockedTiers() async {
    try {
      final user = LeagueService.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final tiers = List<String>.from(doc.data()?['unlockedTiers'] ?? ['Rookie']);
          if (mounted) setState(() => _unlockedTiers = tiers);
        }
      }
    } catch (e) {
      // Fallback to Rookie
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _codeAnimController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && _nameController.text.trim().isEmpty) {
      AppDialogs.showPremiumErrorDialog(context, message: "Please enter a league name.");
      return;
    }
    if (_currentStep < 5) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _createLeague() async {
    setState(() => _isLoading = true);
    try {
      final leagueId = await LeagueService.createLeague(
        name: _nameController.text.trim(),
        leagueType: _leagueType,
        draftType: _draftType,
        maxMembers: _maxMembers,
        scoringType: _scoringType,
        allowPublicJoin: _allowPublicJoin,
        tier: _selectedTier,
      );

      // Fetch the join code back
      final doc = await LeagueService.getUserLeagues();
      final created = doc.firstWhere(
        (l) => l['id'] == leagueId,
        orElse: () => {'joinCode': '------'},
      );

      setState(() {
        _createdLeagueId = leagueId;
        _createdJoinCode = created['joinCode'] as String?;
      });

      _codeAnimController.forward();
    } catch (e) {
      if (mounted) {
        AppDialogs.showPremiumErrorDialog(context, message: "Error creating league: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _createdLeagueId == null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: _currentStep > 0 ? _prevStep : () => Navigator.pop(context),
              )
            : null,
        title: Text(
          _createdLeagueId != null ? 'LEAGUE CREATED!' : 'CREATE LEAGUE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/signup_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.overlayTop,
                    AppColors.overlayBottom,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: _createdLeagueId != null
          ? _buildSuccessScreen()
          : Column(
              children: [
                _buildStepIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1(),
                      _buildStep2(),
                      _buildStepTier(),
                      _buildStep3(),
                      _buildStep4(),
                      _buildStep5(),
                    ],
                  ),
                ),
                _buildBottomButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        children: List.generate(6, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              height: 4.h,
              decoration: BoxDecoration(
                color: isDone || isActive ? AppColors.accentCyan : Colors.white12,
                borderRadius: BorderRadius.circular(2.h),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Step 1: Name ──────────────────────────────────────────────────────────

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Icon(Icons.emoji_events, color: AppColors.accentCyan, size: 48.w),
          SizedBox(height: 20.h),
          Text(
            'Name Your League',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Make it memorable — your members will see this name.',
            style: TextStyle(color: Colors.white54, fontSize: 14.sp),
          ),
          SizedBox(height: 40.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.leagueCardBg,
              borderRadius: BorderRadius.circular(16.h),
              border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _nameController,
              style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'e.g. Gridiron Kings FC',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 16.sp),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.shield_outlined, color: AppColors.accentCyan, size: 22.w),
              ),
              maxLength: 30,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 _\-]'))],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: League Type ──────────────────────────────────────────────────

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Icon(Icons.category, color: AppColors.accentCyan, size: 48.w),
          SizedBox(height: 20.h),
          Text(
            'Choose League Type',
            style: TextStyle(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8.h),
          Text(
            'You can change it later in the settings\n(except Chopped)',
            style: TextStyle(color: AppColors.accentCyan, fontSize: 13.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 32.h),

          _buildTypeOption(
            'redraft', 
            'Redraft', 
            'Everyone starts from scratch every year. Draft a new team each season.',
            Icons.refresh,
          ),
          _buildTypeOption(
            'keeper', 
            'Keeper', 
            'Managers can retain a specific number of players from their previous roster.',
            Icons.save,
          ),
          _buildTypeOption(
            'dynasty', 
            'Dynasty', 
            'The true marathon. Keep your entire roster year-over-year.',
            Icons.history,
          ),
          _buildTypeOption(
            'chopped', 
            'Chopped', 
            'High-stakes elimination mode. Once set, this cannot be changed.',
            Icons.whatshot,
            isPermanent: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption(String value, String label, String description, IconData icon, {bool isPermanent = false}) {
    final isSelected = _leagueType == value;
    return GestureDetector(
      onTap: () => setState(() => _leagueType = value),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentCyan.withOpacity(0.1) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16.h),
          border: Border.all(
            color: isSelected ? AppColors.accentCyan : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentCyan : Colors.white10,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.black : Colors.white24, size: 24.w),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 18.sp, fontWeight: FontWeight.w900)),
                      if (isPermanent) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(4.h)),
                          child: Text("PERMANENT", style: TextStyle(color: Colors.redAccent, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(description, style: TextStyle(color: Colors.white38, fontSize: 12.sp, height: 1.3)),
                ],
              ),
            ),
            if (isSelected) 
              Icon(Icons.check_circle, color: AppColors.accentCyan, size: 24.w),
          ],
        ),
      ),
    );
  }

  // ─── Step Tier Selection ──────────────────────────────────────────────────
  Widget _buildStepTier() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Icon(Icons.workspace_premium_rounded, color: AppColors.accentCyan, size: 48.w),
          SizedBox(height: 20.h),
          Text(
            'Select Competitive Tier',
            style: TextStyle(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8.h),
          Text(
            'Win championships to unlock higher tiers with tougher opponents.',
            style: TextStyle(color: Colors.white54, fontSize: 14.sp),
          ),
          SizedBox(height: 32.h),

          ...LeagueService.TIER_ORDER.map((tier) {
            final bool isUnlocked = _unlockedTiers.contains(tier);
            final bool isSelected = _selectedTier == tier;
            
            String difficulty = "EASY";
            String botGrade = "50-65";
            if (tier == "Pro") { difficulty = "NORMAL"; botGrade = "60-75"; }
            if (tier == "Legendary") { difficulty = "HARD"; botGrade = "70-85"; }
            if (tier == "Hall of Fame") { difficulty = "EXPERT"; botGrade = "80-95"; }

            return GestureDetector(
              onTap: isUnlocked ? () => setState(() => _selectedTier = tier) : null,
              child: Opacity(
                opacity: isUnlocked ? 1.0 : 0.4,
                child: Container(
                  margin: EdgeInsets.only(bottom: 16.h),
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentCyan.withOpacity(0.1) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16.h),
                    border: Border.all(
                      color: isSelected ? AppColors.accentCyan : Colors.white10,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(tier.toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900)),
                                if (!isUnlocked) ...[
                                  SizedBox(width: 8.w),
                                  Icon(Icons.lock, color: Colors.white24, size: 16.w),
                                ],
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Text("DIFFICULTY: ", style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
                                Text(difficulty, style: TextStyle(color: AppColors.accentCyan, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                                Text("  |  BOT GRADE: ", style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
                                Text(botGrade, style: TextStyle(color: Colors.white70, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isSelected) 
                        Icon(Icons.check_circle, color: AppColors.accentCyan, size: 24.w),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ─── Step 3: Draft Type ───────────────────────────────────────────────────

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Icon(Icons.format_list_numbered, color: AppColors.accentCyan, size: 48.w),
          SizedBox(height: 20.h),
          Text(
            'Choose Draft Type',
            style: TextStyle(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8.h),
          Text(
            'Determine how your initial roster is built.',
            style: TextStyle(color: Colors.white54, fontSize: 14.sp),
          ),
          SizedBox(height: 32.h),

          _buildDraftOption(
            'snake', 
            'Snake Draft', 
            'Draft in a specified or randomized order; each round the order reverses. Most common way to draft.',
            Icons.swap_calls,
            isRecommended: true,
          ),
          _buildDraftOption(
            'linear', 
            'Linear Draft', 
            'Standard order that remains constant every round (e.g. 1-10, 1-10).',
            Icons.format_align_left,
          ),
          _buildDraftOption(
            'auction', 
            'Auction Draft', 
            'Every manager has a budget to bid on players. High stakes and high strategy.',
            Icons.gavel,
          ),
        ],
      ),
    );
  }

  Widget _buildDraftOption(String value, String label, String description, IconData icon, {bool isRecommended = false}) {
    final isSelected = _draftType == value;
    return GestureDetector(
      onTap: () => setState(() => _draftType = value),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentCyan.withOpacity(0.1) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16.h),
          border: Border.all(
            color: isSelected ? AppColors.accentCyan : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentCyan : Colors.white10,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.black : Colors.white24, size: 24.w),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 18.sp, fontWeight: FontWeight.w900)),
                      if (isRecommended) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(color: AppColors.accentCyan.withOpacity(0.2), borderRadius: BorderRadius.circular(4.h)),
                          child: Text("MOST COMMON", style: TextStyle(color: AppColors.accentCyan, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(description, style: TextStyle(color: Colors.white38, fontSize: 12.sp, height: 1.3)),
                ],
              ),
            ),
            if (isSelected) 
              Icon(Icons.check_circle, color: AppColors.accentCyan, size: 24.w),
          ],
        ),
      ),
    );
  }

  // ─── Step 4: Settings ──────────────────────────────────────────────────────

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Icon(Icons.tune, color: AppColors.accentCyan, size: 48.w),
          SizedBox(height: 20.h),
          Text(
            'League Settings',
            style: TextStyle(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8.h),
          Text(
            'Customize how your league operates.',
            style: TextStyle(color: Colors.white54, fontSize: 14.sp),
          ),
          SizedBox(height: 32.h),

          // Max Members
          _buildSettingCard(
            icon: Icons.group,
            title: 'Max Members',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('2', style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
                    Text(
                      '$_maxMembers members',
                      style: TextStyle(color: AppColors.accentCyan, fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                    Text('20', style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
                  ],
                ),
                Slider(
                  value: _maxMembers.toDouble(),
                  min: 2,
                  max: 20,
                  divisions: 18,
                  activeColor: AppColors.accentCyan,
                  inactiveColor: Colors.white12,
                  onChanged: (v) => setState(() => _maxMembers = v.round()),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Scoring Type
          _buildSettingCard(
            icon: Icons.scoreboard,
            title: 'Scoring Type',
            child: Column(
              children: [
                _buildScoringOption('standard', 'Standard'),
                _buildScoringOption('half_ppr', 'Half PPR'),
                _buildScoringOption('ppr', 'Full PPR'),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Public Join
          _buildSettingCard(
            icon: Icons.lock_open_outlined,
            title: 'Public Join',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _allowPublicJoin ? 'Anyone with the code can join' : 'Invite only via join code',
                  style: TextStyle(color: Colors.white54, fontSize: 13.sp),
                ),
                Switch(
                  value: _allowPublicJoin,
                  activeColor: AppColors.accentCyan,
                  onChanged: (v) => setState(() => _allowPublicJoin = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.leagueCardBg,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accentCyan, size: 18.w),
              SizedBox(width: 8.w),
              Text(title, style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }

  Widget _buildScoringOption(String value, String label) {
    final isSelected = _scoringType == value;
    return GestureDetector(
      onTap: () => setState(() => _scoringType = value),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentCyan.withOpacity(0.15) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10.h),
          border: Border.all(
            color: isSelected ? AppColors.accentCyan : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.accentCyan : Colors.white38,
              size: 18.w,
            ),
            SizedBox(width: 12.w),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 14.sp)),
          ],
        ),
      ),
    );
  }

  // ─── Step 5: Confirm ───────────────────────────────────────────────────────

  Widget _buildStep5() {
    final name = _nameController.text.trim().isEmpty ? 'Your League' : _nameController.text.trim();
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Icon(Icons.check_circle_outline, color: AppColors.accentCyan, size: 48.w),
          SizedBox(height: 20.h),
          Text(
            'Ready to Create?',
            style: TextStyle(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8.h),
          Text('Review your league settings below.', style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
          SizedBox(height: 32.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accentCyan.withOpacity(0.15), AppColors.leagueCardBg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.h),
              border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow('League Name', name, Icons.emoji_events),
                Divider(color: Colors.white10, height: 24.h),
                _buildSummaryRow('Tier', _selectedTier.toUpperCase(), Icons.workspace_premium_rounded),
                Divider(color: Colors.white10, height: 24.h),
                _buildSummaryRow('League Type', _leagueType.toUpperCase(), Icons.category),
                Divider(color: Colors.white10, height: 24.h),
                _buildSummaryRow('Draft Type', _draftType.toUpperCase(), Icons.format_list_numbered),
                Divider(color: Colors.white10, height: 24.h),
                _buildSummaryRow('Max Members', '$_maxMembers players', Icons.group),
                Divider(color: Colors.white10, height: 24.h),
                _buildSummaryRow('Scoring', _scoringType.toUpperCase().replaceAll('_', ' '), Icons.scoreboard),
                Divider(color: Colors.white10, height: 24.h),
                _buildSummaryRow('Join Type', _allowPublicJoin ? 'Public' : 'Invite Only', Icons.lock_outline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accentCyan, size: 20.w),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
            Text(value, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  // ─── Bottom Button ─────────────────────────────────────────────────────────

  Widget _buildBottomButton() {
    final isLastStep = _currentStep == 5;
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h),
      child: Container(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accentCyan, AppColors.createGradientPurple],
          ),
          borderRadius: BorderRadius.circular(16.h),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentCyan.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : (isLastStep ? _createLeague : _nextStep),
            borderRadius: BorderRadius.circular(16.h),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      height: 24, width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastStep ? 'CREATE LEAGUE' : 'NEXT',
                          style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                        ),
                        SizedBox(width: 8.w),
                        Icon(isLastStep ? Icons.check : Icons.arrow_forward, color: Colors.white, size: 20.w),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Success Screen ────────────────────────────────────────────────────────

  Widget _buildSuccessScreen() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          SizedBox(height: 32.h),
          Container(
            width: 100.w, height: 100.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentCyan.withOpacity(0.15),
            ),
            child: Icon(Icons.emoji_events, color: AppColors.accentCyan, size: 52.w),
          ),
          SizedBox(height: 24.h),
          Text(
            _nameController.text.trim().toUpperCase(),
            style: TextStyle(color: Colors.white, fontSize: 26.sp, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(_allowPublicJoin ? 'Discovery Board Active!' : 'Your league is live!', style: TextStyle(color: Colors.white54, fontSize: 16.sp)),

          SizedBox(height: 40.h),

          if (_allowPublicJoin) ...[
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20.h),
                border: Border.all(color: AppColors.accentCyan.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Icon(Icons.public, color: AppColors.accentCyan, size: 40.w),
                  SizedBox(height: 16.h),
                  Text(
                    'PUBLIC ACCESS ENABLED',
                    style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Managers can now find and join your league instantly from the Discovery board. No join code required.',
                    style: TextStyle(color: Colors.white38, fontSize: 12.sp, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            Text('JOIN CODE', style: TextStyle(color: Colors.white38, fontSize: 12.sp, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
            SizedBox(height: 12.h),
            ScaleTransition(
              scale: _codeAnim,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
                decoration: BoxDecoration(
                  color: AppColors.leagueCardBg,
                  borderRadius: BorderRadius.circular(20.h),
                  border: Border.all(color: AppColors.accentCyan, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentCyan.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  _createdJoinCode ?? '------',
                  style: TextStyle(
                    color: AppColors.accentCyan,
                    fontSize: 36.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8.0,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text('Share this code with friends to invite them.', style: TextStyle(color: Colors.white38, fontSize: 13.sp), textAlign: TextAlign.center),
          ],

          SizedBox(height: 32.h),

          // Action Button
          Container(
            width: double.infinity,
            height: 52.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.accentCyan, AppColors.createGradientPurple]),
              borderRadius: BorderRadius.circular(14.h),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (_allowPublicJoin) {
                    Navigator.pop(context);
                  } else {
                    Clipboard.setData(ClipboardData(text: _createdJoinCode ?? ''));
                    if (mounted) {
                      AppDialogs.showSuccessDialog(
                        context,
                        title: "COPIED",
                        message: "Join code copied to clipboard!",
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(14.h),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_allowPublicJoin ? Icons.check_circle : Icons.copy, color: Colors.white, size: 20.w),
                      SizedBox(width: 8.w),
                      Text(
                        _allowPublicJoin ? 'GET STARTED' : 'COPY JOIN CODE',
                        style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          if (!_allowPublicJoin)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Done', style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
            ),
        ],
      ),
    );
  }
}
