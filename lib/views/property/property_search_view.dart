import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/property_service.dart';
import 'property_details_view.dart';

class PropertySearchView extends StatefulWidget {
  const PropertySearchView({super.key});

  @override
  State<PropertySearchView> createState() => _PropertySearchViewState();
}

class _PropertySearchViewState extends State<PropertySearchView> {
  final TextEditingController _searchController = TextEditingController();
  final PropertyService _propertyService = PropertyService();
  final FocusNode _searchFocusNode = FocusNode();
  
  bool _isLoading = false;
  String _errorMessage = '';
  List<dynamic> _searchResults = [];
  bool _hasSearched = false;

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
    super.dispose();
  }

  Future<void> _performSearch() async {
    final propertyId = _searchController.text.trim();
    
    if (propertyId.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a Property ID',
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
      final response = await _propertyService.searchByPropertyId(
        propertyId: propertyId,
        page: 1,
        limit: 10,
      );

      List<dynamic> results = [];
      
      // Extract properties from response (same logic as PropertyListController)
      if (response.containsKey('property')) {
        final dynamic prop = response['property'];
        if (prop is Map && prop.containsKey('data') && prop['data'] is List) {
          results = List<dynamic>.from(prop['data'] as List);
        }
      } else if (response.containsKey('data')) {
        final dynamic data = response['data'];
        if (data is Map) {
          if (data.containsKey('data') && data['data'] is List) {
            results = List<dynamic>.from(data['data'] as List);
          } else if (data.containsKey('properties') && data['properties'] is List) {
            results = List<dynamic>.from(data['properties'] as List);
          } else if (data.containsKey('items') && data['items'] is List) {
            results = List<dynamic>.from(data['items'] as List);
          }
        } else if (data is List) {
          results = List<dynamic>.from(data);
        }
      } else if (response.containsKey('properties') && response['properties'] is List) {
        results = List<dynamic>.from(response['properties'] as List);
      } else if (response.containsKey('data') && response['data'] is List) {
        results = List<dynamic>.from(response['data'] as List);
      }

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('AuthException: ', '');
        _isLoading = false;
        _searchResults = [];
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _errorMessage = '';
      _hasSearched = false;
    });
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search Property',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
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
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
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
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
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
            Icon(
              Icons.search_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for a Property',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a Property ID to search',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
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
              'No Properties Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No properties match the Property ID: ${_searchController.text.trim()}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final property = _searchResults[index];
        return _PropertySearchItem(
          property: property,
          onTap: () {
            Get.to(() => PropertyDetailsView(property: property));
          },
        );
      },
    );
  }
}

class _PropertySearchItem extends StatelessWidget {
  const _PropertySearchItem({
    required this.property,
    required this.onTap,
  });

  final dynamic property;
  final VoidCallback onTap;

  String _getPropertyId() {
    return property['id']?.toString() ?? 
           property['property_id']?.toString() ?? 
           'N/A';
  }

  String _getAddress() {
    final parts = <String>[];
    if (property['street_name'] != null && property['street_name'].toString().isNotEmpty) {
      parts.add(property['street_name'].toString());
    }
    if (property['ward'] != null && property['ward'].toString().isNotEmpty) {
      parts.add(property['ward'].toString());
    }
    if (property['constituency'] != null && property['constituency'].toString().isNotEmpty) {
      parts.add(property['constituency'].toString());
    }
    return parts.isEmpty ? 'Address not available' : parts.join(', ');
  }

  String _getLandlordName() {
    if (property['landlord'] != null) {
      final landlord = property['landlord'];
      if (landlord is Map) {
        return landlord['name']?.toString() ?? 'N/A';
      }
    }
    return property['landlord_name']?.toString() ?? 'N/A';
  }

  String _getStatusBadge() {
    final status = property['status']?.toString().toLowerCase() ?? '';
    if (status == 'completed' || status == 'c') {
      return 'C';
    } else if (status == 'registered' || status == 'r') {
      return 'R';
    }
    return 'C';
  }

  Color _getStatusColor() {
    final status = property['status']?.toString().toLowerCase() ?? '';
    if (status == 'completed' || status == 'c') {
      return Colors.orange;
    } else if (status == 'registered' || status == 'r') {
      return Colors.blue;
    }
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Property Icon with Status Badge
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.home_rounded,
                      color: Colors.green.shade700,
                      size: 32,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _getStatusBadge(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Property Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Property #${_getPropertyId()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _getAddress(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _getLandlordName(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
















