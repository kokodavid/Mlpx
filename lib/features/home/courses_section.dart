import 'package:flutter/material.dart';
import 'course_card.dart';

class CoursesSection extends StatelessWidget {
  const CoursesSection({Key? key}) : super(key: key);

  static final List<Map<String, dynamic>> _courseData = [
    {
      "courseNumber": "Course 1",
      "title": "Letter Recognition",
      "subtitle": "by MilPress",
      "color": const Color(0xFFF9EC97),
      "isFree": true,
    },
    {
      "courseNumber": "Course 2",
      "title": "Word Recognition",
      "subtitle": "by MilPress",
      "color": const Color(0xFFB8F7B2),
      "isFree": true,
    },
    {
      "courseNumber": "Course 3",
      "title": "Basic Grammar",
      "subtitle": "by MilPress",
      "color": const Color(0xFFFFD6D6),
      "isFree": false,
    },
    {
      "courseNumber": "Course 4",
      "title": "Reading Skills",
      "subtitle": "by MilPress",
      "color": const Color(0xFFD4E6FF),
      "isFree": true,
    },
    {
      "courseNumber": "Course 5",
      "title": "Writing Skills",
      "subtitle": "by MilPress",
      "color": const Color(0xFFE9DFFF),
      "isFree": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            "Featured Courses",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF232B3A),
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _courseData.length,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemBuilder: (context, index) {
              final course = _courseData[index];
              return CourseCard(
                courseNumber: course["courseNumber"]!,
                title: course["title"]!,
                subtitle: course["subtitle"]!,
                color: course["color"]!,
                isFree: course["isFree"]!,
                onEnroll: () {},
              );
            },
          ),
        ),
      ],
    );
  }
}
