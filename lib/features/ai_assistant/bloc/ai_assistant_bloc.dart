import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:gulflands/core/config/app_config.dart';
import 'package:gulflands/features/ai_assistant/models/chat_message.dart';

abstract class AIAssistantEvent {}

class SendMessage extends AIAssistantEvent {
  SendMessage(this.text);
  final String text;
}

class AIAssistantState {
  const AIAssistantState({
    this.messages = const <ChatMessage>[],
    this.isTyping = false,
    this.error,
  });

  final List<ChatMessage> messages;
  final bool isTyping;
  final String? error;

  AIAssistantState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    String? error,
  }) {
    return AIAssistantState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      error: error,
    );
  }
}

class AIAssistantBloc extends Bloc<AIAssistantEvent, AIAssistantState> {
  AIAssistantBloc({GenerativeModel? model})
    : _model = model ?? _buildModel(),
      super(const AIAssistantState()) {
    _chat = _model.startChat(
      history: <Content>[
        Content.text(
          'You are Gulf Lands expert AI. Advise on land investment in '
          'Saudi Arabia, UAE, Qatar, Kuwait, Bahrain, Oman. '
          'Be precise, data-driven, concise. Cite price ranges when relevant.',
        ),
      ],
    );

    on<SendMessage>(_onSendMessage);
  }

  late final GenerativeModel _model;
  late final ChatSession _chat;

  static GenerativeModel _buildModel() {
    final String key = AppConfig.geminiApiKey;
    if (key.isEmpty) {
      return GenerativeModel(model: 'gemini-1.5-flash', apiKey: 'placeholder');
    }
    return GenerativeModel(model: 'gemini-1.5-flash', apiKey: key);
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<AIAssistantState> emit,
  ) async {
    if (AppConfig.geminiApiKey.isEmpty) {
      emit(
        state.copyWith(
          messages: <ChatMessage>[
            ...state.messages,
            ChatMessage(text: event.text, role: MessageRole.user),
            const ChatMessage(
              text:
                  'AI assistant requires GEMINI_API_KEY. '
                  'Run: flutter run --dart-define=GEMINI_API_KEY=your_key',
              role: MessageRole.assistant,
            ),
          ],
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        messages: <ChatMessage>[
          ...state.messages,
          ChatMessage(text: event.text, role: MessageRole.user),
        ],
        isTyping: true,
        error: null,
      ),
    );

    try {
      final GenerateContentResponse response = await _chat.sendMessage(
        Content.text(event.text),
      );
      final String botText =
          response.text ?? 'No response generated. Rephrase your land query.';

      emit(
        state.copyWith(
          messages: <ChatMessage>[
            ...state.messages,
            ChatMessage(text: botText, role: MessageRole.assistant),
          ],
          isTyping: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          messages: <ChatMessage>[
            ...state.messages,
            const ChatMessage(
              text: 'Connection failed. Verify network and API key.',
              role: MessageRole.assistant,
            ),
          ],
          isTyping: false,
          error: e.toString(),
        ),
      );
    }
  }
}
