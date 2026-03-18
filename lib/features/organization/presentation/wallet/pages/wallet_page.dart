import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/Drawer/pages/dynamic_drawer.dart';
import 'package:homelyhope/features/common/widgets/custom_appbar.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import '../providers/organization_wallet_provider.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/wallet_balance_card.dart';
import 'withdraw_funds_page.dart';
import 'transaction_history_page.dart';

class OrganizationWalletPage extends ConsumerWidget {
  const OrganizationWalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    final walletAsync = ref.watch(organizationWalletDetailsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(),
      appBar: const CustomAppBar(title: 'My Wallet'),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: topPadding + 80,
          left: 20,
          right: 20,
          bottom: 20,
        ),
        child: walletAsync.when(
          data: (data) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WalletBalanceCard(
                  currentBalance: data.wallet.currentBalance,
                  totalEarnings: data.wallet.totalEarnings,
                  totalWithdrawn: data.wallet.totalWithdrawn,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WithdrawFundsPage(
                            withdrawableAmount: data.wallet.currentBalance,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Withdraw Amount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightText,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WithdrawalHistoryPage(
                              initialFilter: 'all',
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (data.recentTransactions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No transactions found',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  )
                else
                  ...data.recentTransactions.map(
                    (transaction) =>
                        TransactionListItem(transaction: transaction),
                  ),
              ],
            );
          },
          loading: () => SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: const Center(child: AppLoader()),
          ),
          error: (err, stack) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: $err'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        ref.refresh(organizationWalletDetailsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
