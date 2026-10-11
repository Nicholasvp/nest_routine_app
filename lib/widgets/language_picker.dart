import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';

class _LanguageOption {
  final String code;
  final String flag;
  final String nativeName;
  final String localName;

  const _LanguageOption({
    required this.code,
    required this.flag,
    required this.nativeName,
    required this.localName,
  });
}

/// Abre o seletor de idioma em um dialog com cards totalmente clicáveis.
Future<void> showLanguagePicker(
  BuildContext context,
  LocaleProvider localeProvider,
) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => _LanguagePickerDialog(localeProvider: localeProvider),
  );
}

class _LanguagePickerDialog extends StatelessWidget {
  final LocaleProvider localeProvider;

  const _LanguagePickerDialog({required this.localeProvider});

  static const List<_LanguageOption> _options = [
    _LanguageOption(
      code: 'en',
      flag: '🇺🇸',
      nativeName: 'English',
      localName: 'Inglês',
    ),
    _LanguageOption(
      code: 'pt',
      flag: '🇧🇷',
      nativeName: 'Português',
      localName: 'Português',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;
    final selected = localeProvider.locale.languageCode;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        decoration: BoxDecoration(
          color: AppColors.darkPurple,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.glowPurple.withValues(alpha: 0.25),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sleepPurple.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.language_rounded,
                    size: 18,
                    color: AppColors.sleepPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  strings.language,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ..._options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LanguageCard(
                  option: option,
                  isSelected: selected == option.code,
                  onTap: () {
                    localeProvider.setLocale(option.code);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(strings.cancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final _LanguageOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.sleepPurple.withValues(alpha: 0.14),
        highlightColor: AppColors.sleepPurple.withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.sleepPurple.withValues(alpha: 0.18)
                : AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.sleepPurple : AppColors.cardBorder,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(option.flag, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.nativeName,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.localName,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.sleepPurple : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.sleepPurple
                        : AppColors.cardBorder,
                    width: 1.6,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: AppColors.textPrimary)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
