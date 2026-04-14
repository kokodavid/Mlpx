import 'dart:async';

import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import 'package:milpress/utils/app_colors.dart';

class QuickPickItem {
  final String label;
  final String imageUrl;
  final String audioUrl;
  final bool isCorrect;

  const QuickPickItem({
    required this.label,
    required this.imageUrl,
    required this.audioUrl,
    required this.isCorrect,
  });
}

enum _QuickPickCardState {
  idle,
  correct,
  wrong,
}

class QuickPickStep extends StatefulWidget {
  final String title;
  final String instruction;
  final int timerSeconds;
  final List<QuickPickItem> items;

  const QuickPickStep({
    super.key,
    required this.title,
    required this.instruction,
    required this.timerSeconds,
    required this.items,
  });

  static const List<QuickPickItem> sampleItems = [
    QuickPickItem(
      label: 'apple',
      imageUrl:
          'https://images.unsplash.com/photo-1567306226416-28f0efdc88ce?auto=format&fit=crop&w=600&q=80',
      audioUrl: '',
      isCorrect: true,
    ),
    QuickPickItem(
      label: 'cat',
      imageUrl:
          'https://images.unsplash.com/photo-1511044568932-338cba0ad803?auto=format&fit=crop&w=600&q=80',
      audioUrl: '',
      isCorrect: true,
    ),
    QuickPickItem(
      label: 'bus',
      imageUrl:
          'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=600&q=80',
      audioUrl: '',
      isCorrect: false,
    ),
    QuickPickItem(
      label: 'pen',
      imageUrl:
          'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?auto=format&fit=crop&w=600&q=80',
      audioUrl: '',
      isCorrect: false,
    ),
    QuickPickItem(
      label: 'mug',
      imageUrl:
          'https://images.unsplash.com/photo-1514228742587-6b1558fcca3d?auto=format&fit=crop&w=600&q=80',
      audioUrl: '',
      isCorrect: false,
    ),
    QuickPickItem(
      label: 'taxi',
      imageUrl:
          'https://images.unsplash.com/photo-1519501025264-65ba15a82390?auto=format&fit=crop&w=600&q=80',
      audioUrl: '',
      isCorrect: true,
    ),
    QuickPickItem(
      label: 'cash',
      imageUrl:
          'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?auto=format&fit=crop&w=600&q=80',
      audioUrl: '',
      isCorrect: true,
    ),
    QuickPickItem(
      label: 'spoon',
      imageUrl:
          'https://images.unsplash.com/photo-1514575110897-1253ff7b2ccb?auto=format&fit=crop&w=600&q=80',
      audioUrl: '',
      isCorrect: false,
    ),
    QuickPickItem(
      label: 'bed',
      imageUrl:
          'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=600&q=80',
      audioUrl: '',
      isCorrect: false,
    ),
    QuickPickItem(
      label: 'map',
      imageUrl:
          'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=600&q=80',
      audioUrl: '',
      isCorrect: true,
    ),
    QuickPickItem(
      label: 'comp',
      imageUrl:
          'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=600&q=80',
      audioUrl: '',
      isCorrect: false,
    ),
    QuickPickItem(
      label: 'bag',
      imageUrl:
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=600&q=80',
      audioUrl: '',
      isCorrect: true,
    ),
  ];

  @override
  State<QuickPickStep> createState() => _QuickPickStepState();
}

class _QuickPickStepState extends State<QuickPickStep> {
  Timer? _timer;
  late int _remainingSeconds;
  int _score = 0;
  final Map<int, _QuickPickCardState> _cardStates = <int, _QuickPickCardState>{};

  String get _title =>
      widget.title.isNotEmpty ? widget.title : 'Quick Pick: /a/ Words';

  String get _instruction => widget.instruction.isNotEmpty
      ? widget.instruction
      : 'Tap the word with /a/ sound. skip the others';

  int get _timerSeconds => widget.timerSeconds > 0 ? widget.timerSeconds : 60;

  List<QuickPickItem> get _items =>
      widget.items.isNotEmpty ? widget.items : QuickPickStep.sampleItems;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _timerSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  void _handleCardTap(int index) {
    if (_remainingSeconds <= 0 || _cardStates.containsKey(index)) {
      return;
    }

    final item = _items[index];
    setState(() {
      if (item.isCorrect) {
        _cardStates[index] = _QuickPickCardState.correct;
        _score += 1;
      } else {
        _cardStates[index] = _QuickPickCardState.wrong;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'Practice Game',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Play button
                      Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF6B35),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Title
                      Text(
                        _title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Instruction
                      Text(
                        _instruction,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Timer and Score pills
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoPill(
                              icon: Icons.access_time,
                              label: 'Time: ${_remainingSeconds}s',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoPill(
                              icon: null,
                              label: 'Score: $_score',
                              alignStart: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Grid of cards - exactly 12 cards
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 12, // Force exactly 12 cards
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemBuilder: (context, index) {
                          final item = _items[index % _items.length]; // Loop if less than 12
                          final state = _cardStates[index] ?? _QuickPickCardState.idle;
                          return _buildCard(
                            index: index,
                            item: item,
                            state: state,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPill({
    required IconData? icon,
    required String label,
    bool alignStart = true,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisAlignment:
            alignStart ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: Colors.black87,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required int index,
    required QuickPickItem item,
    required _QuickPickCardState state,
  }) {
    Color borderColor = const Color(0xFFE0E0E0);
    Color shadowColor = Colors.black.withOpacity(0.04);

    if (state == _QuickPickCardState.correct) {
      borderColor = const Color(0xFF4CAF50);
      shadowColor = const Color(0xFF4CAF50).withOpacity(0.2);
    } else if (state == _QuickPickCardState.wrong) {
      borderColor = const Color(0xFFF44336);
      shadowColor = const Color(0xFFF44336).withOpacity(0.2);
    }

    return GestureDetector(
      onTap: () => _handleCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF5F5F5),
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 28,
                          color: Color(0xFF999999),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Label
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            // Audio button - wrapped in Transform.scale to make it smaller
            Transform.scale(
              scale: 0.7, // Scale down to 70% of original size
              child: LessonAudioInlineButton(
                sourceId: 'quick-pick-${item.label}-$index',
                url: item.audioUrl,
                backgroundColor: const Color(0xFFF5F5F5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}