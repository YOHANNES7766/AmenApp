import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/theme_service.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Themes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildThemeOption(
                  context,
                  title: 'Classic',
                  color: Colors.green[200]!,
                  isSelected: themeService.currentTheme == ThemeType.classic,
                  onTap: () => themeService.setTheme(ThemeType.classic),
                ),
                _buildThemeOption(
                  context,
                  title: 'Day',
                  color: Colors.blue[200]!,
                  isSelected: themeService.currentTheme == ThemeType.day,
                  onTap: () => themeService.setTheme(ThemeType.day),
                ),
                _buildThemeOption(
                  context,
                  title: 'Tinted',
                  color: Colors.grey[700]!,
                  isSelected: themeService.currentTheme == ThemeType.tinted,
                  onTap: () => themeService.setTheme(ThemeType.tinted),
                ),
                _buildThemeOption(
                  context,
                  title: 'Night',
                  color: Colors.grey[900]!,
                  isSelected: themeService.currentTheme == ThemeType.night,
                  onTap: () => themeService.setTheme(ThemeType.night),
                ),
                _buildThemeOption(
                  context,
                  title: 'Bible Study',
                  color: const Color(0xFF8c6d46),
                  isSelected: themeService.currentTheme == ThemeType.bibleStudy,
                  onTap: () => themeService.setTheme(ThemeType.bibleStudy),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildColorPalette(),
            const SizedBox(height: 32),
            const Text(
              'Theme settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              icon: Icons.person_outline,
              title: 'Your name color',
              trailing: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: themeService.nameColor,
                  shape: BoxShape.circle,
                ),
              ),
              onTap: () => _showColorPicker(context, themeService),
            ),
            _buildSettingItem(
              icon: Icons.nightlight_outlined,
              title: 'Auto-night mode',
              trailing: Switch(
                value: themeService.autoNightMode,
                onChanged: (value) => themeService.setAutoNightMode(value),
              ),
            ),
            _buildSettingItem(
              icon: Icons.font_download_outlined,
              title: 'Font family',
              trailing: const Text('Default'),
              onTap: () => _showFontPicker(context, themeService),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isBibleStudy = title == 'Bible Study';

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 120,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (isBibleStudy) ...[
                  const Icon(Icons.book, color: Color(0xFFf8f4e3), size: 24),
                  const Icon(Icons.people, color: Color(0xFFf8f4e3), size: 24),
                  const Icon(Icons.church, color: Color(0xFFf8f4e3), size: 24),
                ] else ...[
                  Container(
                    width: 60,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.blue : null,
              fontWeight: isSelected ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette() {
    final colors = [
      Colors.blue,
      Colors.cyan,
      Colors.green,
      Colors.pink,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.indigo,
      Colors.amber,
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((color) {
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showColorPicker(BuildContext context, ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose name color'),
        content: SingleChildScrollView(
          child: _buildColorPalette(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFontPicker(BuildContext context, ThemeService themeService) {
    final fonts = ['Default', 'Roboto', 'Open Sans', 'Lato', 'Montserrat'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose font family'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: fonts.map((font) {
              return ListTile(
                title: Text(font),
                onTap: () {
                  themeService.setFontFamily(font);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
