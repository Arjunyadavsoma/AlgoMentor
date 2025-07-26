import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  MessageModel({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  /// ✅ Convert Firestore data to MessageModel
  factory MessageModel.fromMap(Map<String, dynamic> data) {
    return MessageModel(
      text: data['text'] ?? '',
      isUser: data['isUser'] ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  /// ✅ Convert model to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp,
    };
  }
}
