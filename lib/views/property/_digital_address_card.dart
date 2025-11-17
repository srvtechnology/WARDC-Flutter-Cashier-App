import 'package:flutter/material.dart';

class DigitalAddressCard extends StatelessWidget {
  const DigitalAddressCard({
    required this.propertyId,
    required this.digitalAddresses,
    required this.selectedDigitalAddress,
    required this.onDigitalChanged,
  });

  final String propertyId;
  final Map<String, String> digitalAddresses;
  final String? selectedDigitalAddress;
  final ValueChanged<String?> onDigitalChanged;

  @override
  Widget build(BuildContext context) {
    final hasOptions = digitalAddresses.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Property ID: $propertyId',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (hasOptions)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Digital Address',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6),
                    ],
                  ),
                ),
              ],
            ),
          if (hasOptions)
            DropdownButtonFormField<String>(
              value: selectedDigitalAddress != null &&
                      digitalAddresses.containsKey(selectedDigitalAddress)
                  ? selectedDigitalAddress
                  : null,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              hint: const Text('Select Digital Address'),
              items: digitalAddresses.entries
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: onDigitalChanged,
            ),
        ],
      ),
    );
  }
}


