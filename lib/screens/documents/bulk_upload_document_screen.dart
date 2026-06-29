import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/theme_config.dart';
import '../../models/new/allowed_checklist.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_loader.dart';
import '../../utils/responsive_utils.dart';

class BulkUploadDocumentScreen extends StatefulWidget {
  final int? matterID;
  final int? stageId;
  final int? allowedCheckListId;

  const BulkUploadDocumentScreen({
    super.key,
    this.matterID,
    this.stageId,
    this.allowedCheckListId,
  });

  @override
  State<BulkUploadDocumentScreen> createState() =>
      _BulkUploadDocumentScreenState();
}

class SelectedUploadFile {
  Uint8List bytes;
  String fileName;

  int? selectedChecklistId;
  int? selectedStageId;

  SelectedUploadFile({
    required this.bytes,
    required this.fileName,
    this.selectedChecklistId,
    this.selectedStageId,
  });
}

class _BulkUploadDocumentScreenState extends State<BulkUploadDocumentScreen>
    with SingleTickerProviderStateMixin {
  List<AllowedChecklist> _checklists = [];
  List<SelectedUploadFile> _selectedFiles = [];

  bool _isLoading = false;
  bool _isUploading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _loadChecklists();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  int get _clientMatterId =>
      (widget.matterID != null && widget.matterID! > 0)
          ? widget.matterID!
          : (AuthService.selectedMatterId ?? 0);

  int? get _stageId =>
      widget.stageId != null && widget.stageId! > 0 ? widget.stageId : null;

  Future<void> _loadChecklists() async {
    setState(() => _isLoading = true);

    try {
      final res = await ApiService.getWorkflowAllowedChecklist(
        clientMatterId: _clientMatterId,
        stageId: _stageId,
        allowedChecklistID: widget.allowedCheckListId,
      );

      if (res['success'] == true) {
        final list = res['data']['allowed_checklists'] ?? [];
        _checklists =
            list
                .map<AllowedChecklist>((e) => AllowedChecklist.fromJson(e))
                .toList();
      }
    } catch (e) {
      _showSnack("Checklist load error: $e", isError: true);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _selectedFiles.addAll(
          result.files
              .where((e) => e.bytes != null)
              .map(
                (e) => SelectedUploadFile(bytes: e.bytes!, fileName: e.name),
              ),
        );
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedFiles.add(
          SelectedUploadFile(bytes: bytes, fileName: image.name),
        );
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedFiles.add(
          SelectedUploadFile(bytes: bytes, fileName: image.name),
        );
      });
    }
  }

  Future<void> _openUploadOptions() async {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  "Add Files",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBottomSheetOption(
                  icon: Icons.folder_open_rounded,
                  label: "My Files",
                  subtitle: "PDF, DOC, DOCX, JPG, PNG",
                  color: const Color(0xFF5B8DEF),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickFiles();
                  },
                ),
                const SizedBox(height: 10),
                _buildBottomSheetOption(
                  icon: Icons.photo_library_rounded,
                  label: "Gallery",
                  subtitle: "Pick from your photos",
                  color: const Color(0xFF8B5CF6),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickFromGallery();
                  },
                ),
                if (!kIsWeb) ...[
                  const SizedBox(height: 10),
                  _buildBottomSheetOption(
                    icon: Icons.camera_alt_rounded,
                    label: "Camera",
                    subtitle: "Take a new photo",
                    color: const Color(0xFF10B981),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickFromCamera();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha:0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadAll() async {
    setState(() => _isUploading = true);

    try {
      final filesData = <({Uint8List bytes, String name})>[];
      final ids = <int>[];

      for (final file in _selectedFiles) {
        if (file.selectedChecklistId != null) {
          filesData.add((bytes: file.bytes, name: file.fileName));
          ids.add(file.selectedChecklistId!);
        }
      }

      if (filesData.isEmpty) {
        _showSnack("Please select checklist for files", isError: true);
        setState(() => _isUploading = false);
        return;
      }

      final res = await ApiService.bulkUploadChecklistDocuments(
        filesData: filesData,
        allowedChecklistIds: ids,
        clientMatterId: _clientMatterId,
      );

      if (res['success'] == true) {
        _showSnack("Documents uploaded successfully");
        Navigator.pop(context, true);
      } else {
        _showSnack(res['message'] ?? "Upload failed", isError: true);
      }
    } catch (e) {
      _showSnack("Upload error: $e", isError: true);
    }

    setState(() => _isUploading = false);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  List<int> get _uniqueStageIds {
    final ids = _checklists.map((e) => e.typeId).toSet().toList();
    ids.sort();
    return ids;
  }

  String _getStageName(int stageId) {
    try {
      return _checklists.firstWhere((e) => e.typeId == stageId).typeName;
    } catch (_) {
      return "Stage $stageId";
    }
  }

  List<AllowedChecklist> _getChecklistByStage(int stageId) {
    return _checklists.where((e) => e.typeId == stageId).toList();
  }

  // ─── File icon helper ───────────────────────────────────────────────────────
  IconData _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png'].contains(ext)) return Icons.image_rounded;
    if (ext == 'pdf') return Icons.picture_as_pdf_rounded;
    return Icons.description_rounded;
  }

  Color _fileIconColor(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png'].contains(ext)) return const Color(0xFF8B5CF6);
    if (ext == 'pdf') return const Color(0xFFEF4444);
    return const Color(0xFF5B8DEF);
  }

  // ─── Shared dropdown decoration ─────────────────────────────────────────────
  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade500,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: ThemeConfig.goldenYellow, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  // ─── Desktop table ───────────────────────────────────────────────────────────
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "FILE NAME",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "STAGE",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              "CHECKLIST",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 56, child: Text("")),
        ],
      ),
    );
  }

  Widget _buildFileRow(SelectedUploadFile file, int index) {
    final checklists =
        file.selectedStageId != null
            ? _getChecklistByStage(file.selectedStageId!)
            : <AllowedChecklist>[];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // FILE NAME
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _fileIconColor(file.fileName).withValues(alpha:0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _fileIcon(file.fileName),
                      color: _fileIconColor(file.fileName),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      file.fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // STAGE DROPDOWN
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<int>(
                initialValue: file.selectedStageId,
                isExpanded: true,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                decoration: _dropdownDecoration("Stage"),
                hint: Text(
                  "Select",
                  style: TextStyle(fontSize: 13, color: Colors.black),
                ),
                items:
                    _uniqueStageIds.map((stageId) {
                      return DropdownMenuItem<int>(
                        value: stageId,
                        child: Text(
                          _getStageName(stageId),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    file.selectedStageId = value;
                    file.selectedChecklistId = null;
                  });
                },
              ),
            ),

            const SizedBox(width: 12),

            // CHECKLIST DROPDOWN
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<int>(
                initialValue: file.selectedChecklistId,
                isExpanded: true,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                decoration: _dropdownDecoration("Checklist"),
                hint: Text(
                  file.selectedStageId == null
                      ? "Select stage first"
                      : "Select",
                  style: TextStyle(fontSize: 13, color: Colors.black),
                ),
                items:
                    checklists.map((checklist) {
                      return DropdownMenuItem<int>(
                        value: checklist.id,
                        child: Text(
                          checklist.checklistName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                onChanged:
                    file.selectedStageId == null
                        ? null
                        : (value) {
                          setState(() {
                            file.selectedChecklistId = value;
                          });
                        },
              ),
            ),

            const SizedBox(width: 12),

            // DELETE
            SizedBox(
              width: 56,
              child: Tooltip(
                message: "Remove file",
                child: Material(
                  color: Colors.red.withValues(alpha:0.08),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _selectedFiles.removeAt(index);
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildTableHeader(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedFiles.length,
            itemBuilder:
                (_, index) => _buildFileRow(_selectedFiles[index], index),
          ),
        ],
      ),
    );
  }

  // ─── Mobile card ─────────────────────────────────────────────────────────────
  Widget _buildMobileCard(SelectedUploadFile file, int index) {
    final checklists =
        file.selectedStageId != null
            ? _getChecklistByStage(file.selectedStageId!)
            : <AllowedChecklist>[];

    final bool isComplete =
        file.selectedStageId != null && file.selectedChecklistId != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isComplete
                  ? ThemeConfig.goldenYellow.withValues(alpha:0.4)
                  : Colors.grey.shade200,
          width: isComplete ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _fileIconColor(file.fileName).withValues(alpha:0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _fileIcon(file.fileName),
                    color: _fileIconColor(file.fileName),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isComplete ? "Ready to upload" : "Needs configuration",
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isComplete
                                  ? const Color(0xFF10B981)
                                  : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isComplete)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha:0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF10B981),
                      size: 14,
                    ),
                  ),
                Material(
                  color: Colors.red.withValues(alpha:0.07),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _selectedFiles.removeAt(index);
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade100),

          // Dropdowns
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  initialValue: file.selectedStageId,
                  isExpanded: true,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  decoration: _dropdownDecoration("Stage"),
                  hint: Text(
                    "Select stage",
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  items:
                      _uniqueStageIds.map((stageId) {
                        return DropdownMenuItem<int>(
                          value: stageId,
                          child: Text(
                            _getStageName(stageId),
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      file.selectedStageId = value;
                      file.selectedChecklistId = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: file.selectedChecklistId,
                  isExpanded: true,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  decoration: _dropdownDecoration("Checklist"),
                  hint: Text(
                    file.selectedStageId == null
                        ? "Select a stage first"
                        : "Select checklist",
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  items:
                      checklists.map((checklist) {
                        return DropdownMenuItem<int>(
                          value: checklist.id,
                          child: Text(
                            checklist.checklistName,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                  onChanged:
                      file.selectedStageId == null
                          ? null
                          : (value) {
                            setState(() {
                              file.selectedChecklistId = value;
                            });
                          },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty state ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_upload_outlined,
              size: 36,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "No files selected",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Tap \"Choose Files\" to get started",
            style: TextStyle(fontSize: 13, color: Colors.black),
          ),
        ],
      ),
    );
  }

  // ─── Summary badge ────────────────────────────────────────────────────────────
  Widget _buildSummaryBadge() {
    final ready =
        _selectedFiles.where((f) => f.selectedChecklistId != null).length;
    final total = _selectedFiles.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ThemeConfig.goldenYellow.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeConfig.goldenYellow.withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: ThemeConfig.goldenYellow,
          ),
          const SizedBox(width: 8),
          Text(
            "$ready of $total file${total == 1 ? '' : 's'} configured",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ThemeConfig.goldenYellow,
            ),
          ),
          const Spacer(),
          if (ready < total)
            Text(
              "${total - ready} pending",
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: ThemeConfig.goldenYellow,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Upload Documents",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          if (_selectedFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${_selectedFiles.length} file${_selectedFiles.length == 1 ? '' : 's'}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: AppLoader())
              : FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Choose Files button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _openUploadOptions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ThemeConfig.goldenYellow,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: const Text(
                              "Choose Files",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Summary badge
                    if (_selectedFiles.isNotEmpty) ...[
                      _buildSummaryBadge(),
                      const SizedBox(height: 16),
                    ],

                    // File list
                    Expanded(
                      child:
                          _selectedFiles.isEmpty
                              ? _buildEmptyState()
                              : SingleChildScrollView(
                                padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).padding.bottom +
                                      100,
                                ),
                                child:
                                    isMobile
                                        ? Column(
                                          children: List.generate(
                                            _selectedFiles.length,
                                            (index) => _buildMobileCard(
                                              _selectedFiles[index],
                                              index,
                                            ),
                                          ),
                                        )
                                        : _buildDesktopTable(),
                              ),
                    ),

                    // Upload All button
                    Container(
                      padding: AppResponsive.pagePadding(context).add(
                        EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom + 12,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _uploadAll,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ThemeConfig.goldenYellow,
                            disabledBackgroundColor: ThemeConfig.goldenYellow
                                .withValues(alpha:0.5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child:
                              _isUploading
                                  ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: AppLoader(size: 20),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "Uploading...",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.cloud_upload_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "Upload All",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
