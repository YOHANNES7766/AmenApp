import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../main.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  String _currentLanguage = 'en';
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final locale = await AppLocalizations.getLocale();
    if (mounted) {
      setState(() {
        _currentLanguage = locale.languageCode;
      });
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    final languageNotifier =
        Provider.of<LanguageChangeNotifier>(context, listen: false);

    try {
      languageNotifier.setChanging(true);
      await AppLocalizations.setLocale(languageCode);
      await Future.delayed(const Duration(milliseconds: 500));

      languageNotifier.setLocale(Locale(languageCode));

      if (mounted) {
        setState(() {
          _currentLanguage = languageCode;
          _isOpen = false;
        });
      }
    } catch (e) {
      debugPrint('Error changing language: $e');
    } finally {
      languageNotifier.setChanging(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    // Get language display name
    String displayLanguage;
    switch (_currentLanguage) {
      case 'am':
        displayLanguage = 'አማርኛ';
        break;
      case 'en':
      default:
        displayLanguage = 'English';
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;

          setState(() {
            _isOpen = !_isOpen;
          });

          if (_isOpen) {
            _showLanguagePopup(position, size);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayLanguage,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color: theme.brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show the language popup menu
  void _showLanguagePopup(Offset position, Size size) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Stack(
          children: [
            // Add a gesture detector to dismiss when tapping elsewhere
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _isOpen = false;
                  });
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),

            // The language popup menu
            Positioned(
              top: position.dy + size.height,
              left: position.dx -
                  150 +
                  size.width, // Position it to the right of the button
              width: 200,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLanguageOption('English', 'en', context),
                    _buildLanguageOption('አማርኛ', 'am', context),
                    _buildLanguageOption('Afaan Oromoo', 'or', context),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _isOpen = false;
        });
      }
    });
  }

  Widget _buildLanguageOption(String label, String code, BuildContext context) {
    final isSelected = _currentLanguage == code;
    // For now, only enable English and Amharic
    final isEnabled = code == 'en' || code == 'am';
    final theme = Theme.of(context);

    return InkWell(
      onTap: isEnabled
          ? () {
              _changeLanguage(code);
              Navigator.pop(context);
            }
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? (theme.brightness == Brightness.dark
                  ? theme.primaryColor.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1))
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isEnabled
                ? (theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87)
                : Colors.grey,
          ),
        ),
      ),
    );
  }
}

// Triangle clipper for the dropdown indicator
class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(TriangleClipper oldClipper) => false;
}
