import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/invoice.dart';
import '../../services/api_service.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Invoice> _invoices = [];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));

      _loadMockInvoices();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load invoices: ${e.toString()}';
      });
    }
  }

  void _loadMockInvoices() {
    _invoices = [
      Invoice(
        id: 1,
        invoiceNumber: 'INV-2024-001',
        customerId: 1,
        totalAmount: 1500.00,
        status: 'paid',
        dueDate: DateTime.now().subtract(const Duration(days: 10)),
        paidDate: DateTime.now().subtract(const Duration(days: 12)),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
      Invoice(
        id: 2,
        invoiceNumber: 'INV-2024-002',
        customerId: 1,
        totalAmount: 2500.00,
        status: 'pending',
        dueDate: DateTime.now().add(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Invoice(
        id: 3,
        invoiceNumber: 'INV-2024-003',
        customerId: 1,
        totalAmount: 800.00,
        status: 'overdue',
        dueDate: DateTime.now().subtract(const Duration(days: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Invoice(
        id: 4,
        invoiceNumber: 'INV-2024-004',
        customerId: 1,
        totalAmount: 1200.00,
        status: 'draft',
        dueDate: DateTime.now().add(const Duration(days: 20)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingWidget());
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoices')),
        body: CustomErrorWidget(
          message: _errorMessage!,
          onRetry: _loadInvoices,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
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
      body:
          _invoices.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _invoices.length,
                itemBuilder: (context, index) {
                  final invoice = _invoices[index];
                  return _buildInvoiceCard(invoice);
                },
              ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    final isOverdue =
        invoice.status == 'pending' &&
        invoice.dueDate != null &&
        invoice.dueDate!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showInvoiceDetails(invoice),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Invoice icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getStatusColor(invoice.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(invoice.status),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Invoice info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.invoiceNumber ?? 'No Invoice Number',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Amount: \$${NumberFormat('#,##0.00').format(invoice.totalAmount ?? 0)}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(invoice.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusLabel(invoice.status),
                      style: TextStyle(
                        color: _getStatusColor(invoice.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Due date and actions
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${invoice.dueDate != null ? DateFormat('MMM dd, yyyy').format(invoice.dueDate!) : 'No due date'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isOverdue ? Colors.red : Colors.grey.shade600,
                      fontWeight:
                          isOverdue ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),

                  if (isOverdue) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'OVERDUE',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Action buttons
                  if (invoice.status == 'pending' || isOverdue) ...[
                    OutlinedButton.icon(
                      onPressed: () => _payInvoice(invoice),
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text('Pay Now'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],

                  if (invoice.status == 'paid') ...[
                    OutlinedButton.icon(
                      onPressed: () => _downloadInvoice(invoice),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Download'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No invoices yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Your invoices will appear here once they are generated',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showInvoiceDetails(Invoice invoice) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Invoice ${invoice.invoiceNumber}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'Invoice Number:',
                  invoice.invoiceNumber ?? 'N/A',
                ),
                _buildDetailRow(
                  'Amount:',
                  '\$${NumberFormat('#,##0.00').format(invoice.totalAmount ?? 0)}',
                ),
                _buildDetailRow('Status:', _getStatusLabel(invoice.status)),
                _buildDetailRow(
                  'Due Date:',
                  invoice.dueDate != null
                      ? DateFormat('MMM dd, yyyy').format(invoice.dueDate!)
                      : 'No due date',
                ),
                if (invoice.paidDate != null)
                  _buildDetailRow(
                    'Paid Date:',
                    DateFormat('MMM dd, yyyy').format(invoice.paidDate!),
                  ),
                _buildDetailRow(
                  'Created:',
                  DateFormat('MMM dd, yyyy').format(invoice.createdAt),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              if (invoice.status == 'pending' || invoice.status == 'overdue')
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _payInvoice(invoice);
                  },
                  child: const Text('Pay Now'),
                ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _payInvoice(Invoice invoice) {
    // TODO: Implement payment functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment functionality coming soon!')),
    );
  }

  void _downloadInvoice(Invoice invoice) {
    // TODO: Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download functionality coming soon!')),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'draft':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'overdue':
        return Icons.warning;
      case 'draft':
        return Icons.edit;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return 'PAID';
      case 'pending':
        return 'PENDING';
      case 'overdue':
        return 'OVERDUE';
      case 'draft':
        return 'DRAFT';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return 'UNKNOWN';
    }
  }
}
