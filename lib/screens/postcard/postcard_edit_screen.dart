import 'package:flutter/material.dart';
import '../../models/postcard.dart';

/// 새 엽서 생성과 기존 엽서 수정을 모두 처리하는 편집 화면
/// (엽서 미리보기 없음 / 제목, 도시, 국가, 내용 입력만)
class PostcardEditScreen extends StatefulWidget {
  final Postcard? initial; // null이면 새 엽서 생성
  const PostcardEditScreen({super.key, this.initial});

  @override
  State<PostcardEditScreen> createState() => _PostcardEditScreenState();
}

class _PostcardEditScreenState extends State<PostcardEditScreen> {
  late TextEditingController _title;
  late TextEditingController _city;
  late TextEditingController _country;
  late TextEditingController _content;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initial?.title ?? '');
    _city = TextEditingController(text: widget.initial?.city ?? '');
    _country = TextEditingController(text: widget.initial?.country ?? '');
    _content = TextEditingController(text: widget.initial?.content ?? '');
  }

  void _save() {
    final base = widget.initial;
    final card = Postcard(
      id: base?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _title.text,
      content: _content.text,
      city: _city.text,
      country: _country.text,
      date: base?.date,
      imagePath: base?.imagePath,
    );
    Navigator.pop(context, card);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.initial == null ? '새 엽서 작성' : '엽서 수정')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: '제목', border: OutlineInputBorder()),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _city,
                  decoration: const InputDecoration(labelText: '도시명', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _country,
                  decoration: const InputDecoration(labelText: '국가명', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _content,
            decoration: const InputDecoration(labelText: '내용', border: OutlineInputBorder()),
            maxLines: 10,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('취소'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: const Text('저장'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
