import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/home_v2/providers/home_v2_provider.dart';
import 'package:milpress/features/home_v2/widgets/bottom_section_widget.dart';
import 'package:milpress/features/home_v2/widgets/course_card_widget.dart';
import 'package:milpress/features/home_v2/widgets/date_greeting_widget.dart';
import 'package:milpress/features/home_v2/widgets/home_header_widget.dart';
import 'package:milpress/features/home_v2/widgets/page_dots_widget.dart';
import 'package:milpress/features/home_v2/widgets/review_mode_layout.dart';
import 'package:milpress/features/home_v2/widgets/standalone_completion_card.dart';
import 'package:milpress/features/profile/providers/profile_provider.dart';
import 'package:milpress/utils/app_colors.dart';


// HomeV2Screen

class HomeV2Screen extends ConsumerStatefulWidget {
  const HomeV2Screen({super.key});

  @override
  ConsumerState<HomeV2Screen> createState() => _HomeV2ScreenState();
}

class _HomeV2ScreenState extends ConsumerState<HomeV2Screen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _reviewMode = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _reviewMode = false;
    });
  }

  void _handleCtaTap(BuildContext context, CourseCardViewModel vm) {
    switch (vm.state) {
      case CourseCardState.startCourse:
      case CourseCardState.continueCourse:
        context.push('/course/${vm.courseWithDetails.course.id}');
        break;
      case CourseCardState.reviewCourse:
        setState(() => _reviewMode = true);
        break;
      case CourseCardState.comingNext:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(homeV2Provider);
    final profileAsync = ref.watch(profileProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              HomeHeaderWidget(profileAsync: profileAsync),
              const SizedBox(height: 8),
              const DateGreetingWidget(),
              const SizedBox(height: 16),
              Expanded(
                child: homeAsync.when(
                  data: (viewModels) => _buildBody(context, viewModels),
                  loading: () => const _LoadingState(),
                  error: (error, _) => _ErrorState(error: error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  body builder
  Widget _buildBody(BuildContext context, List<CourseCardViewModel> viewModels) {
    if (viewModels.isEmpty) return const _EmptyState();

    final currentVm = _currentPage < viewModels.length
        ? viewModels[_currentPage]
        : null;

    // Review mode — swaps PageView for the ReviewModeLayout
    if (_reviewMode &&
        currentVm != null &&
        currentVm.state == CourseCardState.reviewCourse) {
      return ReviewModeLayout(
        viewModel: currentVm,
        onExit: () => setState(() => _reviewMode = false),
      );
    }

    return Column(
      children: [
        // Course card PageView
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: viewModels.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) =>
                CourseCardWidget(viewModel: viewModels[index]),
          ),
        ),

        const SizedBox(height: 14),

        // Completion banner (reviewCourse only)
        if (currentVm?.state == CourseCardState.reviewCourse) ...[
          const StandaloneCompletionCard(),
          const SizedBox(height: 14),
        ],

        // Page indicator dots
        PageDotsWidget(count: viewModels.length, current: _currentPage),
        const SizedBox(height: 16),

        // Modules / lessons / eligibility / CTA
        if (currentVm != null)
          BottomSectionWidget(
            viewModel: currentVm,
            onCtaTap: () => _handleCtaTap(context, currentVm),
          ),

        const SizedBox(height: 24),
      ],
    );
  }
}

//
// Inline state placeholders (small enough to keep here)
//

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(
      color: Color(0xFFE8844A),
      strokeWidth: 2.5,
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(
    child: Text(
      'No courses available yet.',
      style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final Object error;
  const _ErrorState({required this.error});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Something went wrong.\n$error',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
      ),
    ),
  );
}