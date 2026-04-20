class ChatThreadRoutePayload {
  const ChatThreadRoutePayload({
    required this.peerEmail,
    required this.peerDisplayName,
    this.peerPhotoUrl,
  });

  final String peerEmail;
  final String peerDisplayName;
  final String? peerPhotoUrl;
}
