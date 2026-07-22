import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../l10n.dart';

// Horizontal scrollable sport selector. "All Sports" is selected by default.
class SportSelector extends StatelessWidget {
  final String selectedKey;
  final ValueChanged<String> onSelected;
  final Locale locale;

  const SportSelector({
    super.key,
    required this.selectedKey,
    required this.onSelected,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final lang = locale.languageCode;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: sports.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final sport = sports[index];
          final selected = sport.key == selectedKey;
          final name = sport.key == 'all'
              ? AppStrings.get(lang, 'allSports')
              : sport.name;
          return ChoiceChip(
            label: Text('${sport.emoji}  $name'),
            selected: selected,
            onSelected: (_) => onSelected(sport.key),
            backgroundColor:
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkCard
                    : Colors.white,
            selectedColor: AppColors.brandBlue,
            labelStyle: TextStyle(
              color: selected ? Colors.white : null,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: selected
                    ? AppColors.brandBlue
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          );
        },
      ),
    );
  }
}
