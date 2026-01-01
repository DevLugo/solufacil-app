import 'package:flutter/material.dart';
import '../../data/models/loan.dart';
import 'loan_card.dart';

class LoansList extends StatelessWidget {
  final List<Loan> loans;
  final bool isCollateral;

  const LoansList({
    super.key,
    required this.loans,
    this.isCollateral = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: loans.length,
      itemBuilder: (context, index) {
        return LoanCard(
          loan: loans[index],
          isCollateral: isCollateral,
        );
      },
    );
  }
}
