import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/reports_repository.dart';

// Provider do repositório
final reportsRepositoryProvider = Provider((ref) => ReportsRepository());

// Provider de período selecionado
enum ReportPeriod { today, week, month, custom }

class ReportsState {
  final ReportPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? summary;
  final List<Map<String, dynamic>> dailySales;
  final List<Map<String, dynamic>> topProducts;
  final List<Map<String, dynamic>> salesByCategory;
  final List<Map<String, dynamic>> salesByDayPeriod;
  final Map<String, dynamic>? comparison;
  final Map<String, dynamic>? channelAnalysis;
  final Map<String, dynamic>? deliveryAnalysis;
  final Map<String, dynamic>? costAnalysis;
  final List<Map<String, dynamic>> leastProducts;

  ReportsState({
    this.period = ReportPeriod.today,
    required this.startDate,
    required this.endDate,
    this.isLoading = false,
    this.error,
    this.summary,
    this.dailySales = const [],
    this.topProducts = const [],
    this.salesByCategory = const [],
    this.salesByDayPeriod = const [],
    this.comparison,
    this.channelAnalysis,
    this.deliveryAnalysis,
    this.costAnalysis,
    this.leastProducts = const [],
  });

  ReportsState copyWith({
    ReportPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? summary,
    List<Map<String, dynamic>>? dailySales,
    List<Map<String, dynamic>>? topProducts,
    List<Map<String, dynamic>>? salesByCategory,
    List<Map<String, dynamic>>? salesByDayPeriod,
    Map<String, dynamic>? comparison,
    Map<String, dynamic>? channelAnalysis,
    Map<String, dynamic>? deliveryAnalysis,
    Map<String, dynamic>? costAnalysis,
    List<Map<String, dynamic>>? leastProducts,
  }) {
    return ReportsState(
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      summary: summary ?? this.summary,
      dailySales: dailySales ?? this.dailySales,
      topProducts: topProducts ?? this.topProducts,
      salesByCategory: salesByCategory ?? this.salesByCategory,
      salesByDayPeriod: salesByDayPeriod ?? this.salesByDayPeriod,
      comparison: comparison ?? this.comparison,
      channelAnalysis: channelAnalysis ?? this.channelAnalysis,
      deliveryAnalysis: deliveryAnalysis ?? this.deliveryAnalysis,
      costAnalysis: costAnalysis ?? this.costAnalysis,
      leastProducts: leastProducts ?? this.leastProducts,
    );
  }
}

final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((
  ref,
) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return ReportsNotifier(
    ref.read(reportsRepositoryProvider),
    initialStartDate: today,
    initialEndDate: now,
  );
});

class ReportsNotifier extends StateNotifier<ReportsState> {
  final ReportsRepository _repository;

  ReportsNotifier(
    this._repository, {
    required DateTime initialStartDate,
    required DateTime initialEndDate,
  }) : super(
         ReportsState(startDate: initialStartDate, endDate: initialEndDate),
       ) {
    loadReports();
  }

  void setPeriod(ReportPeriod period) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (period) {
      case ReportPeriod.today:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case ReportPeriod.week:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case ReportPeriod.month:
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case ReportPeriod.custom:
        return; // Mantém as datas atuais
    }

    state = state.copyWith(
      period: period,
      startDate: startDate,
      endDate: endDate,
    );
    loadReports();
  }

  void setCustomPeriod(DateTime start, DateTime end) {
    state = state.copyWith(
      period: ReportPeriod.custom,
      startDate: start,
      endDate: end,
    );
    loadReports();
  }

  Future<void> loadReports() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Carregar todos os dados em paralelo
      final results = await Future.wait([
        _repository.getSalesByPeriod(
          startDate: state.startDate,
          endDate: state.endDate,
        ),
        _repository.getDailySales(
          startDate: state.startDate,
          endDate: state.endDate,
        ),
        _repository.getTopSellingProducts(
          startDate: state.startDate,
          endDate: state.endDate,
          limit: 10,
        ),
        _repository.getSalesByCategory(
          startDate: state.startDate,
          endDate: state.endDate,
        ),
        _repository.getSalesByDayPeriod(
          startDate: state.startDate,
          endDate: state.endDate,
        ),
        _repository.getComparison(
          currentStart: state.startDate,
          currentEnd: state.endDate,
        ),
        _repository.getSalesByChannel(
          startDate: state.startDate,
          endDate: state.endDate,
        ),
        _repository.getDeliveryAnalysis(
          startDate: state.startDate,
          endDate: state.endDate,
        ),
        _repository.getCostAnalysis(
          startDate: state.startDate,
          endDate: state.endDate,
        ),
        _repository.getLeastSellingProducts(
          startDate: state.startDate,
          endDate: state.endDate,
          limit: 5,
        ),
      ]);

      state = state.copyWith(
        summary: results[0] as Map<String, dynamic>,
        dailySales: results[1] as List<Map<String, dynamic>>,
        topProducts: results[2] as List<Map<String, dynamic>>,
        salesByCategory: results[3] as List<Map<String, dynamic>>,
        salesByDayPeriod: results[4] as List<Map<String, dynamic>>,
        comparison: results[5] as Map<String, dynamic>,
        channelAnalysis: results[6] as Map<String, dynamic>,
        deliveryAnalysis: results[7] as Map<String, dynamic>,
        costAnalysis: results[8] as Map<String, dynamic>,
        leastProducts: results[9] as List<Map<String, dynamic>>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
