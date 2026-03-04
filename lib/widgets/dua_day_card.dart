import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme.dart';
import '../screens/dua_screen.dart';

class DuaDayCard extends StatefulWidget {
  const DuaDayCard({super.key});

  @override
  State<DuaDayCard> createState() => _DuaDayCardState();
}

class _DuaDayCardState extends State<DuaDayCard> {
  Map<String, dynamic>? _dua;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final json = await rootBundle.loadString('assets/data/duas.json');
    final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return;
    final dayIndex = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    if (mounted) {
      setState(() => _dua = list[dayIndex % list.length]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dua == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DuaScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryLight),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.gold, size: 15),
                  const SizedBox(width: 6),
                  const Text(
                    'DUA OF THE DAY',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _dua!['category'] as String,
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: AppColors.textDim, size: 16),
                ],
              ),
              const SizedBox(height: 10),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  _dua!['arabic'] as String,
                  style: const TextStyle(
                    fontFamily: 'Scheherazade',
                    fontSize: 19,
                    color: AppColors.gold,
                    height: 1.85,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _dua!['translation'] as String,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.45,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
