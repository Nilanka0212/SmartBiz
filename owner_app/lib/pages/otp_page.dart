import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_services.dart';
import 'dashboard_page.dart';

class OtpPage extends StatefulWidget {
  final String ownerId;
  final String phone;
  final String? dummyOtp;

  const OtpPage({
    super.key,
    required this.ownerId,
    required this.phone,
    this.dummyOtp,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());
  bool _isLoading  = false;
  int _secondsLeft = 180; // 2 minutes

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes){
    f.dispose();
    super.dispose();
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _secondsLeft > 0) {
        setState(() => _secondsLeft--);
        _startTimer();
      }
    });
  }

  String get _timerText {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _otpValue =>
      _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
  if (_otpValue.length < 6) {
    _showError('Please enter complete 6 digit OTP');
    return;
  }

  setState(() => _isLoading = true);

  final result = await ApiService.verifyOtp(
    ownerId: widget.ownerId,
    otp:     _otpValue,
  );

  setState(() => _isLoading = false);

  if (result['data']['success'] == true) {
    // ── Save login session ──
    await AuthService.saveLogin(
      token: result['data']['token'],
      owner: Map<String, dynamic>.from(
          result['data']['owner']),
    );

    if (!mounted) return;

    // ── Go to dashboard ──
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardPage(
          owner: Map<String, dynamic>.from(
              result['data']['owner']),
        ),
      ),
      (route) => false,
    );
  } else {
    _showError(
        result['data']['message'] ?? 'Invalid OTP');
  }
}

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: const Text('OTP Verification',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false, // no back button
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),

                // Icon
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.orange, width: 2),
                  ),
                  child: const Icon(Icons.sms,
                      color: Colors.orange, size: 44),
                ),

                const SizedBox(height: 24),

                const Text('Enter OTP',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'We sent a 6 digit code to\n${widget.phone}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.black54, fontSize: 14),
                ),

                // Show test OTP
                if (widget.dummyOtp != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.science,
                            color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Test OTP: ${widget.dummyOtp}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 36),

                // OTP boxes
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (i) => _otpBox(i)),
                ),

                const SizedBox(height: 24),

                // Timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: _secondsLeft > 60
                          ? Colors.black45
                          : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _secondsLeft > 0
                          ? 'OTP expires in $_timerText'
                          : 'OTP expired!',
                      style: TextStyle(
                        color: _secondsLeft > 60
                            ? Colors.black54
                            : Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // Verify button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading || _secondsLeft == 0
                        ? null
                        : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14)),
                    ),
                    child: const Text('Verify OTP',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 16),

                // Resend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Didn't receive OTP?  ",
                        style: TextStyle(
                            color: Colors.black54,
                            fontSize: 13)),
                    GestureDetector(
                      onTap: _secondsLeft == 0
                          ? () {
                              
                            }
                          : null,
                      child: Text(
                        'Resend',
                        style: TextStyle(
                          color: _secondsLeft == 0
                              ? Colors.orange
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(
                    color: Colors.orange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 48, height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: Colors.orange, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
          if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          // Auto verify when all 6 digits entered
          if (_otpValue.length == 6) {
            _verifyOtp();
          }
        },
      ),
    );
  }
}