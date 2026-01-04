import 'package:flutter_test/flutter_test.dart';
import 'package:solufacil_mobile/data/models/loan.dart';

void main() {
  group('LoanPayment', () {
    group('constructor', () {
      test('should create LoanPayment with required fields', () {
        final now = DateTime.now();
        final payment = LoanPayment(
          id: 'payment-123',
          amount: 500.0,
          type: 'NORMAL',
          paymentMethod: PaymentMethod.cash,
          receivedAt: now,
          loanId: 'loan-456',
          createdAt: now,
        );

        expect(payment.id, 'payment-123');
        expect(payment.amount, 500.0);
        expect(payment.comission, 0); // default value
        expect(payment.type, 'NORMAL');
        expect(payment.paymentMethod, PaymentMethod.cash);
        expect(payment.loanId, 'loan-456');
      });

      test('should create LoanPayment with comission', () {
        final now = DateTime.now();
        final payment = LoanPayment(
          id: 'payment-123',
          amount: 500.0,
          comission: 25.0,
          type: 'NORMAL',
          paymentMethod: PaymentMethod.moneyTransfer,
          receivedAt: now,
          loanId: 'loan-456',
          createdAt: now,
        );

        expect(payment.comission, 25.0);
        expect(payment.paymentMethod, PaymentMethod.moneyTransfer);
      });
    });

    group('fromRow', () {
      test('should parse valid row data', () {
        final row = {
          'id': 'payment-123',
          'amount': 750.5,
          'comission': 37.5,
          'type': 'NORMAL',
          'paymentMethod': 'CASH',
          'receivedAt': '2026-01-03T10:30:00.000Z',
          'loan': 'loan-456',
          'createdAt': '2026-01-03T10:30:00.000Z',
        };

        final payment = LoanPayment.fromRow(row);

        expect(payment.id, 'payment-123');
        expect(payment.amount, 750.5);
        expect(payment.comission, 37.5);
        expect(payment.type, 'NORMAL');
        expect(payment.paymentMethod, PaymentMethod.cash);
        expect(payment.loanId, 'loan-456');
      });

      test('should handle null values with defaults', () {
        final row = <String, dynamic>{
          'id': null,
          'amount': null,
          'comission': null,
          'type': null,
          'paymentMethod': null,
          'receivedAt': null,
          'loan': null,
          'createdAt': null,
        };

        final payment = LoanPayment.fromRow(row);

        expect(payment.id, '');
        expect(payment.amount, 0);
        expect(payment.comission, 0);
        expect(payment.type, 'NORMAL');
        expect(payment.paymentMethod, PaymentMethod.cash);
        expect(payment.loanId, '');
      });

      test('should parse MONEY_TRANSFER payment method', () {
        final row = {
          'id': 'payment-123',
          'amount': 500,
          'type': 'NORMAL',
          'paymentMethod': 'MONEY_TRANSFER',
          'loan': 'loan-456',
        };

        final payment = LoanPayment.fromRow(row);

        expect(payment.paymentMethod, PaymentMethod.moneyTransfer);
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        final now = DateTime(2026, 1, 3, 10, 30);
        final payment1 = LoanPayment(
          id: 'payment-123',
          amount: 500.0,
          comission: 25.0,
          type: 'NORMAL',
          paymentMethod: PaymentMethod.cash,
          receivedAt: now,
          loanId: 'loan-456',
          createdAt: now,
        );
        final payment2 = LoanPayment(
          id: 'payment-123',
          amount: 500.0,
          comission: 25.0,
          type: 'NORMAL',
          paymentMethod: PaymentMethod.cash,
          receivedAt: now,
          loanId: 'loan-456',
          createdAt: now,
        );

        expect(payment1, equals(payment2));
      });

      test('should not be equal when properties differ', () {
        final now = DateTime.now();
        final payment1 = LoanPayment(
          id: 'payment-123',
          amount: 500.0,
          type: 'NORMAL',
          paymentMethod: PaymentMethod.cash,
          receivedAt: now,
          loanId: 'loan-456',
          createdAt: now,
        );
        final payment2 = LoanPayment(
          id: 'payment-456', // different id
          amount: 500.0,
          type: 'NORMAL',
          paymentMethod: PaymentMethod.cash,
          receivedAt: now,
          loanId: 'loan-456',
          createdAt: now,
        );

        expect(payment1, isNot(equals(payment2)));
      });
    });
  });

  group('PaymentMethod', () {
    group('fromString', () {
      test('should parse CASH correctly', () {
        expect(PaymentMethod.fromString('CASH'), PaymentMethod.cash);
        expect(PaymentMethod.fromString('cash'), PaymentMethod.cash);
      });

      test('should parse MONEY_TRANSFER correctly', () {
        expect(PaymentMethod.fromString('MONEY_TRANSFER'), PaymentMethod.moneyTransfer);
        expect(PaymentMethod.fromString('money_transfer'), PaymentMethod.moneyTransfer);
      });

      test('should default to cash for unknown values', () {
        expect(PaymentMethod.fromString('UNKNOWN'), PaymentMethod.cash);
        expect(PaymentMethod.fromString(null), PaymentMethod.cash);
        expect(PaymentMethod.fromString(''), PaymentMethod.cash);
      });
    });

    group('displayName', () {
      test('should return correct display names', () {
        expect(PaymentMethod.cash.displayName, 'Efectivo');
        expect(PaymentMethod.moneyTransfer.displayName, 'Transferencia');
      });
    });
  });
}
