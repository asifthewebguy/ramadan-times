import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';

class DuaScreen extends StatefulWidget {
  const DuaScreen({super.key});

  @override
  State<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends State<DuaScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _duas = [];
  Set<String> _favourites = {};
  late TabController _tabController;
  bool _loading = true;

  static const _categories = [
    'All',
    'Morning',
    'Evening',
    'Before Prayer',
    'After Prayer',
    'Ramadan',
    'Travel',
    'Food',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final json = await rootBundle.loadString('assets/data/duas.json');
    final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('dua_favourites') ?? [];
    if (mounted) {
      setState(() {
        _duas = list;
        _favourites = Set.from(favs);
        _loading = false;
      });
    }
  }

  Future<void> _toggleFavourite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favourites.contains(id)) {
        _favourites.remove(id);
      } else {
        _favourites.add(id);
      }
    });
    await prefs.setStringList('dua_favourites', _favourites.toList());
  }

  List<Map<String, dynamic>> _filteredDuas(String category) {
    if (category == 'All') return _duas;
    return _duas.where((d) => d['category'] == category).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Dua Library'),
        backgroundColor: AppColors.primaryDark,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textDim,
          indicatorColor: AppColors.gold,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: AppColors.primaryLight,
          tabs: _categories.map((c) => Tab(text: c)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : TabBarView(
              controller: _tabController,
              children: _categories
                  .map((cat) => _DuaList(
                        duas: _filteredDuas(cat),
                        favourites: _favourites,
                        onToggleFav: _toggleFavourite,
                      ))
                  .toList(),
            ),
    );
  }
}

class _DuaList extends StatelessWidget {
  final List<Map<String, dynamic>> duas;
  final Set<String> favourites;
  final ValueChanged<String> onToggleFav;

  const _DuaList({
    required this.duas,
    required this.favourites,
    required this.onToggleFav,
  });

  @override
  Widget build(BuildContext context) {
    if (duas.isEmpty) {
      return const Center(
        child: Text('No duas found', style: TextStyle(color: AppColors.textDim)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: duas.length,
      itemBuilder: (_, i) => _DuaCard(
        dua: duas[i],
        isFav: favourites.contains(duas[i]['id']),
        onToggleFav: () => onToggleFav(duas[i]['id'] as String),
      ),
    );
  }
}

class _DuaCard extends StatelessWidget {
  final Map<String, dynamic> dua;
  final bool isFav;
  final VoidCallback onToggleFav;

  const _DuaCard({
    required this.dua,
    required this.isFav,
    required this.onToggleFav,
  });

  void _share() {
    final text =
        '${dua['arabic']}\n\n${dua['transliteration']}\n\n${dua['translation']}\n\nSource: ${dua['source']}';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Arabic text (RTL)
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                dua['arabic'] as String,
                style: const TextStyle(
                  fontFamily: 'Scheherazade',
                  fontSize: 22,
                  color: AppColors.gold,
                  height: 1.9,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.primaryLight, height: 1),
            const SizedBox(height: 10),
            // Transliteration
            Text(
              dua['transliteration'] as String,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            // Translation
            Text(
              dua['translation'] as String,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 10),
            // Footer: source + actions
            Row(
              children: [
                Text(
                  dua['source'] as String,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onToggleFav,
                  child: Icon(
                    isFav ? Icons.bookmark : Icons.bookmark_outline,
                    color: isFav ? AppColors.gold : AppColors.textDim,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: _share,
                  child: const Icon(
                    Icons.share_outlined,
                    color: AppColors.textDim,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
