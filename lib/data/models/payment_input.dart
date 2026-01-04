import 'package:equatable/equatable.dart';
import 'loan.dart';

/// Input para crear un pago individual de un cliente
class CreatePaymentInput extends Equatable {
  final String loanId;
  final double amount;
  final double comission;
  final PaymentMethod paymentMethod;
  final DateTime receivedAt;
  final String type; // NORMAL, EXTRA

  const CreatePaymentInput({
    required this.loanId,
    required this.amount,
    this.comission = 0,
    required this.paymentMethod,
    required this.receivedAt,
    this.type = 'NORMAL',
  });

  Map<String, dynamic> toMap() => {
        'loan': loanId,
        'amount': amount,
        'comission': comission,
        'paymentMethod': paymentMethod == PaymentMethod.cash
            ? 'CASH'
            : 'MONEY_TRANSFER',
        'receivedAt': receivedAt.toIso8601String(),
        'type': type,
        'createdAt': DateTime.now().toIso8601String(),
      };

  @override
  List<Object?> get props => [
        loanId,
        amount,
        comission,
        paymentMethod,
        receivedAt,
        type,
      ];
}

/// Entrada de pago pendiente en el estado del dia (antes de guardar)
/// Soporta pagos mixtos (parte efectivo, parte transferencia)
class PaymentEntry extends Equatable {
  final String loanId;
  final String borrowerName;
  final double cashAmount;      // Monto en efectivo
  final double bankAmount;      // Monto por transferencia
  final double comission;
  final bool isNoPayment;       // True si el cliente no pago (falta)
  final double expectedWeeklyPayment;

  const PaymentEntry({
    required this.loanId,
    required this.borrowerName,
    this.cashAmount = 0,
    this.bankAmount = 0,
    this.comission = 0,
    this.isNoPayment = false,
    required this.expectedWeeklyPayment,
  });

  /// Total del pago (efectivo + transferencia)
  double get amount => cashAmount + bankAmount;

  /// Método de pago principal (para compatibilidad)
  PaymentMethod get paymentMethod {
    if (bankAmount > 0 && cashAmount > 0) {
      // Mixto - retorna el mayor
      return cashAmount >= bankAmount ? PaymentMethod.cash : PaymentMethod.moneyTransfer;
    }
    return bankAmount > 0 ? PaymentMethod.moneyTransfer : PaymentMethod.cash;
  }

  /// Es pago mixto (tiene ambos tipos)
  bool get isMixed => cashAmount > 0 && bankAmount > 0;

  /// Es solo efectivo
  bool get isCashOnly => cashAmount > 0 && bankAmount == 0;

  /// Es solo transferencia
  bool get isBankOnly => bankAmount > 0 && cashAmount == 0;

  PaymentEntry copyWith({
    String? loanId,
    String? borrowerName,
    double? cashAmount,
    double? bankAmount,
    double? comission,
    bool? isNoPayment,
    double? expectedWeeklyPayment,
  }) {
    return PaymentEntry(
      loanId: loanId ?? this.loanId,
      borrowerName: borrowerName ?? this.borrowerName,
      cashAmount: cashAmount ?? this.cashAmount,
      bankAmount: bankAmount ?? this.bankAmount,
      comission: comission ?? this.comission,
      isNoPayment: isNoPayment ?? this.isNoPayment,
      expectedWeeklyPayment:
          expectedWeeklyPayment ?? this.expectedWeeklyPayment,
    );
  }

  @override
  List<Object?> get props => [
        loanId,
        borrowerName,
        cashAmount,
        bankAmount,
        comission,
        isNoPayment,
        expectedWeeklyPayment,
      ];
}

/// Estado de pagos del dia (en memoria hasta confirmar)
class DayPaymentState extends Equatable {
  final String leadId;
  final String localityId;
  final DateTime date;
  final List<PaymentEntry> payments;

  const DayPaymentState({
    required this.leadId,
    required this.localityId,
    required this.date,
    this.payments = const [],
  });

  /// Total cobrado en efectivo (suma de cashAmount de todos los pagos)
  double get totalCash => payments
      .where((p) => !p.isNoPayment)
      .fold(0, (sum, p) => sum + p.cashAmount);

  /// Total cobrado por transferencia bancaria (suma de bankAmount de todos los pagos)
  double get totalBank => payments
      .where((p) => !p.isNoPayment)
      .fold(0, (sum, p) => sum + p.bankAmount);

  /// Total cobrado (cash + bank)
  double get totalCollected => totalCash + totalBank;

  /// Total de comisiones
  double get totalComission =>
      payments.where((p) => !p.isNoPayment).fold(0, (sum, p) => sum + p.comission);

  /// Numero de pagos registrados (excluyendo faltas)
  int get paymentCount => payments.where((p) => !p.isNoPayment).length;

  /// Numero de faltas
  int get noPaymentCount => payments.where((p) => p.isNoPayment).length;

  DayPaymentState copyWith({
    String? leadId,
    String? localityId,
    DateTime? date,
    List<PaymentEntry>? payments,
  }) {
    return DayPaymentState(
      leadId: leadId ?? this.leadId,
      localityId: localityId ?? this.localityId,
      date: date ?? this.date,
      payments: payments ?? this.payments,
    );
  }

  DayPaymentState addPayment(PaymentEntry payment) {
    // Reemplazar si ya existe un pago para este loan
    final updatedPayments = payments
        .where((p) => p.loanId != payment.loanId)
        .toList()
      ..add(payment);
    return copyWith(payments: updatedPayments);
  }

  DayPaymentState removePayment(String loanId) {
    return copyWith(
      payments: payments.where((p) => p.loanId != loanId).toList(),
    );
  }

  @override
  List<Object?> get props => [leadId, localityId, date, payments];
}

/// Input para guardar la distribucion final del dia
class LeadPaymentReceivedInput extends Equatable {
  final String leadId;
  final String localityId;
  final DateTime date;
  final List<PaymentEntry> payments;
  final double bankTransferAmount; // Efectivo que el lider deposita al banco
  final double falcoAmount; // Efectivo perdido/robado

  const LeadPaymentReceivedInput({
    required this.leadId,
    required this.localityId,
    required this.date,
    required this.payments,
    this.bankTransferAmount = 0,
    this.falcoAmount = 0,
  });

  /// Total cobrado en efectivo por clientes
  double get totalCash => payments
      .where((p) => !p.isNoPayment)
      .fold(0, (sum, p) => sum + p.cashAmount);

  /// Total cobrado por transferencia directa de clientes
  double get totalBank => payments
      .where((p) => !p.isNoPayment)
      .fold(0, (sum, p) => sum + p.bankAmount);

  /// Efectivo que queda con el lider despues de depositar y descontar FALCO
  double get cashPaidAmount => totalCash - bankTransferAmount - falcoAmount;

  /// Total en banco (transferencias directas + deposito del lider)
  double get bankPaidAmount => totalBank + bankTransferAmount;

  @override
  List<Object?> get props => [
        leadId,
        localityId,
        date,
        payments,
        bankTransferAmount,
        falcoAmount,
      ];
}

/// Resumen de cobranza de una localidad
class LocalitySummary extends Equatable {
  final String localityId;
  final String localityName;
  final int totalLoans;
  final double expectedAmount;
  final double collectedAmount;
  final int paidCount;
  final int pendingCount;

  const LocalitySummary({
    required this.localityId,
    required this.localityName,
    required this.totalLoans,
    required this.expectedAmount,
    required this.collectedAmount,
    required this.paidCount,
    required this.pendingCount,
  });

  double get pendingAmount => expectedAmount - collectedAmount;

  double get progressPercent {
    if (expectedAmount == 0) return 0;
    return (collectedAmount / expectedAmount * 100).clamp(0, 100);
  }

  @override
  List<Object?> get props => [
        localityId,
        localityName,
        totalLoans,
        expectedAmount,
        collectedAmount,
        paidCount,
        pendingCount,
      ];
}
