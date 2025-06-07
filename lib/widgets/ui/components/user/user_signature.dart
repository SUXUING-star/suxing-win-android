// lib/widgets/ui/components/user/user_signature.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';

class UserSignature extends StatelessWidget {
  final String? signature;
  final bool isDesktop;

  const UserSignature({
    super.key,
    required this.isDesktop,
    required this.signature,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle signatureStyle = isDesktop
        ? TextStyle(
            fontSize: 12,
            color: Colors.black.withSafeOpacity(0.75),
            height: 1.35)
        : TextStyle(
            fontSize: 11,
            color: Colors.black.withSafeOpacity(0.70),
            height: 1.3);
    final int signatureMaxLines = isDesktop ? 3 : 2;
    final signatureText = signature;
    return signatureText == null
        ? const SizedBox.shrink()
        : Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24.0 : 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: isDesktop ? 18 : 14,
                  color: Colors.grey.shade500,
                ),
                SizedBox(width: isDesktop ? 6 : 4),
                Flexible(
                  child: AppText(
                    signatureText,
                    textAlign: TextAlign.center,
                    style: signatureStyle,
                    maxLines: signatureMaxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
  }
}
