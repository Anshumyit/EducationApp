import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String display = status.replaceAll('_', ' ').toUpperCase();

    if (color != null) {
      bg = color!.withOpacity(0.16);
      fg = color!;
    } else {
      switch (status.toUpperCase()) {
        case 'APPROVED':
        case 'PRESENT':
        case 'PAID':
          bg = AppColors.emerald.withOpacity(0.16);
          fg = AppColors.emerald;
          break;
      case 'ABSENT':
      case 'REJECTED':
      case 'OVERDUE':
        bg = AppColors.rose.withOpacity(0.16);
        fg = AppColors.rose;
        break;
      case 'LATE':
      case 'HALF_DAY':
      case 'PARTIAL':
        bg = AppColors.amber.withOpacity(0.16);
        fg = AppColors.amber;
        break;
      case 'PENDING':
      default:
        bg = AppColors.primary.withOpacity(0.16);
        fg = AppColors.primaryLight;
        break;
      }
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.3), width: 1),
      ),
      child: Text(
        display,
        style: GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
