class Postcard {
  final String id;
  String title;
  String content;
  DateTime? date;
  String? imagePath;
  String city;
  String country;

  Postcard({
    required this.id,
    required this.title,
    required this.content,
    required this.city,
    required this.country,
    this.date,
    this.imagePath,
  });

  Postcard copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    String? imagePath,
    String? city,
    String? country,
  }) => Postcard(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    date: date ?? this.date,
    imagePath: imagePath ?? this.imagePath,
    city: city ?? this.city,
    country: country ?? this.country,
  );
}