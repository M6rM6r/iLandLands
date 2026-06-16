import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:injectable/injectable.dart';
import 'package:gulflands/features/ai_assistant/models/chat_message.dart';

/// Abstract base class for AI Assistant events.
abstract class AIAssistantEvent {}

/// Event to send a message to the AI Assistant.
class SendMessage extends AIAssistantEvent {
  final String text;
  SendMessage(this.text);
}

/// State for the AI Assistant BLoC, holding chat messages and typing status.
class AIAssistantState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final String? error;

  AIAssistantState({
    this.messages = const <ChatMessage>[],
    this.isTyping = false,
    this.error,
  });

  AIAssistantState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    String? error,
  }) {
    return AIAssistantState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      error:
          error, // Note: This doesn't allow clearing the error easily, but works for this context
    );
  }
}

@injectable
class AIAssistantBloc extends Bloc<AIAssistantEvent, AIAssistantState> {
  final GenerativeModel _model;
  late final ChatSession _chat;

  AIAssistantBloc(this._model) : super(AIAssistantState()) {
    _chat = _model.startChat(
      history: <Content>[
        Content.text(
          "You are a Gulf Lands expert. Help users find land in KSA, UAE, Qatar, etc. Be professional and concise.",
        ),
      ],
    );

    on<SendMessage>((SendMessage event, Emitter<AIAssistantState> emit) async {
      final ChatMessage userMsg = ChatMessage(
        text: event.text,
        role: MessageRole.user,
      );
      emit(
        state.copyWith(
          messages: <ChatMessage>[...state.messages, userMsg],
          isTyping: true,
          error: null,
        ),
      );

      try {
        final GenerateContentResponse response = await _chat.sendMessage(
          Content.text(event.text),
        );
        final String botText =
            response.text ??
            "I couldn't understand that. Try asking about land in Riyadh.";

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
                text:
                    "Sorry, I'm having trouble connecting. Please check your internet.",
                role: MessageRole.assistant,
              ),
            ],
            isTyping: false,
            error: "Connection failed. Please try again.",
          ),
        );
      }
    });
  }
}
