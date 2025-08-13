class Invoice {
  final int id;
  final int? customerId;
  final String? invoiceNumber;
  final String? status;
  final DateTime? dueDate;
  final DateTime? issuedDate;
  final DateTime? paidDate;
  final double? subtotal;
  final double? taxAmount;
  final double? totalAmount;
  final double? paidAmount;
  final double? balanceDue;
  final String? currency;
  final String? notes;
  final List<InvoiceItem>? items;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    this.customerId,
    this.invoiceNumber,
    this.status,
    this.dueDate,
    this.issuedDate,
    this.paidDate,
    this.subtotal,
    this.taxAmount,
    this.totalAmount,
    this.paidAmount,
    this.balanceDue,
    this.currency,
    this.notes,
    this.items,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor from JSON
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] ?? 0,
      customerId: json['customer_id'],
      invoiceNumber: json['invoice_number'],
      status: json['status'] ?? 'draft',
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date']) : null,
      issuedDate: json['issued_date'] != null 
          ? DateTime.parse(json['issued_date']) : null,
      paidDate: json['paid_date'] != null 
          ? DateTime.parse(json['paid_date']) : null,
      subtotal: json['subtotal']?.toDouble(),
      taxAmount: json['tax_amount']?.toDouble(),
      totalAmount: json['total_amount']?.toDouble(),
      paidAmount: json['paid_amount']?.toDouble(),
      balanceDue: json['balance_due']?.toDouble(),
      currency: json['currency'] ?? 'USD',
      notes: json['notes'],
      items: json['items'] != null 
          ? (json['items'] as List).map((item) => InvoiceItem.fromJson(item)).toList()
          : null,
      metadata: json['metadata'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'invoice_number': invoiceNumber,
      'status': status,
      'due_date': dueDate?.toIso8601String(),
      'issued_date': issuedDate?.toIso8601String(),
      'paid_date': paidDate?.toIso8601String(),
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'balance_due': balanceDue,
      'currency': currency,
      'notes': notes,
      'items': items?.map((item) => item.toJson()).toList(),
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Copy with method
  Invoice copyWith({
    int? id,
    int? customerId,
    String? invoiceNumber,
    String? status,
    DateTime? dueDate,
    DateTime? issuedDate,
    DateTime? paidDate,
    double? subtotal,
    double? taxAmount,
    double? totalAmount,
    double? paidAmount,
    double? balanceDue,
    String? currency,
    String? notes,
    List<InvoiceItem>? items,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      issuedDate: issuedDate ?? this.issuedDate,
      paidDate: paidDate ?? this.paidDate,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceDue: balanceDue ?? this.balanceDue,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get status color
  String get statusColor {
    switch (status?.toLowerCase()) {
      case 'paid':
        return '#27AE60'; // Green
      case 'pending':
        return '#F39C12'; // Orange
      case 'overdue':
        return '#E74C3C'; // Red
      case 'draft':
        return '#95A5A6'; // Gray
      case 'cancelled':
        return '#C0392B'; // Dark Red
      case 'partial':
        return '#9B59B6'; // Purple
      default:
        return '#95A5A6'; // Gray
    }
  }

  // Check if invoice is paid
  bool get isPaid {
    return status?.toLowerCase() == 'paid';
  }

  // Check if invoice is pending
  bool get isPending {
    return status?.toLowerCase() == 'pending';
  }

  // Check if invoice is overdue
  bool get isOverdue {
    if (dueDate == null || isPaid) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  // Check if invoice is draft
  bool get isDraft {
    return status?.toLowerCase() == 'draft';
  }

  // Check if invoice is cancelled
  bool get isCancelled {
    return status?.toLowerCase() == 'cancelled';
  }

  // Check if invoice is partially paid
  bool get isPartiallyPaid {
    return status?.toLowerCase() == 'partial';
  }

  // Check if invoice is due today
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
           dueDate!.month == now.month &&
           dueDate!.day == now.day;
  }

  // Check if invoice is due soon (within 7 days)
  bool get isDueSoon {
    if (dueDate == null || isPaid) return false;
    final now = DateTime.now();
    final difference = dueDate!.difference(now).inDays;
    return difference >= 0 && difference <= 7;
  }

  // Get due date formatted
  String get dueDateFormatted {
    if (dueDate == null) return 'No due date';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final invoiceDueDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    
    if (invoiceDueDate == today) {
      return 'Due today';
    } else if (invoiceDueDate == today.add(const Duration(days: 1))) {
      return 'Due tomorrow';
    } else if (invoiceDueDate.isBefore(today)) {
      return 'Overdue by ${today.difference(invoiceDueDate).inDays} days';
    } else {
      final difference = invoiceDueDate.difference(today).inDays;
      if (difference <= 7) {
        return 'Due in $difference days';
      } else {
        return 'Due ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}';
      }
    }
  }

  // Get payment status text
  String get paymentStatusText {
    if (isPaid) return 'Paid';
    if (isPartiallyPaid) return 'Partially Paid';
    if (isOverdue) return 'Overdue';
    if (isDueToday) return 'Due Today';
    if (isDueSoon) return 'Due Soon';
    if (isPending) return 'Pending Payment';
    if (isDraft) return 'Draft';
    if (isCancelled) return 'Cancelled';
    return 'Unknown';
  }

  // Get amount formatted
  String get amountFormatted {
    if (totalAmount == null) return 'N/A';
    return '\$${totalAmount!.toStringAsFixed(2)}';
  }

  // Get balance formatted
  String get balanceFormatted {
    if (balanceDue == null) return 'N/A';
    return '\$${balanceDue!.toStringAsFixed(2)}';
  }

  // Get paid amount formatted
  String get paidAmountFormatted {
    if (paidAmount == null) return 'N/A';
    return '\$${paidAmount!.toStringAsFixed(2)}';
  }

  // Get payment percentage
  double get paymentPercentage {
    if (totalAmount == null || totalAmount == 0) return 0.0;
    if (paidAmount == null) return 0.0;
    return (paidAmount! / totalAmount!) * 100;
  }

  // Get days until due
  int? get daysUntilDue {
    if (dueDate == null || isPaid) return null;
    final now = DateTime.now();
    final difference = dueDate!.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  // Get days overdue
  int? get daysOverdue {
    if (dueDate == null || isPaid) return null;
    if (!isOverdue) return null;
    final now = DateTime.now();
    return now.difference(dueDate!).inDays;
  }

  // Get display invoice number
  String get displayInvoiceNumber {
    return invoiceNumber ?? 'INV-${id.toString().padLeft(6, '0')}';
  }

  // Get display status
  String get displayStatus {
    return status ?? 'Draft';
  }

  // Get display currency
  String get displayCurrency {
    return currency ?? 'USD';
  }

  @override
  String toString() {
    return 'Invoice(id: $id, invoiceNumber: $invoiceNumber, status: $status, totalAmount: $totalAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Invoice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class InvoiceItem {
  final int id;
  final String? description;
  final int? quantity;
  final double? unitPrice;
  final double? totalPrice;
  final String? itemType;
  final Map<String, dynamic>? metadata;

  InvoiceItem({
    required this.id,
    this.description,
    this.quantity,
    this.unitPrice,
    this.totalPrice,
    this.itemType,
    this.metadata,
  });

  // Factory constructor from JSON
  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] ?? 0,
      description: json['description'],
      quantity: json['quantity'],
      unitPrice: json['unit_price']?.toDouble(),
      totalPrice: json['total_price']?.toDouble(),
      itemType: json['item_type'],
      metadata: json['metadata'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'item_type': itemType,
      'metadata': metadata,
    };
  }

  // Get quantity formatted
  String get quantityFormatted {
    return quantity?.toString() ?? '0';
  }

  // Get unit price formatted
  String get unitPriceFormatted {
    if (unitPrice == null) return 'N/A';
    return '\$${unitPrice!.toStringAsFixed(2)}';
  }

  // Get total price formatted
  String get totalPriceFormatted {
    if (totalPrice == null) return 'N/A';
    return '\$${totalPrice!.toStringAsFixed(2)}';
  }

  // Get display description
  String get displayDescription {
    return description ?? 'No description';
  }

  // Get display item type
  String get displayItemType {
    return itemType ?? 'Service';
  }

  @override
  String toString() {
    return 'InvoiceItem(id: $id, description: $description, quantity: $quantity, totalPrice: $totalPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvoiceItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
