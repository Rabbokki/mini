import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart'; // QR 코드 패키지 추가
import 'package:url_launcher/url_launcher.dart'; // 외부 앱 호출용
import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentWebView extends StatefulWidget {
  final String name;
  final int amount;
  final String buyerEmail;
  final String buyerName;

  const PaymentWebView({
    Key? key,
    required this.name,
    required this.amount,
    required this.buyerEmail,
    required this.buyerName,
  }) : super(key: key);

  @override
  _PaymentWebViewState createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  String? _paymentUrl;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    print('PaymentWebView 초기화');
    print('name: ${widget.name}');
    print('amount: ${widget.amount}');
    print('buyerEmail: ${widget.buyerEmail}');
    print('buyerName: ${widget.buyerName}');
    
    // 결제 URL 생성
    _generatePaymentUrl();
  }

  void _generatePaymentUrl() {
    final merchantUid = 'mid_${DateTime.now().millisecondsSinceEpoch}';
    final paymentUrl = 'https://example.com/payment/$merchantUid?amount=${widget.amount}&name=${Uri.encodeComponent(widget.name)}&email=${Uri.encodeComponent(widget.buyerEmail)}&buyer=${Uri.encodeComponent(widget.buyerName)}';
    
    setState(() {
      _paymentUrl = paymentUrl;
    });
    
    print('결제 URL 생성: $paymentUrl');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결제'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 결제 정보 카드
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💳 결제 정보',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow('상품명', widget.name),
                    _buildInfoRow('구매자', widget.buyerName),
                    _buildInfoRow('이메일', widget.buyerEmail),
                    _buildInfoRow('결제 금액', '${widget.amount.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},'
                    )}원'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 결제 방법 선택
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '결제 방법 선택',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildPaymentMethodButton(
                      '신용카드',
                      Icons.credit_card,
                      Colors.blue,
                      () => _launchPayment('card'),
                    ),
                    const SizedBox(height: 10),
                    _buildPaymentMethodButton(
                      '계좌이체',
                      Icons.account_balance,
                      Colors.green,
                      () => _launchPayment('trans'),
                    ),
                    const SizedBox(height: 10),
                    _buildPaymentMethodButton(
                      '가상계좌',
                      Icons.account_balance_wallet,
                      Colors.orange,
                      () => _launchPayment('vbank'),
                    ),
                    const SizedBox(height: 10),
                    _buildPaymentMethodButton(
                      '휴대폰',
                      Icons.phone_android,
                      Colors.purple,
                      () => _launchPayment('phone'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // QR 코드 섹션
            if (_paymentUrl != null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'QR 코드로 결제하기',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '다른 기기에서 QR 코드를 스캔하여 결제를 진행할 수 있습니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      QrImageView(
                        data: _paymentUrl!,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _launchPayment('qr'),
                        icon: const Icon(Icons.qr_code),
                        label: const Text('QR 코드로 결제'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            
            // 외부 브라우저로 결제
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      '외부 브라우저로 결제',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '기본 브라우저에서 결제 페이지를 열어 결제를 진행합니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _launchExternalBrowser(),
                      icon: _isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.open_in_browser),
                      label: Text(_isLoading ? '로딩 중...' : '브라우저에서 결제'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _launchPayment(String method) async {
    if (_paymentUrl == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 결제 방법에 따른 URL 수정
      String paymentUrl = _paymentUrl!;
      if (method != 'qr') {
        paymentUrl += '&method=$method';
      }
      
      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('결제 페이지 열기 성공: $paymentUrl');
        
        // 결제 완료 안내
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('결제 페이지가 열렸습니다. 결제를 완료한 후 앱으로 돌아와주세요.'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('결제 페이지 열기 실패');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('결제 페이지를 열 수 없습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('결제 페이지 열기 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _launchExternalBrowser() async {
    if (_paymentUrl == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 실제 결제 서비스 URL로 변경 (예: 아임포트, 토스페이먼츠 등)
      final paymentServiceUrl = 'https://payment.example.com/pay?' + 
        'merchant_uid=${DateTime.now().millisecondsSinceEpoch}' +
        '&amount=${widget.amount}' +
        '&name=${Uri.encodeComponent(widget.name)}' +
        '&buyer_email=${Uri.encodeComponent(widget.buyerEmail)}' +
        '&buyer_name=${Uri.encodeComponent(widget.buyerName)}';
      
      final uri = Uri.parse(paymentServiceUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('외부 브라우저에서 결제 페이지 열기 성공');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('브라우저에서 결제 페이지가 열렸습니다.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('외부 브라우저 열기 실패');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('브라우저를 열 수 없습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('외부 브라우저 열기 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 