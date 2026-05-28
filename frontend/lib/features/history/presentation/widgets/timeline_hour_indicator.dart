import 'package:flutter/material.dart';

class TimelineHourIndicator extends StatelessWidget {
  final double hourHeight;
  final int startHour;
  final int endHour;

  const TimelineHourIndicator({
    super.key,
    this.hourHeight = 60.0,
    this.startHour = 0,
    this.endHour = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate((endHour - startHour) + 1, (index) {
        final currentHour = (startHour + index) % 24;
        final hourStr = currentHour.toString().padLeft(2, '0');

        return SizedBox(
          height: hourHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  hourStr,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.05),
                  margin: const EdgeInsets.only(top: 6),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
