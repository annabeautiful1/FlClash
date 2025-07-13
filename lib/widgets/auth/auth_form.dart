import 'package:flutter/material.dart';

class AuthForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final String title;
  final Widget? titleIcon;
  final CrossAxisAlignment crossAxisAlignment;
  final double maxWidth;

  const AuthForm({
    super.key,
    required this.formKey,
    required this.children,
    required this.title,
    this.titleIcon,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.maxWidth = 400,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: const EdgeInsets.all(32),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: crossAxisAlignment,
                children: [
                  // Title Section
                  if (titleIcon != null) ...[
                    titleIcon!,
                    const SizedBox(height: 16),
                  ],
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Form Fields
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}