import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';

import '../../models/postcard.dart';
import 'postcard_edit_screen.dart';

class PostcardDetailScreen extends StatefulWidget {
  final Postcard postcard; // 이미 존재하는 엽서 클릭 시 진입
  const PostcardDetailScreen({super.key, required this.postcard});

  @override
  State<PostcardDetailScreen> createState() => _PostcardDetailScreenState();
}

class _PostcardDetailScreenState extends State<PostcardDetailScreen> {
  late Postcard _postcard;
  bool _isBack = false;

  // 앞면에서만 바꾸는 값 (이미지/날짜)
  DateTime? _date;
  String? _imagePath;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _postcard = widget.postcard;
    _date = _postcard.date;
    _imagePath = _postcard.imagePath;
  }

  // ===== 앞면 버튼 동작 =====
  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) setState(() => _imagePath = x.path);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _saveFront() {
    final updated = _postcard.copyWith(
      date: _date,
      imagePath: _imagePath,
    );
    Navigator.pop(context, updated);
  }

  // ===== 뒷면 버튼 동작 =====
  void _cancelBack() => setState(() => _isBack = false); // 앞면으로 플립만

  Future<void> _editBack() async {
    final edited = await Navigator.push<Postcard>(
      context,
      MaterialPageRoute(
        builder: (_) => PostcardEditScreen(initial: _postcard),
      ),
    );
    if (edited != null) {
      setState(() => _postcard = edited);
    }
  }

  Future<void> _deleteBack() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('엽서 삭제'),
        content: const Text('정말 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok == true) {
      // 부모에게 삭제 신호 전달
      Navigator.pop(context, const Postcard(id: '__deleted__'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Postcards')),
      body: Center(
        child: GestureDetector(
          onTap: () => setState(() => _isBack = !_isBack),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, anim) => RotationYTransition(turns: anim, child: child),
            child: _isBack ? _buildBack() : _buildFront(),
          ),
        ),
      ),
    );
  }

  // ================= FRONT =================
  Widget _buildFront() {
    return Column(
      key: const ValueKey('front'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _stampFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 메인 이미지
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF8F6F1), borderRadius: BorderRadius.circular(6)),
                  clipBehavior: Clip.antiAlias,
                  child: _imagePath != null
                      ? (File(_imagePath!).existsSync()
                      ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                      : Image.asset(_imagePath!, fit: BoxFit.cover))
                      : const Center(child: Icon(Icons.image, size: 96, color: Colors.grey)),
                ),
              ),
              // 타이틀 + 날짜
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  _postcard.title.isEmpty ? 'Untitled' : _postcard.title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFFFF8903)),
                ),
              ),
              if (_date != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                  child: Text(
                    "${_date!.month.toString().padLeft(2, '0')}/${_date!.day.toString().padLeft(2, '0')}/${_date!.year}",
                    style: const TextStyle(color: Color(0xFFFF8903), fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // 앞면 버튼: 이미지 변경 / 날짜 변경 / 저장
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            _ActionLabel(icon: Icons.image, label: '이미지 변경'),
            _ActionLabel(icon: Icons.calendar_month, label: '날짜 변경'),
            _ActionLabel(icon: Icons.check_circle, label: '저장'),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(onPressed: _pickImage, icon: const Icon(Icons.image)),
            IconButton(onPressed: _pickDate, icon: const Icon(Icons.calendar_month)),
            IconButton(onPressed: _saveFront, icon: const Icon(Icons.check_circle)),
          ],
        ),
      ],
    );
  }

  // ================= BACK =================
  Widget _buildBack() {
    final hasContent = (_postcard.content ?? '').trim().isNotEmpty;
    return Column(
      key: const ValueKey('back'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _stampFrame(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_postcard.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                hasContent
                    ? Text(_postcard.content!)
                    : const SizedBox(height: 120), // 내용 없을 때 비어있는 종이 느낌
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // 뒷면 버튼: 취소(앞면으로), 수정(편집화면), 삭제
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            _ActionLabel(icon: Icons.arrow_back, label: '취소'),
            _ActionLabel(icon: Icons.edit, label: '수정'),
            _ActionLabel(icon: Icons.delete, label: '삭제'),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(onPressed: _cancelBack, icon: const Icon(Icons.arrow_back)),
            IconButton(onPressed: _editBack, icon: const Icon(Icons.edit)),
            IconButton(onPressed: _deleteBack, icon: const Icon(Icons.delete)),
          ],
        ),
      ],
    );
  }

  // 공통 스탬프 프레임
  Widget _stampFrame({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF219EBC),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      width: 320,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F6F1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      ),
    );
  }
}

// flip 효과: 유지
class RotationYTransition extends AnimatedWidget {
  final Widget child;
  final Animation<double> turns;
  const RotationYTransition({super.key, required this.child, required this.turns}) : super(listenable: turns);

  @override
  Widget build(BuildContext context) {
    final angle = (listenable as Animation<double>).value * math.pi;
    return Transform(
      transform: Matrix4.rotationY(angle),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _ActionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ActionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
