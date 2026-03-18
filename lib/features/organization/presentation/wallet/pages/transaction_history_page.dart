import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/features/common/widgets/custom_appbar.dart';
import '../providers/organization_wallet_provider.dart';
import '../widgets/transaction_list_item.dart';

class WithdrawalHistoryPage extends ConsumerStatefulWidget {
  final String initialFilter;
  const WithdrawalHistoryPage({super.key, this.initialFilter = 'withdraw'});

  @override
  ConsumerState<WithdrawalHistoryPage> createState() =>
      _WithdrawalHistoryPageState();
}

class _WithdrawalHistoryPageState extends ConsumerState<WithdrawalHistoryPage> {
  late String currentFilter;

  @override
  void initState() {
    super.initState();
    currentFilter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(transactionsProvider(currentFilter));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: 'Transaction History',
        showBackButton: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Withdrawals',
                  isSelected: currentFilter == 'withdraw',
                  onSelected: () => setState(() => currentFilter = 'withdraw'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'All Transactions',
                  isSelected: currentFilter == 'all',
                  onSelected: () => setState(() => currentFilter = 'all'),
                ),
              ],
            ),
          ),
          Expanded(
            child: historyAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    return TransactionListItem(
                      transaction: transactions[index],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF15306C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF15306C) : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF15306C).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
