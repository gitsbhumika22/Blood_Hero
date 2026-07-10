import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../core/colors.dart';
import 'login_screen.dart';
import 'package:flutter/services.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final List<String> bloodGroups = [
    "A+","A-","B+","B-","AB+","AB-","O+","O-",
  ];

  String? selectedBloodGroup;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> registerUser() async {

    if (selectedBloodGroup == null ||
        nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      await FirebaseDatabase.instance.ref("users/$uid").set({
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "bloodGroup": selectedBloodGroup,
      });

      setState(() => isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );

    } on FirebaseAuthException catch (e) {

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Registration failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 80),

            const Text(
              "Create Account",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            _buildTextField("Full Name", Icons.person, nameController),
            const SizedBox(height: 20),

            _buildTextField("Email", Icons.email, emailController),
            const SizedBox(height: 20),

            _buildPhoneField(),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: selectedBloodGroup,
              decoration: const InputDecoration(
                labelText: "Select Blood Group",
              ),
              items: bloodGroups.map((group) {
                return DropdownMenuItem(
                  value: group,
                  child: Text(group),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedBloodGroup = value;
                });
              },
            ),

            const SizedBox(height: 20),

            _buildTextField("Password", Icons.lock,
                passwordController,
                isPassword: true),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: isLoading ? null : registerUser,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Register",
                  style: TextStyle(fontSize: 18)),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextField(
      controller: phoneController,
      keyboardType: TextInputType.phone,
      style: const TextStyle(color: AppColors.textPrimary),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: InputDecoration(
        labelText: "Phone Number",
        hintText: "Enter 10-digit mobile number",
        prefixIcon: Icon(Icons.phone, color: AppColors.primary),
        errorText: phoneController.text.isNotEmpty && phoneController.text.length != 10 
            ? "Phone number must be exactly 10 digits" 
            : phoneController.text.isNotEmpty && !RegExp(r'^[6-9]\d{9}$').hasMatch(phoneController.text)
                ? "Enter valid Indian mobile number"
                : null,
      ),
    );
  }

  Widget _buildTextField(
      String hint,
      IconData icon,
      TextEditingController controller,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}