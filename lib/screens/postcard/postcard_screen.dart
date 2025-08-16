import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/app_bottom_nav.dart';

/// ---------------------------------------------------------------------------
/// Model
/// ---------------------------------------------------------------------------
class Postcard {
  final String id;
  String title;          // e.g., Gyeongbokgung
  String city;           // e.g., Seoul
  String country;        // e.g., Korea
  DateTime? date;        // taken/visited date
  String? imagePath;     // local file path
  String? content;       // back-side message

  Postcard({
    required this.id,
    this.title = '',
    this.city = '',
    this.country = '',
    this.date,
    this.imagePath,
    this.content,
  });

  factory Postcard.fromJson(Map<String, dynamic> j) => Postcard(
    id: j['id'] as String,
    title: j['title'] ?? '',
    city: j['city'] ?? '',
    country: j['country'] ?? '',
    date: j['date'] != null ? DateTime.tryParse(j['date']) : null,
    imagePath: j['imagePath'] as String?,
    content: j['content'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'city': city,
    'country': country,
    'date': date?.toIso8601String(),
    'imagePath': imagePath,
    'content': content,
  };
}

/// ---------------------------------------------------------------------------
/// Repository – lightweight local DB using SharedPreferences
/// ---------------------------------------------------------------------------
class PostcardRepo {
  static const _key = 'postcards.v1';

  Future<List<Postcard>> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map>().map((e) => Postcard.fromJson(e.cast<String, dynamic>())).toList();
    // 최신순 정렬 (Recent 탭용)
    list.sort((a, b) => (b.date ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.date ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return list;
  }

  Future<void> saveAll(List<Postcard> items) async {
    final sp = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await sp.setString(_key, raw);
  }

  Future<void> upsert(Postcard item) async {
    final list = await load();
    final idx = list.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      list[idx] = item;
    } else {
      list.add(item);
    }
    await saveAll(list);
  }
}

/// ---------------------------------------------------------------------------
/// List/Grid Screen with empty state & FAB (Figma #1, #2)
/// ---------------------------------------------------------------------------
class PostcardScreen extends StatefulWidget {
  static const routeName = '/postcard';
  const PostcardScreen({super.key});

  @override
  State<PostcardScreen> createState() => _PostcardScreenState();
}

class _PostcardScreenState extends State<PostcardScreen> {
  final _repo = PostcardRepo();
  List<Postcard> _all = [];
  String _query = '';
  int _segment = 0; // 0: Recent, 1: Later (예약/미래날짜)

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await _repo.load();
    setState(() => _all = list);
  }

  List<Postcard> get _filtered {
    final now = DateTime.now();
    Iterable<Postcard> items = _all;
    if (_segment == 0) {
      items = items.where((e) => (e.date ?? now).isBefore(now.add(const Duration(days: 1))));
    } else {
      items = items.where((e) => (e.date ?? now).isAfter(now));
    }
    if (_query.isNotEmpty) {
      items = items.where((e) {
        final hay = '${e.title} ${e.city} ${e.country}'.toLowerCase();
        return hay.contains(_query.toLowerCase());
      });
    }
    return items.toList();
  }

  void _openCreate() async {
    final created = await Navigator.of(context).push<Postcard>(
      MaterialPageRoute(builder: (_) => PostcardEditor()),
    );
    if (created != null) {
      await _repo.upsert(created);
      _reload();
    }
  }

  void _openDetail(Postcard p) async {
    final updated = await Navigator.of(context).push<Postcard>(
      MaterialPageRoute(builder: (_) => PostcardDetail(postcard: p)),
    );
    if (updated != null) {
      await _repo.upsert(updated);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _filtered.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Postcards'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search here',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF6F7F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          // Segmented (Recent / Later)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: CupertinoSlidingSegmentedControl<int>(
              thumbColor: Colors.white,
              groupValue: _segment,
              children: const {0: Text('Recent'), 1: Text('Later')},
              backgroundColor: const Color(0xFFEDEFF3),
              onValueChanged: (v) => setState(() => _segment = v ?? 0),
            ),
          ),

          // Content
          Expanded(
            child: hasData
                ? _GridView(
              items: _filtered,
              onTap: _openDetail,
            )
                : _EmptyState(onTapAdd: _openCreate),
          ),
        ],
      ),

      // Bottom bar + floating add
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFB300),
        onPressed: _openCreate,
        child: const Icon(Icons.add),
        elevation: 0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _BottomBar(currentIndex: 1),
    );
  }
}

/// Empty state (Figma #1)
class _EmptyState extends StatelessWidget {
  final VoidCallback onTapAdd;
  const _EmptyState({required this.onTapAdd});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Center(
          child: Text(
            'record your journey...',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ],
    );
  }
}

/// Grid (Figma #2)
class _GridView extends StatelessWidget {
  final List<Postcard> items;
  final void Function(Postcard) onTap;
  const _GridView({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final p = items[i];
        return GestureDetector(
          onTap: () => onTap(p),
          child: _StampTile(postcard: p),
        );
      },
    );
  }
}

/// Stamp-like tile
class _StampTile extends StatelessWidget {
  final Postcard postcard;
  const _StampTile({required this.postcard});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0DA4BF), width: 14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (postcard.imagePath != null && File(postcard.imagePath!).existsSync())
            Image.file(File(postcard.imagePath!), fit: BoxFit.cover)
          else
            Container(color: const Color(0xFFEFF7FA)),
          Positioned(
            left: 8,
            bottom: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  postcard.city.isNotEmpty ? postcard.city : "City's name",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

/// Bottom nav bar mimic (keeps style consistent across screens)
class _BottomBar extends StatelessWidget {
  final int currentIndex; // 0 Explore, 1 Postcard, 2 SNS, 3 Settings
  const _BottomBar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Postcard'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'SNS Search'),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Settings'),
      ],
      onTap: (i) {
        if (i == 0) Navigator.popUntil(context, (r) => r.isFirst);
        if (i == 2) Navigator.pushNamed(context, '/sns');
        if (i == 3) Navigator.pushNamed(context, '/settings');
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// Detail (front/back flip) + quick actions (Figma #3, #4)
/// ---------------------------------------------------------------------------
class PostcardDetail extends StatefulWidget {
  final Postcard postcard;
  const PostcardDetail({super.key, required this.postcard});

  @override
  State<PostcardDetail> createState() => _PostcardDetailState();
}

class _PostcardDetailState extends State<PostcardDetail> with SingleTickerProviderStateMixin {
  late bool _isFront;
  final _picker = ImagePicker();
  late Postcard _model;

  @override
  void initState() {
    super.initState();
    _isFront = true;
    _model = Postcard(
      id: widget.postcard.id,
      title: widget.postcard.title,
      city: widget.postcard.city,
      country: widget.postcard.country,
      date: widget.postcard.date,
      imagePath: widget.postcard.imagePath,
      content: widget.postcard.content,
    );
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) setState(() => _model.imagePath = x.path);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _model.date ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _model.date = picked);
  }

  void _save() => Navigator.pop(context, _model);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Postcards'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _isFront = !_isFront),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  transitionBuilder: (child, anim) {
                    final rotate = Tween(begin: math.pi, end: 0.0).animate(anim);
                    return AnimatedBuilder(
                      animation: rotate,
                      child: child,
                      builder: (context, child) {
                        final isUnder = (ValueKey(_isFront) != child!.key);
                        var tilt = (anim.value - 0.5).abs() - 0.5;
                        tilt *= isUnder ? -0.003 : 0.003;
                        final value = isUnder ? math.min(rotate.value, math.pi / 2) : rotate.value;
                        return Transform(
                          transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
                          alignment: Alignment.center,
                          child: child,
                        );
                      },
                    );
                  },
                  layoutBuilder: (w, l) => Stack(children: [if (w != null) w, ...l]),
                  child: _isFront
                      ? _FrontCard(key: const ValueKey(true), model: _model)
                      : _BackCard(key: const ValueKey(false), model: _model),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Action(icon: Icons.image, label: '이미지 변경', onTap: _pickImage),
                _Action(icon: Icons.calendar_month, label: '날짜 변경', onTap: _pickDate),
                _Action(icon: Icons.check_circle, label: '저장', onTap: _save),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }
}

class _FrontCard extends StatelessWidget {
  final Postcard model;
  const _FrontCard({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF0DA4BF), width: 18),
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: (model.imagePath != null && File(model.imagePath!).existsSync())
                  ? Image.file(File(model.imagePath!), fit: BoxFit.cover)
                  : Container(color: const Color(0xFFEFF7FA)),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.date != null ? _monthDay(model.date!) : "Month 00'",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.orange),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    model.city.isNotEmpty ? model.city : "City's name",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.orange),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackCard extends StatelessWidget {
  final Postcard model;
  const _BackCard({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final title = model.title.isNotEmpty ? model.title : ' ';
    final content = model.content?.trim() ?? '';
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF0DA4BF), width: 18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: content.isNotEmpty
                    ? SingleChildScrollView(child: Text(content))
                    : _RuledPaperPlaceholder(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuledPaperPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final lines = <Widget>[];
        for (int i = 0; i < 14; i++) {
          lines.add(Container(
            height: 14,
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFBFC7D1), width: 1),
              ),
            ),
          ));
        }
        return Column(children: lines);
      },
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(onPressed: onTap, icon: Icon(icon)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Editor (Create/Edit) – Figma #5 ~ #8
/// ---------------------------------------------------------------------------
class PostcardEditor extends StatefulWidget {
  final Postcard? initial;
  PostcardEditor({super.key, this.initial});

  @override
  State<PostcardEditor> createState() => _PostcardEditorState();
}

class _PostcardEditorState extends State<PostcardEditor> {
  final _form = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late Postcard _model;
  bool _editing = true; // shows 수정 상태 (enable fields)

  @override
  void initState() {
    super.initState();
    _model = widget.initial ?? Postcard(id: UniqueKey().toString());
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) setState(() => _model.imagePath = x.path);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _model.date ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _model.date = picked);
  }

  void _cancel() => Navigator.pop(context);

  void _save() {
    if (_form.currentState?.validate() ?? false) {
      _form.currentState?.save();
      Navigator.pop(context, _model);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Postcards'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Front preview (stamp frame)
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF0DA4BF), width: 18),
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: _model.imagePath != null && File(_model.imagePath!).existsSync()
                    ? Image.file(File(_model.imagePath!), fit: BoxFit.cover)
                    : Center(
                  child: Text(
                    "tourist spot's name",
                    style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Buttons row – image, date, save
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Action(icon: Icons.image, label: '이미지 업로드', onTap: _pickImage),
                _Action(icon: Icons.calendar_month, label: '날짜 설정', onTap: _pickDate),
                _Action(icon: Icons.check_circle, label: '저장', onTap: _save),
              ],
            ),
            const SizedBox(height: 24),

            // Back editor fields
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    initialValue: _model.title,
                    decoration: const InputDecoration(labelText: '제목 (엽서 앞/뒤 상단 Bold)', border: OutlineInputBorder()),
                    onSaved: (v) => _model.title = v?.trim() ?? '',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _model.city,
                          decoration: const InputDecoration(labelText: '도시명', border: OutlineInputBorder()),
                          onSaved: (v) => _model.city = v?.trim() ?? '',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: _model.country,
                          decoration: const InputDecoration(labelText: '국가명', border: OutlineInputBorder()),
                          onSaved: (v) => _model.country = v?.trim() ?? '',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    minLines: 5,
                    maxLines: 10,
                    initialValue: _model.content,
                    decoration: const InputDecoration(
                      labelText: '내용 (엽서 뒷면 Regular)',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (v) => _model.content = v?.trim(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Bottom action row – cancel, edit toggle, save
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Action(icon: Icons.arrow_back, label: '취소', onTap: _cancel),
                _Action(
                    icon: Icons.edit,
                    label: '수정',
                    onTap: () => setState(() => _editing = true)),
                _Action(icon: Icons.check_circle, label: '저장', onTap: _save),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Small helpers
String _monthDay(DateTime dt) {
  final m = _monthName(dt.month);
  final d = dt.day.toString().padLeft(2, '0');
  return '$m $d\''; // e.g., July 29'
}

String _monthName(int m) {
  const names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'July', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return names[(m - 1).clamp(0, 11)];
}