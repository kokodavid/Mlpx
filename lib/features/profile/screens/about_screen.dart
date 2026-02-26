import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../utils/app_colors.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.copBlue),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'About Milpress',
          style: TextStyle(
            color: AppColors.copBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            // App logo + name + subtitle
            Column(
              children: [
                Image.asset(
                  'assets/orange_logo.png',
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Milpress Educational',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.copBlue,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your learning companion for phonics and\nliteracy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Contact / links card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildItem(
                    icon: Icons.email,
                    title: 'Email support',
                    subtitle: 'support@milpress.com',
                    showExternalIcon: false,
                    onTap: () {
                      // TODO: open mail client
                    },
                  ),
                  _buildDivider(),
                  _buildItem(
                    icon: Icons.help,
                    title: 'Help Center',
                    subtitle: 'Get help and FAQs',
                    showExternalIcon: true,
                    onTap: () {
                      // TODO: open help center
                    },
                  ),
                  _buildDivider(),
                  _buildItem(
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    showExternalIcon: true,
                    onTap: () {
                      // TODO: open privacy policy
                    },
                  ),
                  _buildDivider(),
                  _buildItem(
                    icon: Icons.description,
                    title: 'Term of Service',
                    subtitle: 'Read our terms of service',
                    showExternalIcon: true,
                    onTap: () {
                      // TODO: open terms of service
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Version section
            _AppVersionSection(
              version: _version,
              buildNumber: _buildNumber,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool showExternalIcon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Light grey container, solid copBlue filled icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.copBlue, size: 22),
            ),
            const SizedBox(width: 12),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.copBlue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textColor,
                    ),
                  ),
                ],
              ),
            ),

            // External link icon (untouched)
            if (showExternalIcon)
              const Icon(
                Icons.open_in_new,
                size: 16,
                color: AppColors.textColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 64,
      endIndent: 0,
      color: AppColors.borderColor,
    );
  }
}

// App version section
class _AppVersionSection extends StatelessWidget {
  final String version;
  final String buildNumber;

  const _AppVersionSection({
    required this.version,
    required this.buildNumber,
  });

  @override
  Widget build(BuildContext context) {
    final versionText = version.isNotEmpty
        ? 'Version $version ($buildNumber)'
        : '';

    return Column(
      children: [
        const Text(
          'Version',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          versionText.isNotEmpty ? versionText : '—',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}