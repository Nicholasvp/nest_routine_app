import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';

class UpdateModal extends StatelessWidget {
  final String latestVersion;
  final String? releaseNotes;
  final String? storeUrl;
  final bool isForceUpdate;
  final VoidCallback? onDismiss;

  const UpdateModal({
    super.key,
    required this.latestVersion,
    this.releaseNotes,
    this.storeUrl,
    this.isForceUpdate = false,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required String latestVersion,
    String? releaseNotes,
    String? storeUrl,
    bool isForceUpdate = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      barrierColor: Colors.black54,
      builder: (_) => UpdateModal(
        latestVersion: latestVersion,
        releaseNotes: releaseNotes,
        storeUrl: storeUrl,
        isForceUpdate: isForceUpdate,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<void> _openStore() async {
    if (storeUrl == null) return;
    final uri = Uri.parse(storeUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;

    return PopScope(
      canPop: !isForceUpdate,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.sleepPurple.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.sleepPurple.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: AppColors.sleepPurple,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                strings.updateAvailable,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.updateDesc(latestVersion),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (isForceUpdate) ...[
                const SizedBox(height: 8),
                Text(
                  strings.updateRequired,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.sleepPurple.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (releaseNotes != null && releaseNotes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.sleepPurple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.whatsNew,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        releaseNotes!,
                        style: TextStyle(
                          color: AppColors.textPrimary.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openStore,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(
                    strings.updateNow,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sleepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (!isForceUpdate) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onDismiss,
                  child: Text(
                    strings.updateLater,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
