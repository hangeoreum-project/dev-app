import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';

import '../../models/postcard.dart';
import 'postcard_edit_screen.dart';

/// 새 엽서 생성 플로우
/// - flip 사용: 앞면(이미지 업로드/날짜 설정/저장), 뒷면(취소/추가)
/// - [추가]를 누르면 PostcardEditScreen으로 이동해 제목/내용/도시/국가를 작성
class PostcardCreateScreen extends StatefulWidget {
  const PostcardCreateScreen({super.key});

  @override
  State<PostcardCreateScreen> createState() => _PostcardCreateScreenState();
}

class _PostcardCreateScreenState extends State<PostcardCreateScreen> {
  bool _isBack = false;
  final _picker = ImagePicker();
  DateTime? _date;
  String? _imagePath;

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
    // 제목/도시/국가/내용 없이도 저장을 허용 (나중에 수정 가능)
    final created = Postcard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '',
      content: '',
      city: '',
      country: '',
      date: _date,
      imagePath: _imagePath,
    );
    Navigator.pop(context, created);
  }

  // ===== 뒷면 버튼 동작 =====
  void _cancelBack() => setState(() => _isBack = false); // 앞면으로 플립

  Future<void> _addBack() async {
    // 현재 앞면에서 고른 이미지/날짜를 바탕으로 초기값 구성
    final draft = Postcard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '',
      content: '',
      city: '',
      country: '',
      date: _date,
      imagePath: _imagePath,
    );

    final result = await Navigator.push<Postcard>(
      context,
      MaterialPageRoute(builder: (_) => PostcardEditScreen(initial: draft)),
    );

    if (result != null) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 엽서 만들기')),
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
              if (_date != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                  child: Text(
                    "${_date!.month.toString().padLeft(2, '0')}/${_date!.day.toString().padLeft(2, '0')}/${_date!.year}",
                    style: const TextStyle(color: Color(0xFFFF8903), fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            _ActionLabel(icon: Icons.file_upload, label: '이미지 업로드'),
            _ActionLabel(icon: Icons.calendar_month, label: '날짜 설정'),
            _ActionLabel(icon: Icons.check_circle, label: '저장'),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(onPressed: _pickImage, icon: const Icon(Icons.file_upload)),
            IconButton(onPressed: _pickDate, icon: const Icon(Icons.calendar_month)),
            IconButton(onPressed: _saveFront, icon: const Icon(Icons.check_circle)),
          ],
        ),
      ],
    );
  }

  // ================= BACK =================
  Widget _buildBack() {
    return Column(
      key: const ValueKey('back'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _stampFrame(
          child: const SizedBox(height: 240), // 뒷면은 내용 없이 종이 느낌만
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            _ActionLabel(icon: Icons.arrow_back, label: '취소'),
            _ActionLabel(icon: Icons.add, label: '추가'),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(onPressed: _cancelBack, icon: const Icon(Icons.arrow_back)),
            IconButton(onPressed: _addBack, icon: const Icon(Icons.add)),
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

// flip 효과 공통
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
