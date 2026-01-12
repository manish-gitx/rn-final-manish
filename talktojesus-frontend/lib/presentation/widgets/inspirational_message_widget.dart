import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InspirationalMessageWidget extends StatelessWidget {
  final String message;

  const InspirationalMessageWidget({
    super.key,
    this.message = 'I will help you develop self-control "For the grace of God has appeared, bringing salvation for all people..."',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 268,
      padding: const EdgeInsets.only(
        top: 12,
        left: 12,
        right: 12,
        bottom: 16,
      ),
      decoration: ShapeDecoration(
        color: const Color(0x7F45362F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.50,
                letterSpacing: -0.28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}