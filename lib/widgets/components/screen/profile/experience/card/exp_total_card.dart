// lib/widgets/components/screen/profile/experience/exp_total_card.dart

import 'package:flutter/material.dart';
import '../../../../../../../../utils/font/font_config.dart';

class ExpTotalCard extends StatelessWidget {
  final int totalExp;

  const ExpTotalCard({
    Key? key,
    required this.totalExp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '总经验值',
              style: TextStyle(
                fontFamily: FontConfig.defaultFontFamily,
                fontFamilyFallback: FontConfig.fontFallback,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '$totalExp',
              style: TextStyle(
                fontFamily: FontConfig.defaultFontFamily,
                fontFamilyFallback: FontConfig.fontFallback,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}