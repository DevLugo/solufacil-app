import 'dart:math';

/// Métricas calculadas para un préstamo
class LoanMetrics {
  final double profitAmount;
  final double totalDebtAcquired;
  final double expectedWeeklyPayment;

  const LoanMetrics({
    required this.profitAmount,
    required this.totalDebtAcquired,
    required this.expectedWeeklyPayment,
  });

  @override
  String toString() =>
      'LoanMetrics(profit: $profitAmount, totalDebt: $totalDebtAcquired, weeklyPayment: $expectedWeeklyPayment)';
}

/// Información de renovación
class RenewalInfo {
  final String previousLoanId;
  final double pendingDebt;
  final double previousProfitAmount;
  final double previousTotalDebt;
  final double inheritedProfit;
  final double amountToGive;

  const RenewalInfo({
    required this.previousLoanId,
    required this.pendingDebt,
    required this.previousProfitAmount,
    required this.previousTotalDebt,
    required this.inheritedProfit,
    required this.amountToGive,
  });
}

/// Servicio de cálculos para préstamos
/// Replica la lógica de business-logic/src/calculations/profit.ts
class LoanCalculator {
  /// Calcula las métricas de un nuevo préstamo
  ///
  /// [requestedAmount] - Monto solicitado por el cliente
  /// [rate] - Tasa de interés (ej: 0.40 para 40%)
  /// [weekDuration] - Duración en semanas
  static LoanMetrics calculateMetrics({
    required double requestedAmount,
    required double rate,
    required int weekDuration,
  }) {
    // profitAmount = requestedAmount × rate
    final profitAmount = _roundToTwoDecimals(requestedAmount * rate);

    // totalDebtAcquired = requestedAmount + profitAmount
    final totalDebtAcquired = _roundToTwoDecimals(requestedAmount + profitAmount);

    // expectedWeeklyPayment = totalDebtAcquired / weekDuration
    final expectedWeeklyPayment = _roundToTwoDecimals(totalDebtAcquired / weekDuration);

    return LoanMetrics(
      profitAmount: profitAmount,
      totalDebtAcquired: totalDebtAcquired,
      expectedWeeklyPayment: expectedWeeklyPayment,
    );
  }

  /// Calcula la ganancia heredada en una renovación
  ///
  /// IMPORTANTE: Solo la PORCIÓN DE GANANCIA de la deuda pendiente se hereda,
  /// NO el monto total pendiente.
  ///
  /// Fórmula:
  /// profitRatio = previousProfitAmount / previousTotalDebt
  /// inheritedProfit = pendingAmount × profitRatio
  ///
  /// Ejemplo:
  /// - Préstamo anterior: $3,000 al 40%, 14 semanas
  /// - Ganancia original: $1,200, Deuda total: $4,200
  /// - Deuda pendiente después de 10 pagos: $1,200
  /// - Ratio de ganancia: 1200/4200 = 28.57%
  /// - Ganancia heredada: $1,200 × 28.57% = $342.86 (NO los $1,200 completos)
  static double calculateInheritedProfit({
    required double pendingAmount,
    required double previousProfitAmount,
    required double previousTotalDebt,
  }) {
    if (previousTotalDebt <= 0) return 0;

    final profitRatio = previousProfitAmount / previousTotalDebt;
    return _roundToTwoDecimals(pendingAmount * profitRatio);
  }

  /// Calcula el monto a entregar en una renovación
  ///
  /// En renovaciones, el monto a entregar es:
  /// amountToGive = max(0, requestedAmount - pendingDebt)
  ///
  /// Si el cliente solicita $3,000 pero debe $1,200, recibe $1,800
  static double calculateAmountToGive({
    required double requestedAmount,
    required double? pendingDebt,
    required bool isRenewal,
  }) {
    if (!isRenewal || pendingDebt == null) {
      return requestedAmount;
    }
    return max(0, requestedAmount - pendingDebt);
  }

  /// Calcula la distribución de ganancia en un pago
  ///
  /// Cada pago se divide proporcionalmente entre:
  /// - Ganancia (profitAmount)
  /// - Retorno a capital (returnToCapital)
  ///
  /// Fórmula:
  /// profitPortion = payment × (totalProfit / totalDebt)
  /// capitalPortion = payment - profitPortion
  static ({double profitAmount, double returnToCapital}) calculatePaymentDistribution({
    required double paymentAmount,
    required double totalProfit,
    required double totalDebtAcquired,
    bool isBadDebt = false,
  }) {
    // Deuda incobrable: 100% es ganancia (incentiva la cobranza)
    if (isBadDebt) {
      return (profitAmount: paymentAmount, returnToCapital: 0);
    }

    if (totalDebtAcquired <= 0) {
      return (profitAmount: 0, returnToCapital: paymentAmount);
    }

    // Proporción normal
    var profitAmount = _roundToTwoDecimals(
      paymentAmount * (totalProfit / totalDebtAcquired),
    );

    // Seguridad: la ganancia nunca puede ser mayor que el pago
    if (profitAmount > paymentAmount) {
      profitAmount = paymentAmount;
    }

    final returnToCapital = _roundToTwoDecimals(paymentAmount - profitAmount);

    return (profitAmount: profitAmount, returnToCapital: returnToCapital);
  }

  /// Obtiene toda la información de renovación para un préstamo activo
  static RenewalInfo? calculateRenewalInfo({
    required String previousLoanId,
    required double pendingAmount,
    required double previousProfitAmount,
    required double previousTotalDebt,
    required double newRequestedAmount,
  }) {
    if (pendingAmount <= 0) return null;

    final inheritedProfit = calculateInheritedProfit(
      pendingAmount: pendingAmount,
      previousProfitAmount: previousProfitAmount,
      previousTotalDebt: previousTotalDebt,
    );

    final amountToGive = calculateAmountToGive(
      requestedAmount: newRequestedAmount,
      pendingDebt: pendingAmount,
      isRenewal: true,
    );

    return RenewalInfo(
      previousLoanId: previousLoanId,
      pendingDebt: pendingAmount,
      previousProfitAmount: previousProfitAmount,
      previousTotalDebt: previousTotalDebt,
      inheritedProfit: inheritedProfit,
      amountToGive: amountToGive,
    );
  }

  /// Calcula las métricas totales incluyendo ganancia heredada
  static LoanMetrics calculateMetricsWithInheritedProfit({
    required double requestedAmount,
    required double rate,
    required int weekDuration,
    required double inheritedProfit,
  }) {
    final baseMetrics = calculateMetrics(
      requestedAmount: requestedAmount,
      rate: rate,
      weekDuration: weekDuration,
    );

    // La ganancia heredada se suma a la ganancia base
    final totalProfit = _roundToTwoDecimals(baseMetrics.profitAmount + inheritedProfit);
    final totalDebt = _roundToTwoDecimals(requestedAmount + totalProfit);
    final weeklyPayment = _roundToTwoDecimals(totalDebt / weekDuration);

    return LoanMetrics(
      profitAmount: totalProfit,
      totalDebtAcquired: totalDebt,
      expectedWeeklyPayment: weeklyPayment,
    );
  }

  /// Redondea a 2 decimales
  static double _roundToTwoDecimals(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
