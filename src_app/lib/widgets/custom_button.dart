import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_constants.dart';
import '../config/app_text_styles.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  final bool outlined;
  final bool fullWidth;

  final IconData? icon;
  final Color? borderColor;
  final Color? textColor;
  final Color? backgroundColor;
  final double iconSpacing;
  final double? width;
  final double? height;

  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.outlined = false,
    this.fullWidth = true,
    this.icon,
    this.borderColor,
    this.textColor,
    this.backgroundColor,
    this.iconSpacing = 8.0,
    this.width,
    this.height,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final double buttonHeight = height ?? 50;

    Widget buildContent({required Color color}) {
      if (isLoading) {
        return SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.3,
            color: color,
          ),
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 18),
            SizedBox(width: iconSpacing),
          ],
          Text(
            text,
            style: AppTextStyles.button.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: width ?? (fullWidth ? double.infinity : null),
      height: buttonHeight,
      child: outlined
          ? OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor ?? AppColors.primary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          backgroundColor: Colors.white,
        ),
        onPressed: isLoading ? null : onPressed,
        child: buildContent(color: textColor ?? AppColors.primary),
      )
          : ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: isLoading ? null : onPressed,
        child: buildContent(color: Colors.white),
      ),
    );
  }
}
