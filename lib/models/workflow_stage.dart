import '../config/client_stage_mapping.dart';

class ChecklistItem {
  final int id;
  final String name;
  final int noOfDocumentUploaded;

  ChecklistItem({
    required this.id,
    required this.name,
    required this.noOfDocumentUploaded,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] ?? '',
      noOfDocumentUploaded:
          int.tryParse(json['no_of_document_uploaded']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'no_of_document_uploaded': noOfDocumentUploaded,
    };
  }
}

class WorkflowStage {
  final int id;
  final String name;
  final String stageName;
  /// Client-facing label from API (`client_label`), e.g. "Getting started".
  final String? clientLabel;
  final bool isActive;
  final bool isCurrentStage;
  final String? createdAt;
  final String? updatedAt;
  final int allowedChecklistCount;
  final List<ChecklistItem> allowedChecklist;

  WorkflowStage({
    required this.id,
    required this.name,
    required this.stageName,
    this.clientLabel,
    this.isActive = false,
    this.isCurrentStage = false,
    this.createdAt,
    this.updatedAt,
    this.allowedChecklistCount = 0,
    this.allowedChecklist = const [],
  });

  factory WorkflowStage.fromJson(Map<String, dynamic> json) {
    var checklist = <ChecklistItem>[];
    if (json['allowed_checklist'] != null) {
      checklist = (json['allowed_checklist'] as List)
          .map((item) => ChecklistItem.fromJson(item))
          .toList();
    }

    final crmName = (json['stage_name'] ?? json['name'] ?? '').toString();
    final apiLabel = json['client_label']?.toString().trim();

    return WorkflowStage(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] ?? '',
      stageName: crmName,
      clientLabel:
          (apiLabel != null && apiLabel.isNotEmpty) ? apiLabel : null,
      isActive: json['is_active'] ?? false,
      isCurrentStage: json['is_current_stage'] ?? false,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      allowedChecklistCount: json['allowed_checklist_count'] ?? 0,
      allowedChecklist: checklist,
    );
  }

  /// Prefer API `client_label`, then prototype mapping, then CRM name.
  String get displayName => clientDisplayName(
        clientLabel: clientLabel,
        crmName: stageName.isNotEmpty ? stageName : name,
        fallback: name,
      );

  ClientStageMapping? get mapping =>
      findClientStageMapping(stageName.isNotEmpty ? stageName : name);

  bool get isSilent => mapping?.silent ?? false;

  ClientStageTag get statusTag => clientStageTag(
        crmName: stageName.isNotEmpty ? stageName : name,
        clientLabel: clientLabel,
      );

  int get mappedProgressPercent => clientProgressPercent(
        clientLabel: clientLabel,
        crmName: stageName.isNotEmpty ? stageName : name,
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stage_name': stageName,
      'client_label': clientLabel,
      'is_active': isActive,
      'is_current_stage': isCurrentStage,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'allowed_checklist_count': allowedChecklistCount,
      'allowed_checklist': allowedChecklist.map((e) => e.toJson()).toList(),
    };
  }

  String get statusText {
    if (isCurrentStage || isActive) return 'Current';
    return 'Upcoming';
  }

  @override
  String toString() {
    return 'WorkflowStage(id: $id, name: $name, displayName: $displayName, isActive: $isActive)';
  }
}

class ActiveStageInfo {
  final int id;
  final String name;
  final String stageName;
  final String? clientLabel;
  final String? clientMatterNo;
  final int? matterStatus;
  final String? stageUpdatedAt;
  final bool isActive;

  ActiveStageInfo({
    required this.id,
    required this.name,
    required this.stageName,
    this.clientLabel,
    this.clientMatterNo,
    this.matterStatus,
    this.stageUpdatedAt,
    this.isActive = true,
  });

  factory ActiveStageInfo.fromJson(Map<String, dynamic> json) {
    final crmName = (json['stage_name'] ?? json['name'] ?? '').toString();
    final apiLabel = json['client_label']?.toString().trim();
    return ActiveStageInfo(
      id: _parseInt(json['id']) ?? 0,
      name: json['name'] ?? '',
      stageName: crmName,
      clientLabel:
          (apiLabel != null && apiLabel.isNotEmpty) ? apiLabel : null,
      clientMatterNo: json['client_matter_no'],
      matterStatus: _parseInt(json['matter_status']),
      stageUpdatedAt: json['stage_updated_at'],
      isActive: json['is_active'] ?? true,
    );
  }

  String get displayName => clientDisplayName(
        clientLabel: clientLabel,
        crmName: stageName.isNotEmpty ? stageName : name,
        fallback: name,
      );

  ClientStageTag get statusTag => clientStageTag(
        crmName: stageName.isNotEmpty ? stageName : name,
        clientLabel: clientLabel,
      );

  int get mappedProgressPercent => clientProgressPercent(
        clientLabel: clientLabel,
        crmName: stageName.isNotEmpty ? stageName : name,
      );

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stage_name': stageName,
      'client_label': clientLabel,
      'client_matter_no': clientMatterNo,
      'matter_status': matterStatus,
      'stage_updated_at': stageUpdatedAt,
      'is_active': isActive,
    };
  }
}

class WorkflowStagesResponse {
  final List<WorkflowStage> workflowStages;
  final int totalStages;
  final ActiveStageInfo? activeStage;
  final bool hasActiveStage;
  final int clientId;
  final int? clientMatterId;
  final CaseSummary? caseSummary;

  WorkflowStagesResponse({
    required this.workflowStages,
    required this.totalStages,
    this.activeStage,
    required this.hasActiveStage,
    required this.clientId,
    this.clientMatterId,
    this.caseSummary,
  });

  factory WorkflowStagesResponse.fromJson(Map<String, dynamic> json) {
    var stagesList = <WorkflowStage>[];
    if (json['workflow_stages'] != null) {
      stagesList = (json['workflow_stages'] as List)
          .map((stage) => WorkflowStage.fromJson(stage))
          .toList();
    }

    ActiveStageInfo? activeStageInfo;
    if (json['active_stage'] != null) {
      activeStageInfo = ActiveStageInfo.fromJson(json['active_stage']);
      // Enrich client_label from the matching stage row when active_stage omits it
      if ((activeStageInfo.clientLabel == null ||
              activeStageInfo.clientLabel!.isEmpty) &&
          activeStageInfo.id != 0) {
        final match = stagesList.where((s) => s.id == activeStageInfo!.id);
        if (match.isNotEmpty &&
            match.first.clientLabel != null &&
            match.first.clientLabel!.isNotEmpty) {
          final m = match.first;
          activeStageInfo = ActiveStageInfo(
            id: activeStageInfo.id,
            name: activeStageInfo.name,
            stageName: activeStageInfo.stageName,
            clientLabel: m.clientLabel,
            clientMatterNo: activeStageInfo.clientMatterNo,
            matterStatus: activeStageInfo.matterStatus,
            stageUpdatedAt: activeStageInfo.stageUpdatedAt,
            isActive: activeStageInfo.isActive,
          );
        }
      }
    }

    CaseSummary? summary;
    if (json['case_summary'] != null) {
      summary = CaseSummary.fromJson(json['case_summary']);
    }

    return WorkflowStagesResponse(
      workflowStages: stagesList,
      totalStages: _parseInt(json['total_stages']) ?? 0,
      activeStage: activeStageInfo,
      hasActiveStage: json['has_active_stage'] ?? false,
      clientId: _parseInt(json['client_id']) ?? 0,
      clientMatterId: _parseInt(json['client_matter_id']),
      caseSummary: summary,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  int get currentStageIndex {
    if (!hasActiveStage || activeStage == null) return -1;
    return workflowStages.indexWhere((stage) => stage.id == activeStage!.id);
  }

  WorkflowStage? get currentStage {
    final i = currentStageIndex;
    if (i < 0 || i >= workflowStages.length) return null;
    return workflowStages[i];
  }

  /// Client-facing progress from prototype mapping (preferred) or index fallback.
  int get progressPercentage {
    final current = currentStage;
    if (current != null) {
      return current.mappedProgressPercent;
    }
    if (activeStage != null) {
      return activeStage!.mappedProgressPercent;
    }
    if (totalStages == 0 || currentStageIndex < 0) return 0;
    return ((currentStageIndex / totalStages) * 100).round();
  }

  String get currentDisplayName {
    final current = currentStage;
    if (current != null) return current.displayName;
    if (activeStage != null) return activeStage!.displayName;
    return '';
  }

  ClientStageTag get currentStatusTag {
    final current = currentStage;
    if (current != null) return current.statusTag;
    if (activeStage != null) return activeStage!.statusTag;
    return ClientStageTag.bansal;
  }

  /// Unique non-silent client timeline labels in order of first appearance.
  /// Prefer the curated 9-step client journey from the portal mapping prototype
  /// so the UI always matches the designed timeline.
  List<String> get clientTimelineSteps =>
      List<String>.from(kClientTimelineSteps);

  /// Ordered unique client labels actually present in this matter's CRM stages.
  List<String> get matterClientLabels {
    final seen = <String>{};
    final steps = <String>[];
    for (final stage in workflowStages) {
      if (stage.isSilent) continue;
      final label = stage.displayName;
      if (label.isEmpty || seen.contains(label)) continue;
      seen.add(label);
      steps.add(label);
    }
    return steps;
  }

  int get currentClientStepIndex {
    final name = currentDisplayName;
    if (name.isEmpty) return -1;
    final steps = clientTimelineSteps;
    final i = steps.indexOf(name);
    if (i >= 0) return i;
    // RFI overlays lodged step
    if (name.toLowerCase().contains('more info')) {
      final lodged = steps.indexWhere(
        (s) => s.toLowerCase().contains('lodged'),
      );
      return lodged >= 0 ? lodged : -1;
    }
    return -1;
  }

  int get completedStages {
    if (currentStageIndex < 0) return 0;
    return currentStageIndex;
  }

  int get remainingStages {
    if (currentStageIndex < 0) return totalStages;
    return totalStages - currentStageIndex - 1;
  }
}

class CaseSummary {
  final String? caseName;
  final String? caseStatus;
  final String? migrationAgent;
  final String? personResponsible;
  final String? personAssisting;

  CaseSummary({
    this.caseName,
    this.caseStatus,
    this.migrationAgent,
    this.personResponsible,
    this.personAssisting,
  });

  factory CaseSummary.fromJson(Map<String, dynamic> json) {
    return CaseSummary(
      caseName: json['case_name'],
      caseStatus: json['case_status'],
      migrationAgent: json['migration_agent'],
      personResponsible: json['person_responsible'],
      personAssisting: json['person_assisting'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'case_name': caseName,
      'case_status': caseStatus,
      'migration_agent': migrationAgent,
      'person_responsible': personResponsible,
      'person_assisting': personAssisting,
    };
  }
}
