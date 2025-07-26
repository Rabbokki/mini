import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../components/auth_page.dart';
import '../components/diary_calendar.dart' as diary_calendar_lib;
import '../components/diary_entry.dart' as diary_entry_lib;
import '../components/my_page.dart';


class IndexPage extends StatelessWidget {
  const IndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Show auth page if not authenticated
        if (!appState.isAuthenticated) {
          return const AuthPage();
        }

        // Show different views based on current view state
        switch (appState.currentView) {
          case CurrentView.entry:
            final existingEntry = appState.emotionData[appState.selectedDate];
            return diary_entry_lib.DiaryEntry(
              selectedDate: appState.selectedDate,
              existingEntry: existingEntry,
              onBack: () => appState.handleBackToCalendar(),
              onSave: (String entry, Emotion emotion, List<String>? images) {
                appState.saveDiary(entry, emotion, images);
              },
            );
          
          case CurrentView.mypage:
            return const MyPage();
          

          
          case CurrentView.calendar:
          default:
            return Consumer<AppState>(
              builder: (context, calendarAppState, child) {
                return diary_calendar_lib.DiaryCalendar(
                  onDateSelect: (dateKey) {
                    print('DiaryCalendar onDateSelect called: $dateKey'); // 디버깅용 로그
                    calendarAppState.handleDateSelect(dateKey);
                  },
                  onSettingsClick: () => calendarAppState.handleSettingsClick(),
                  emoticonEnabled: calendarAppState.emoticonEnabled,
                  userBirthday: calendarAppState.userBirthday,
                  onGoToMyPage: () => calendarAppState.setCurrentView(CurrentView.mypage),
                );
              },
            );
        }
      },
    );
  }
} 