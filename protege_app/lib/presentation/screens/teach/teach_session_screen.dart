import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_typography.dart';

/// Teaching session screen - chat interface for Reverse Tutoring
class TeachSessionScreen extends ConsumerStatefulWidget {
  final String topic;
  
  const TeachSessionScreen({
    super.key,
    required this.topic,
  });

  @override
  ConsumerState<TeachSessionScreen> createState() => _TeachSessionScreenState();
}

class _TeachSessionScreenState extends ConsumerState<TeachSessionScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isAiTyping = false;
  int _currentAhaScore = 0;
  int _messageCount = 0;
  
  // Backend session tracking
  String? _backendSessionId;
  late final Dio _dio;
  
  // Selected persona
  String _selectedPersonaId = 'maya';
  
  final Map<String, _Persona> _personas = {
    'maya': _Persona(
      name: 'Curious Maya',
      age: 8,
      avatar: '👧',
      description: 'A curious child who asks "why?" a lot',
      color: const Color(0xFFFF6B6B),
    ),
    'jake': _Persona(
      name: 'Skeptical Jake',
      age: 16,
      avatar: '🧑',
      description: 'A teenager who challenges everything',
      color: const Color(0xFF4ECDC4),
    ),
    'sarah': _Persona(
      name: 'Confused Sarah',
      age: 35,
      avatar: '👩',
      description: 'An adult learner who needs patience',
      color: const Color(0xFF9B59B6),
    ),
    'alex': _Persona(
      name: 'Technical Alex',
      age: 28,
      avatar: '🧔',
      description: 'A peer who asks about edge cases',
      color: const Color(0xFF3498DB),
    ),
  };

  @override
  void initState() {
    super.initState();
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    // Show persona selection on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPersonaSelection();
    });
  }

  void _showPersonaSelection() {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.5,
        maxChildSize: 0.85,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 24),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Choose Your Student',
                style: AppTypography.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Each student has a different personality',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Persona cards
              ..._personas.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() => _selectedPersonaId = entry.key);
                      Navigator.pop(context);
                      _startSession();
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 72),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: entry.value.color.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: entry.value.color.withAlpha(77),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            entry.value.avatar,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.value.name}, ${entry.value.age}',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: entry.value.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  entry.value.description,
                                  style: AppTypography.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: entry.value.color,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  /// Start a teaching session via the backend API
  void _startSession() async {
    final persona = _personas[_selectedPersonaId]!;
    
    setState(() {
      _isAiTyping = true;
    });

    try {
      print('[TEACH] Starting session: topic=${widget.topic}, persona=$_selectedPersonaId');
      
      final response = await _dio.post(
        '/api/v1/teaching-simple/start',
        data: {
          'topic': widget.topic,
          'persona_id': _selectedPersonaId,
        },
      );

      final data = response.data as Map<String, dynamic>;
      _backendSessionId = data['session_id'] as String?;
      final greeting = data['greeting'] as String? ?? _getDefaultGreeting(persona);
      
      print('[TEACH] Session started: $_backendSessionId');
      print('[TEACH] Greeting: ${greeting.substring(0, greeting.length.clamp(0, 80))}...');
      
      if (mounted) {
        setState(() {
          _isAiTyping = false;
          _messages.add(_ChatMessage(
            isUser: false,
            text: greeting,
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      print('[TEACH] API error during start: $e');
      // Fallback to default greeting
      if (mounted) {
        setState(() {
          _isAiTyping = false;
          _messages.add(_ChatMessage(
            isUser: false,
            text: _getDefaultGreeting(persona),
            timestamp: DateTime.now(),
          ));
        });
      }
    }
  }

  /// Get a default greeting when API is unavailable
  String _getDefaultGreeting(_Persona persona) {
    switch (_selectedPersonaId) {
      case 'maya':
        return "Hi! I'm ${persona.name}! 👋 I heard you know about ${widget.topic}. That sounds really cool! Can you tell me what it is? I love learning new things! 🌟";
      case 'jake':
        return "Hey. So you think you can explain ${widget.topic}? Alright, let's see what you got. Start from the beginning... 🤔";
      case 'sarah':
        return "Hello! I'm trying to learn ${widget.topic} for my new career. I hope you can help me understand it. I'm a bit nervous about learning new technical things... 😅";
      case 'alex':
        return "Hey, I've heard about ${widget.topic} but I want to understand it at a deeper level. Can you explain it comprehensively? I might have some follow-up questions about edge cases. 💡";
      default:
        return "Hi! Can you teach me about ${widget.topic}?";
    }
  }

  /// Send a message to the AI persona via backend API
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isAiTyping) return;
    
    setState(() {
      _messages.add(_ChatMessage(
        isUser: true,
        text: text,
        timestamp: DateTime.now(),
      ));
      _isAiTyping = true;
      _messageCount++;
    });
    
    _messageController.clear();
    _scrollToBottom();
    
    // Call backend API for AI response
    if (_backendSessionId != null) {
      try {
        print('[TEACH] Sending message to session $_backendSessionId');
        
        final response = await _dio.post(
          '/api/v1/teaching-simple/respond',
          data: {
            'session_id': _backendSessionId!,
            'user_message': text,
          },
        );

        final data = response.data as Map<String, dynamic>;
        final aiResponse = data['response'] as String? ?? _getContextualFallback(text);
        final ahaScore = (data['aha_score'] as num?)?.toInt() ?? _currentAhaScore;
        
        print('[TEACH] AI response received. Aha! score: $ahaScore');
        
        if (mounted) {
          setState(() {
            _isAiTyping = false;
            _currentAhaScore = ahaScore;
            
            _messages.add(_ChatMessage(
              isUser: false,
              text: aiResponse,
              timestamp: DateTime.now(),
            ));
          });
        }
      } catch (e) {
        print('[TEACH] API error during respond: $e');
        // Fallback to contextual response
        if (mounted) {
          setState(() {
            _isAiTyping = false;
            // Heuristic score increase as fallback
            final scoreIncrease = 5 + (text.length > 100 ? 10 : 5) + (text.length > 200 ? 5 : 0);
            _currentAhaScore = (_currentAhaScore + scoreIncrease).clamp(0, 100);
            
            _messages.add(_ChatMessage(
              isUser: false,
              text: _getContextualFallback(text),
              timestamp: DateTime.now(),
            ));
          });
        }
      }
    } else {
      // No backend session - use offline fallback
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        setState(() {
          _isAiTyping = false;
          final scoreIncrease = 5 + (text.length > 100 ? 10 : 5) + (text.length > 200 ? 5 : 0);
          _currentAhaScore = (_currentAhaScore + scoreIncrease).clamp(0, 100);
          
          _messages.add(_ChatMessage(
            isUser: false,
            text: _getContextualFallback(text),
            timestamp: DateTime.now(),
          ));
        });
      }
    }
    
    _scrollToBottom();
  }

  /// Generate a contextual fallback based on the user's message content
  String _getContextualFallback(String userMessage) {
    // Extract meaningful keywords from the user's message
    final words = userMessage.split(' ');
    final keyWords = words.where((w) => 
      w.length > 4 && 
      !{'about', 'which', 'their', 'there', 'these', 'those', 'would',
       'could', 'should', 'because', 'really', 'actually', 'basically'}.contains(w.toLowerCase())
    ).toList();
    
    final keyword = keyWords.isNotEmpty ? keyWords.first : widget.topic;
    
    switch (_selectedPersonaId) {
      case 'maya':
        final responses = [
          "Ooh cool! But what does '$keyword' actually mean? Can you explain it simpler? 🤔",
          "Wow! So when you say '$keyword', is that like something I can see? Give me an example! ✨",
          "Wait, I'm a bit confused about the '$keyword' part. Can you explain it like I'm really little? 😅",
          "That's interesting! But WHY does '$keyword' work that way? 🌟",
        ];
        return responses[_messageCount % responses.length];
      case 'jake':
        final responses = [
          "Hmm okay, but you mentioned '$keyword' - how does that actually work in practice?",
          "I get the idea, but what happens if '$keyword' doesn't work as expected? Any edge cases?",
          "That's one way to look at it. But is '$keyword' always the best approach? Why?",
          "Fine, but can you prove that? What evidence is there that '$keyword' is correct?",
        ];
        return responses[_messageCount % responses.length];
      case 'sarah':
        final responses = [
          "I think I'm starting to understand '$keyword', but could you walk me through a real example? 😊",
          "So when you mention '$keyword', how would I actually use that at work?",
          "That helps! But I'm still a bit fuzzy on '$keyword'. What's the most common mistake people make?",
          "Thank you! Could you explain '$keyword' one more time with a different analogy? 🙏",
        ];
        return responses[_messageCount % responses.length];
      case 'alex':
        final responses = [
          "Good point about '$keyword'. What about edge cases though?",
          "That's the standard approach for '$keyword'. Any alternatives or optimizations?",
          "Interesting take on '$keyword'. How does this scale in production?",
          "Makes sense. What are common anti-patterns related to '$keyword'?",
        ];
        return responses[_messageCount % responses.length];
      default:
        return "That's interesting! Can you tell me more about '$keyword'?";
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final persona = _personas[_selectedPersonaId]!;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(context),
        ),
        title: Row(
          children: [
            Text(
              persona.avatar,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    persona.name,
                    style: AppTypography.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.topic,
                    style: AppTypography.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Live Aha! Score
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getScoreColor(_currentAhaScore).withAlpha(26),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  color: _getScoreColor(_currentAhaScore),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_currentAhaScore',
                  style: AppTypography.labelMedium.copyWith(
                    color: _getScoreColor(_currentAhaScore),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isAiTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isAiTyping) {
                  return _TypingIndicator(persona: persona);
                }
                return _MessageBubble(
                  message: _messages[index],
                  persona: persona,
                );
              },
            ),
          ),
          
          // Input area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Explain the concept...',
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(77),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.textTertiary;
  }

  /// End session dialog — calls backend for final evaluation
  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End Session?'),
        content: Text(
          'Your current Aha! score is $_currentAhaScore. Are you sure you want to end this teaching session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Continue Teaching'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              // Call backend to end session and get evaluation
              if (_backendSessionId != null) {
                try {
                  final response = await _dio.post(
                    '/api/v1/teaching-simple/end',
                    data: {'session_id': _backendSessionId!},
                  );
                  
                  final data = response.data as Map<String, dynamic>;
                  final evaluation = data['evaluation'] as Map<String, dynamic>?;
                  
                  if (mounted && evaluation != null) {
                    _showFinalEvaluation(evaluation);
                    return;
                  }
                } catch (e) {
                  print('[TEACH] Error ending session: $e');
                }
              }
              
              // If no evaluation available, just pop
              if (mounted) context.pop();
            },
            child: Text(
              'End Session',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  /// Show final evaluation results from the AI
  void _showFinalEvaluation(Map<String, dynamic> evaluation) {
    final overallScore = (evaluation['overall_score'] as num?)?.toInt() ?? _currentAhaScore;
    final clarityScore = (evaluation['clarity_score'] as num?)?.toInt() ?? 0;
    final accuracyScore = (evaluation['accuracy_score'] as num?)?.toInt() ?? 0;
    final depthScore = (evaluation['depth_score'] as num?)?.toInt() ?? 0;
    final strengths = (evaluation['strengths'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final improvements = (evaluation['improvements'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final summary = evaluation['summary'] as String? ?? 'Session completed.';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: _getScoreColor(overallScore), size: 28),
            const SizedBox(width: 8),
            Text('Session Complete!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall score
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _getScoreColor(overallScore).withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$overallScore',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: _getScoreColor(overallScore),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Summary
              Text(summary, style: AppTypography.bodyMedium),
              const SizedBox(height: 16),
              
              // Score breakdown
              _ScoreBar(label: 'Clarity', score: clarityScore),
              const SizedBox(height: 8),
              _ScoreBar(label: 'Accuracy', score: accuracyScore),
              const SizedBox(height: 8),
              _ScoreBar(label: 'Depth', score: depthScore),
              
              // Strengths
              if (strengths.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('💪 Strengths:', style: AppTypography.titleSmall),
                const SizedBox(height: 4),
                ...strengths.map((s) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Text('• $s', style: AppTypography.bodySmall),
                )),
              ],
              
              // Areas to improve
              if (improvements.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('📈 Areas to Improve:', style: AppTypography.titleSmall),
                const SizedBox(height: 4),
                ...improvements.map((i) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Text('• $i', style: AppTypography.bodySmall),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _dio.close();
    super.dispose();
  }
}

class _Persona {
  final String name;
  final int age;
  final String avatar;
  final String description;
  final Color color;

  const _Persona({
    required this.name,
    required this.age,
    required this.avatar,
    required this.description,
    required this.color,
  });
}

class _ChatMessage {
  final bool isUser;
  final String text;
  final DateTime timestamp;

  const _ChatMessage({
    required this.isUser,
    required this.text,
    required this.timestamp,
  });
}

/// Score bar widget for final evaluation display
class _ScoreBar extends StatelessWidget {
  final String label;
  final int score;

  const _ScoreBar({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: AppTypography.bodySmall),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                score >= 80 ? AppColors.success :
                score >= 50 ? AppColors.warning :
                AppColors.error,
              ),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$score', style: AppTypography.labelSmall),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final _Persona persona;

  const _MessageBubble({
    required this.message,
    required this.persona,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: persona.color.withAlpha(26),
              child: Text(persona.avatar, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? AppColors.primary 
                    : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: AppTypography.bodyMedium.copyWith(
                  color: message.isUser 
                      ? AppColors.textOnPrimary 
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final _Persona persona;

  const _TypingIndicator({required this.persona});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: persona.color.withAlpha(26),
          child: Text(persona.avatar, style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _Dot(delay: 0),
              SizedBox(width: 4),
              _Dot(delay: 150),
              SizedBox(width: 4),
              _Dot(delay: 300),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;

  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.textTertiary.withAlpha((128 + (_animation.value * 127)).toInt()),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
