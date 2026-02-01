import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/process_repository.dart';
import '../../data/services/process_service.dart';

/// Provider for ProcessService
final processServiceProvider = Provider<ProcessService>((ref) {
  return ProcessService();
});

/// Provider for ProcessRepository
final processRepositoryProvider = Provider<ProcessRepository>((ref) {
  final service = ref.watch(processServiceProvider);
  return ProcessRepository(processService: service);
});
