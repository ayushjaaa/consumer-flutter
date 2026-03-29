import 'package:flutter/material.dart';
import 'package:onetap365app/core/constants/app_colors.dart';
import 'package:onetap365app/data/repositories/auth_repository.dart';
import 'package:onetap365app/features/auth/screens/signup_info_screen.dart';

import '../widgets/otp_input_field.dart';
import '../widgets/success_otp.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final int _otpLength = 4;
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final AuthRepository _authRepository = AuthRepository();

  bool get _isOtpComplete => _controllers.every((c) => c.text.isNotEmpty);

  bool _isVerifying = false; // shows loader
  bool _isVerified = false; // shows success checkmark

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _showVerificationSuccess() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "success",
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) {
        return const SizedBox();
      },
      transitionBuilder: (context, animation, _, __) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: FadeTransition(
            opacity: animation,
            child: const SuccessPopup(),
          ),
        );
      },
    );

    // Auto close after animation
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.of(context).pop(); // close success popup

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SignUpInfoScreen(
            phoneNumber: widget.phoneNumber,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              /// Header
              SizedBox(
                height: 56,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Center(
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              /// Title
              const Text(
                'Enter verification code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              /// Subtitle
              Text(
                'We have sent you a 4 digit verification code on\n+91 ${widget.phoneNumber}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              /// OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_otpLength, (index) {
                  return OtpBox(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    onChanged: (value) {
                      if (value.isNotEmpty && index < _otpLength - 1) {
                        _focusNodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      setState(() {});
                    },
                  );
                }),
              ),

              const SizedBox(height: 40),

              /// Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: _isVerified
                        ? AppColors.primary
                        : _isOtpComplete
                            ? AppColors.primary
                            : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ElevatedButton(
                    onPressed: (!_isOtpComplete || _isVerifying)
                        ? null
                        : () async {
                            final otp = _controllers.map((c) => c.text).join();

                            setState(() => _isVerifying = true);

                            try {
                              final result = await _authRepository.verifyOtp(
                                phoneNumber: widget.phoneNumber,
                                otp: otp,
                              );

                              if (!mounted) return;

                              if (result['success']) {
                                setState(() {
                                  _isVerifying = false;
                                  _isVerified = true;
                                });

                                _showVerificationSuccess();
                              } else {
                                setState(() => _isVerifying = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ??
                                        'OTP verification failed'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              setState(() => _isVerifying = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error: ${e.toString()}')),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isVerifying
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : _isVerified
                              ? const Icon(
                                  Icons.check_rounded,
                                  key: ValueKey('success'),
                                  color: Colors.white,
                                  size: 28,
                                )
                              : const Text(
                                  'Submit',
                                  key: ValueKey('text'),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// Resend
              Center(
                child: GestureDetector(
                  onTap: () async {
                    try {
                      final result =
                          await _authRepository.resendOtp(widget.phoneNumber);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              result['message'] ?? 'OTP resent successfully'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: "I didn't receive the code! ",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'Resend',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
}
