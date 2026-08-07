import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

class AppleSignInButton extends StatefulWidget {
  final Function? callback;
  const AppleSignInButton({
    super.key,
    this.callback,
  });
  @override
  State<AppleSignInButton> createState() => _AppleSignInButtonState();
}

class _AppleSignInButtonState extends State<AppleSignInButton> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return GestureDetector(
      onTap: () {
        setState(() {
          loading = true;
        });
        Future.delayed(const Duration(seconds: 1), () async {
          await auth.signInWithApple();
          setState(() {
            loading = false;
          });
          if (widget.callback != null) widget.callback!();
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/apple.png',
                        width: 22, height: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Sign in with Apple',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
