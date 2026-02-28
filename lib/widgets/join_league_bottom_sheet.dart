import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import '../services/league_service.dart';
import 'app_dialogs.dart';

class JoinLeagueBottomSheet extends StatefulWidget {
  const JoinLeagueBottomSheet({super.key});

  @override
  State<JoinLeagueBottomSheet> createState() => _JoinLeagueBottomSheetState();
}

class _JoinLeagueBottomSheetState extends State<JoinLeagueBottomSheet> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      AppDialogs.showPremiumErrorDialog(context, message: 'Code must be exactly 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await LeagueService.joinLeague(code);
      if (mounted) {
        Navigator.pop(context, true); // true = success, needs refresh
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        final isNetwork = errorStr.contains('network') || 
                          errorStr.contains('connection') || 
                          errorStr.contains('timeout') || 
                          errorStr.contains('host') ||
                          errorStr.contains('unreachable');
        
        AppDialogs.showPremiumErrorDialog(
          context,
          message: isNetwork 
            ? "UNSTABLE CONNECTION DETECTED. PLEASE CHECK YOUR INTERNET AND TRY AGAIN."
            : e.toString().replaceAll('Exception: ', ''),
          isNetworkError: isNetwork,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 24.h + bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.surface, // AppColors.surface
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.w)),
        border: Border(top: BorderSide(color: AppColors.accentCyan.withOpacity(0.3), width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'JOIN LEAGUE',
                style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white54, size: 24.w),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Enter the 6-character join code provided by your league commissioner.',
            style: TextStyle(color: Colors.white54, fontSize: 13.sp, height: 1.5),
          ),
          SizedBox(height: 24.h),
          
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.leagueCardBg,
              borderRadius: BorderRadius.circular(16.w),
              border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _codeController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: TextStyle(color: AppColors.accentCyan, fontSize: 24.sp, fontWeight: FontWeight.w900, letterSpacing: 8.0),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                counterText: '',
                hintText: '      ',
                hintStyle: TextStyle(color: Colors.white24, letterSpacing: 8.0),
                border: InputBorder.none,
              ),
              onChanged: (val) {},
            ),
          ),

          SizedBox(height: 32.h),

          // Join Button
          Container(
            width: double.infinity,
            height: 56.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentCyan, AppColors.createGradientPurple],
              ),
              borderRadius: BorderRadius.circular(16.w),
              boxShadow: [
                BoxShadow(color: AppColors.accentCyan.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _handleJoin,
                borderRadius: BorderRadius.circular(16.w),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('JOIN NOW', style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                            SizedBox(width: 8.w),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 20.w),
                          ],
                        ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

}

