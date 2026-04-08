import 'dart:async';
import 'package:flutter/material.dart';
import '../services/check_in_service.dart';
import '../core/responsive_helper.dart';

class CheckInCountdown extends StatefulWidget {
  final TextStyle? style;
  final String prefix;

  const CheckInCountdown({
    super.key,
    this.style,
    this.prefix = "RESET IN ",
  });

  @override
  State<CheckInCountdown> createState() => _CheckInCountdownState();
}

class _CheckInCountdownState extends State<CheckInCountdown> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = CheckInService.getTimeUntilNextCheckIn();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remaining = CheckInService.getTimeUntilNextCheckIn();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Text(
      "${widget.prefix}${_formatDuration(_remaining)}",
      style: widget.style ?? TextStyle(
        color: Colors.white54,
        fontSize: 10.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
