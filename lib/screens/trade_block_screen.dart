import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import '../services/trade_service.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/propose_trade_bottom_sheet.dart';

class TradeBlockScreen extends StatefulWidget {
  final bool isEmbedded;
  const TradeBlockScreen({super.key, this.isEmbedded = false});

  @override
  State<TradeBlockScreen> createState() => _TradeBlockScreenState();
}

class _TradeBlockScreenState extends State<TradeBlockScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showProposeTradeSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProposeTradeBottomSheet(),
    );
    
    // StreamBuilders will automatically refresh, but we could add manual refresh if needed.
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.isEmbedded ? null : AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "TRADE BLOCK",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: _buildProposeButton(),
      body: Column(
        children: [
          _buildTabSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: TradeService.getIncomingTradesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
                    }
                    return _buildTradeList(snapshot.data ?? [], isIncoming: true);
                  }
                ),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: TradeService.getOutgoingTradesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
                    }
                    return _buildTradeList(snapshot.data ?? [], isIncoming: false);
                  }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
      height: 44.h,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: Colors.white10),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.accentCyan,
          borderRadius: BorderRadius.circular(10.h),
        ),
        labelColor: Colors.black87,
        unselectedLabelColor: Colors.white70,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
        tabs: [
          const Tab(text: "INCOMING"),
          const Tab(text: "OUTGOING"),
        ],
      ),
    );
  }

  Widget _buildTradeList(List<Map<String, dynamic>> trades, {required bool isIncoming}) {
    if (trades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz, color: Colors.white24, size: 64.w),
            SizedBox(height: 16.h),
            Text(
              isIncoming ? "NO INCOMING OFFERS" : "NO OUTGOING OFFERS",
              style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 8.h),
            Text(
              isIncoming
                  ? "Other managers haven't sent you any trades yet."
                  : "Tap the button below to propose a trade.",
              style: TextStyle(color: Colors.white38, fontSize: 13.sp),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: trades.length,
      itemBuilder: (_, i) => _buildTradeCard(trades[i], isIncoming: isIncoming),
    );
  }

  Widget _buildTradeCard(Map<String, dynamic> trade, {required bool isIncoming}) {
    final List<Map<String, dynamic>> offering = List<Map<String, dynamic>>.from(trade['offeringFull'] ?? []);
    final List<Map<String, dynamic>> requesting = List<Map<String, dynamic>>.from(trade['requestingFull'] ?? []);
    final List<Map<String, dynamic>> offeringPicks = List<Map<String, dynamic>>.from(trade['offeringPicks'] ?? []);
    final List<Map<String, dynamic>> requestingPicks = List<Map<String, dynamic>>.from(trade['requestingPicks'] ?? []);
    final status = trade['status'] as String? ?? 'pending';
    final isPending = status == 'pending';

    final statusColor = isPending
        ? AppColors.orangeGradientStart
        : status == 'accepted'
            ? Colors.green
            : Colors.redAccent;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.h),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isIncoming ? Icons.call_received : Icons.call_made,
                    color: isIncoming ? AppColors.accentCyan : AppColors.orangeGradientStart,
                    size: 16.w,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    isIncoming ? 'From: ${trade['fromTeamName']}' : 'To: ${trade['toTeamName']}',
                    style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8.h),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 9.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(child: _buildTradeColumn(isIncoming ? "THEY OFFER" : "YOU OFFER", offering, offeringPicks, AppColors.accentCyan)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Icon(Icons.swap_horiz, color: Colors.white24, size: 20.w),
              ),
              Expanded(child: _buildTradeColumn(isIncoming ? "THEY WANT" : "YOU WANT", requesting, requestingPicks, AppColors.orangeGradientStart)),
            ],
          ),
          if (isIncoming && isPending) ...[
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      try {
                        await TradeService.updateTradeStatus(trade['id'], 'rejected');
                      } catch (e) {
                        if (mounted) {
                          AppDialogs.showPremiumErrorDialog(context, message: 'Failed to decline trade. Please try again.');
                        }
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.h),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text("DECLINE", style: TextStyle(color: Colors.redAccent, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      try {
                        await TradeService.acceptTrade(trade['id']);
                        if (mounted) {
                          AppDialogs.showSuccessDialog(
                            context,
                            title: 'Trade Accepted!',
                            message: 'The trade has been completed. Check your roster for the new players.',
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          AppDialogs.showPremiumErrorDialog(context, message: 'Failed to accept trade. Please try again.');
                        }
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accentCyan, AppColors.createGradientPurple],
                        ),
                        borderRadius: BorderRadius.circular(10.h),
                      ),
                      child: Center(
                        child: Text("ACCEPT", style: TextStyle(color: Colors.black, fontSize: 12.sp, fontWeight: FontWeight.w900)),
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

  Widget _buildTradeColumn(String label, List<Map<String, dynamic>> players, List<Map<String, dynamic>> picks, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white38, fontSize: 9.sp, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        SizedBox(height: 10.h),
        ...players.map((p) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: ClipOval(
                      child: p['player_id'] != null
                          ? Image.network(
                              "https://sleepercdn.com/content/nfl/players/thumb/${p['player_id']}.jpg",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                  Icon(Icons.person, color: color, size: 14.w),
                            )
                          : Icon(Icons.person, color: color, size: 14.w),
                    ),
                    ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['name']?.toString() ?? "UNKNOWN",
                          style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${p['pos']} - ${p['team']}",
                          style: TextStyle(color: Colors.white38, fontSize: 8.sp),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
        if (picks.isNotEmpty) ...[
          if (players.isNotEmpty) SizedBox(height: 4.h),
          ...picks.map((pick) => Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Row(
              children: [
                Container(
                  width: 24.w, height: 24.w,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.2))),
                  child: Center(child: Text(pick['round'].toString(), style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.bold))),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    "${pick['year']} Rd ${pick['round']}",
                    style: TextStyle(color: Colors.white70, fontSize: 10.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildProposeButton() {
    return GestureDetector(
      onTap: _showProposeTradeSheet,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accentCyan, AppColors.createGradientPurple],
          ),
          borderRadius: BorderRadius.circular(30.h),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentCyan.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz, color: Colors.black, size: 20.w),
            SizedBox(width: 8.w),
            Text(
              "PROPOSE TRADE",
              style: TextStyle(color: Colors.black, fontSize: 13.sp, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
