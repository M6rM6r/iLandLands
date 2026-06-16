enum MessageRole { user, assistant }

class ChatMessage {
  const ChatMessage({required this.text, required this.role});

  final String text;
  final MessageRole role;
}
