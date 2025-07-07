import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../main.dart';
import 'admin_home_screen.dart';

class LanguageManagement extends StatefulWidget {
  const LanguageManagement({Key? key}) : super(key: key);

  @override
  State<LanguageManagement> createState() => _LanguageManagementState();
}

class _LanguageManagementState extends State<LanguageManagement> {
  String _selectedLanguage = 'en';
  bool _isChangingLanguage = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final locale = await AppLocalizations.getLocale();
    setState(() {
      _selectedLanguage = locale.languageCode;
    });
  }

  Future<void> _changeLanguage(String? languageCode) async {
    if (languageCode == null || _isChangingLanguage) return;

    // Get the language notifier at the start - before any async operations
    final languageNotifier =
        Provider.of<LanguageChangeNotifier>(context, listen: false);

    setState(() {
      _isChangingLanguage = true;
    });

    try {
      // Set changing state before async operations
      languageNotifier.setChanging(true);

      // First, show feedback to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageCode == 'en'
                ? 'Switching to English...'
                : 'ወደ አማርኛ በመቀየር ላይ...'),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      // Save the language preference
      await AppLocalizations.setLocale(languageCode);

      if (mounted) {
        setState(() {
          _selectedLanguage = languageCode;
        });
      }

      // Ensure SharedPreferences is updated
      await Future.delayed(const Duration(milliseconds: 300));

      // Update the notifier with the new locale
      languageNotifier.setLocale(Locale(languageCode));

      // Show a success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageCode == 'en'
                ? 'Language changed to English'
                : 'ቋንቋ ወደ አማርኛ ተቀይሯል'),
            backgroundColor: Colors.green,
          ),
        );

        // Pop back to previous screen after a short delay to allow the language change to apply
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminHomeScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing language: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Reset changing state - do this regardless of mounted state
      languageNotifier.setChanging(false);

      if (mounted) {
        setState(() {
          _isChangingLanguage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final languageNotifier = Provider.of<LanguageChangeNotifier>(context);
    final isLoading = _isChangingLanguage || languageNotifier.isChanging;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminHomeScreen(),
              ),
            );
          },
        ),
        title: Text(localizations.languageSettings),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _selectedLanguage == 'en'
                        ? 'Changing to English...'
                        : 'ወደ አማርኛ በመቀየር ላይ...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    localizations.language,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                _buildLanguageOption(
                  title: localizations.english,
                  value: 'en',
                  icon: Icons.language,
                  context: context,
                ),
                _buildLanguageOption(
                  title: localizations.amharic,
                  value: 'am',
                  icon: Icons.language,
                  context: context,
                ),
                const SizedBox(height: 30),
                if (_selectedLanguage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _selectedLanguage == 'en'
                          ? 'Currently selected: English'
                          : 'አሁን የተመረጠው: አማርኛ',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String value,
    required IconData icon,
    required BuildContext context,
  }) {
    final isSelected = _selectedLanguage == value;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      color: isSelected ? theme.primaryColor.withOpacity(0.1) : null,
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _changeLanguage(value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? theme.primaryColor : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? theme.primaryColor : null,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
