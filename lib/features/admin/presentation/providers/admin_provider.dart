import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/admin_repository.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/sold_license.dart';
import '../../domain/entities/company_user.dart';

// Provider do repositório
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

// ==================== CUSTOMERS STATE ====================

class CustomersState {
  final List<Customer> customers;
  final bool isLoading;
  final String? error;

  CustomersState({
    this.customers = const [],
    this.isLoading = false,
    this.error,
  });

  CustomersState copyWith({
    List<Customer>? customers,
    bool? isLoading,
    String? error,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CustomersNotifier extends StateNotifier<CustomersState> {
  final AdminRepository _repository;

  CustomersNotifier(this._repository) : super(CustomersState()) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final customers = await _repository.getAllCustomers();
      state = state.copyWith(customers: customers, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createCustomer(Customer customer) async {
    try {
      await _repository.createCustomer(customer);
      await loadCustomers();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateCustomer(Customer customer) async {
    try {
      await _repository.updateCustomer(customer);
      await loadCustomers();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    try {
      await _repository.deleteCustomer(id);
      await loadCustomers();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Customer? getCustomerById(String id) {
    try {
      return state.customers.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}

final customersProvider =
    StateNotifierProvider<CustomersNotifier, CustomersState>((ref) {
      final repository = ref.watch(adminRepositoryProvider);
      return CustomersNotifier(repository);
    });

// ==================== LICENSES STATE ====================

class LicensesState {
  final List<SoldLicense> licenses;
  final bool isLoading;
  final String? error;

  LicensesState({this.licenses = const [], this.isLoading = false, this.error});

  LicensesState copyWith({
    List<SoldLicense>? licenses,
    bool? isLoading,
    String? error,
  }) {
    return LicensesState(
      licenses: licenses ?? this.licenses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<SoldLicense> get activeLicenses =>
      licenses.where((l) => l.status == 'active' && !l.isExpired).toList();

  List<SoldLicense> get expiredLicenses =>
      licenses.where((l) => l.isExpired || l.status == 'expired').toList();

  List<SoldLicense> get revokedLicenses =>
      licenses.where((l) => l.status == 'revoked').toList();

  List<SoldLicense> get expiringSoon => licenses
      .where((l) => l.daysRemaining <= 7 && l.daysRemaining > 0)
      .toList();
}

class LicensesNotifier extends StateNotifier<LicensesState> {
  final AdminRepository _repository;

  LicensesNotifier(this._repository) : super(LicensesState()) {
    loadLicenses();
  }

  Future<void> loadLicenses() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final licenses = await _repository.getAllLicenses();
      state = state.copyWith(licenses: licenses, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<SoldLicense?> generateLicense({
    required String customerId,
    required int days,
    double? price,
    String? paymentMethod,
    String? notes,
  }) async {
    try {
      final license = await _repository.generateLicense(
        customerId: customerId,
        days: days,
        price: price,
        paymentMethod: paymentMethod,
        notes: notes,
      );
      await loadLicenses();
      return license;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> renewLicense(
    String licenseId,
    int additionalDays, {
    double? price,
    String? paymentMethod,
  }) async {
    try {
      await _repository.renewLicense(
        licenseId,
        additionalDays,
        price: price,
        paymentMethod: paymentMethod,
      );
      await loadLicenses();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> revokeLicense(String licenseId, String reason) async {
    try {
      await _repository.revokeLicense(licenseId, reason);
      await loadLicenses();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  List<SoldLicense> getLicensesByCustomerId(String customerId) {
    return state.licenses.where((l) => l.customerId == customerId).toList();
  }
}

final licensesProvider = StateNotifierProvider<LicensesNotifier, LicensesState>(
  (ref) {
    final repository = ref.watch(adminRepositoryProvider);
    return LicensesNotifier(repository);
  },
);

// ==================== ADMIN STATISTICS ====================

final adminStatisticsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getAdminStatistics();
});

// ==================== ADMIN SETTINGS ====================

class AdminSettingsState {
  final bool isLoading;
  final String? error;

  AdminSettingsState({this.isLoading = false, this.error});

  AdminSettingsState copyWith({bool? isLoading, String? error}) {
    return AdminSettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminSettingsNotifier extends StateNotifier<AdminSettingsState> {
  final AdminRepository _repository;

  AdminSettingsNotifier(this._repository) : super(AdminSettingsState());

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.changeAdminPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
}

final adminProvider =
    StateNotifierProvider<AdminSettingsNotifier, AdminSettingsState>((ref) {
      final repository = ref.watch(adminRepositoryProvider);
      return AdminSettingsNotifier(repository);
    });

// ==================== COMPANY USERS (MULTI-TENANT) ====================

class CompanyUsersState {
  final List<CompanyUser> users;
  final bool isLoading;
  final String? error;

  CompanyUsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  CompanyUsersState copyWith({
    List<CompanyUser>? users,
    bool? isLoading,
    String? error,
  }) {
    return CompanyUsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CompanyUsersNotifier extends StateNotifier<CompanyUsersState> {
  final AdminRepository _repository;

  CompanyUsersNotifier(this._repository) : super(CompanyUsersState());

  Future<void> loadUsersByCustomer(String customerId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _repository.getCompanyUsersByCustomerId(customerId);
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createUser(CompanyUser user) async {
    try {
      await _repository.createCompanyUser(user);
      await loadUsersByCustomer(user.customerId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateUser(CompanyUser user) async {
    try {
      await _repository.updateCompanyUser(user);
      await loadUsersByCustomer(user.customerId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateUserPassword(
    String userId,
    String newPassword,
    String customerId,
  ) async {
    try {
      await _repository.updateCompanyUserPassword(userId, newPassword);
      await loadUsersByCustomer(customerId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteUser(String userId, String customerId) async {
    try {
      await _repository.deleteCompanyUser(userId);
      await loadUsersByCustomer(customerId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final companyUsersProvider =
    StateNotifierProvider<CompanyUsersNotifier, CompanyUsersState>((ref) {
      final repository = ref.watch(adminRepositoryProvider);
      return CompanyUsersNotifier(repository);
    });
