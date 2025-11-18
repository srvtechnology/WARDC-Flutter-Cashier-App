import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/property_service.dart';
import 'property_details_view.dart';

class PaymentSearchView extends StatefulWidget {
  const PaymentSearchView({super.key, this.useScaffold = true});

  final bool useScaffold;

  @override
  State<PaymentSearchView> createState() => _PaymentSearchViewState();
}

class _PaymentSearchViewState extends State<PaymentSearchView> {
  final TextEditingController _searchController = TextEditingController();
  final PropertyService _propertyService = PropertyService();
  final FocusNode _searchFocusNode = FocusNode();

  // Payment form controllers
  final TextEditingController _payingAmountController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _chequeNoController = TextEditingController();
  final TextEditingController _payeeNameController = TextEditingController();
  final TextEditingController _transactionIdController =
      TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  dynamic _searchResult;
  bool _hasSearched = false;
  // Payment type: 'Select', 'Cash', 'Cheque', 'Online'
  String _paymentType = 'Select';
  String? _selectedPartPaymentYear;
  bool _isSavingPayment = false;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus search field when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _payingAmountController.dispose();
    _discountController.dispose();
    _chequeNoController.dispose();
    _payeeNameController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final searchQuery = _searchController.text.trim();

    if (searchQuery.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a search query',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _hasSearched = true;
    });

    try {
      // Determine search year
      final String yearToUse =
          _selectedPartPaymentYear ?? DateTime.now().year.toString();

      // Prepare search data as per API
      final searchData = {
        'property_id': searchQuery,
        'old_digital_address': '',
        'digital_address': '',
        'year': int.tryParse(yearToUse) ?? yearToUse,
      };

      final response = await _propertyService.searchPayment(
        searchData: searchData,
      );

      setState(() {
        _searchResult = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('AuthException: ', '');
        _isLoading = false;
        _searchResult = null;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResult = null;
      _errorMessage = '';
      _hasSearched = false;
    });
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
              decoration: InputDecoration(
                hintText: 'Enter Property ID (e.g., 122417)',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.search_rounded,
                    color: Colors.green.shade700,
                    size: 22,
                  ),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _clearSearch,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),
              onChanged: (text) {
                setState(() {});
                if (text.isEmpty) {
                  _clearSearch();
                }
              },
              keyboardType: TextInputType.number,
            ),
          ),
        ),

        // Results Section
        Expanded(child: _buildResults()),
      ],
    );

    if (widget.useScaffold) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Search Payment',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          ),
          elevation: 0,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: body,
      );
    } else {
      return body;
    }
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _performSearch,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Search for Payment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a Property ID to search for payment information',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    if (_searchResult == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Payment Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No payment information found for Property ID: ${_searchController.text.trim()}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Display payment information
    return _buildPaymentInformation(_searchResult);
  }

  Widget _buildPaymentInformation(dynamic result) {
    if (result == null || result is! Map) {
      return const Center(child: Text('Invalid response format'));
    }

    final property = result['property'] as Map<String, dynamic>? ?? {};
    final allAssessments = result['allAssesments'] as List? ?? [];
    final propertyAssessment =
        result['propertyAssesment'] as Map<String, dynamic>? ??
        (allAssessments.isNotEmpty
            ? allAssessments.first as Map<String, dynamic>?
            : null);
    final amountPaid = (result['amountPaid'] as num?)?.toDouble() ?? 0.0;

    // Extract assessment data - check multiple possible locations
    Map<String, dynamic>? currentAssessment;
    if (allAssessments.isNotEmpty) {
      currentAssessment = allAssessments.first as Map<String, dynamic>?;
    } else if (propertyAssessment != null) {
      currentAssessment = propertyAssessment;
    }

    // Calculate values using payment-search response (match web Payment Form)
    final assessedValue2025 = _getNumericValue(
      propertyAssessment?['current_year_assessment_amount'],
    );
    final arrearDue = _getNumericValue(propertyAssessment?['arrear_calc']);
    final penalty = _getNumericValue(propertyAssessment?['newpenalty']);
    final amountPaid2025 = amountPaid;
    final dueAmount = _getNumericValue(propertyAssessment?['due']);
    final balanceDue = dueAmount;

    // Property ID for header
    final propertyIdForHeader =
        _getPropertyId(property, propertyAssessment) ?? '';

    // Get available years for part payment
    final availableYears = _getAvailableYears(allAssessments);

    if (_selectedPartPaymentYear != null &&
        !availableYears.contains(_selectedPartPaymentYear)) {
      _selectedPartPaymentYear = availableYears.first;
    }
    final selectedYear = _selectedPartPaymentYear ?? availableYears.first;

    final propertyId = _getPropertyId(property, propertyAssessment);
    final assessmentId = _getAssessmentId(property, currentAssessment);
    final paymentYear = selectedYear;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Property Details Card
          const Text(
            'Payment Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Property ID: $propertyIdForHeader',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (propertyId != null)
                TextButton.icon(
                  onPressed: _isLoadingDetails
                      ? null
                      : () => _handleViewDetails(propertyId),
                  icon: _isLoadingDetails
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.visibility, size: 18),
                  label: Text(
                    _isLoadingDetails ? 'Loading...' : 'View Details',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _PropertyDetailsCard(
            assessedValue2025: assessedValue2025,
            arrearDue: arrearDue,
            dueAmount: dueAmount,
            penalty: penalty,
            amountPaid2025: amountPaid2025,
            balanceDue: balanceDue,
          ),
          const SizedBox(height: 16),

          // Payment Input Card
          _PaymentInputCard(
            balanceDue: balanceDue,
            payingAmountController: _payingAmountController,
            discountController: _discountController,
            paymentType: _paymentType,
            onPaymentTypeChanged: (type) {
              setState(() {
                _paymentType = type;
              });
            },
            selectedPartPaymentYear: selectedYear,
            availableYears: availableYears,
            onPartPaymentYearChanged: (year) {
              setState(() {
                _selectedPartPaymentYear = year;
              });
            },
            chequeNoController: _chequeNoController,
            payeeNameController: _payeeNameController,
            transactionIdController: _transactionIdController,
            onAmountsChanged: () {
              setState(() {});
            },
            isSaving: _isSavingPayment,
            onSave: assessmentId != null && propertyId != null
                ? () => _handleSavePayment(
                    propertyId: propertyId,
                    assessmentId: assessmentId,
                    paymentYear: paymentYear,
                    balanceDue: balanceDue,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  double _getNumericValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  List<String> _getAvailableYears(List<dynamic> assessments) {
    final years = <String>[];
    for (final assessment in assessments) {
      if (assessment is Map) {
        final year =
            assessment['year']?.toString() ??
            assessment['assessment_year']?.toString();
        if (year != null && year.isNotEmpty && !years.contains(year)) {
          years.add(year);
        }
      }
    }
    // Add current year if not present
    final currentYear = DateTime.now().year.toString();
    if (!years.contains(currentYear)) {
      years.insert(0, currentYear);
    }
    // Add previous year
    final previousYear = (DateTime.now().year - 1).toString();
    if (!years.contains(previousYear)) {
      years.add(previousYear);
    }
    return years.isNotEmpty ? years : ['2024', '2025'];
  }

  String? _getPropertyId(
    Map<String, dynamic> property,
    Map<String, dynamic>? assessment,
  ) {
    final dynamic id =
        property['id'] ??
        property['property_id'] ??
        property['propertyId'] ??
        assessment?['property_id'];
    return id?.toString();
  }

  String? _getAssessmentId(
    Map<String, dynamic> property,
    Map<String, dynamic>? assessment,
  ) {
    final dynamic id =
        property['assessment_id'] ??
        property['assessmentId'] ??
        assessment?['assessment_id'] ??
        assessment?['id'];
    return id?.toString();
  }

  Future<void> _handleViewDetails(String propertyId) async {
    setState(() {
      _isLoadingDetails = true;
    });

    try {
      final response = await _propertyService.getPropertyDetails(
        propertyId: propertyId,
      );

      if (response['success'] == true && response['property'] != null) {
        final propertyData = response['property'] as Map<String, dynamic>;

        // Navigate to PropertyDetailsView
        Get.to(
          () => PropertyDetailsView(property: propertyData),
          transition: Transition.rightToLeft,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to load property details',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceFirst('AuthException: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    }
  }

  Future<void> _handleSavePayment({
    required String propertyId,
    required String assessmentId,
    required String paymentYear,
    required double balanceDue,
  }) async {
    final payingAmount =
        double.tryParse(_payingAmountController.text.trim()) ?? 0.0;
    final discountOffered =
        double.tryParse(_discountController.text.trim()) ?? 0.0;

    if (payingAmount <= 0) {
      Get.snackbar(
        'Error',
        'Please enter a valid payment amount',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (discountOffered < 0) {
      Get.snackbar(
        'Error',
        'Discount offered cannot be negative',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (payingAmount + discountOffered > balanceDue) {
      Get.snackbar(
        'Error',
        'Payment + discount cannot exceed balance due',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_paymentType == 'Select') {
      Get.snackbar(
        'Error',
        'Please select a payment type',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final payeeName = _payeeNameController.text.trim();
    final chequeNo = _chequeNoController.text.trim();
    final transactionId = _transactionIdController.text.trim();

    if (_paymentType == 'Cash') {
      if (payeeName.isEmpty) {
        Get.snackbar(
          'Error',
          'Please enter payee name',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    } else if (_paymentType == 'Online') {
      if (payeeName.isEmpty || transactionId.isEmpty) {
        Get.snackbar(
          'Error',
          'Please enter payee name and transaction ID',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    } else if (_paymentType == 'Cheque') {
      if (payeeName.isEmpty || chequeNo.isEmpty) {
        Get.snackbar(
          'Error',
          'Please enter payee name and cheque number',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }

    final remainingDue = (balanceDue - payingAmount - discountOffered).clamp(
      0.0,
      balanceDue,
    );

    final payload = <String, dynamic>{
      'assessment_id': int.tryParse(assessmentId) ?? assessmentId,
      'property_id': int.tryParse(propertyId) ?? propertyId,
      'payment_year': paymentYear,
      'paying_amount': payingAmount.toString(),
      'discount_offered': discountOffered.toString(),
      'payment_type': _paymentType.toLowerCase(),
      'cheque_no': _paymentType == 'Cheque' ? chequeNo : '',
      'transaction_id': _paymentType == 'Online' ? transactionId : '',
      'payee_name': payeeName,
      'due': remainingDue.toStringAsFixed(2),
    };

    try {
      FocusScope.of(context).unfocus();
      setState(() {
        _isSavingPayment = true;
      });
      final response = await _propertyService.submitPayment(payload: payload);
      final message =
          response['message']?.toString() ?? 'Payment saved successfully';
      Get.snackbar(
        'Success',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      _payingAmountController.clear();
      _chequeNoController.clear();
      _payeeNameController.clear();
      _discountController.clear();
      _transactionIdController.clear();
      await _performSearch();
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceFirst('AuthException: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPayment = false;
        });
      }
    }
  }
}

// Property Details Card Widget
class _PropertyDetailsCard extends StatelessWidget {
  const _PropertyDetailsCard({
    required this.assessedValue2025,
    required this.arrearDue,
    required this.dueAmount,
    required this.penalty,
    required this.amountPaid2025,
    required this.balanceDue,
  });

  final double assessedValue2025;
  final double arrearDue;
  final double dueAmount;
  final double penalty;
  final double amountPaid2025;
  final double balanceDue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Form',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow(
            label: '2025 Assessment',
            value: _formatCurrency(assessedValue2025),
          ),
          const SizedBox(height: 12),
          _DetailRow(label: 'Arrear', value: _formatCurrency(arrearDue)),
          const SizedBox(height: 12),
          _DetailRow(label: 'Due', value: _formatCurrency(dueAmount)),
          const SizedBox(height: 12),
          _DetailRow(label: 'Penalty', value: _formatCurrency(penalty)),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'Amount Paid (2025)',
            value: _formatCurrency(amountPaid2025),
          ),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'Balance',
            value: _formatCurrency(dueAmount),
            isHighlighted: true,
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    // Show raw numeric value (no currency prefix) like the web form
    return amount.toStringAsFixed(2);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  final String label;
  final String value;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
            color: isHighlighted ? Colors.blue.shade700 : Colors.black87,
          ),
        ),
      ],
    );
  }
}

// Payment Input Card Widget
class _PaymentInputCard extends StatelessWidget {
  const _PaymentInputCard({
    required this.balanceDue,
    required this.payingAmountController,
    required this.discountController,
    required this.paymentType,
    required this.onPaymentTypeChanged,
    required this.selectedPartPaymentYear,
    required this.availableYears,
    required this.onPartPaymentYearChanged,
    required this.chequeNoController,
    required this.payeeNameController,
    required this.transactionIdController,
    required this.onAmountsChanged,
    required this.isSaving,
    required this.onSave,
  });

  final double balanceDue;
  final TextEditingController payingAmountController;
  final TextEditingController discountController;
  final String paymentType;
  final ValueChanged<String> onPaymentTypeChanged;
  final String? selectedPartPaymentYear;
  final List<String> availableYears;
  final ValueChanged<String?> onPartPaymentYearChanged;
  final TextEditingController chequeNoController;
  final TextEditingController payeeNameController;
  final TextEditingController transactionIdController;
  final VoidCallback onAmountsChanged;
  final bool isSaving;
  final VoidCallback? onSave;

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final double totalAmount =
        _parse(payingAmountController) + _parse(discountController);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Form',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Paying Amount (full width)
          const Text(
            'Paying Amount',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: payingAmountController,
            keyboardType: TextInputType.number,
            onChanged: (_) => onAmountsChanged(),
            decoration: InputDecoration(
              hintText: 'Enter Amount Paying',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Discount Offered (full width)
          const Text(
            'Discount Offered',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: discountController,
            keyboardType: TextInputType.number,
            onChanged: (_) => onAmountsChanged(),
            decoration: InputDecoration(
              hintText: 'Enter Discount',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Total Amount (read-only, full width)
          const Text(
            'Total Amount',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              totalAmount.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Payment Type
          const Text(
            'Payment Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: paymentType == 'Select' ? null : paymentType,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            hint: const Text('Select'),
            items: const [
              DropdownMenuItem(value: 'Cash', child: Text('Cash')),
              DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
              DropdownMenuItem(value: 'Online', child: Text('Online')),
            ],
            onChanged: (value) {
              if (value != null) onPaymentTypeChanged(value);
            },
          ),
          const SizedBox(height: 16),

          // Adjust Paying Year
          const Text(
            'Adjust Paying Year',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedPartPaymentYear ?? availableYears.first,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            items: availableYears.map((year) {
              return DropdownMenuItem(value: year, child: Text(year));
            }).toList(),
            onChanged: onPartPaymentYearChanged,
          ),
          const SizedBox(height: 16),

          // Cheque No (only if Cheque is selected)
          if (paymentType == 'Cheque') ...[
            TextField(
              controller: chequeNoController,
              decoration: InputDecoration(
                labelText: 'Cheque No',
                hintText: 'Enter Cheque No',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Transaction Id (only if Online is selected)
          if (paymentType == 'Online') ...[
            TextField(
              controller: transactionIdController,
              decoration: InputDecoration(
                labelText: 'Transaction Id',
                hintText: 'Enter Transaction Id',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Payee Name (for all non-select payment types)
          if (paymentType != 'Select') ...[
            TextField(
              controller: payeeNameController,
              decoration: InputDecoration(
                labelText: 'Payee Name',
                hintText: 'Enter Payee Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (onSave == null || isSaving) ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Submit Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
