class DiagnosisAdvice {
  final String cause;
  final String immediateAction;
  final String organicTreatment;
  final String chemicalTreatment;
  final String prevention;

  const DiagnosisAdvice({
    this.cause = '',
    this.immediateAction = '',
    this.organicTreatment = '',
    this.chemicalTreatment = '',
    this.prevention = '',
  });

  factory DiagnosisAdvice.fromJson(Map<String, dynamic> j) => DiagnosisAdvice(
        cause: j['cause'] ?? '',
        immediateAction: j['immediate_action'] ?? '',
        organicTreatment: j['organic_treatment'] ?? '',
        chemicalTreatment: j['chemical_treatment'] ?? '',
        prevention: j['prevention'] ?? '',
      );
}

class Diagnosis {
  final String diseaseName;
  final double confidence;
  final String scientificName;
  final String crop;
  final String urgency;
  final DiagnosisAdvice english;
  final DiagnosisAdvice tokPisin;
  final String createdAt;

  const Diagnosis({
    required this.diseaseName,
    this.confidence = 0,
    this.scientificName = '',
    this.crop = '',
    this.urgency = 'low',
    this.english = const DiagnosisAdvice(),
    this.tokPisin = const DiagnosisAdvice(),
    this.createdAt = '',
  });

  factory Diagnosis.fromJson(Map<String, dynamic> j) => Diagnosis(
        diseaseName: j['disease_name'] ?? 'unknown',
        confidence: (j['confidence_score'] ?? 0).toDouble(),
        scientificName: j['scientific_name'] ?? '',
        crop: j['crop'] ?? '',
        urgency: j['urgency'] ?? 'low',
        english: DiagnosisAdvice.fromJson(j['english'] ?? {}),
        tokPisin: DiagnosisAdvice.fromJson(j['tok_pisin'] ?? {}),
        createdAt: j['created_at'] ?? DateTime.now().toIso8601String(),
      );
}

class Disease {
  final String id;
  final String nameEn;
  final String nameTpi;
  final String scientificName;
  final String crop;
  final String urgency;
  final String symptoms;
  final String symptomsTpi;
  final String treatmentEn;
  final String treatmentTpi;
  final String preventionEn;
  final String preventionTpi;

  const Disease({
    required this.id,
    required this.nameEn,
    required this.nameTpi,
    this.scientificName = '',
    this.crop = '',
    this.urgency = 'low',
    this.symptoms = '',
    this.symptomsTpi = '',
    this.treatmentEn = '',
    this.treatmentTpi = '',
    this.preventionEn = '',
    this.preventionTpi = '',
  });

  factory Disease.fromJson(Map<String, dynamic> j) => Disease(
        id: j['id'] ?? '',
        nameEn: j['name_en'] ?? '',
        nameTpi: j['name_tpi'] ?? '',
        scientificName: j['scientific_name'] ?? '',
        crop: j['crop'] ?? '',
        urgency: j['urgency'] ?? 'low',
        symptoms: j['symptoms'] ?? '',
        symptomsTpi: j['symptoms_tpi'] ?? '',
        treatmentEn: j['treatment_en'] ?? '',
        treatmentTpi: j['treatment_tpi'] ?? '',
        preventionEn: j['prevention_en'] ?? '',
        preventionTpi: j['prevention_tpi'] ?? '',
      );
}
