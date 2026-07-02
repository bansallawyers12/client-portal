import 'dart:io';

import 'package:client/utils/app_loader.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:pay/pay.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/stripe_config.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/stripe_service.dart';
import '../../../utils/payment_config.dart';
import '../../../utils/responsive_utils.dart';
import 'book_appointment_success_screen.dart';
import 'booking_widget.dart';

class BookConfirmAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> selectedOptions;

  const BookConfirmAppointmentScreen({
    super.key,
    required this.selectedOptions,
  });

  @override
  State<BookConfirmAppointmentScreen> createState() =>
      _BookConfirmAppointmentScreenState();
}

class _BookConfirmAppointmentScreenState
    extends State<BookConfirmAppointmentScreen> {
  bool isLoading = false;
  bool isLoadingWallet = false;
  bool isProcessingPayment = false;

  Future<void> _handleWalletPayment(Map<String, dynamic> result) async {
    setState(() {
      isLoadingWallet = true;
    });

    try {
      final paymentToken =
          result['paymentMethodData']?['tokenizationData']?['token'] ??
          result.toString();

      final appointmentResponse = await _createAppointmentWithoutLogin();

      final appointmentId = appointmentResponse['data']['id'];

      if (appointmentId != null) {
        AuthService.isAuthenticated
            ? await ApiService.recordPaymentWallet(
              appointmentId: appointmentId,
              paymentIntentId: paymentToken,
              paymentType:
                  defaultTargetPlatform == TargetPlatform.iOS
                      ? "apple_pay"
                      : "gpay",
            )
            : await ApiService.recordPaymentWalletWithoutLogin(
              appointmentId: appointmentId,
              paymentIntentId: paymentToken,
              paymentType:
                  defaultTargetPlatform == TargetPlatform.iOS
                      ? "apple_pay"
                      : "gpay",
            );
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => BookAppointmentSuccessScreen(data: appointmentResponse),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Wallet payment failed: $e")));
    } finally {
      setState(() {
        isLoadingWallet = false;
      });
    }
  }

  Future<Map<String, dynamic>> _createAppointmentWithoutLogin() async {
    final serviceId =
        int.tryParse(widget.selectedOptions['service_id'].toString()) ?? 0;
    final noeId =
        int.tryParse(widget.selectedOptions['noe_id'].toString()) ?? 0;
    final inPersonAddress =
        int.tryParse(
          widget.selectedOptions['inperson_address']?.toString() ?? '0',
        ) ??
        0;
    final appointmentDetails =
        int.tryParse(
          widget.selectedOptions['appointment_details']?.toString() ?? '0',
        ) ??
        0;
    final preferredLanguage =
        int.tryParse(
          widget.selectedOptions['preferred_language']?.toString() ?? '0',
        ) ??
        0;

    final response = await ApiService.createAppointmentWithoutLogin(
      noeId: noeId,
      serviceId: serviceId,
      appointDate: widget.selectedOptions['appoint_date'],
      appointTime: widget.selectedOptions['appoint_time'],
      description: widget.selectedOptions['description'],
      appointmentDetails: appointmentDetails,
      preferredLanguage: preferredLanguage,
      inPersonAddress: inPersonAddress,
      fullName: widget.selectedOptions['full_name'] ?? '',
      email: widget.selectedOptions['email'] ?? '',
      phone: widget.selectedOptions['phone'] ?? '',
      countryCode: widget.selectedOptions['country_code'] ?? '"+61"',
    );

    return response;
  }

  Future<void> _handlePaymentAndCreateAppointment() async {
    final price = widget.selectedOptions['service_price'] ?? 0;

    setState(() {
      isLoading = true;
      isProcessingPayment = true;
    });

    try {
      String? paymentMethodId;

      if (price != 0) {
        // macOS → Stripe Checkout in browser
        if (!kIsWeb && Platform.isMacOS) {
          await _handleMacOSPayment();
          return; // navigation handled inside _handleMacOSPayment
        }

        final amountInMinorUnit = StripeService.amountToMinorUnit(
          price.toDouble(),
        );

        final paymentIntent = await StripeService.createPaymentIntent(
          amountInMinorUnit: amountInMinorUnit,
          currency: StripeConfig.defaultCurrency.toLowerCase(),
          description:
              'Appointment payment for ${widget.selectedOptions['service_name']}',
          metadata: {
            'service_id':
                widget.selectedOptions['service_id']?.toString() ?? '',
            'appointment_date':
                widget.selectedOptions['appoint_date']?.toString() ?? '',
            'appointment_time':
                widget.selectedOptions['appoint_time']?.toString() ?? '',
          },
        );

        final clientSecret = paymentIntent['client_secret'];
        if (clientSecret == null || clientSecret.isEmpty) {
          throw Exception('Missing Stripe client secret');
        }

        if (kIsWeb) {
          await _handleStripeWebPayment(clientSecret);
        } else {
          await StripeService.presentPayment(
            context: context,
            clientSecret: clientSecret,
          );
        }

        paymentMethodId = paymentIntent['id'];
      }

      final appointmentResponse = await _createAppointmentWithoutLogin();

      final appointmentId = appointmentResponse['data']['id'];

      if (appointmentId != null && paymentMethodId != null) {
        AuthService.isAuthenticated
            ? await ApiService.recordAppointmentPayment(
              appointmentId: appointmentId,
              paymentIntentId: paymentMethodId,
            )
            : await ApiService.recordAppointmentPaymentWithoutLogin(
              appointmentId: appointmentId,
              paymentIntentId: paymentMethodId,
            );
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => BookAppointmentSuccessScreen(data: appointmentResponse),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    } finally {
      setState(() {
        isLoading = false;
        isProcessingPayment = false;
      });
    }
  }

  Future<void> _handleMacOSPayment() async {
    final price = widget.selectedOptions['service_price'] ?? 0;

    try {
      setState(() {
        isLoading = true;
        isProcessingPayment = true;
      });

      final session = await StripeService.createCheckoutSession(
        amount: price,
        currency: StripeConfig.defaultCurrency.toLowerCase(),
        serviceName: widget.selectedOptions['service_name'] ?? '',
        customerEmail: widget.selectedOptions['email'] ?? '',
      );

      final sessionId = session['session_id'];
      final url = Uri.parse(session['checkout_url']);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open Stripe Checkout');
      }

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const Text('Complete Payment'),
              content: const Text(
                'Please complete the payment in your browser.\n\n'
                'Click "I have paid" once payment is complete.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F3C88),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('I have paid'),
                ),
              ],
            ),
      );

      if (confirmed != true) {
        setState(() {
          isLoading = false;
          isProcessingPayment = false;
        });
        return;
      }

      final verified = await _verifyWithRetry(sessionId);

      if (verified['payment_status'] != 'paid') {
        throw Exception('Payment not completed. Please try again.');
      }

      await _onPaymentSuccess(sessionId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
      setState(() {
        isLoading = false;
        isProcessingPayment = false;
      });
    }
  }

  Future<Map<String, dynamic>> _verifyWithRetry(
    String sessionId, {
    int maxRetries = 3,
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final result = await StripeService.verifyCheckoutSession(
          sessionId: sessionId,
        );
        if (result['payment_status'] == 'paid') {
          return result;
        }
        if (i < maxRetries - 1) {
          await Future.delayed(const Duration(seconds: 2));
        }
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception('Payment not completed. Please try again.');
  }

  Future<void> _onPaymentSuccess(String? sessionId) async {
    try {
      /*final appointmentResponse = AuthService.isAuthenticated
          ? await _createAppointment()
          : await _createAppointmentWithoutLogin();*/
      final appointmentResponse = await _createAppointmentWithoutLogin();

      final appointmentId = appointmentResponse['data']['id'];

      if (appointmentId != null && sessionId != null) {
        AuthService.isAuthenticated
            ? await ApiService.recordAppointmentPayment(
              appointmentId: appointmentId,
              paymentIntentId: sessionId,
            )
            : await ApiService.recordAppointmentPaymentWithoutLogin(
              appointmentId: appointmentId,
              paymentIntentId: sessionId,
            );
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => BookAppointmentSuccessScreen(data: appointmentResponse),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    } finally {
      setState(() {
        isLoading = false;
        isProcessingPayment = false;
      });
    }
  }

  Future<void> _handleStripeWebPayment(String clientSecret) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter Card Details"),
          content: const CardField(),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await Stripe.instance.confirmPayment(
                    paymentIntentClientSecret: clientSecret,
                    data: const PaymentMethodParams.card(
                      paymentMethodData: PaymentMethodData(),
                    ),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  Navigator.pop(context);
                  throw Exception(e.toString());
                }
              },
              child: const Text("Pay"),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade200);

  @override
  Widget build(BuildContext context) {
    final opts = widget.selectedOptions;
    final price = opts['service_price'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: const BookingAppBar(title: 'Confirm Your Appointment'),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppResponsive.maxContentWidth,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _detailRow('Full Name', opts['full_name'] ?? '-'),
                        _divider(),
                        _detailRow('Email', opts['email'] ?? '-'),
                        _divider(),
                        _detailRow('Phone', opts['phone'] ?? '-'),
                        _divider(),
                        _detailRow('Location', opts['location_name'] ?? '-'),
                        _divider(),
                        _detailRow('Meeting Type', opts['meeting_type'] ?? '-'),
                        _divider(),
                        _detailRow('Service', opts['service_name'] ?? '-'),
                        _divider(),
                        _detailRow(
                          'Date & Time',
                          '${opts['appoint_date']} at ${opts['appoint_time']}',
                        ),
                        _divider(),
                        _detailRow(
                          'Enquiry Details',
                          opts['description'] ?? '-',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Wallet buttons (iOS / Android only — not macOS) ──────────
                  if (price != 0 && !kIsWeb && !Platform.isMacOS) ...[
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child:
                            Platform.isIOS
                                ? AbsorbPointer(
                                  absorbing: isLoadingWallet,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ApplePayButton(
                                        paymentConfiguration:
                                            PaymentConfiguration.fromJsonString(
                                              applePayConfig,
                                            ),
                                        paymentItems: [
                                          PaymentItem(
                                            label: opts['service_name'],
                                            amount: price.toString(),
                                            status:
                                                PaymentItemStatus.final_price,
                                          ),
                                        ],
                                        width: double.infinity,
                                        height: 50,
                                        onPaymentResult: _handleWalletPayment,
                                      ),
                                      if (isLoadingWallet) const AppLoader(),
                                    ],
                                  ),
                                )
                                : AbsorbPointer(
                                  absorbing: isLoadingWallet,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      GooglePayButton(
                                        paymentConfiguration:
                                            PaymentConfiguration.fromJsonString(
                                              googlePayConfig,
                                            ),
                                        paymentItems: [
                                          PaymentItem(
                                            label: opts['service_name'],
                                            amount: price.toString(),
                                            status:
                                                PaymentItemStatus.final_price,
                                          ),
                                        ],
                                        width: double.infinity,
                                        height: 50,
                                        onPaymentResult: _handleWalletPayment,
                                      ),
                                      if (isLoadingWallet) const AppLoader(),
                                    ],
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(child: Text("OR")),
                    const SizedBox(height: 12),
                  ],

                  // ── Pay & Submit button ───────────────────────────────────────
                  NextButton(
                    label:
                        price == 0
                            ? 'Submit'
                            : 'Pay & Submit (\$${price.toStringAsFixed(2)})',
                    isLoading: isLoading || isProcessingPayment,
                    onTap:
                        (isLoading || isProcessingPayment)
                            ? null
                            : _handlePaymentAndCreateAppointment,
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
