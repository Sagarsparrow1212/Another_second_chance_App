/// Model for pending messages (messages waiting to be sent)
class PendingMessageModel {
  final String tempId; // Temporary ID (UUID) for pending messages
  final String chatId;
  final String text;
  final DateTime createdAt;
  final String senderId; // Current user ID

  PendingMessageModel({
    required this.tempId,
    required this.chatId,
    required this.text,
    required this.createdAt,
    required this.senderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'tempId': tempId,
      'chatId': chatId,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'senderId': senderId,
    };
  }

  factory PendingMessageModel.fromJson(Map<String, dynamic> json) {
    return PendingMessageModel(
      tempId: json['tempId'] ?? '',
      chatId: json['chatId'] ?? '',
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      senderId: json['senderId'] ?? '',
    );
  }
}

