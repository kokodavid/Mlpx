import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/models/lesson_models.dart';
import 'package:milpress/features/lessons_v2/screens/lesson_attempt_screen.dart';
import 'package:milpress/utils/app_colors.dart';

class Course2Lesson2PreviewScreen extends StatefulWidget {
  final int initialStepIndex;

  const Course2Lesson2PreviewScreen({
    super.key,
    this.initialStepIndex = 0,
  });

  @override
  State<Course2Lesson2PreviewScreen> createState() =>
      _Course2Lesson2PreviewScreenState();
}

class _Course2Lesson2PreviewScreenState
    extends State<Course2Lesson2PreviewScreen> {
  int _selectedStepIndex = 0;

  @override
  void initState() {
    super.initState();
    final steps = course2Lesson2PreviewLesson.steps;
    _selectedStepIndex = widget.initialStepIndex.clamp(0, steps.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final steps = course2Lesson2PreviewLesson.steps;
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Course 2 Lesson 2 Preview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LessonAttemptScreen(
              lessonDefinition: course2Lesson2PreviewLesson,
              initialStepIndex: _selectedStepIndex,
              onFinish: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Preview complete. Use hot restart if you want to replay from step 1.',
                    ),
                  ),
                );
              },
              embedInParent: true,
            ),
          ),
        ],
      ),
    );
  }
}

const LessonDefinition course2Lesson2PreviewLesson = LessonDefinition(
  lessonType: LessonType.word,
  title: 'Course 2 Lesson 2 Preview',
  progressLabel: 'Lesson Progress',
  steps: [
    LessonStepDefinition(
      key: 'c2l2-intro',
      type: LessonStepType.introduction,
      config: {
        'title': 'Welcome to Blending',
        'display_text': 'A a',
        'audio': {
          'base_url': '',
          'speed_variants': {
            'slow': '',
            'normal': '',
          },
        },
        'practice_tip': {
          'text': 'Practice: Say the sound slowly and listen for the vowel in the middle.',
          'audio_url': '',
        },
        'how_to_svg_url': '',
      },
    ),
    LessonStepDefinition(
      key: 'c2l2-demonstration',
      type: LessonStepType.demonstration,
      config: {
        'title': 'Letter Formation',
        'feedbackTitle': 'Great tracing!',
        'feedbackBody': 'Trace each letter slowly and follow the arrows.',
        'image_urls': [
          'https://picsum.photos/seed/letter1/300/200',
          'https://picsum.photos/seed/letter2/300/200',
        ],
      },
    ),
    LessonStepDefinition(
      key: 'c2l2-practice',
      type: LessonStepType.practice,
      config: {
        'title': 'Practice Words',
        'tip': {
          'text': 'Tap each word to hear it and say it aloud.',
          'sound_url': '',
        },
        'items': [
          {
            'label': 'cat',
            'image_url': 'https://picsum.photos/seed/cat/120/120',
            'sound_url': '',
          },
          {
            'label': 'dog',
            'image_url': 'https://picsum.photos/seed/dog/120/120',
            'sound_url': '',
          },
          {
            'label': 'sun',
            'image_url': 'https://picsum.photos/seed/sun/120/120',
            'sound_url': '',
          },
          {
            'label': 'map',
            'image_url': 'https://picsum.photos/seed/map/120/120',
            'sound_url': '',
          },
        ],
      },
    ),
    LessonStepDefinition(
      key: 'c2l2-blending',
      type: LessonStepType.blending,
      config: {
        'title': 'Blending',
        'instruction': 'Tap each letter to hear its sound, then tap "Blend" to form the word.',
        'instruction_audio_url': '',
        'examples': [
          {
            'word': 'map',
            'word_audio_url': '',
            'phonemes': [
              {'label': 'm', 'audio_url': '', 'highlighted': false},
              {'label': 'a', 'audio_url': '', 'highlighted': true},
              {'label': 'p', 'audio_url': '', 'highlighted': false},
            ],
          },
          {
            'word': 'sun',
            'word_audio_url': '',
            'phonemes': [
              {'label': 's', 'audio_url': '', 'highlighted': false},
              {'label': 'u', 'audio_url': '', 'highlighted': true},
              {'label': 'n', 'audio_url': '', 'highlighted': false},
            ],
          },
          {
            'word': 'ship',
            'word_audio_url': '',
            'phonemes': [
              {'label': 'sh', 'audio_url': '', 'highlighted': false},
              {'label': 'i', 'audio_url': '', 'highlighted': true},
              {'label': 'p', 'audio_url': '', 'highlighted': false},
            ],
          },
        ],
      },
    ),
    LessonStepDefinition(
      key: 'c2l2-sound-discrimination',
      type: LessonStepType.soundDiscrimination,
      config: {
        'title': 'Sound Discrimination',
        'title_audio_url': '',
        'target_sound': 'a',
        'reference_word': 'apple',
        'tip_text': 'Listen carefully and choose the word with the same sound.',
        'items': [
          {
            'title': 'cat',
            'title_audio_url': '',
            'image_url': 'https://picsum.photos/seed/cat/120/120',
            'contains_target_sound': true,
            'highlighted_text': 'a',
          },
          {
            'title': 'dog',
            'title_audio_url': '',
            'image_url': 'https://picsum.photos/seed/dog/120/120',
            'contains_target_sound': false,
            'highlighted_text': 'o',
          },
          {
            'title': 'map',
            'title_audio_url': '',
            'image_url': 'https://picsum.photos/seed/map/120/120',
            'contains_target_sound': true,
            'highlighted_text': 'a',
          },
        ],
      },
    ),
    LessonStepDefinition(
      key: 'c2l2-sound-presence',
      type: LessonStepType.soundPresenceCheck,
      config: {
        'title': 'Sound Presence',
        'questions': [
          {
            'prompt': 'Does this word have the /a/ sound?',
            'prompt_audio_url': '',
            'word_text': 'cat',
            'word_audio_url': '',
            'target_sound': 'a',
            'correct_answer': true,
            'yes_label': 'Yes',
            'no_label': 'No',
          },
          {
            'prompt': 'Does this word have the /a/ sound?',
            'prompt_audio_url': '',
            'word_text': 'dog',
            'word_audio_url': '',
            'target_sound': 'a',
            'correct_answer': false,
            'yes_label': 'Yes',
            'no_label': 'No',
          },
        ],
      },
    ),
    LessonStepDefinition(
      key: 'c2l2-sound-item-matching',
      type: LessonStepType.soundItemMatching,
      config: {
        'title': 'Sound Matching',
        'activities': [
          {
            'prompt': 'Tap the word that has the /a/ sound.',
            'prompt_audio_url': '',
            'content_audio_url': '',
            'target_sound': 's',
            'tip_text': 'tip: Find the /a/ Sound',
            'options': [
              {'label': 'rat', 'is_correct': true},
              {'label': 'dog', 'is_correct': false},
              {'label': 'hat', 'is_correct': true},
            ],
          },
          {
            'prompt': 'Tap the word that has the /a/ sound.',
            'prompt_audio_url': '',
            'content_audio_url': '',
            'target_sound': 's',
            'tip_text': 'tip: Find the /a/ Sound.',
            'options': [
              {'label': 'tap', 'is_correct': true},
              {'label': 'dog', 'is_correct': false},
              {'label': 'ship', 'is_correct': true},
            ],
          },
          {
            'prompt': 'Tap the word that has the /a/ sound.',
            'prompt_audio_url': '',
            'content_audio_url': '',
            'target_sound': 's',
            'tip_text': 'tip: Find the /a/ Sound.',
            'options': [
              {'label': 'cat', 'is_correct': true},
              {'label': 'dog', 'is_correct': false},
              {'label': 'ship', 'is_correct': true},
            ],
          },
        ],
      },
    ),
    LessonStepDefinition(
      key: 'c2l2-matching-words-2',
      type: LessonStepType.matchingWords,
      config: {
        'title': 'Matching Words Review',
        'instruction_audio_url': '',
        'activities': [
          {
            'mode': 'sound_to_word',
            'prompt_text': 'Which word says "dog"?',
            'prompt_audio_url': '',
            'correct_option_id': 'dog',
            'options': [
              {
                'id': 'dog',
                'label': 'dog',
                'image_url': 'https://picsum.photos/seed/dog/120/120',
              },
              {
                'id': 'dig',
                'label': 'dig',
                'image_url': 'https://picsum.photos/seed/dig/120/120',
              },
              {
                'id': 'dot',
                'label': 'dot',
                'image_url': 'https://picsum.photos/seed/dot/120/120',
              },
            ],
          },
          {
            'mode': 'image_to_word',
            'prompt_text': 'Which word matches the picture?',
            'prompt_audio_url': '',
            'prompt_image_url': 'https://picsum.photos/seed/ball/240/180',
            'correct_option_id': 'ball',
            'options': [
              {
                'id': 'ball',
                'label': 'ball',
                'image_url': 'https://picsum.photos/seed/ball-option/120/120',
              },
              {
                'id': 'bat',
                'label': 'bat',
                'image_url': 'https://picsum.photos/seed/bat-option/120/120',
              },
              {
                'id': 'bag',
                'label': 'bag',
                'image_url': 'https://picsum.photos/seed/bag-option/120/120',
              },
            ],
          },
          {
            'mode': 'sound_to_image',
            'prompt_text': 'Tap the picture that says "cat".',
            'prompt_audio_url': '',
            'correct_option_id': 'cat',
            'options': [
              {
                'id': 'cat',
                'label': 'cat',
                'image_url': 'https://picsum.photos/seed/cat-option/120/120',
              },
              {
                'id': 'car',
                'label': 'car',
                'image_url': 'https://picsum.photos/seed/car-option/120/120',
              },
              {
                'id': 'cap',
                'label': 'cap',
                'image_url': 'https://picsum.photos/seed/cap-option/120/120',
              },
            ],
          },
        ],
      },
    ),
    LessonStepDefinition(
      key: 'c2l2-word-reading',
      type: LessonStepType.wordReading,
      config: {
        'title': 'Read the Words',
        'instruction_audio_url': '',
        'items': [
          {
            'word': 'cat',
            'image_url': 'https://picsum.photos/seed/cat/120/120',
            'word_audio_url': '',
            'model_reading_label': 'Listen and read',
            'segments': [
              {'label': 'c', 'audio_url': '', 'highlighted': false},
              {'label': 'a', 'audio_url': '', 'highlighted': true},
              {'label': 't', 'audio_url': '', 'highlighted': false},
            ],
          },
          {
            'word': 'mat',
            'image_url': 'https://picsum.photos/seed/mat/120/120',
            'word_audio_url': '',
            'model_reading_label': 'Listen and read',
            'segments': [
              {'label': 'm', 'audio_url': '', 'highlighted': false},
              {'label': 'a', 'audio_url': '', 'highlighted': true},
              {'label': 't', 'audio_url': '', 'highlighted': false},
            ],
          },
        ],
      },
    ),
    LessonStepDefinition(
      key: 'c2l2-sentence-reading',
      type: LessonStepType.sentenceReading,
      config: {
        'title': 'Sentence Reading',
        'instruction_audio_url': '',
        'items': [
          {
            'sentence_text': 'The cat is on the mat.',
            'display_tokens': ['The', 'cat', 'is', 'on', 'the', 'mat.'],
            'sentence_audio_url': '',
            'self_read_label': 'Read it yourself',
          },
          {
            'sentence_text': 'The sun is hot.',
            'display_tokens': ['The', 'sun', 'is', 'hot.'],
            'sentence_audio_url': '',
            'self_read_label': 'Read it yourself',
          },
        ],
      },
    ),
    LessonStepDefinition(
      key: 'c2l2-guided-reading',
      type: LessonStepType.guidedReading,
      config: {
        'title': 'Guided Reading',
        'activities': [
          {
            'instruction_text': 'Listen to the sounds. Then hear the whole word',
            'instruction_audio_url': '',
            'word_text': 'man',
            'word_audio_url': '',
            'segments': [
              {'phoneme_label': '/m/', 'grapheme': 'm', 'audio_url': '', 'is_focus': false},
              {'phoneme_label': '/a/', 'grapheme': 'a', 'audio_url': '', 'is_focus': true},
              {'phoneme_label': '/n/', 'grapheme': 'n', 'audio_url': '', 'is_focus': false},
            ],
          },
          {
            'instruction_text': 'Now read the next word with the focus sound.',
            'instruction_audio_url': '',
            'word_text': 'mat',
            'word_audio_url': '',
            'segments': [
              {'phoneme_label': 'm', 'grapheme': 'm', 'audio_url': '', 'is_focus': false},
              {'phoneme_label': 'a', 'grapheme': 'a', 'audio_url': '', 'is_focus': true},
              {'phoneme_label': 't', 'grapheme': 't', 'audio_url': '', 'is_focus': false},
            ],
          },
        ],
      },
    ),
    LessonStepDefinition(
      key: 'c2l2-missing-letters',
      type: LessonStepType.missingLetters,
      config: {
        'title': 'Fill in the Missing Letter',
        'instruction_audio_url': '',
        'activities': [
          {
            'prompt_text': 'Complete the word using the missing letter.',
            'target_word': 'cat',
            'answer_template': [
              {'value': 'c', 'is_given': true},
              {'value': '', 'is_missing': true},
              {'value': 't', 'is_given': true},
            ],
            'options': ['a', 'o', 'i'],
          },
          {
            'prompt_text': 'Complete the word using the missing letter.',
            'target_word': 'map',
            'answer_template': [
              {'value': 'm', 'is_given': true},
              {'value': '', 'is_missing': true},
              {'value': 'p', 'is_given': true},
            ],
            'options': ['a', 'e', 'u'],
          },
        ],
      },
    ),
    LessonStepDefinition(
      key: 'c2l2-practice-game',
      type: LessonStepType.practiceGame,
      config: {
        'title': 'Sound Game',
        'instruction_text': 'Tap the pictures that contain the /s/ sound.',
        'instruction_audio_url': '',
        'target_sound': 's',
        'duration_seconds': 25,
        'passing_score': 2,
        'options': [
          {
            'title': 'sun',
            'image_url': 'https://picsum.photos/seed/sun/120/120',
            'audio_url': '',
            'is_correct': true,
          },
          {
            'title': 'dog',
            'image_url': 'https://picsum.photos/seed/dog/120/120',
            'audio_url': '',
            'is_correct': false,
          },
          {
            'title': 'ship',
            'image_url': 'https://picsum.photos/seed/ship/120/120',
            'audio_url': '',
            'is_correct': true,
          },
          {
            'title': 'cat',
            'image_url': 'https://picsum.photos/seed/cat/120/120',
            'audio_url': '',
            'is_correct': false,
          },
          {
            'title': 'sock',
            'image_url': 'https://picsum.photos/seed/sock/120/120',
            'audio_url': '',
            'is_correct': true,
          },
          {
            'title': 'ball',
            'image_url': 'https://picsum.photos/seed/ball/120/120',
            'audio_url': '',
            'is_correct': false,
          },
          {
            'title': 'sun',
            'image_url': 'https://picsum.photos/seed/sun/120/120',
            'audio_url': '',
            'is_correct': true,
          },
          {
            'title': 'dog',
            'image_url': 'https://picsum.photos/seed/dog/120/120',
            'audio_url': '',
            'is_correct': false,
          },
          {
            'title': 'ship',
            'image_url': 'https://picsum.photos/seed/ship/120/120',
            'audio_url': '',
            'is_correct': true,
          },
          {
            'title': 'cat',
            'image_url': 'https://picsum.photos/seed/cat/120/120',
            'audio_url': '',
            'is_correct': false,
          },
          {
            'title': 'sock',
            'image_url': 'https://picsum.photos/seed/sock/120/120',
            'audio_url': '',
            'is_correct': true,
          },
          {
            'title': 'ball',
            'image_url': 'https://picsum.photos/seed/ball/120/120',
            'audio_url': '',
            'is_correct': false,
          },
        ],
      },
    ),
    LessonStepDefinition(
      key: 'c2l2-mini-story',
      type: LessonStepType.miniStoryCard,
      config: {
        'title': 'Mini Story',
        'instruction_audio_url': '',
        'items': [
          {
            'heading': 'A Sunny Day',
            'heading_audio_url': '',
            'body_lines': [
              'Sam and Sun went to the park.',
              'They saw a cat on a mat.',
            ],
            'story_audio_url': '',
            'cta_label': 'Listen Again',
          },
        ],
      },
    ),
    LessonStepDefinition(
      key: 'c2l2-assessment',
      type: LessonStepType.assessment,
      config: {
        'title': 'Final Check',
        'prompt': 'Select all the words that have the /a/ sound.',
        'sound_instruction_url': '',
        'options': [
          {
            'label': 'cat',
            'image_url': 'https://picsum.photos/seed/cat/120/120',
            'is_correct': true,
          },
          {
            'label': 'dog',
            'image_url': 'https://picsum.photos/seed/dog/120/120',
            'is_correct': false,
          },
          {
            'label': 'map',
            'image_url': 'https://picsum.photos/seed/map/120/120',
            'is_correct': true,
          },
          {
            'label': 'sun',
            'image_url': 'https://picsum.photos/seed/sun/120/120',
            'is_correct': false,
          },
          {
            'label': 'hat',
            'image_url': 'https://picsum.photos/seed/hat/120/120',
            'is_correct': true,
          },
          {
            'label': 'bed',
            'image_url': 'https://picsum.photos/seed/bed/120/120',
            'is_correct': false,
          },
        ],
      },
    ),
  ],
);
