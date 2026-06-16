import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gulflands/features/ai_assistant/bloc/ai_assistant_bloc.dart';
import 'package:gulflands/features/ai_assistant/models/chat_message.dart';

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gulf Lands AI Assistant')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: BlocConsumer<AIAssistantBloc, AIAssistantState>(
              listener: (BuildContext context, AIAssistantState state) {
                if (state.error != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.error!)));
                }
                // Scroll to bottom when a new message arrives or bot starts typing
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );
              },
              builder: (BuildContext context, AIAssistantState state) {
                if (state.messages.isEmpty) {
                  return Center(
                    child: Text(
                      'How can I help you find your dream land today?',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }
                return Scrollbar(
                  controller: _scrollController,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
                    itemCount: state.messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ChatMessage msg = state.messages[index];
                      final bool isUser = msg.role == MessageRole.user;
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.blue[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          constraints: BoxConstraints(maxWidth: 0.7.sw),
                          child: Text(msg.text),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          if (context.watch<AIAssistantBloc>().state.isTyping)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: const LinearProgressIndicator(minHeight: 2), // Added const
            ),
          _buildInput(context),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ask about lands, prices, or locations...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue), // Added const
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                context.read<AIAssistantBloc>().add(
                  SendMessage(_controller.text),
                );
                _controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
