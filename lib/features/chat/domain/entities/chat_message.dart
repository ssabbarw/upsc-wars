class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderEmail,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String chatId;
  final String senderEmail;
  final String text;
  final int createdAt;
}
