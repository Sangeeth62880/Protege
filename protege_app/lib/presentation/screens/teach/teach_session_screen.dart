import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/theme/app_typography.dart';
import 'dart:convert';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

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
  int _accuracyConfidence = 100;
  int _messageCount = 0;
  
  // Backend session tracking
  String? _backendSessionId;
  late final Dio _dio;
  
  // Selected persona
  String _selectedPersonaId = 'maya';
  
  // Audio state
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlayingAudio = false;
  bool _isTranscribing = false;
  
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
      useRootNavigator: true,
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
      
      final speaker = _getSpeakerForPersona(_selectedPersonaId);
      await _playAiVoice(greeting, speaker);
      
      if (mounted) {
        setState(() {
          _isAiTyping = false;
          _messages.add(_ChatMessage(
            isUser: false,
            text: greeting,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('[TEACH] API error during start: $e');
      // Fallback to default greeting
      final fallbackGreeting = _getDefaultGreeting(persona);
      final speaker = _getSpeakerForPersona(_selectedPersonaId);
      await _playAiVoice(fallbackGreeting, speaker);
      
      if (mounted) {
        setState(() {
          _isAiTyping = false;
          _messages.add(_ChatMessage(
            isUser: false,
            text: fallbackGreeting,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
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

  /// Maps persona IDs to specific Sarvam TTS bulbul:v3 voices
  String _getSpeakerForPersona(String personaId) {
    switch (personaId) {
      case 'maya': return 'priya';   // Female child-like
      case 'jake': return 'aditya';  // Male teen
      case 'sarah': return 'shreya'; // Female adult
      case 'alex': return 'shubh';   // Male adult
      default: return 'aditya';
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
        final accuracyConf = (data['accuracy_confidence'] as num?)?.toInt() ?? _accuracyConfidence;
        final sessionAutoComplete = data['session_auto_complete'] as bool? ?? false;
        final misconceptionDetected = data['misconception_detected'] as String?;
        final misconceptionCanonical = data['misconception_canonical'] as String?;
        
        print('[TEACH] AI response received. Aha! score: $ahaScore, AccConf: $accuracyConf');
        
        final speaker = _getSpeakerForPersona(_selectedPersonaId);
        await _playAiVoice(aiResponse, speaker);
        
        if (mounted) {
          setState(() {
            _isAiTyping = false;
            _currentAhaScore = ahaScore;
            _accuracyConfidence = accuracyConf;
            
            _messages.add(_ChatMessage(
              isUser: false,
              text: aiResponse,
              timestamp: DateTime.now(),
              misconceptionDetected: misconceptionDetected,
              misconceptionCanonical: misconceptionCanonical,
            ));
          });
          
          if (misconceptionDetected != null && misconceptionCanonical != null) {
            _showMisconceptionBottomSheet(misconceptionDetected, misconceptionCanonical);
          }
          
          if (sessionAutoComplete) {
            // Give the user a moment to read the final message before wrapping up
            Future.delayed(const Duration(seconds: 4), () {
              if (mounted) _endSessionAndRoute();
            });
          }
        }
      } catch (e) {
        print('[TEACH] API error during respond: $e');
        // Fallback to contextual response
        final fallbackText = _getContextualFallback(text);
        final speaker = _getSpeakerForPersona(_selectedPersonaId);
        await _playAiVoice(fallbackText, speaker);
        
        if (mounted) {
          setState(() {
            _isAiTyping = false;
            // Heuristic score increase as fallback
            final scoreIncrease = 5 + (text.length > 100 ? 10 : 5) + (text.length > 200 ? 5 : 0);
            _currentAhaScore = (_currentAhaScore + scoreIncrease).clamp(0, 100);
            
            _messages.add(_ChatMessage(
              isUser: false,
              text: fallbackText,
              timestamp: DateTime.now(),
            ));
          });
        }
      }
    } else {
      // No backend session - use offline fallback
      final fallbackText = _getContextualFallback(text);
      final speaker = _getSpeakerForPersona(_selectedPersonaId);
      
      await Future.delayed(const Duration(milliseconds: 1200));
      await _playAiVoice(fallbackText, speaker);
      
      if (mounted) {
        setState(() {
          _isAiTyping = false;
          final scoreIncrease = 5 + (text.length > 100 ? 10 : 5) + (text.length > 200 ? 5 : 0);
          _currentAhaScore = (_currentAhaScore + scoreIncrease).clamp(0, 100);
          
          _messages.add(_ChatMessage(
            isUser: false,
            text: fallbackText,
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

  void _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        if (Theme.of(context).platform == TargetPlatform.android || Theme.of(context).platform == TargetPlatform.iOS) {
          final dir = await getTemporaryDirectory();
          final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(
            const RecordConfig(),
            path: path,
          );
        } else {
          // Fallback for Web/Desktop where getTemporaryDirectory might fail
          await _audioRecorder.start(const RecordConfig(), path: '');
        }
        setState(() => _isRecording = true);
      }
    } catch (e) {
      print('[TEACH AUDIO] Error starting record: $e');
    }
  }

  void _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        _transcribeAudio(path);
      }
    } catch (e) {
      print('[TEACH AUDIO] Error stopping record: $e');
    }
  }

  void _transcribeAudio(String path) async {
    setState(() => _isTranscribing = true);
    try {
      MultipartFile fileToUpload;
      if (Theme.of(context).platform == TargetPlatform.android || Theme.of(context).platform == TargetPlatform.iOS) {
        fileToUpload = await MultipartFile.fromFile(path);
      } else {
        // Web flow: fetch the blob and extract bytes
        final response = await http.get(Uri.parse(path));
        fileToUpload = MultipartFile.fromBytes(
          response.bodyBytes,
          filename: 'audio_web_record.webm',
        );
      }
      
      final formData = FormData.fromMap({
        'file': fileToUpload,
      });
      
      final response = await _dio.post(
        '/api/v1/audio/transcribe',
        data: formData,
      );
      final text = response.data['text'] as String?;
      
      setState(() => _isTranscribing = false);
      if (text != null && text.isNotEmpty) {
        _messageController.text = text;
        _sendMessage(); // Automatically send
      }
    } catch (e) {
      print('[TEACH AUDIO] Transcription error: $e');
      setState(() => _isTranscribing = false);
    }
  }

  Future<void> _playAiVoice(String text, String speaker) async {
    if (_isPlayingAudio) {
      await _audioPlayer.stop();
    }
    
    try {
      final response = await _dio.post(
        '/api/v1/audio/tts',
        data: {'text': text, 'language_code': 'en-IN', 'speaker': speaker},
      );
      
      final base64Audio = response.data['audio_base64'] as String?;
      if (base64Audio != null && base64Audio.isNotEmpty) {
        final bytes = base64Decode(base64Audio);
        setState(() => _isPlayingAudio = true);
        
        await _audioPlayer.play(BytesSource(bytes));
        
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() => _isPlayingAudio = false);
          }
        });
      }
    } catch (e) {
      print('[TEACH AUDIO] TTS error: $e');
      setState(() => _isPlayingAudio = false);
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
          // Wrap Up button
          IconButton(
            icon: const Icon(Icons.outlined_flag_rounded, color: AppColors.textSecondary),
            tooltip: 'Wrap Up Now',
            onPressed: () => _showExitDialog(context),
          ),
          // Accuracy Confidence Indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getAccuracyColor(_accuracyConfidence).withAlpha(26),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  color: _getAccuracyColor(_accuracyConfidence),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_accuracyConfidence%',
                  style: AppTypography.labelMedium.copyWith(
                    color: _getAccuracyColor(_accuracyConfidence),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Live Aha! Score
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getScoreColor(_currentAhaScore).withAlpha(26),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  color: _getScoreColor(_currentAhaScore),
                  size: 16,
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
            padding: EdgeInsets.fromLTRB(
              16, 
              12, 
              16, 
              MediaQuery.of(context).viewInsets.bottom > 0 ? 24.0 : 24.0 + AppSpacing.navbarClearance,
            ),
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
                    onLongPressStart: _isTranscribing ? null : (_) => _startRecording(),
                    onLongPressEnd: _isTranscribing ? null : (_) => _stopRecording(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isRecording ? 54 : 48,
                      height: _isRecording ? 54 : 48,
                      decoration: BoxDecoration(
                        color: _isRecording ? Colors.red.withAlpha(26) : Colors.transparent,
                        border: Border.all(
                          color: _isRecording ? Colors.red : AppColors.divider,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: _isTranscribing
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.textSecondary),
                              ),
                            )
                          : Icon(
                              _isRecording ? Icons.mic : Icons.mic_none_rounded,
                              color: _isRecording ? Colors.red : AppColors.textSecondary,
                              size: _isRecording ? 28 : 24,
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
  
  Color _getAccuracyColor(int conf) {
    if (conf >= 90) return AppColors.success;
    if (conf >= 70) return AppColors.warning;
    return AppColors.error;
  }

  void _showMisconceptionBottomSheet(String detected, String canonical) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.error),
                const SizedBox(width: 8),
                Text('Misconception Detected', style: AppTypography.titleMedium.copyWith(color: AppColors.error)),
              ],
            ),
            const SizedBox(height: 16),
            Text('You said:', style: AppTypography.labelSmall),
            const SizedBox(height: 4),
            Text(detected, style: AppTypography.bodyMedium),
            const SizedBox(height: 16),
            Text('Actually:', style: AppTypography.labelSmall.copyWith(color: AppColors.success)),
            const SizedBox(height: 4),
            Text(canonical, style: AppTypography.bodyMedium),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Got it', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _endSessionAndRoute() async {
    if (_backendSessionId == null) {
      if (mounted) context.pop();
      return;
    }
    
    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final response = await _dio.post(
        '/api/v1/teaching-simple/end',
        data: {'session_id': _backendSessionId!},
      );
      
      if (mounted) {
        Navigator.pop(context); // Close loading overlay
        final data = response.data as Map<String, dynamic>? ?? <String, dynamic>{};
        
        // Pass local state
        data['accuracy_confidence'] = _accuracyConfidence;
        
        // Extract all misconceptions caught during this session
        final misconceptions = _messages
          .where((m) => m.misconceptionDetected != null && m.misconceptionCanonical != null)
          .map((m) => {
            'detected': m.misconceptionDetected,
            'canonical': m.misconceptionCanonical,
          })
          .toList();
          
        data['misconceptions'] = misconceptions;
        
        context.pushReplacement('/teach/session/complete', extra: data);
      }
    } catch (e) {
      print('[TEACH] Error ending session: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading overlay
        context.pop(); // Revert back
      }
    }
  }

  /// End session dialog — calls backend for final evaluation
  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Wrap Up Session?'),
        content: Text(
          'Your current Aha! score is $_currentAhaScore. Are you sure you want to end this teaching session early?',
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
              if (mounted) {
                _endSessionAndRoute();
              }
              
              // If no evaluation available, just pop
              if (mounted) context.pop();
            },
            child: Text(
              'Wrap Up Now',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
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
  final String? misconceptionDetected;
  final String? misconceptionCanonical;

  const _ChatMessage({
    required this.isUser,
    required this.text,
    required this.timestamp,
    this.misconceptionDetected,
    this.misconceptionCanonical,
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
