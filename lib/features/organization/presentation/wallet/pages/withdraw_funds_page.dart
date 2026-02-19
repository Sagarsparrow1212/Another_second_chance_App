import 'package:flutter/material.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/widgets/custom_appbar.dart';

class WithdrawFundsPage extends StatefulWidget {
  final double withdrawableAmount;

  const WithdrawFundsPage({super.key, required this.withdrawableAmount});

  @override
  State<WithdrawFundsPage> createState() => _WithdrawFundsPageState();
}

class _WithdrawFundsPageState extends State<WithdrawFundsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  String _amountWords = "Zero Dollars";
  bool _isButtonEnabled = false;
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

    // Validate amount
    final bool isValid = amount > 0 && amount <= widget.withdrawableAmount;

    // amount is greater than withdrawable amount
    if (amount > widget.withdrawableAmount) {
      setState(() {
        //amount = widget.withdrawableAmount;
        _amountController.text = widget.withdrawableAmount.toStringAsFixed(2);
        _amountWords = usdToWords(widget.withdrawableAmount);
        // _isButtonEnabled = false;
      });
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light grey background
      appBar: const CustomAppBar(
        title: 'Withdraw Amount',
        showBackButton: true,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isButtonEnabled
                  ? () {
                      // TODO: Implement withdraw action
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isButtonEnabled
                    ? AppTheme.primary
                    : Colors.grey[200],
                foregroundColor: _isButtonEnabled
                    ? Colors.white
                    : Colors.grey[500],
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('PROCEED'),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                        'Withdrawable Amount',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.lightSubText,
                        ),
                      ),
                      // const SizedBox(width: 4),
                      // Icon(
                      //   Icons.info_outline,
                      //   size: 16,
                      //   color: AppTheme.lightSubText,
                      // ),
                      const Spacer(),
                      Text(
                        '\$ ${widget.withdrawableAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enter Amount',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.lightSubText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    //initialValue: '0',
                    //  placeholder: '0.0',
                    controller: _amountController,
                    onChanged: _updateAmount,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.0',
                      prefixIcon: const Icon(
                        Icons.attach_money,
                        size: 28,
                        color: Colors.black,
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
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1), // Light yellow bg
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Learn how your withdrawable amount and unsettled balance are calculated',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.lightText.withOpacity(0.8),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.black54,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Transactions Link
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
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
                onTap: () {},
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
