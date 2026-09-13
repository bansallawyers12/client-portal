import '../config/theme_config.dart';
import 'package:flutter/material.dart';

/// Client-facing stage mapping from the Client Portal Mapping prototype
/// (`client-portal-prototype.html`). CRM staff names stay internal; the app
/// shows [cli] labels, status tags, and curated progress %.
class ClientStageMapping {
  final String crm;
  final String cli;
  final int step;
  final ClientStageTag tag;
  final int pct;
  final bool silent;

  const ClientStageMapping({
    required this.crm,
    required this.cli,
    required this.step,
    required this.tag,
    required this.pct,
    this.silent = false,
  });
}

enum ClientStageTag { action, bansal, dept, done }

extension ClientStageTagX on ClientStageTag {
  String get label {
    switch (this) {
      case ClientStageTag.action:
        return 'Action required';
      case ClientStageTag.bansal:
        return 'With Bansal';
      case ClientStageTag.dept:
        return 'With Immigration';
      case ClientStageTag.done:
        return 'Complete';
    }
  }

  Color get foreground {
    switch (this) {
      case ClientStageTag.action:
        return const Color(0xFFC77A21);
      case ClientStageTag.bansal:
        return const Color(0xFF3B6EA5);
      case ClientStageTag.dept:
        return const Color(0xFF3A4B5E);
      case ClientStageTag.done:
        return const Color(0xFF1F8A5B);
    }
  }

  Color get background {
    switch (this) {
      case ClientStageTag.action:
        return const Color(0xFFFBF1E3);
      case ClientStageTag.bansal:
        return const Color(0xFFEAF1F8);
      case ClientStageTag.dept:
        return const Color(0xFFF4F6F9);
      case ClientStageTag.done:
        return const Color(0xFFE7F4EE);
    }
  }
}

/// Linear timeline shown in the client app (deduped client labels).
const List<String> kClientTimelineSteps = [
  'Getting started',
  'Sign your agreement',
  'Setting up your file',
  'Documents needed',
  'Preparing your application',
  'Review your draft',
  'Lodged with Immigration',
  'Decision received',
  'File completed',
];

const List<ClientStageMapping> kClientStageMap = [
  ClientStageMapping(
    crm: 'Checklist & Agreement Sent',
    cli: 'Getting started',
    step: 0,
    tag: ClientStageTag.bansal,
    pct: 5,
  ),
  ClientStageMapping(
    crm: 'Awaiting Client Action',
    cli: 'Sign your agreement',
    step: 1,
    tag: ClientStageTag.action,
    pct: 12,
  ),
  ClientStageMapping(
    crm: 'Verification & File Setup',
    cli: 'Setting up your file',
    step: 2,
    tag: ClientStageTag.bansal,
    pct: 20,
  ),
  ClientStageMapping(
    crm: 'Documents Review & Completion',
    cli: 'Documents needed',
    step: 3,
    tag: ClientStageTag.action,
    pct: 30,
  ),
  ClientStageMapping(
    crm: 'Draft Preparation',
    cli: 'Preparing your application',
    step: 4,
    tag: ClientStageTag.bansal,
    pct: 42,
  ),
  ClientStageMapping(
    crm: 'Internal Review',
    cli: 'Preparing your application',
    step: 4,
    tag: ClientStageTag.bansal,
    pct: 48,
    silent: true,
  ),
  ClientStageMapping(
    crm: 'Client Draft Approval',
    cli: 'Review your draft',
    step: 5,
    tag: ClientStageTag.action,
    pct: 55,
  ),
  ClientStageMapping(
    crm: 'Lodgement Completed',
    cli: 'Lodged with Immigration',
    step: 6,
    tag: ClientStageTag.dept,
    pct: 70,
  ),
  ClientStageMapping(
    crm: 'Awaiting Outcome',
    cli: 'Lodged with Immigration',
    step: 6,
    tag: ClientStageTag.dept,
    pct: 75,
    silent: true,
  ),
  ClientStageMapping(
    crm: 'Additional Request, if Any',
    cli: 'More info requested',
    step: 6,
    tag: ClientStageTag.action,
    pct: 78,
  ),
  ClientStageMapping(
    crm: 'Decision Received',
    cli: 'Decision received',
    step: 7,
    tag: ClientStageTag.done,
    pct: 90,
  ),
  ClientStageMapping(
    crm: 'Outcome / Ready to Close',
    cli: 'Decision received',
    step: 7,
    tag: ClientStageTag.done,
    pct: 95,
    silent: true,
  ),
  ClientStageMapping(
    crm: 'File Closed',
    cli: 'File completed',
    step: 8,
    tag: ClientStageTag.done,
    pct: 100,
  ),
];

ClientStageMapping? findClientStageMapping(String? crmName) {
  if (crmName == null || crmName.trim().isEmpty) return null;
  final needle = crmName.trim().toLowerCase();
  for (final m in kClientStageMap) {
    if (m.crm.toLowerCase() == needle) return m;
  }
  // Partial match for slight CRM wording differences
  for (final m in kClientStageMap) {
    if (needle.contains(m.crm.toLowerCase()) ||
        m.crm.toLowerCase().contains(needle)) {
      return m;
    }
  }
  return null;
}

String clientDisplayName({
  String? clientLabel,
  String? crmName,
  String fallback = '',
}) {
  final fromApi = clientLabel?.trim();
  if (fromApi != null && fromApi.isNotEmpty) return fromApi;
  final mapped = findClientStageMapping(crmName);
  if (mapped != null) return mapped.cli;
  final crm = crmName?.trim();
  if (crm != null && crm.isNotEmpty) return crm;
  return fallback;
}

int clientProgressPercent({
  String? clientLabel,
  String? crmName,
  int? fallbackIndexBased,
}) {
  final mapped = findClientStageMapping(crmName);
  if (mapped != null) return mapped.pct;
  // Fall back to step index from known client labels
  final label = clientDisplayName(clientLabel: clientLabel, crmName: crmName);
  final step = kClientTimelineSteps.indexOf(label);
  if (step >= 0) {
    return (((step + 1) / kClientTimelineSteps.length) * 100).round();
  }
  return fallbackIndexBased ?? 0;
}

ClientStageTag clientStageTag({String? crmName, String? clientLabel}) {
  final mapped = findClientStageMapping(crmName);
  if (mapped != null) return mapped.tag;
  final label =
      clientDisplayName(clientLabel: clientLabel, crmName: crmName)
          .toLowerCase();
  if (label.contains('sign') ||
      label.contains('documents') ||
      label.contains('review') ||
      label.contains('more info')) {
    return ClientStageTag.action;
  }
  if (label.contains('lodged') || label.contains('immigration')) {
    return ClientStageTag.dept;
  }
  if (label.contains('decision') || label.contains('completed')) {
    return ClientStageTag.done;
  }
  return ClientStageTag.bansal;
}

/// Brand chip colors aligned with ThemeConfig when needed.
Color clientTagAccent(ClientStageTag tag) {
  switch (tag) {
    case ClientStageTag.bansal:
      return ThemeConfig.navyBlue;
    case ClientStageTag.action:
      return ThemeConfig.goldenYellow;
    case ClientStageTag.dept:
      return const Color(0xFF3A4B5E);
    case ClientStageTag.done:
      return ThemeConfig.successColor;
  }
}
