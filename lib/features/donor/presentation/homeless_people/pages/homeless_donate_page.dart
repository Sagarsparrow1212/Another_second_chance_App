import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/providers/snackbar_provider.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/widgets/custom_appbar.dart';
import 'package:homelyhope/features/common/widgets/divider.dart';
import 'package:homelyhope/features/donor/data/datasources/homeless_people/homeless_remote_datasource.dart';

import 'package:homelyhope/features/donor/data/models/payment/payment_success_request.dart';
import 'package:homelyhope/features/donor/presentation/payment/providers/payment_provider.dart';
import 'package:homelyhope/features/donor/presentation/dashboard/providers/donor_dashboard_provider.dart';
import 'package:http/http.dart' as http;

class DonorHomelessDonatePage extends ConsumerStatefulWidget {
  final HomelessPerson homeless;

  const DonorHomelessDonatePage({super.key, required this.homeless});

  @override
  ConsumerState<DonorHomelessDonatePage> createState() =>
      _DonorHomelessDonatePageState();
}

class _DonorHomelessDonatePageState
    extends ConsumerState<DonorHomelessDonatePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _paymentMethodController =
      TextEditingController();
  final TextEditingController _transactionIdController =
      TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _paymentMethodController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

  String? _buildImageUrl(String? profilePicture) {
    if (profilePicture == null || profilePicture.isEmpty) {
      return null;
    }

    if (profilePicture.startsWith('http://') ||
        profilePicture.startsWith('https://')) {
      return profilePicture;
    } else if (profilePicture.startsWith('/')) {
      return '$baseUrl$profilePicture';
    } else {
      return '$baseUrl/$profilePicture';
    }
  }

  Future<void> makePayment() async {
    try {
      setState(() {
        _isSubmitting = true;
      });
      final headers = await getHeaders();
      // 1️⃣ Call backend
      final response = await http.post(
        Uri.parse("$apiBaseUrl/payments/create-payment-intent"),
        headers: headers,
        body: jsonEncode({
          'amount': double.parse(_amountController.text.trim()),
          'currency': 'usd',
        }),
      );

      final data = jsonDecode(response.body);

      // // 2️⃣ Initialize PaymentSheet
      //  Stripe.instance.initPaymentSheet(
      //   paymentSheetParameters: SetupPaymentSheetParameters(
      //     paymentIntentClientSecret: data['clientSecret'],
      //     merchantDisplayName: 'Test App',
      //   ),
      // );

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: data['clientSecret'],
          merchantDisplayName: 'My App',
          appearance: PaymentSheetAppearance(
            // 🔘 Primary Button Styling
            primaryButton: PaymentSheetPrimaryButtonAppearance(
              colors: PaymentSheetPrimaryButtonTheme(
                light: PaymentSheetPrimaryButtonThemeColors(
                  background: AppTheme.primary,
                  text: Colors.white,
                ),
                dark: PaymentSheetPrimaryButtonThemeColors(
                  background: AppTheme.primary,
                  text: Colors.white,
                ),
              ),
            ),

            // 🎨 Sheet Colors
            colors: PaymentSheetAppearanceColors(
              primary: AppTheme.primary, // highlights & focus
              background: AppTheme.lightBg, // sheet background
              componentBackground: Colors.white,
              componentBorder: AppTheme.primary.withOpacity(0.2),
              componentDivider: AppTheme.primary.withOpacity(0.15),

              primaryText: AppTheme.lightText,
              secondaryText: AppTheme.lightSubText,
              componentText: AppTheme.lightText,

              icon: AppTheme.primary,
              placeholderText: AppTheme.lightSubText,
              error: Colors.redAccent,
            ),

            // 🔲 Rounded Shapes
            shapes: PaymentSheetShape(
              borderRadius: 16,
              shadow: PaymentSheetShadowParams(color: Colors.black12),
            ),
          ),
        ),
      );

      // 3️⃣ Present PaymentSheet
      await Stripe.instance.presentPaymentSheet();

      // 4️⃣ Call Backend to Save Donation
      final request = PaymentSuccessRequest(
        paymentIntentId: data['paymentIntentId'] ?? '',
        homelessId: widget.homeless.id,
        donationType: 'Money',
        message: _descriptionController.text,
        isAnonymous: false,
      );

      await ref
          .read(paymentNotifierProvider.notifier)
          .confirmPaymentSuccess(request);

      // Invalidate dashboard stats to force refresh
      ref.invalidate(donorDashboardStatsProvider);

      setState(() {
        _isSubmitting = false;
      });
      debugPrint("✅ Payment successful");
      if (mounted) {
        ref.read(snackbarServiceProvider).showSuccess('Payment successful!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ref.read(snackbarServiceProvider).showError('Payment failed: $e');
        debugPrint("❌ Payment failed: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.homeless;
    final imageUrl = _buildImageUrl(person.profilePicture);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(title: 'Donate', showBackButton: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                      backgroundImage: imageUrl != null
                          ? NetworkImage(imageUrl)
                          : null,
                      child: imageUrl == null
                          ? Text(
                              person.fullName.isNotEmpty
                                  ? person.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            )
                          : null,
                    ),
                    Text(
                      person.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (person.gender != null)
                          _buildChip(
                            icon: Icons.person_outline,
                            label: person.gender!,
                          ),
                        if (person.age != null) ...[
                          const SizedBox(width: 6),
                          _buildChip(
                            icon: Icons.cake_outlined,
                            label: '${person.age} yrs',
                          ),
                        ],
                      ],
                    ),
                    if (person.location != null &&
                        person.location!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              person.location!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter donation amount',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        onChanged: (value) async {
                          await Future.delayed(
                            const Duration(milliseconds: 500),
                          );
                          if (value.isNotEmpty) {
                            if (_formKey.currentState!.validate()) {
                              setState(() {
                                _isSubmitting = false;
                              });
                            }
                          }
                        },
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          prefixText: '\$ ',
                          hintText: '50.00',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primary,
                              width: 1.5,
                            ),
                          ),

                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an amount';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Monthly support donation',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primary,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _paymentMethodController,
                        decoration: InputDecoration(
                          labelText: 'Payment Method (Optional)',
                          hintText: 'UPI, Bank Transfer, Cash, etc.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primary,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _transactionIdController,
                        decoration: InputDecoration(
                          labelText: 'Transaction ID (Optional)',
                          hintText: 'TXN123456789',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primary,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  if (_amountController.text == '') {
                                    ref
                                        .read(snackbarServiceProvider)
                                        .showInfo('Please enter a amount');
                                    return;
                                  }
                                  makePayment();
                                },
                          icon: _isSubmitting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: spinkitForButton(),
                                )
                              : const Icon(Icons.favorite),
                          label: Text(
                            _isSubmitting ? 'Submitting...' : 'Pay & Support',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              customDivider(),
              const SizedBox(height: 8),
              Text(
                textAlign: TextAlign.center,
                'Your support helps provide essentials, healthcare, and opportunities.',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
