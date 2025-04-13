import 'package:flutter/material.dart';
import 'login_view.dart';
import 'signup_view.dart';

class HomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF0DF),
      body: Column(
        children: [
          // Background Image (Covers 60% of the screen)
          const Expanded(
            flex: 1,
            child: Center(
              child: Text(
                "NutriTrack",
                style: TextStyle(
                  color: Color.fromRGBO(232,134,7,1),
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 4, // 3/5th of the screen
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/homepage_img.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Expanded(
              flex:1,
              child: Container(
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                        "Empowering healthier choices with personalized nutrition, hydration, and wellness tracking.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.fromRGBO(232,134,7,1),
                        fontWeight: FontWeight.normal,
                        fontSize: 17
                      ),
                    ),
                  ),
                ),
              )
          ),
          // Buttons Section (Covers 2/5th of the screen)
          Expanded(
            flex: 2, // 2/5th of the screen
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Sign In Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginView()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Color.fromRGBO(232,134,7,1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Sign In",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignUpView()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Color.fromRGBO(232,134,7,1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
