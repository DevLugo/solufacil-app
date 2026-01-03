import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'powersync_provider.dart';
import 'collector_dashboard_provider.dart';
import 'client_search_provider.dart';
import '../data/models/loan_type.dart';
import '../data/models/loan.dart';
import '../data/repositories/borrower_repository.dart';
import '../data/repositories/loan_repository.dart';
import '../data/repositories/account_entry_repository.dart';
import '../core/services/loan_calculator.dart';

/// Wizard steps for credit creation
enum CreditWizardStep {
  client,        // Step 1: Select/create client
  loanType,      // Step 2: Select loan type and amount
  collateral,    // Step 3: Optional collateral/aval
  firstPayment,  // Step 4: Optional first payment
  documents,     // Step 5: Document photos (INE, proof of address, promissory note)
  signature,     // Step 6: Contract/promissory note signature
  fingerprints,  // Step 7: Fingerprints capture
  videoRecording,// Step 8: Video recording
  confirmation,  // Step 9: Review and confirm
}

/// Input for first payment in wizard
class FirstPaymentInput {
  final double amount;
  final bool isCash;
  final double commissionAmount;

  const FirstPaymentInput({
    required this.amount,
    this.isCash = true,
    this.commissionAmount = 0,
  });

  FirstPaymentInput copyWith({
    double? amount,
    bool? isCash,
    double? commissionAmount,
  }) {
    return FirstPaymentInput(
      amount: amount ?? this.amount,
      isCash: isCash ?? this.isCash,
      commissionAmount: commissionAmount ?? this.commissionAmount,
    );
  }
}

/// Signature data for contract/promissory note
class SignatureData {
  final String? borrowerSignaturePath;
  final String? collateralSignaturePath;
  final DateTime? signedAt;

  const SignatureData({
    this.borrowerSignaturePath,
    this.collateralSignaturePath,
    this.signedAt,
  });

  SignatureData copyWith({
    String? borrowerSignaturePath,
    String? collateralSignaturePath,
    DateTime? signedAt,
    bool clearBorrowerSignature = false,
    bool clearCollateralSignature = false,
  }) {
    return SignatureData(
      borrowerSignaturePath: clearBorrowerSignature ? null : (borrowerSignaturePath ?? this.borrowerSignaturePath),
      collateralSignaturePath: clearCollateralSignature ? null : (collateralSignaturePath ?? this.collateralSignaturePath),
      signedAt: signedAt ?? this.signedAt,
    );
  }

  bool get hasBorrowerSignature => borrowerSignaturePath != null;
  bool get hasCollateralSignature => collateralSignaturePath != null;
  bool get isComplete => hasBorrowerSignature;
}

/// Fingerprint/Biometric verification data
class FingerprintData {
  final bool borrowerVerified;
  final DateTime? borrowerVerifiedAt;
  final bool collateralVerified;
  final DateTime? collateralVerifiedAt;

  const FingerprintData({
    this.borrowerVerified = false,
    this.borrowerVerifiedAt,
    this.collateralVerified = false,
    this.collateralVerifiedAt,
  });

  FingerprintData copyWith({
    bool? borrowerVerified,
    DateTime? borrowerVerifiedAt,
    bool? collateralVerified,
    DateTime? collateralVerifiedAt,
    bool clearBorrower = false,
    bool clearCollateral = false,
  }) {
    return FingerprintData(
      borrowerVerified: clearBorrower ? false : (borrowerVerified ?? this.borrowerVerified),
      borrowerVerifiedAt: clearBorrower ? null : (borrowerVerifiedAt ?? this.borrowerVerifiedAt),
      collateralVerified: clearCollateral ? false : (collateralVerified ?? this.collateralVerified),
      collateralVerifiedAt: clearCollateral ? null : (collateralVerifiedAt ?? this.collateralVerifiedAt),
    );
  }

  bool get hasBorrowerVerification => borrowerVerified;
  bool get hasCollateralVerification => collateralVerified;
  bool get isComplete => borrowerVerified;
}

/// Video recording data
class VideoRecordingData {
  final String? videoPath;
  final Duration? duration;
  final DateTime? recordedAt;
  final String? thumbnailPath;

  const VideoRecordingData({
    this.videoPath,
    this.duration,
    this.recordedAt,
    this.thumbnailPath,
  });

  VideoRecordingData copyWith({
    String? videoPath,
    Duration? duration,
    DateTime? recordedAt,
    String? thumbnailPath,
    bool clearVideo = false,
  }) {
    return VideoRecordingData(
      videoPath: clearVideo ? null : (videoPath ?? this.videoPath),
      duration: clearVideo ? null : (duration ?? this.duration),
      recordedAt: recordedAt ?? this.recordedAt,
      thumbnailPath: clearVideo ? null : (thumbnailPath ?? this.thumbnailPath),
    );
  }

  bool get hasVideo => videoPath != null;
  bool get isComplete => hasVideo;
}

/// Document photos data (INE, proof of address, signed promissory note)
class DocumentPhotosData {
  // Borrower documents
  final String? borrowerIneFrontPath;
  final String? borrowerIneBackPath;
  final String? borrowerProofOfAddressPath;
  final String? signedPromissoryNotePath;

  // Collateral documents (if applicable)
  final String? collateralIneFrontPath;
  final String? collateralIneBackPath;
  final String? collateralProofOfAddressPath;

  final DateTime? capturedAt;

  const DocumentPhotosData({
    this.borrowerIneFrontPath,
    this.borrowerIneBackPath,
    this.borrowerProofOfAddressPath,
    this.signedPromissoryNotePath,
    this.collateralIneFrontPath,
    this.collateralIneBackPath,
    this.collateralProofOfAddressPath,
    this.capturedAt,
  });

  DocumentPhotosData copyWith({
    String? borrowerIneFrontPath,
    String? borrowerIneBackPath,
    String? borrowerProofOfAddressPath,
    String? signedPromissoryNotePath,
    String? collateralIneFrontPath,
    String? collateralIneBackPath,
    String? collateralProofOfAddressPath,
    DateTime? capturedAt,
    bool clearBorrowerIneFront = false,
    bool clearBorrowerIneBack = false,
    bool clearBorrowerProofOfAddress = false,
    bool clearSignedPromissoryNote = false,
    bool clearCollateralIneFront = false,
    bool clearCollateralIneBack = false,
    bool clearCollateralProofOfAddress = false,
  }) {
    return DocumentPhotosData(
      borrowerIneFrontPath: clearBorrowerIneFront ? null : (borrowerIneFrontPath ?? this.borrowerIneFrontPath),
      borrowerIneBackPath: clearBorrowerIneBack ? null : (borrowerIneBackPath ?? this.borrowerIneBackPath),
      borrowerProofOfAddressPath: clearBorrowerProofOfAddress ? null : (borrowerProofOfAddressPath ?? this.borrowerProofOfAddressPath),
      signedPromissoryNotePath: clearSignedPromissoryNote ? null : (signedPromissoryNotePath ?? this.signedPromissoryNotePath),
      collateralIneFrontPath: clearCollateralIneFront ? null : (collateralIneFrontPath ?? this.collateralIneFrontPath),
      collateralIneBackPath: clearCollateralIneBack ? null : (collateralIneBackPath ?? this.collateralIneBackPath),
      collateralProofOfAddressPath: clearCollateralProofOfAddress ? null : (collateralProofOfAddressPath ?? this.collateralProofOfAddressPath),
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }

  bool get hasBorrowerIne => borrowerIneFrontPath != null && borrowerIneBackPath != null;
  bool get hasBorrowerProofOfAddress => borrowerProofOfAddressPath != null;
  bool get hasSignedPromissoryNote => signedPromissoryNotePath != null;
  bool get hasCollateralIne => collateralIneFrontPath != null && collateralIneBackPath != null;
  bool get hasCollateralProofOfAddress => collateralProofOfAddressPath != null;

  /// Minimum required: INE and proof of address for borrower
  bool get isComplete => hasBorrowerIne && hasBorrowerProofOfAddress;
}

/// Complete state for the create credit wizard
class CreateCreditState {
  // Current step
  final CreditWizardStep currentStep;

  // Step 1: Client
  final ClientForLoan? selectedClient;
  final bool isNewClient;
  final CreateBorrowerInput? newClientInput;

  // Renewal info (auto-detected from selected client)
  final bool isRenewal;
  final RenewalInfo? renewalInfo;

  // Step 2: Loan type and amount
  final LoanType? selectedLoanType;
  final double requestedAmount;
  final LoanMetrics? calculatedMetrics;
  final double amountToGive;

  // Step 3: Collateral (optional)
  final bool hasCollateral;
  final ClientForLoan? selectedCollateral;
  final bool isNewCollateral;
  final CreateBorrowerInput? newCollateralInput;

  // Step 4: First payment (optional)
  final bool hasFirstPayment;
  final FirstPaymentInput? firstPayment;

  // Step 5: Document photos
  final DocumentPhotosData? documentPhotosData;

  // Step 6: Signature
  final SignatureData? signatureData;

  // Step 7: Fingerprints
  final FingerprintData? fingerprintData;

  // Step 8: Video recording
  final VideoRecordingData? videoData;

  // Process state
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final String? createdLoanId;
  final bool isSuccess;

  const CreateCreditState({
    this.currentStep = CreditWizardStep.client,
    this.selectedClient,
    this.isNewClient = false,
    this.newClientInput,
    this.isRenewal = false,
    this.renewalInfo,
    this.selectedLoanType,
    this.requestedAmount = 0,
    this.calculatedMetrics,
    this.amountToGive = 0,
    this.hasCollateral = false,
    this.selectedCollateral,
    this.isNewCollateral = false,
    this.newCollateralInput,
    this.hasFirstPayment = false,
    this.firstPayment,
    this.documentPhotosData,
    this.signatureData,
    this.fingerprintData,
    this.videoData,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.createdLoanId,
    this.isSuccess = false,
  });

  CreateCreditState copyWith({
    CreditWizardStep? currentStep,
    ClientForLoan? selectedClient,
    bool? isNewClient,
    CreateBorrowerInput? newClientInput,
    bool? isRenewal,
    RenewalInfo? renewalInfo,
    LoanType? selectedLoanType,
    double? requestedAmount,
    LoanMetrics? calculatedMetrics,
    double? amountToGive,
    bool? hasCollateral,
    ClientForLoan? selectedCollateral,
    bool? isNewCollateral,
    CreateBorrowerInput? newCollateralInput,
    bool? hasFirstPayment,
    FirstPaymentInput? firstPayment,
    DocumentPhotosData? documentPhotosData,
    SignatureData? signatureData,
    FingerprintData? fingerprintData,
    VideoRecordingData? videoData,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    String? createdLoanId,
    bool? isSuccess,
    // For clearing optional fields
    bool clearSelectedClient = false,
    bool clearNewClientInput = false,
    bool clearRenewalInfo = false,
    bool clearSelectedLoanType = false,
    bool clearCalculatedMetrics = false,
    bool clearSelectedCollateral = false,
    bool clearNewCollateralInput = false,
    bool clearFirstPayment = false,
    bool clearDocumentPhotosData = false,
    bool clearSignatureData = false,
    bool clearFingerprintData = false,
    bool clearVideoData = false,
    bool clearError = false,
    bool clearCreatedLoanId = false,
  }) {
    return CreateCreditState(
      currentStep: currentStep ?? this.currentStep,
      selectedClient: clearSelectedClient ? null : (selectedClient ?? this.selectedClient),
      isNewClient: isNewClient ?? this.isNewClient,
      newClientInput: clearNewClientInput ? null : (newClientInput ?? this.newClientInput),
      isRenewal: isRenewal ?? this.isRenewal,
      renewalInfo: clearRenewalInfo ? null : (renewalInfo ?? this.renewalInfo),
      selectedLoanType: clearSelectedLoanType ? null : (selectedLoanType ?? this.selectedLoanType),
      requestedAmount: requestedAmount ?? this.requestedAmount,
      calculatedMetrics: clearCalculatedMetrics ? null : (calculatedMetrics ?? this.calculatedMetrics),
      amountToGive: amountToGive ?? this.amountToGive,
      hasCollateral: hasCollateral ?? this.hasCollateral,
      selectedCollateral: clearSelectedCollateral ? null : (selectedCollateral ?? this.selectedCollateral),
      isNewCollateral: isNewCollateral ?? this.isNewCollateral,
      newCollateralInput: clearNewCollateralInput ? null : (newCollateralInput ?? this.newCollateralInput),
      hasFirstPayment: hasFirstPayment ?? this.hasFirstPayment,
      firstPayment: clearFirstPayment ? null : (firstPayment ?? this.firstPayment),
      documentPhotosData: clearDocumentPhotosData ? null : (documentPhotosData ?? this.documentPhotosData),
      signatureData: clearSignatureData ? null : (signatureData ?? this.signatureData),
      fingerprintData: clearFingerprintData ? null : (fingerprintData ?? this.fingerprintData),
      videoData: clearVideoData ? null : (videoData ?? this.videoData),
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      createdLoanId: clearCreatedLoanId ? null : (createdLoanId ?? this.createdLoanId),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  /// Check if current step can proceed to next
  bool get canProceed {
    switch (currentStep) {
      case CreditWizardStep.client:
        return selectedClient != null || (isNewClient && newClientInput != null);
      case CreditWizardStep.loanType:
        return selectedLoanType != null && requestedAmount > 0 && calculatedMetrics != null;
      case CreditWizardStep.collateral:
        // Collateral is optional, always can proceed
        return true;
      case CreditWizardStep.firstPayment:
        // First payment is optional, always can proceed
        return true;
      case CreditWizardStep.documents:
        // Require at least borrower INE and proof of address
        return documentPhotosData?.isComplete ?? false;
      case CreditWizardStep.signature:
        // Require borrower signature
        return signatureData?.isComplete ?? false;
      case CreditWizardStep.fingerprints:
        // Require borrower fingerprints
        return fingerprintData?.isComplete ?? false;
      case CreditWizardStep.videoRecording:
        // Require video recording
        return videoData?.isComplete ?? false;
      case CreditWizardStep.confirmation:
        return !isSubmitting;
    }
  }

  /// Get step number (1-based)
  int get stepNumber => currentStep.index + 1;

  /// Total steps
  int get totalSteps => CreditWizardStep.values.length;

  /// Progress percentage (0-100)
  double get progress => (stepNumber / totalSteps) * 100;
}

/// Notifier for create credit wizard
class CreateCreditNotifier extends StateNotifier<CreateCreditState> {
  final LoanRepository? _loanRepository;
  final AccountEntryRepository? _accountEntryRepository;
  final BorrowerRepository? _borrowerRepository;
  final String? _leadId;
  final String? _routeId;
  final String? _routeName;
  final String? _accountId;
  final _uuid = const Uuid();

  CreateCreditNotifier({
    LoanRepository? loanRepository,
    AccountEntryRepository? accountEntryRepository,
    BorrowerRepository? borrowerRepository,
    String? leadId,
    String? routeId,
    String? routeName,
    String? accountId,
  })  : _loanRepository = loanRepository,
        _accountEntryRepository = accountEntryRepository,
        _borrowerRepository = borrowerRepository,
        _leadId = leadId,
        _routeId = routeId,
        _routeName = routeName,
        _accountId = accountId,
        super(const CreateCreditState());

  // ============ NAVIGATION ============

  /// Go to next step
  void nextStep() {
    if (!state.canProceed) return;

    final currentIndex = state.currentStep.index;
    if (currentIndex < CreditWizardStep.values.length - 1) {
      state = state.copyWith(
        currentStep: CreditWizardStep.values[currentIndex + 1],
        clearError: true,
      );
    }
  }

  /// Go to previous step
  void previousStep() {
    final currentIndex = state.currentStep.index;
    if (currentIndex > 0) {
      state = state.copyWith(
        currentStep: CreditWizardStep.values[currentIndex - 1],
        clearError: true,
      );
    }
  }

  /// Go to specific step
  void goToStep(CreditWizardStep step) {
    state = state.copyWith(currentStep: step, clearError: true);
  }

  // ============ STEP 1: CLIENT ============

  /// Select an existing client
  Future<void> selectClient(ClientForLoan client) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Check if client has active loan (for renewal)
      RenewalInfo? renewalInfo;
      if (client.hasActiveLoan && client.activeLoan != null) {
        final activeLoan = client.activeLoan!;
        renewalInfo = LoanCalculator.calculateRenewalInfo(
          previousLoanId: activeLoan.loanId,
          pendingAmount: activeLoan.pendingAmount,
          previousProfitAmount: activeLoan.profitAmount,
          previousTotalDebt: activeLoan.totalDebtAcquired,
          newRequestedAmount: 0, // Will be updated when amount is set
        );
      }

      state = state.copyWith(
        selectedClient: client,
        isNewClient: false,
        clearNewClientInput: true,
        isRenewal: client.hasActiveLoan,
        renewalInfo: renewalInfo,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Error al seleccionar cliente: $e',
        isLoading: false,
      );
    }
  }

  /// Set new client mode
  void setNewClientMode(bool isNew) {
    state = state.copyWith(
      isNewClient: isNew,
      clearSelectedClient: isNew,
      clearRenewalInfo: isNew,
      isRenewal: false,
    );
  }

  /// Set new client input
  void setNewClientInput(CreateBorrowerInput input) {
    state = state.copyWith(newClientInput: input);
  }

  /// Clear client selection
  void clearClient() {
    state = state.copyWith(
      clearSelectedClient: true,
      isNewClient: false,
      clearNewClientInput: true,
      isRenewal: false,
      clearRenewalInfo: true,
    );
  }

  // ============ STEP 2: LOAN TYPE & AMOUNT ============

  /// Select loan type
  void selectLoanType(LoanType loanType) {
    state = state.copyWith(selectedLoanType: loanType);
    _recalculateMetrics();
  }

  /// Set requested amount
  void setRequestedAmount(double amount) {
    state = state.copyWith(requestedAmount: amount);
    _recalculateMetrics();
  }

  /// Recalculate loan metrics based on current state
  void _recalculateMetrics() {
    final loanType = state.selectedLoanType;
    final amount = state.requestedAmount;

    if (loanType == null || amount <= 0) {
      state = state.copyWith(
        clearCalculatedMetrics: true,
        amountToGive: 0,
      );
      return;
    }

    LoanMetrics metrics;
    double amountToGive;
    RenewalInfo? updatedRenewalInfo;

    if (state.isRenewal && state.selectedClient?.activeLoan != null) {
      final activeLoan = state.selectedClient!.activeLoan!;

      // Calculate renewal info with new requested amount
      updatedRenewalInfo = LoanCalculator.calculateRenewalInfo(
        previousLoanId: activeLoan.loanId,
        pendingAmount: activeLoan.pendingAmount,
        previousProfitAmount: activeLoan.profitAmount,
        previousTotalDebt: activeLoan.totalDebtAcquired,
        newRequestedAmount: amount,
      );

      // Calculate metrics with inherited profit
      metrics = LoanCalculator.calculateMetricsWithInheritedProfit(
        requestedAmount: amount,
        rate: loanType.rate,
        weekDuration: loanType.weekDuration,
        inheritedProfit: updatedRenewalInfo?.inheritedProfit ?? 0,
      );

      amountToGive = updatedRenewalInfo?.amountToGive ?? amount;
    } else {
      // Standard new loan
      metrics = LoanCalculator.calculateMetrics(
        requestedAmount: amount,
        rate: loanType.rate,
        weekDuration: loanType.weekDuration,
      );
      amountToGive = amount;
    }

    state = state.copyWith(
      calculatedMetrics: metrics,
      amountToGive: amountToGive,
      renewalInfo: updatedRenewalInfo,
    );

    // Update first payment suggestion if enabled
    if (state.hasFirstPayment && state.firstPayment != null) {
      state = state.copyWith(
        firstPayment: state.firstPayment!.copyWith(
          amount: metrics.expectedWeeklyPayment,
        ),
      );
    }
  }

  // ============ STEP 3: COLLATERAL ============

  /// Toggle collateral
  void toggleCollateral(bool hasCollateral) {
    state = state.copyWith(
      hasCollateral: hasCollateral,
      clearSelectedCollateral: !hasCollateral,
      isNewCollateral: false,
      clearNewCollateralInput: !hasCollateral,
    );
  }

  /// Select collateral person
  void selectCollateral(ClientForLoan collateral) {
    state = state.copyWith(
      selectedCollateral: collateral,
      isNewCollateral: false,
      clearNewCollateralInput: true,
    );
  }

  /// Set new collateral mode
  void setNewCollateralMode(bool isNew) {
    state = state.copyWith(
      isNewCollateral: isNew,
      clearSelectedCollateral: isNew,
    );
  }

  /// Set new collateral input
  void setNewCollateralInput(CreateBorrowerInput input) {
    state = state.copyWith(newCollateralInput: input);
  }

  // ============ STEP 4: FIRST PAYMENT ============

  /// Toggle first payment
  void toggleFirstPayment(bool hasFirstPayment) {
    if (hasFirstPayment && state.calculatedMetrics != null) {
      state = state.copyWith(
        hasFirstPayment: true,
        firstPayment: FirstPaymentInput(
          amount: state.calculatedMetrics!.expectedWeeklyPayment,
          isCash: true,
          commissionAmount: 0,
        ),
      );
    } else {
      state = state.copyWith(
        hasFirstPayment: false,
        clearFirstPayment: true,
      );
    }
  }

  /// Update first payment amount
  void setFirstPaymentAmount(double amount) {
    if (state.firstPayment != null) {
      state = state.copyWith(
        firstPayment: state.firstPayment!.copyWith(amount: amount),
      );
    }
  }

  /// Update first payment method
  void setFirstPaymentMethod(bool isCash) {
    if (state.firstPayment != null) {
      state = state.copyWith(
        firstPayment: state.firstPayment!.copyWith(isCash: isCash),
      );
    }
  }

  /// Update first payment commission
  void setFirstPaymentCommission(double commission) {
    if (state.firstPayment != null) {
      state = state.copyWith(
        firstPayment: state.firstPayment!.copyWith(commissionAmount: commission),
      );
    }
  }

  // ============ STEP 5: DOCUMENT PHOTOS ============

  /// Set borrower INE front photo
  void setBorrowerIneFront(String path) {
    final current = state.documentPhotosData ?? const DocumentPhotosData();
    state = state.copyWith(
      documentPhotosData: current.copyWith(
        borrowerIneFrontPath: path,
        capturedAt: DateTime.now(),
      ),
    );
  }

  /// Set borrower INE back photo
  void setBorrowerIneBack(String path) {
    final current = state.documentPhotosData ?? const DocumentPhotosData();
    state = state.copyWith(
      documentPhotosData: current.copyWith(
        borrowerIneBackPath: path,
        capturedAt: DateTime.now(),
      ),
    );
  }

  /// Set borrower proof of address photo
  void setBorrowerProofOfAddress(String path) {
    final current = state.documentPhotosData ?? const DocumentPhotosData();
    state = state.copyWith(
      documentPhotosData: current.copyWith(
        borrowerProofOfAddressPath: path,
        capturedAt: DateTime.now(),
      ),
    );
  }

  /// Set signed promissory note photo
  void setSignedPromissoryNote(String path) {
    final current = state.documentPhotosData ?? const DocumentPhotosData();
    state = state.copyWith(
      documentPhotosData: current.copyWith(
        signedPromissoryNotePath: path,
        capturedAt: DateTime.now(),
      ),
    );
  }

  /// Set collateral INE front photo
  void setCollateralIneFront(String path) {
    final current = state.documentPhotosData ?? const DocumentPhotosData();
    state = state.copyWith(
      documentPhotosData: current.copyWith(
        collateralIneFrontPath: path,
        capturedAt: DateTime.now(),
      ),
    );
  }

  /// Set collateral INE back photo
  void setCollateralIneBack(String path) {
    final current = state.documentPhotosData ?? const DocumentPhotosData();
    state = state.copyWith(
      documentPhotosData: current.copyWith(
        collateralIneBackPath: path,
        capturedAt: DateTime.now(),
      ),
    );
  }

  /// Set collateral proof of address photo
  void setCollateralProofOfAddress(String path) {
    final current = state.documentPhotosData ?? const DocumentPhotosData();
    state = state.copyWith(
      documentPhotosData: current.copyWith(
        collateralProofOfAddressPath: path,
        capturedAt: DateTime.now(),
      ),
    );
  }

  /// Clear all document photos
  void clearDocumentPhotos() {
    state = state.copyWith(clearDocumentPhotosData: true);
  }

  // ============ STEP 6: SIGNATURE ============

  /// Set borrower signature
  void setBorrowerSignature(String path) {
    final current = state.signatureData ?? const SignatureData();
    state = state.copyWith(
      signatureData: current.copyWith(
        borrowerSignaturePath: path,
        signedAt: DateTime.now(),
      ),
    );
  }

  /// Set collateral signature
  void setCollateralSignature(String path) {
    final current = state.signatureData ?? const SignatureData();
    state = state.copyWith(
      signatureData: current.copyWith(
        collateralSignaturePath: path,
        signedAt: DateTime.now(),
      ),
    );
  }

  /// Clear borrower signature
  void clearBorrowerSignature() {
    if (state.signatureData != null) {
      state = state.copyWith(
        signatureData: state.signatureData!.copyWith(clearBorrowerSignature: true),
      );
    }
  }

  /// Clear collateral signature
  void clearCollateralSignature() {
    if (state.signatureData != null) {
      state = state.copyWith(
        signatureData: state.signatureData!.copyWith(clearCollateralSignature: true),
      );
    }
  }

  // ============ STEP 7: BIOMETRIC VERIFICATION ============

  /// Set borrower biometric verification
  void setBorrowerBiometricVerified(bool verified) {
    final current = state.fingerprintData ?? const FingerprintData();
    state = state.copyWith(
      fingerprintData: current.copyWith(
        borrowerVerified: verified,
        borrowerVerifiedAt: verified ? DateTime.now() : null,
      ),
    );
  }

  /// Set collateral biometric verification
  void setCollateralBiometricVerified(bool verified) {
    final current = state.fingerprintData ?? const FingerprintData();
    state = state.copyWith(
      fingerprintData: current.copyWith(
        collateralVerified: verified,
        collateralVerifiedAt: verified ? DateTime.now() : null,
      ),
    );
  }

  /// Clear all biometric verifications
  void clearBiometricVerifications() {
    state = state.copyWith(clearFingerprintData: true);
  }

  // ============ STEP 8: VIDEO RECORDING ============

  /// Set video recording data
  void setVideoRecording({
    required String videoPath,
    Duration? duration,
    String? thumbnailPath,
  }) {
    state = state.copyWith(
      videoData: VideoRecordingData(
        videoPath: videoPath,
        duration: duration,
        recordedAt: DateTime.now(),
        thumbnailPath: thumbnailPath,
      ),
    );
  }

  /// Clear video recording
  void clearVideoRecording() {
    state = state.copyWith(clearVideoData: true);
  }

  // ============ STEP 9: SUBMIT ============

  /// Submit and create the loan
  Future<bool> submit() async {
    if (_loanRepository == null || _borrowerRepository == null) {
      state = state.copyWith(error: 'Repositorios no disponibles');
      return false;
    }

    if (_leadId == null || _routeId == null) {
      state = state.copyWith(error: 'No se ha seleccionado una localidad');
      return false;
    }

    if (state.selectedLoanType == null || state.calculatedMetrics == null) {
      state = state.copyWith(error: 'Datos del préstamo incompletos');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      // 1. Get or create borrower
      String borrowerId;
      String? personalDataId;

      if (state.isNewClient && state.newClientInput != null) {
        // Create new client
        final newClient = await _borrowerRepository!.createBorrower(state.newClientInput!);
        borrowerId = newClient.borrowerId!;
        personalDataId = newClient.id;
      } else if (state.selectedClient != null) {
        // Use existing client
        personalDataId = state.selectedClient!.id;
        if (state.selectedClient!.borrowerId != null) {
          borrowerId = state.selectedClient!.borrowerId!;
        } else {
          // Create borrower record if doesn't exist
          borrowerId = await _borrowerRepository!.getOrCreateBorrowerId(personalDataId);
        }
      } else {
        throw Exception('No se ha seleccionado un cliente');
      }

      // 2. Get or create collateral if needed
      final collateralIds = <String>[];
      if (state.hasCollateral) {
        if (state.isNewCollateral && state.newCollateralInput != null) {
          final newCollateral = await _borrowerRepository!.createBorrower(state.newCollateralInput!);
          collateralIds.add(newCollateral.id); // PersonalData ID for collaterals
        } else if (state.selectedCollateral != null) {
          collateralIds.add(state.selectedCollateral!.id);
        }
      }

      // 3. Calculate commission
      final loanType = state.selectedLoanType!;
      final commissionRate = loanType.getComissionRate(state.isRenewal);
      final commissionAmount = loanType.calculateComission(state.requestedAmount, state.isRenewal);

      // 4. Create loan
      final loanId = await _loanRepository!.createLoan(CreateLoanInput(
        borrowerId: borrowerId,
        loantypeId: loanType.id,
        requestedAmount: state.requestedAmount,
        amountGived: state.amountToGive,
        profitAmount: state.calculatedMetrics!.profitAmount,
        totalDebtAcquired: state.calculatedMetrics!.totalDebtAcquired,
        expectedWeeklyPayment: state.calculatedMetrics!.expectedWeeklyPayment,
        comissionAmount: commissionAmount,
        leadId: _leadId!,
        routeId: _routeId!,
        routeName: _routeName ?? '',
        previousLoanId: state.renewalInfo?.previousLoanId,
        collateralIds: collateralIds,
      ));

      // 5. Create account entries if account is available
      if (_accountEntryRepository != null && _accountId != null) {
        final now = DateTime.now();

        // DEBIT entry for loan grant (money leaving account)
        await _accountEntryRepository!.createLoanGrantEntry(
          accountId: _accountId!,
          amountGived: state.amountToGive,
          loanId: loanId,
          entryDate: now,
          leadId: _leadId,
          routeId: _routeId,
        );

        // DEBIT entry for commission if any
        if (commissionAmount > 0) {
          await _accountEntryRepository!.createLoanCommissionEntry(
            accountId: _accountId!,
            commissionAmount: commissionAmount,
            loanId: loanId,
            entryDate: now,
            leadId: _leadId,
            routeId: _routeId,
          );
        }

        // 6. Create first payment if configured
        if (state.hasFirstPayment && state.firstPayment != null) {
          final firstPayment = state.firstPayment!;

          // Create loan payment
          final paymentId = await _createLoanPayment(
            loanId: loanId,
            amount: firstPayment.amount,
            isCash: firstPayment.isCash,
          );

          // Calculate profit/capital split
          final distribution = LoanCalculator.calculatePaymentDistribution(
            paymentAmount: firstPayment.amount,
            totalProfit: state.calculatedMetrics!.profitAmount,
            totalDebtAcquired: state.calculatedMetrics!.totalDebtAcquired,
          );

          // CREDIT entry for payment (money entering account)
          await _accountEntryRepository!.createPaymentEntry(
            accountId: _accountId!,
            paymentAmount: firstPayment.amount,
            loanId: loanId,
            loanPaymentId: paymentId,
            entryDate: now,
            leadId: _leadId,
            routeId: _routeId,
            isCash: firstPayment.isCash,
            profitAmount: distribution.profitAmount,
            returnToCapital: distribution.returnToCapital,
          );

          // Update loan pending amount
          await _loanRepository!.updatePendingAmount(loanId, firstPayment.amount);

          // Commission on payment if any
          if (firstPayment.commissionAmount > 0) {
            await _accountEntryRepository!.createPaymentCommissionEntry(
              accountId: _accountId!,
              commissionAmount: firstPayment.commissionAmount,
              loanPaymentId: paymentId,
              entryDate: now,
              leadId: _leadId,
              routeId: _routeId,
            );
          }
        }
      }

      state = state.copyWith(
        isSubmitting: false,
        createdLoanId: loanId,
        isSuccess: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Error al crear el crédito: $e',
      );
      return false;
    }
  }

  /// Create loan payment record
  Future<String> _createLoanPayment({
    required String loanId,
    required double amount,
    required bool isCash,
  }) async {
    final paymentId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    // This will need the db instance - for now using repository pattern
    // The actual implementation would be in a LoanPaymentRepository
    // For now, this is a placeholder that would be called from the repository

    // TODO: Implement via repository
    return paymentId;
  }

  // ============ RESET ============

  /// Reset the wizard to initial state
  void reset() {
    state = const CreateCreditState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ============ PROVIDERS ============

/// Repository providers
final loanRepositoryProvider = Provider<LoanRepository?>((ref) {
  final dbAsync = ref.watch(powerSyncDatabaseProvider);
  final db = dbAsync.valueOrNull;
  if (db == null) return null;
  return LoanRepository(db);
});

final accountEntryRepositoryProvider = Provider<AccountEntryRepository?>((ref) {
  final dbAsync = ref.watch(powerSyncDatabaseProvider);
  final db = dbAsync.valueOrNull;
  if (db == null) return null;
  return AccountEntryRepository(db);
});

/// Current lead/employee ID provider (from auth or selected context)
/// For now returns null - needs to be implemented based on auth context
final currentLeadIdProvider = Provider<String?>((ref) {
  // TODO: Get from auth user's employee ID
  return null;
});

/// Current account ID provider
/// For now returns null - needs to be implemented based on lead's account
final currentAccountIdProvider = Provider<String?>((ref) {
  // TODO: Get from lead's associated account
  return null;
});

/// Main create credit provider
/// [locationId] - Optional location filter (from route selector)
final createCreditProvider = StateNotifierProvider.autoDispose
    .family<CreateCreditNotifier, CreateCreditState, String?>((ref, locationId) {
  final loanRepository = ref.watch(loanRepositoryProvider);
  final accountEntryRepository = ref.watch(accountEntryRepositoryProvider);
  final borrowerRepository = ref.watch(borrowerRepositoryProvider);
  final selectedRoute = ref.watch(selectedRouteProvider);
  final leadId = ref.watch(currentLeadIdProvider);
  final accountId = ref.watch(currentAccountIdProvider);

  return CreateCreditNotifier(
    loanRepository: loanRepository,
    accountEntryRepository: accountEntryRepository,
    borrowerRepository: borrowerRepository,
    leadId: leadId,
    routeId: selectedRoute?.id ?? locationId,
    routeName: selectedRoute?.name,
    accountId: accountId,
  );
});

/// Provider for loans created today (for the credits list page)
final loansCreatedTodayProvider = FutureProvider.family<List<Loan>, String?>((ref, leadId) async {
  final repository = ref.watch(loanRepositoryProvider);
  if (repository == null || leadId == null) return [];

  return repository.getLoansCreatedToday(leadId);
});

/// Provider for loan day summary
final loanDaySummaryProvider = FutureProvider.family<LoanDaySummary, String?>((ref, leadId) async {
  final repository = ref.watch(loanRepositoryProvider);
  if (repository == null || leadId == null) return const LoanDaySummary.empty();

  return repository.getDaySummary(leadId);
});
