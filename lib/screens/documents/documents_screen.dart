import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/document.dart';
import 'upload_document_screen.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<Document> _documents = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Mock documents data - replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
    _documents = [
      Document(
        id: 1,
        title: 'Passport Copy',
        status: 'approved',
        uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Document(
        id: 2,
            title: 'Birth Certificate',
        status: 'pending_review',
        uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Document(
        id: 3,
            title: 'Employment Letter',
        status: 'rejected',
            uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            updatedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          Document(
            id: 4,
            title: 'Educational Certificates',
            status: 'approved',
        uploadedAt: DateTime.now().subtract(const Duration(days: 7)),
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Document(
            id: 5,
            title: 'Medical Examination Report',
        status: 'pending_review',
            uploadedAt: DateTime.now().subtract(const Duration(hours: 6)),
            createdAt: DateTime.now().subtract(const Duration(hours: 6)),
            updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load documents: ${e.toString()}';
      });
    }
  }

  List<Document> get _filteredDocuments {
    return _documents.where((doc) {
      final matchesSearch = (doc.title?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesStatus = _statusFilter == 'all' || doc.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending_review':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'pending_review':
        return 'Pending Review';
      case 'rejected':
        return 'Rejected';
      case 'draft':
        return 'Draft';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'pending_review':
        return Icons.visibility;
      case 'rejected':
        return Icons.cancel;
      case 'draft':
        return Icons.edit;
      default:
        return Icons.help;
    }
  }

  IconData _getDocumentIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('passport')) return Icons.credit_card;
    if (lowerTitle.contains('birth') || lowerTitle.contains('certificate')) return Icons.cake;
    if (lowerTitle.contains('employment') || lowerTitle.contains('letter')) return Icons.work;
    if (lowerTitle.contains('medical') || lowerTitle.contains('examination')) return Icons.medical_services;
    if (lowerTitle.contains('educational') || lowerTitle.contains('diploma')) return Icons.school;
    return Icons.description;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Documents'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocuments,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const UploadDocumentScreen(),
            ),
          );
        },
        icon: const Icon(Icons.upload),
        label: const Text('Upload'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
                        children: [
          // Search and Filter Bar
                          Container(
            padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                // Search Bar
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search documents...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Status Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Approved', 'approved'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending Review', 'pending_review'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Rejected', 'rejected'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

          // Documents List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadDocuments,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredDocuments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.folder_open,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty || _statusFilter != 'all'
                                      ? 'No documents match your search'
                                      : 'No documents found',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const UploadDocumentScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.upload),
                                  label: const Text('Upload Document'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadDocuments,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredDocuments.length,
                              itemBuilder: (context, index) {
                                final document = _filteredDocuments[index];
                                return _buildDocumentCard(document);
                              },
                            ),
                          ),
                  ),
                ],
              ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
        });
      },
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildDocumentCard(Document document) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Open document preview or download
          _showDocumentOptions(document);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getDocumentIcon(document.title ?? 'unknown'),
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      document.title ?? 'Untitled Document',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(document.status ?? 'unknown').withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(document.status ?? 'unknown').withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(document.status ?? 'unknown'),
                          size: 14,
                          color: _getStatusColor(document.status ?? 'unknown'),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(document.status ?? 'unknown'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getStatusColor(document.status ?? 'unknown'),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
              const SizedBox(height: 12),
              
              Row(
        children: [
                  Icon(
                    Icons.upload,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Uploaded: ${document.uploadedAt != null ? DateFormat('MMM d, y').format(document.uploadedAt!) : 'Unknown'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.update,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Updated: ${DateFormat('MMM d, y').format(document.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
          ),
        ],
      ),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
                    'Document #${document.id}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Icons.more_vert,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDocumentOptions(Document document) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View Document'),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Implement document viewing
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Document viewing not implemented yet')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Download'),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Implement document download
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Document download not implemented yet')),
                  );
                },
              ),
              if (document.status == 'rejected')
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('Re-upload'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const UploadDocumentScreen(),
                      ),
                    );
                  },
              ),
            ],
          ),
        );
      },
    );
  }
}