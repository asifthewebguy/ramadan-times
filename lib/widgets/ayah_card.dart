import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/theme.dart';

class AyahCard extends StatefulWidget {
  const AyahCard({super.key});

  @override
  State<AyahCard> createState() => _AyahCardState();
}

class _AyahCardState extends State<AyahCard> {
  Map<String, dynamic>? _ayah;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final json = await rootBundle.loadString('assets/data/ayah_daily.json');
    final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return;
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year))
        .inDays;
    if (mounted) {
      setState(() => _ayah = list[dayOfYear % list.length]);
    }
  }

  void _share() {
    if (_ayah == null) return;
    final text =
        '${_ayah!['arabic']}\n\n"${_ayah!['translation']}"\n\n— ${_ayah!['surah']} ${_ayah!['ayah']}';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    if (_ayah == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryLight,
              AppColors.cardBg,
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.25),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row
              Row(
                children: [
                  const Icon(Icons.menu_book_outlined, color: AppColors.gold, size: 15),
                  const SizedBox(width: 6),
                  const Text(
                    'AYAH OF THE DAY',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_ayah!['surah']} : ${_ayah!['ayah']}',
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Arabic text
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  _ayah!['arabic'] as String,
                  style: const TextStyle(
                    fontFamily: 'Scheherazade',
                    fontSize: 21,
                    color: AppColors.gold,
                    height: 1.9,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 8),
              // Translation
              Text(
                _ayah!['translation'] as String,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: _expanded ? null : 3,
                overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Footer
              Row(
                children: [
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.expand_more,
                      color: AppColors.textDim,
                      size: 18,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _share,
                    child: const Icon(
                      Icons.share_outlined,
                      color: AppColors.textDim,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
