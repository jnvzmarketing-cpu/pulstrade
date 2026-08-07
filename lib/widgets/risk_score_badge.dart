import 'package:flutter/material.dart';
import '../theme.dart';

/// Risk Score Badge — visualizes signal quality
/// Used inline in Signal Cards and Signal Detail
class RiskScoreBadge extends StatelessWidget {
  final int confidence;
  final String? note; // Backend note like "A+ setup (4/5)" or "A setup (2/5, premium)"
  final bool compact;

  const RiskScoreBadge({
    super.key,
    required this.confidence,
    this.note,
    this.compact = false,
  });

  /// Determine risk level from confidence + note
  /// Returns: ('LOW', '🟢') / ('MED', '🟡') / ('HIGH', '🔴')
  ({String level, Color color, String emoji, String label}) _classify() {
    // Extract quality from note if present
    final hasAplus = note?.contains('A+') ?? false;
    final hasPremium = note?.contains('premium') ?? false;
    final hasConfirmed = note?.contains('CONFIRMED') ?? false;

    // Strong signals (A+ setup OR Confirmation Sweep OR conf >= 85)
    if (hasAplus || hasConfirmed || confidence >= 85) {
      return (
        level: 'A+',
        color: AppColors.green,
        emoji: '🟢',
        label: 'STRONG',
      );
    }

    // Good signals (A setup with premium, OR conf >= 75)
    if (hasPremium || confidence >= 75) {
      return (
        level: 'A',
        color: AppColors.gold,
        emoji: '🟡',
        label: 'GOOD',
      );
    }

    // Moderate (conf 65-74)
    if (confidence >= 65) {
      return (
        level: 'B',
        color: AppColors.gold,
        emoji: '🟠',
        label: 'MODERATE',
      );
    }

    // Weak (conf < 65)
    return (
      level: 'C',
      color: AppColors.red,
      emoji: '🔴',
      label: 'WEAK',
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = _classify();

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: score.color.withOpacity(.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: score.color.withOpacity(.4), width: .5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(score.emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(score.level,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: score.color,
                  letterSpacing: 0.5)),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: score.color.withOpacity(.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: score.color.withOpacity(.4), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: score.color,
            shape: BoxShape.circle,
          ),
          child: Text(score.emoji, style: const TextStyle(fontSize: 11)),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Risk Quality',
              style: TextStyle(
                  fontSize: 9,
                  color: score.color.withOpacity(.8),
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 1),
          Row(children: [
            Text(score.level,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: score.color,
                    letterSpacing: -0.3)),
            const SizedBox(width: 6),
            Text(score.label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: score.color,
                    letterSpacing: 0.3)),
          ]),
        ]),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: score.color.withOpacity(.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('$confidence%',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: score.color)),
        ),
      ]),
    );
  }
}
