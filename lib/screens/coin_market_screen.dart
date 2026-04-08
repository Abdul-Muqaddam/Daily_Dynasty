import '../services/coin_market_service.dart';
import '../services/league_service.dart';
import '../services/user_service.dart';
import '../widgets/app_dialogs.dart';
import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';

class CoinMarketScreen extends StatefulWidget {
  final bool isEmbedded;
  const CoinMarketScreen({super.key, this.isEmbedded = false});

  @override
  State<CoinMarketScreen> createState() => _CoinMarketScreenState();
}


class _CoinMarketScreenState extends State<CoinMarketScreen> {
  String? _leagueId;
  String? _ageRange;
  bool _isLoadingLeague = true;
  bool _isProcessingBuy = false;

  @override
  void initState() {
    super.initState();
    _loadLeague();
  }

  Future<void> _loadLeague() async {
    final leagues = await LeagueService.getUserLeagues();
    final profile = await UserService.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _leagueId = leagues.isNotEmpty ? leagues.first['id'] : null;
        _ageRange = profile?['ageRange'];
        _isLoadingLeague = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent, // Parent provides background
      appBar: widget.isEmbedded ? null : AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "COIN MARKET",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          if (_ageRange == 'under-18')
            SliverToBoxAdapter(
              child: _buildSafeMarketBanner(),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, widget.isEmbedded ? 20.h : 0, 24.w, 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   if (!widget.isEmbedded) ...[
                     Text(
                      "PLAYER AUCTION",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 8.h),
                   ],
                  Text(
                    "Buy players directly from other managers using coins.",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoadingLeague)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.gold))),
          if (!_isLoadingLeague && _leagueId == null)
            SliverFillRemaining(
              child: Center(
                child: Text("You must be in a league to access the market.", style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
              ),
            ),
          if (!_isLoadingLeague && _leagueId != null)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: CoinMarketService.getActiveListingsStream(_leagueId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.gold)));
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(child: Center(child: Text("Error loading market", style: TextStyle(color: Colors.red))));
                }

                final listings = snapshot.data ?? [];
                if (listings.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text("NO PLAYERS LISTED", style: TextStyle(color: Colors.white38, fontSize: 16.sp, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                    ),
                  );
                }

                return SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildListTile(listings[index]);
                      },
                      childCount: listings.length,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildListTile(Map<String, dynamic> listing) {
    final player = listing['player'];
    final askingPrice = listing['askingPrice'] as int;
    final isAffordable = true; // Could listen to CoinService balance stream or handle error on rejection
    
    Color posColor = AppColors.accentCyan;
    if (player['pos'] == 'QB') posColor = const Color(0xFFFF5252);
    else if (player['pos'] == 'RB') posColor = const Color(0xFF69F0AE);
    else if (player['pos'] == 'WR') posColor = const Color(0xFF40C4FF);
    else if (player['pos'] == 'TE') posColor = const Color(0xFFFFAB40);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            padding: EdgeInsets.symmetric(vertical: 4.h),
            decoration: BoxDecoration(
              color: posColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8.h),
              border: Border.all(color: posColor.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                player['pos'],
                style: TextStyle(color: posColor, fontSize: 13.sp, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player['name'],
                  style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      "SPS: ${player['sps']}",
                      style: TextStyle(color: AppColors.accentCyan, fontSize: 11.sp, fontWeight: FontWeight.bold),
                    ),
                    Text("  •  ", style: TextStyle(color: Colors.white24, fontSize: 11.sp)),
                    Text(
                      "SELLER: ${listing['sellerTeamName']}",
                      style: TextStyle(color: Colors.white54, fontSize: 11.sp),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: _isProcessingBuy ? null : () async {
              setState(() => _isProcessingBuy = true);
              try {
                await CoinMarketService.buyPlayer(_leagueId!, listing['id']);
                if (mounted) {
                  AppDialogs.showSuccessDialog(
                    context,
                    title: "PURCHASE SUCCESSFUL",
                    message: "Successfully purchased ${player['name']}!",
                  );
                }
              } catch (e) {
                if (mounted) {
                  AppDialogs.showPremiumErrorDialog(context, message: e.toString());
                }
              } finally {
                if (mounted) setState(() => _isProcessingBuy = false);
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isAffordable 
                      ? [AppColors.gold, Color(0xFFFFA500)] 
                      : [Colors.white10, Colors.white12],
                ),
                borderRadius: BorderRadius.circular(12.h),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monetization_on, color: isAffordable ? Colors.black : Colors.white24, size: 14.w),
                  SizedBox(width: 4.w),
                  Text(
                    "${askingPrice}",
                    style: TextStyle(
                      color: isAffordable ? Colors.black : Colors.white54, 
                      fontSize: 13.sp, 
                      fontWeight: FontWeight.w900
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeMarketBanner() {
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.selectionGreenStart.withOpacity(0.15),
            AppColors.accentCyan.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: AppColors.selectionGreenStart.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_rounded, color: AppColors.selectionGreenStart, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SAFE MARKET ACTIVE",
                  style: TextStyle(
                    color: AppColors.selectionGreenStart,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "All assets are virtual. Stay safe and trade responsibly.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.sp,
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
