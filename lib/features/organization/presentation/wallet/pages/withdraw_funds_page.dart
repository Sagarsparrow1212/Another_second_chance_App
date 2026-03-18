import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/widgets/custom_appbar.dart';
import '../../dashboard/providers/payment_provider.dart';
import '../providers/organization_wallet_provider.dart';
import 'transaction_history_page.dart';

class WithdrawFundsPage extends ConsumerStatefulWidget {
  final double withdrawableAmount;

  const WithdrawFundsPage({super.key, required this.withdrawableAmount});

  @override
  ConsumerState<WithdrawFundsPage> createState() => _WithdrawFundsPageState();
}

class _WithdrawFundsPageState extends ConsumerState<WithdrawFundsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  String _amountWords = "Zero Dollars";
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateAmount(String value) {
    if (value.isEmpty) {
      setState(() {
        _amountWords = "Zero Dollars";
        _isButtonEnabled = false;
      });
      return;
    }

    final amount = double.tryParse(value) ?? 0.0;

    // Get available balance from provider
    final connectBalanceAsync = ref.read(connectBalanceProvider);
    double availableLimit = widget.withdrawableAmount;

    connectBalanceAsync.whenData((balance) {
      if (balance != null) {
        final stripeAvailable =
            (balance['available'] as num?)?.toDouble() ?? 0.0;
        // Use the minimum of app logic amount and actual Stripe available amount
        if (stripeAvailable < availableLimit) {
          availableLimit = stripeAvailable;
        }
      }
    });

    // amount is greater than the allowed limit
    if (amount > availableLimit) {
      setState(() {
        _amountController.text = availableLimit.toStringAsFixed(2);
        _amountWords = usdToWords(availableLimit);
        _isButtonEnabled = availableLimit > 0;
        // Move cursor to end
        _amountController.selection = TextSelection.fromPosition(
          TextPosition(offset: _amountController.text.length),
        );
      });
      return;
    }

    // Validate amount
    final bool isValid = amount > 0 && amount <= availableLimit;

    setState(() {
      _amountWords = usdToWords(amount);
      _isButtonEnabled = isValid;
    });

    _animationController.reset();
    _animationController.forward();
  }

  String usdToWords(double amount) {
    if (amount == 0) return "Zero Dollars";

    int dollars = amount.floor();
    int cents = ((amount - dollars) * 100).round();

    String dollarWords = _numberToWords(dollars);
    String centWords = cents > 0 ? _numberToWords(cents) : "";

    String result = "";

    if (dollars > 0) {
      result += "$dollarWords ${dollars == 1 ? 'Dollar' : 'Dollars'}";
    }

    if (cents > 0) {
      if (dollars > 0) {
        result += " and ";
      }
      result += "$centWords ${cents == 1 ? 'Cent' : 'Cents'}";
    }

    return result;
  }

  String _numberToWords(int number) {
    final units = [
      "Zero",
      "One",
      "Two",
      "Three",
      "Four",
      "Five",
      "Six",
      "Seven",
      "Eight",
      "Nine",
      "Ten",
      "Eleven",
      "Twelve",
      "Thirteen",
      "Fourteen",
      "Fifteen",
      "Sixteen",
      "Seventeen",
      "Eighteen",
      "Nineteen",
    ];

    final tens = [
      "",
      "",
      "Twenty",
      "Thirty",
      "Forty",
      "Fifty",
      "Sixty",
      "Seventy",
      "Eighty",
      "Ninety",
    ];

    if (number < 20) return units[number];

    if (number < 100) {
      return tens[number ~/ 10] +
          (number % 10 != 0 ? "-${units[number % 10]}" : "");
    }

    if (number < 1000) {
      return "${units[number ~/ 100]} Hundred" +
          (number % 100 != 0 ? " ${_numberToWords(number % 100)}" : "");
    }

    if (number < 1000000) {
      return "${_numberToWords(number ~/ 1000)} Thousand" +
          (number % 1000 != 0 ? " ${_numberToWords(number % 1000)}" : "");
    }

    if (number < 1000000000) {
      return "${_numberToWords(number ~/ 1000000)} Million" +
          (number % 1000000 != 0 ? " ${_numberToWords(number % 1000000)}" : "");
    }

    return "${_numberToWords(number ~/ 1000000000)} Billion" +
        (number % 1000000000 != 0
            ? " ${_numberToWords(number % 1000000000)}"
            : "");
  }

  Future<void> _handleWithdraw() async {
    final amountText = _amountController.text;
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) return;

    setState(() {
      _isLoading = true;
      _isButtonEnabled = false;
    });

    try {
      final withdraw = ref.read(withdrawFundsProvider);
      await withdraw(amount);

      // Give the backend a little time to process the Stripe withdrawal
      await Future.delayed(const Duration(seconds: 2));

      // Refresh providers to fetch updated balance
      ref.invalidate(organizationWalletDetailsProvider);
      ref.invalidate(connectBalanceProvider);

      await ref.read(organizationWalletDetailsProvider.future);
      await ref.read(connectBalanceProvider.future);

      if (mounted) {
        // Show redesigned success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green.shade600,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Transfer Successful',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your withdrawal has been processed\nsuccessfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.lightSubText,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Amount',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.lightSubText,
                              ),
                            ),
                            Text(
                              '\$${amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.lightText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.lightSubText,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade500,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'COMPLETED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back to wallet page
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'BACK TO WALLET',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isButtonEnabled = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectBalanceAsync = ref.watch(connectBalanceProvider);
    final walletAsync = ref.watch(organizationWalletDetailsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light grey background
      appBar: const CustomAppBar(
        title: 'Withdraw Amount',
        showBackButton: true,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isButtonEnabled && !_isLoading)
                  ? _handleWithdraw
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: (_isButtonEnabled && !_isLoading)
                    ? AppTheme.primary
                    : Colors.grey[200],
                foregroundColor: (_isButtonEnabled && !_isLoading)
                    ? Colors.white
                    : Colors.grey[500],
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('PROCEED'),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Net Wallet Balance',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.lightSubText,
                        ),
                      ),
                      const Spacer(),
                      walletAsync.when(
                        data: (walletData) => Text(
                          '\$${walletData.wallet.currentBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightText,
                          ),
                        ),
                        loading: () => const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (_, __) => Text(
                          '\$${widget.withdrawableAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  connectBalanceAsync.when(
                    data: (balance) {
                      if (balance == null) return const SizedBox.shrink();

                      final available =
                          (balance['available'] as num?)?.toDouble() ?? 0.0;
                      final pending =
                          (balance['pending'] as num?)?.toDouble() ?? 0.0;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Available Balance',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                Text(
                                  '\$${available.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Pending',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                                Text(
                                  '\$${pending.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Stripe fees are deducted before payout.',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade700,
                                fontStyle: FontStyle.italic,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    error: (error, stack) => Text(
                      'Could not load balance details',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade300,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter Amount',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.lightSubText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _amountController,
                    onChanged: _updateAmount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.0',
                      prefixIcon: const Icon(
                        Icons.attach_money,
                        size: 24,
                        color: Colors.black87,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Text(
                      _amountWords,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.lightSubText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Container(
                  //   padding: const EdgeInsets.all(12),
                  //   decoration: BoxDecoration(
                  //     color: const Color(0xFFFFF8E1), // Light yellow bg
                  //     borderRadius: BorderRadius.circular(8),
                  //   ),
                  //   child: Row(
                  //     children: [
                  //       const Icon(
                  //         Icons.info_outline,
                  //         color: Colors.orange,
                  //         size: 20,
                  //       ),
                  //       const SizedBox(width: 12),
                  //       Expanded(
                  //         child: Text(
                  //           'Learn how your withdrawable amount and unsettled balance are calculated',
                  //           style: TextStyle(
                  //             fontSize: 12,
                  //             color: AppTheme.lightText.withOpacity(0.8),
                  //           ),
                  //         ),
                  //       ),
                  //       const Icon(
                  //         Icons.chevron_right,
                  //         color: Colors.black54,
                  //         size: 20,
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Transactions Link
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Transactions',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'History of funds withdrawn',
                  style: TextStyle(fontSize: 12, color: AppTheme.lightSubText),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WithdrawalHistoryPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Footer Information
          ],
        ),
      ),
    );
  }
}
