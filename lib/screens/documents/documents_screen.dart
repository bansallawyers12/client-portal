import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../models/document.dart';
import '../../models/case.dart';
import '../../services/api_service.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/documents/document_card.dart';
import '../../widgets/documents/upload_progress.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Document> _documents = [];
  List<Case> _cases = [];

  // Upload state
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadStatus;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _loadCases();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));

      _loadMockDocuments();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load documents: ${e.toString()}';
      });
    }
  }

  Future<void> _loadCases() async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      _loadMockCases();
    } catch (e) {
      // Handle error silently for now
      print('Failed to load cases: $e');
    }
  }

  void _loadMockDocuments() {
    _documents = [
      Document(
        id: 1,
        title: 'Passport Copy',
        description: 'Valid passport with at least 6 months validity',
        status: 'approved',
        uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Document(
        id: 2,
        title: 'Academic Transcripts',
        description: 'Official academic transcripts from university',
        status: 'pending_review',
        uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Document(
        id: 3,
        title: 'Financial Statements',
        description: 'Bank statements for the last 6 months',
        status: 'rejected',
        uploadedAt: DateTime.now().subtract(const Duration(days: 7)),
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Document(
        id: 4,
        title: 'Employment Letter',
        description: 'Current employment verification letter',
        status: 'pending_review',
        uploadedAt: DateTime.now().subtract(const Duration(hours: 12)),
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];
  }

  void _loadMockCases() {
    _cases = [
      Case(
        id: 1,
        name: 'Student Visa Application',
        status: 'in_progress',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Case(
        id: 2,
        name: 'Work Permit Renewal',
        status: 'pending_documents',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  Future<void> _uploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Show upload dialog
        final uploaded = await _showUploadDialog(file);

        if (uploaded) {
          // Refresh documents list
          await _loadDocuments();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showUploadDialog(PlatformFile file) async {
    String title = '';
    String description = '';
    int? selectedCaseId;
    String priority = 'medium';

    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Upload Document'),
                content: StatefulBuilder(
                  builder:
                      (context, setState) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // File info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getFileIcon(file.extension),
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Title field
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Document Title',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) => title = value,
                          ),

                          const SizedBox(height: 16),

                          // Description field
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            onChanged: (value) => description = value,
                          ),

                          const SizedBox(height: 16),

                          // Case selection
                          if (_cases.isNotEmpty) ...[
                            DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'Related Case (Optional)',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedCaseId,
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('No specific case'),
                                ),
                                ..._cases.map(
                                  (caseItem) => DropdownMenuItem(
                                    value: caseItem.id,
                                    child: Text(caseItem.name),
                                  ),
                                ),
                              ],
                              onChanged: (value) => selectedCaseId = value,
                            ),

                            const SizedBox(height: 16),
                          ],

                          // Priority selection
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(),
                            ),
                            value: priority,
                            items: const [
                              DropdownMenuItem(
                                value: 'low',
                                child: Text('Low'),
                              ),
                              DropdownMenuItem(
                                value: 'medium',
                                child: Text('Medium'),
                              ),
                              DropdownMenuItem(
                                value: 'high',
                                child: Text('High'),
                              ),
                              DropdownMenuItem(
                                value: 'critical',
                                child: Text('Critical'),
                              ),
                            ],
                            onChanged: (value) => priority = value!,
                          ),
                        ],
                      ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        title.trim().isEmpty
                            ? null
                            : () async {
                              Navigator.of(context).pop(true);
                              await _performUpload(
                                file,
                                title,
                                description,
                                selectedCaseId,
                                priority,
                              );
                            },
                    child: const Text('Upload'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<void> _performUpload(
    PlatformFile file,
    String title,
    String description,
    int? caseId,
    String priority,
  ) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Preparing upload...';
    });

    try {
      // Simulate upload progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        setState(() {
          _uploadProgress = i / 100;
          _uploadStatus = 'Uploading... ${i}%';
        });
      }

      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Simulate API response
      final newDocument = Document(
        id: _documents.length + 1,
        title: title,
        description: description,
        status: 'pending_review',
        uploadedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      setState(() {
        _documents.insert(0, newDocument);
        _isUploading = false;
        _uploadStatus = 'Upload completed successfully!';
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset status after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _uploadStatus = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadStatus = 'Upload failed: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingWidget());
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Documents')),
        body: CustomErrorWidget(
          message: _errorMessage!,
          onRetry: _loadDocuments,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Upload progress indicator
          if (_isUploading || _uploadStatus != null)
            UploadProgress(
              isUploading: _isUploading,
              progress: _uploadProgress,
              status: _uploadStatus ?? '',
            ),

          // Documents list
          Expanded(
            child:
                _documents.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _documents.length,
                      itemBuilder: (context, index) {
                        final document = _documents[index];
                        return DocumentCard(
                          document: document,
                          onTap: () {
                            // TODO: Navigate to document details
                          },
                          onDelete: () => _deleteDocument(document),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _uploadDocument,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No documents yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your first document to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _uploadDocument,
            icon: const Icon(Icons.upload),
            label: const Text('Upload Document'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDocument(Document document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Document'),
            content: Text(
              'Are you sure you want to delete "${document.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // TODO: Replace with actual API call
        await Future.delayed(const Duration(milliseconds: 500));

        setState(() {
          _documents.removeWhere((d) => d.id == document.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete document: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
