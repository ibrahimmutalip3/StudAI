import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/dao_providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/homework_dao.dart';
import '../../../core/utils/date_utils.dart';

enum HomeworkFilter { today, tomorrow, thisWeek, overdue, completed, all }

final homeworkFilterProvider = StateProvider<HomeworkFilter>((ref) => HomeworkFilter.all);

final filteredHomeworkProvider = StreamProvider<List<HomeworkWithSubject>>((ref) {
  final dao = ref.watch(homeworkDaoProvider);
  final filter = ref.watch(homeworkFilterProvider);

  return dao.watchAll().map((all) {
    switch (filter) {
      case HomeworkFilter.today:
        return all
            .where((h) =>
                AppDateUtils.isToday(h.homework.deadline) &&
                h.homework.status != HomeworkStatus.completed)
            .toList();
      case HomeworkFilter.tomorrow:
        return all
            .where((h) =>
                AppDateUtils.isTomorrow(h.homework.deadline) &&
                h.homework.status != HomeworkStatus.completed)
            .toList();
      case HomeworkFilter.thisWeek:
        return all
            .where((h) =>
                AppDateUtils.isThisWeek(h.homework.deadline) &&
                h.homework.status != HomeworkStatus.completed)
            .toList();
      case HomeworkFilter.overdue:
        return all.where((h) => h.homework.status == HomeworkStatus.overdue).toList();
      case HomeworkFilter.completed:
        return all.where((h) => h.homework.status == HomeworkStatus.completed).toList();
      case HomeworkFilter.all:
        return all.where((h) => h.homework.status != HomeworkStatus.completed).toList();
    }
  });
});
