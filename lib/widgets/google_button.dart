import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

class GoogleSignInButton extends StatefulWidget {
  final Function? callback;
  const GoogleSignInButton({
    super.key,
    this.callback,
  });
  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
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
          await auth.signInWithGoogle();
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
                    Image.asset('assets/images/google.png',
                        width: 20, height: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Sign in with Google',
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
