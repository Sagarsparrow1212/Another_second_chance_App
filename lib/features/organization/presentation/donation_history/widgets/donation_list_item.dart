import 'package:flutter/material.dart';
import 'package:homelyhope/core/theme/app_theme.dart';

import 'package:intl/intl.dart';
import '../../../data/models/donation/organization_donation_history_response.dart';

class DonationListItem extends StatelessWidget {
  final OrganizationDonationHistoryItem donation;

  const DonationListItem({super.key, required this.donation});

  @override
  Widget build(BuildContext context) {
    // Use direct values from API
    final orgShare = donation.organizationAmount;
    final homelessShare = donation.homelessAmount;

    final isCompleted = donation.status.toLowerCase() == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9), // Light Green
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF2E7D32), // Dark Green
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Money',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat(
                      'MMM d, yyyy • h:mm a',
                    ).format(donation.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFE8F5E9)
                      : Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  donation.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? const Color(0xFF2E7D32)
                        : Colors.orange[800],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Main Amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Amount:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\$${donation.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.credit_card, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                'Homeless: ${donation.homeless!.fullName ?? "Card"}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Payment Info
          Row(
            children: [
              Icon(Icons.credit_card, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                'Payment: ${donation.paymentMethod ?? "Card"}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.receipt_long, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'TXN: ${donation.donationId}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),
          // Breakdown Table
          _buildBreakdownRow(
            'Net Amount',
            donation.netAmount,
            Colors.black87,
            isBold: true,
          ),
          const SizedBox(height: 8),
          _buildBreakdownRow(
            'Organization Share',
            orgShare,
            Colors.blue.shade800,
          ),
          const SizedBox(height: 4),
          _buildBreakdownRow(
            'Homeless Share',
            homelessShare,
            Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    double amount,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
