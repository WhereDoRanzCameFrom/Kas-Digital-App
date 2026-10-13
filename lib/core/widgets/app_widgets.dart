import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../../data/models/models.dart';
import '../utils/formatters.dart';

// ─── AppButton ────────────────────────────────────────────────────────────────

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final IconData? icon;
  final Color? color;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : icon != null
                ? Icon(icon, size: 18)
                : const SizedBox.shrink(),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: c,
          side: BorderSide(color: c),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusM)),
        ),
      );
    }
    return FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : icon != null
              ? Icon(icon, size: 18)
              : const SizedBox.shrink(),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: c,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM)),
      ),
    );
  }
}

// ─── AppTextField ─────────────────────────────────────────────────────────────

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      validator: validator,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
    );
  }
}

// ─── RoleBadge ────────────────────────────────────────────────────────────────

class RoleBadge extends StatelessWidget {
  final UserRole role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: role.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: role.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        role.shortLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: role.color,
        ),
      ),
    );
  }
}

// ─── TransactionTile ──────────────────────────────────────────────────────────

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final bool showDate;
  final VoidCallback? onDelete;
  // TAMBAHAN: callback untuk edit transaksi
  final VoidCallback? onEdit;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.showDate = true,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isIn = transaction.type == TransactionType.masuk;
    final color = isIn ? AppColors.income : AppColors.expense;
    final bgColor = isIn ? AppColors.incomeLight : AppColors.expenseLight;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(
            isIn ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              transaction.category.label,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            if (showDate) ...[
              const SizedBox(height: 1),
              Text(
                '${DateFormatter.short(transaction.date)} • '
                '${transaction.date.hour.toString().padLeft(2, '0')}:'
                '${transaction.date.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIn ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isIn ? 'Masuk' : 'Keluar',
                    style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            // Tombol Edit
            if (onEdit != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.textHint),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Edit',
              ),
            ],
            // Tombol Hapus
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.textHint),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Hapus',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── SummaryCard ──────────────────────────────────────────────────────────────

class SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final bool isIncome;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppColors.income : AppColors.expense;
    final bgColor = isIncome ? AppColors.incomeLight : AppColors.expenseLight;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 13, color: color, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: Icon(
                  isIncome
                      ? Icons.north_east_rounded
                      : Icons.south_east_rounded,
                  size: 14,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

// ─── EmptyState ───────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState(
      {super.key, required this.message, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

// ─── SetoranStatusBadge ───────────────────────────────────────────────────────

class SetoranStatusBadge extends StatelessWidget {
  final SetoranStatus status;

  const SetoranStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: status.color),
      ),
    );
  }
}

// ─── DayakAppBar ──────────────────────────────────────────────────────────────
// AppBar dengan motif ukiran Dayak Kalimantan (putih di atas hijau).
// Penggunaan:
//   appBar: DayakAppBar(title: 'Nama Halaman'),
//   appBar: DayakAppBar(title: 'Transaksi', bottom: TabBar(...)),

class DayakAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;

  const DayakAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottom,
    this.backgroundColor,
  });

  @override
  Size get preferredSize {
    final bottomH = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomH);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary;
    return PreferredSize(
      preferredSize: preferredSize,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background hijau
          Container(color: bgColor),

          // Motif ukiran Dayak (hanya di area toolbar, bukan TabBar)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: kToolbarHeight + MediaQuery.of(context).padding.top,
            child: CustomPaint(painter: _DayakPatternPainter()),
          ),

          // AppBar transparan di atas motif
          AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: titleWidget ??
                Text(
                  title ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            leading: leading,
            actions: actions,
            bottom: bottom,
          ),
        ],
      ),
    );
  }
}

class _DayakPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.13)
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.2;

    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final h = size.height;
    final w = size.width;

    // ── 1. Border bawah — garis ganda khas tenun Dayak
    paint.color = Colors.white.withValues(alpha: 0.20);
    canvas.drawRect(Rect.fromLTWH(0, h - 3, w, 1.5), paint);
    paint.color = Colors.white.withValues(alpha: 0.10);
    canvas.drawRect(Rect.fromLTWH(0, h - 6, w, 1.2), paint);

    // ── 2. Motif segitiga pucuk rebung (kiri & kanan)
    paint.color = Colors.white.withValues(alpha: 0.11);
    _drawPucukRebungRow(canvas, paint, size);

    // ── 3. Spiral / ukel Dayak — kiri
    _drawUkel(canvas, strokePaint, paint, Offset(28, h * 0.50), 10);
    _drawUkel(canvas, strokePaint, paint, Offset(58, h * 0.50), 8);

    // ── 4. Spiral / ukel Dayak — kanan
    _drawUkel(canvas, strokePaint, paint, Offset(w - 28, h * 0.50), 10);
    _drawUkel(canvas, strokePaint, paint, Offset(w - 58, h * 0.50), 8);

    // ── 5. Diamond / belah ketupat center-left & center-right
    paint.color = Colors.white.withValues(alpha: 0.10);
    strokePaint.color = Colors.white.withValues(alpha: 0.20);
    _drawDiamond(canvas, strokePaint, paint, Offset(w * 0.15, h * 0.48), 7);
    _drawDiamond(canvas, strokePaint, paint, Offset(w * 0.85, h * 0.48), 7);
    _drawDiamond(canvas, strokePaint, paint, Offset(w * 0.08, h * 0.48), 4.5);
    _drawDiamond(canvas, strokePaint, paint, Offset(w * 0.92, h * 0.48), 4.5);

    // ── 6. Motif kembang/flora kecil di tengah-kiri dan tengah-kanan
    strokePaint.color = Colors.white.withValues(alpha: 0.15);
    _drawFloralAccent(canvas, strokePaint, Offset(w * 0.22, h * 0.50), 9);
    _drawFloralAccent(canvas, strokePaint, Offset(w * 0.78, h * 0.50), 9);
  }

  // Baris segitiga pucuk rebung di bawah AppBar
  void _drawPucukRebungRow(Canvas canvas, Paint paint, Size size) {
    const triW = 14.0;
    const triH = 7.0;
    final y = size.height - 10;
    int count = (size.width / triW).ceil() + 1;
    for (int i = 0; i < count; i++) {
      final x = i * triW;
      final path = Path()
        ..moveTo(x, y + triH)
        ..lineTo(x + triW / 2, y)
        ..lineTo(x + triW, y + triH)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  // Spiral / ukel — motif spiral khas Dayak
  void _drawUkel(
      Canvas canvas, Paint stroke, Paint fill, Offset center, double r) {
    // Lingkaran luar
    canvas.drawCircle(center, r, stroke);
    // Lingkaran dalam
    canvas.drawCircle(center, r * 0.5, fill);
    // Spiral path
    final path = Path();
    path.moveTo(center.dx + r, center.dy);
    for (double angle = 0; angle <= 3.5 * 3.14159; angle += 0.1) {
      final radius = r * (1 - angle / (4 * 3.14159));
      if (radius < 1) break;
      path.lineTo(
        center.dx + radius * _cos(angle),
        center.dy + radius * _sin(angle),
      );
    }
    canvas.drawPath(path, stroke);
  }

  // Diamond / belah ketupat
  void _drawDiamond(
      Canvas canvas, Paint stroke, Paint fill, Offset center, double r) {
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r * 0.65, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r * 0.65, center.dy)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  // Motif kembang 4 kelopak
  void _drawFloralAccent(Canvas canvas, Paint stroke, Offset center, double r) {
    for (int i = 0; i < 4; i++) {
      final angle = i * 3.14159 / 2;
      final cx = center.dx + r * 0.55 * _cos(angle);
      final cy = center.dy + r * 0.55 * _sin(angle);
      canvas.drawCircle(Offset(cx, cy), r * 0.38, stroke);
    }
    canvas.drawCircle(center, r * 0.28, stroke);
  }

  double _cos(double a) => _mathCos(a);
  double _sin(double a) => _mathSin(a);

  static double _mathCos(double x) {
    x = x % (2 * 3.14159265358979);
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  static double _mathSin(double x) {
    x = x % (2 * 3.14159265358979);
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
