import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/global_methods.dart';
import '../fetch_screen.dart';
import 'text_widget.dart';

class GoogleButton extends StatelessWidget {
  const GoogleButton({Key? key}) : super(key: key);

  Future<void> _googleSignIn(BuildContext context) async {
    try {
      // Show loading indicator
      GlobalMethods.showLoading(context, "Signing in with Google...");
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithGoogle();
      
      // Hide loading indicator
      if (context.mounted) {
        Navigator.of(context).pop(); // Remove loading dialog
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const FetchScreen(),
          ),
        );
      }
    } catch (error) {
      // Hide loading indicator if still showing
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      if (context.mounted) {
        GlobalMethods.errorDialog(
          subtitle: 'Google sign-in failed: ${error.toString()}', 
          context: context
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.blue,
      child: InkWell(
        onTap: () => _googleSignIn(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start, 
          children: [
            Container(
              color: Colors.white,
              child: Image.asset(
                'assets/images/google.png',
                width: 40.0,
              ),
            ),
            const SizedBox(width: 8),
            TextWidget(
                text: 'Sign in with Google', 
                color: Colors.white, 
                textSize: 18)
          ]
        ),
      ),
    );
  }
}
