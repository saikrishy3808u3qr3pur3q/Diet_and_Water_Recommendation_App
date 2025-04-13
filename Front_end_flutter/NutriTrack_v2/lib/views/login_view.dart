import 'package:flutter/material.dart';
import 'package:nutritrack_v2/views/signup_view.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'dashboard_view.dart';
import 'update_view.dart';

class LoginView extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF0DF),
      appBar: AppBar(
        title: Text(
          "",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Color.fromRGBO(247, 186, 106, 1),
        iconTheme: IconThemeData(
          color: Colors.white, // Change this to your desired color
        ),
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss the keyboard when tapping outside the input fields
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight, // Prevents overflow
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: screenHeight * 0.05),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!keyboardVisible) ...[
                      Text(
                        "Welcome Back!",
                        style: TextStyle(
                          fontSize: screenHeight * 0.08,
                          color: Color.fromRGBO(232, 134, 7, 1),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.start,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                    Text(
                      "Enter your email and password to continue your nutritious journey!",
                      style: TextStyle(
                        fontSize: screenHeight * 0.02,
                        color: Color.fromRGBO(232, 134, 7, 1),
                      ),
                      textAlign: TextAlign.start,
                    ),
                    SizedBox(height: screenHeight * 0.05),

                    // Email Field
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle: TextStyle(color: Colors.orange),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color.fromRGBO(247, 186, 106, 1), width: 2.0),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color.fromRGBO(232, 134, 7, 1), width: 2.5),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // Password Field
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: TextStyle(color: Colors.orange),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color.fromRGBO(247, 186, 106, 1), width: 2.0),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color.fromRGBO(232, 134, 7, 1), width: 2.5),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Login Button
                    Container(
                      width: 120,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          bool success = await authViewModel.login(
                            emailController.text,
                            passwordController.text,
                          );
                          if (success) {
                            Navigator.pushReplacementNamed(context, '/mainApp');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Login Failed")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(255, 209, 150, 1),
                        ),
                        child: Text(
                          "Login",
                          style: TextStyle(
                            color: Color.fromRGBO(232, 134, 7, 1),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),

                    // Forgot Password Button
                    TextButton(
                      onPressed: () async {
                        if (emailController.text.isNotEmpty) {
                          bool success = await authViewModel.resetPassword(emailController.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? "Password reset link sent to your email"
                                  : "Failed to send reset link"),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Enter your email first")),
                          );
                        }
                      },
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: Color.fromRGBO(232, 134, 7, 1),
                          fontSize: 16,
                        ),
                      ),
                    ),

                    // Sign Up Button
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignUpView()),
                        );
                      },
                      child: Text(
                        "Don't have an account? Sign Up",
                        style: TextStyle(
                          color: Color.fromRGBO(232, 134, 7, 1),
                          fontSize: 16,
                        ),
                      ),
                    ),

                    // Prevent Overflow by pushing content up
                    Expanded(child: Container()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
