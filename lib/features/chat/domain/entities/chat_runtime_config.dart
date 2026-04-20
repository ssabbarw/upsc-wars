class ChatRuntimeConfig {
  const ChatRuntimeConfig({
    required this.enableOnlineIndicator,
    required this.enableTypingIndicator,
    required this.enableUnreadCount,
  });

  final bool enableOnlineIndicator;
  final bool enableTypingIndicator;
  final bool enableUnreadCount;

  static const defaults = ChatRuntimeConfig(
    enableOnlineIndicator: true,
    enableTypingIndicator: true,
    enableUnreadCount: true,
  );
}
