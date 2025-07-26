class DSAQuestion {
  final String id;
  final String title;
  final String description;
  final String hint;
  final String difficulty;
  final String category;
  final String example;

  DSAQuestion({
    required this.id,
    required this.title,
    required this.description,
    required this.hint,
    required this.difficulty,
    required this.category,
    required this.example,
  });

  factory DSAQuestion.fromMap(Map<String, dynamic> data, String documentId) {
    return DSAQuestion(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      hint: data['hint'] ?? '',
      difficulty: data['difficulty'] ?? '',
      category: data['category'] ?? '',
      example: data['example'] ?? '',
    );
  }



  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'hint': hint,
      'difficulty': difficulty,
      'category': category,
      'example': example,
    };
  }
}
