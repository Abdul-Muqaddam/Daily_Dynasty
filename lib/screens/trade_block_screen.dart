import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';

class TradeBlockScreen extends StatefulWidget {
  const TradeBlockScreen({super.key});

  @override
  State<TradeBlockScreen> createState() => _TradeBlockScreenState();
}

class _TradeBlockScreenState extends State<TradeBlockScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data
  final List<Map<String, dynamic>> _incomingTrades = [
    {
      'from': 'CYBER TITANS',
      'offering': ['Patrick Mahomes (QB)', 'Breece Hall (RB)'],
      'requesting': ['Justin Jefferson (WR)', 'Travis Kelce (TE)'],
      'status': 'pending',
      'timeAgo': '2h ago',
    },
  ];

  final List<Map<String, dynamic>> _outgoingTrades = [];

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

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
                _buildTradeList(_incomingTrades, isIncoming: true),
                _buildTradeList(_outgoingTrades, isIncoming: false),
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
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("INCOMING"),
                if (_incomingTrades.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(left: 6.w),
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10.h),
                    ),
                    child: Text(
                      '${_incomingTrades.length}',
                      style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.w900),
                    ),
                  ),
              ],
            ),
          ),
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
    final List<String> offering = List<String>.from(trade['offering'] as List);
    final List<String> requesting = List<String>.from(trade['requesting'] as List);
    final status = trade['status'] as String;
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
                    isIncoming ? 'From: ${trade['from']}' : 'To: ${trade['from']}',
                    style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(trade['timeAgo'] as String, style: TextStyle(color: Colors.white24, fontSize: 10.sp)),
                  SizedBox(width: 8.w),
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
              Expanded(child: _buildTradeColumn("THEY OFFER", offering, AppColors.accentCyan)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Icon(Icons.swap_horiz, color: Colors.white24, size: 20.w),
              ),
              Expanded(child: _buildTradeColumn("THEY WANT", requesting, AppColors.orangeGradientStart)),
            ],
          ),
          if (isIncoming && isPending) ...[
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _incomingTrades.first['status'] = 'rejected'),
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
                    onTap: () => setState(() => _incomingTrades.first['status'] = 'accepted'),
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

  Widget _buildTradeColumn(String label, List<String> players, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white38, fontSize: 9.sp, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        SizedBox(height: 6.h),
        ...players.map((p) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 10.w,
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(Icons.person, color: color, size: 12.w),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      p,
                      style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildProposeButton() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trade proposal builder coming soon!')),
        );
      },
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
