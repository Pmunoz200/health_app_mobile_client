import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:health_app_mobile_client/services/fit_bit_data_service.dart';
import 'package:health_app_mobile_client/services/google_fit_data_service.dart';
import 'package:health_app_mobile_client/util/app_states.dart';
import 'package:health_app_mobile_client/util/default_data_util.dart';

class HomeDataProvider extends ChangeNotifier {
  final GoogleFitDataService googleFitHealthDataService =
      GoogleFitDataService();

  List<DefaultDataPoint> _currentActivityDataPoints = [];
  List<DefaultDataPoint> get currentActivityDataPoints =>
      _currentActivityDataPoints;
  void updateActivityDataPoints(List<DefaultDataPoint> newDataPoints) {
    _currentActivityDataPoints.addAll(newDataPoints);
    notifyListeners();
  }

  Future<void> fetchActivityDataPoints(
      DateTime startDate, DateTime endDate) async {
    final List<HealthDataAccess> permission = [
      HealthDataAccess.READ,
      // HealthDataAccess.READ,
      // HealthDataAccess.READ
    ];
    final List<HealthDataType> type = [
      HealthDataType.MOVE_MINUTES,
      // HealthDataType.SLEEP_ASLEEP,
      // HealthDataType.ACTIVE_ENERGY_BURNED,
    ];
    // Check permission to read Move minutes
    updateCurrentAppState(AppState.FETCHING_DATA);
    bool permitedAcces =
        await googleFitHealthDataService.checkPermissions(permission, type);
    if (!permitedAcces) {
      updateCurrentAppState(AppState.AUTH_NOT_GRANTED);
    } else {
      List<DefaultDataPoint> fetchedData = await googleFitHealthDataService
          .fetchGoogleFitHealthData(startDate, endDate, type);
      if (fetchedData.isEmpty & currentActivityDataPoints.isEmpty) {
        updateCurrentAppState(AppState.NO_DATA);
      } else {
        // Update your data points with the fetched data
        updateActivityDataPoints(fetchedData);
        updateCurrentAppState(AppState.DATA_READY);

        DateTime tempMinDate = currentMinDate;
        if (startDate.isBefore(currentMinDate) ||
            startDate.isAfter(currentMaxDate)) {
          updateCurrentMinDate(startDate);
        }
        if (endDate.isAfter(currentMaxDate) || endDate.isBefore(tempMinDate)) {
          updateCurrentMaxDate(endDate);
        }
      }
    }
  }

  late FitBitDataService _fitBitDataService;
  FitBitDataService get fitBitDataService =>
      _fitBitDataService;
  void updatefitBitDataService(FitBitDataService fitBitDataService) {
    _fitBitDataService = fitBitDataService;
    notifyListeners();
  }

  List<DefaultDataPoint> _currentSleepDataPoints = [];
  List<DefaultDataPoint> get currentSleepDataPoints => _currentSleepDataPoints;
  void updateSleepDataPoints(List<DefaultDataPoint> newDataPoints) {
    _currentSleepDataPoints.addAll(newDataPoints);
    notifyListeners();
  }

  Future<void> fetchSleepDataPoints(
      DateTime startDate, DateTime endDate) async {
    updateCurrentAppState(AppState.FETCHING_DATA);
    List<DefaultDataPoint> fetchedData = await fitBitDataService.fetchFitBitSleepData(startDate, endDate: endDate);
    if (fetchedData.isEmpty & currentSleepDataPoints.isEmpty) {
      updateCurrentAppState(AppState.NO_DATA);
    } else {
      // Update your data points with the fetched data
      updateSleepDataPoints(fetchedData);
      updateCurrentAppState(AppState.DATA_READY);

      DateTime tempMinDate = currentMinDate;
      if (startDate.isBefore(currentMinDate) ||
          startDate.isAfter(currentMaxDate)) {
        updateCurrentMinDate(startDate);
      }
      if (endDate.isAfter(currentMaxDate) || endDate.isBefore(tempMinDate)) {
        updateCurrentMaxDate(endDate);
      }
    }
  }

  DateTime _currentDate = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day + 1)
      .subtract(const Duration(seconds: 1)); //Start at current date
  DateTime get currentDate => _currentDate;
  void updateCurrentDate(DateTime newDate) {
    _currentDate = newDate;
    notifyListeners();
  }

  DateTime _currentMinDate = DateTime(DateTime.now().year, DateTime.now().month,
      DateTime.now().day); // Initialize with a default value
  DateTime get currentMinDate => _currentMinDate;
  void updateCurrentMinDate(DateTime newMinDate) {
    _currentMinDate = newMinDate;
    notifyListeners();
  }

  DateTime _currentMaxDate =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime get currentMaxDate => _currentMaxDate;
  void updateCurrentMaxDate(DateTime newMaxDate) {
    _currentMaxDate = newMaxDate;
    notifyListeners();
  }

  AppState _currentAppState = AppState.DATA_NOT_FETCHED; // Range of data stored
  AppState get currentAppState => _currentAppState;
  void updateCurrentAppState(AppState newAppState) {
    _currentAppState = newAppState;
    notifyListeners();
  }

  String _currentTopBarSelect = 'day';
  String get currentTopBarSelect => _currentTopBarSelect;
  void updateCurrentTopBarSelect(String newTopBarSelect) {
    if (newTopBarSelect != _currentTopBarSelect) {
      _currentTopBarSelect = newTopBarSelect;
      _currentDate = DateTime(
              DateTime.now().year, DateTime.now().month, DateTime.now().day + 1)
          .subtract(const Duration(minutes: 1));
      switch (newTopBarSelect) {
        case 'day':
          _currentMinDate = DateTime(
              _currentDate.year, _currentDate.month, _currentDate.day - 10);
          fetchActivityDataPoints(_currentMinDate, _currentDate);
          break;
        case 'week':
          int weekday = _currentDate.weekday;
          _currentMinDate = _currentDate.subtract(Duration(days: weekday - 1));
          fetchActivityDataPoints(_currentMinDate, _currentDate);
          break;
        case 'month':
          _currentMinDate = DateTime(_currentDate.year, _currentDate.month, 1);
          fetchActivityDataPoints(_currentMinDate, _currentDate);
          break;
      }
      notifyListeners();
    }
  }
}
