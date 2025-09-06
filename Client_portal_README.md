# LegiComply Client Portal - Flutter Application

## Overview

The LegiComply Client Portal is a comprehensive Flutter application designed for immigration and legal services. This document provides complete technical specifications for integrating with a Laravel backend system.

## Application Information

- **App Name**: LegiComply Client Portal
- **Version**: 1.0.0
- **Company**: LegiComply
- **Description**: Immigration & Legal Services Client Portal
- **Platform**: Flutter (Web, Android, iOS, Windows, macOS, Linux)

## Architecture

### Technology Stack
- **Frontend**: Flutter 3.x
- **State Management**: Provider
- **Local Storage**: Hive
- **HTTP Client**: Dio + Retrofit
- **Authentication**: JWT with refresh tokens
- **File Handling**: image_picker, file_picker
- **Notifications**: Firebase Cloud Messaging
- **Charts**: fl_chart
- **UI Components**: Material Design 3

### Project Structure
```
lib/
├── config/                 # Configuration files
│   ├── api_config.dart     # API endpoints and settings
│   ├── app_config.dart     # App-wide configuration
│   └── theme_config.dart   # UI theme configuration
├── models/                 # Data models
│   ├── client.dart         # Client/User model
│   ├── appointment.dart    # Appointment model
│   ├── case.dart          # Legal case model
│   ├── document.dart      # Document model
│   ├── invoice.dart       # Invoice/Billing model
│   ├── task.dart          # Task model
│   ├── message.dart       # Message model
│   └── ...                # Other models
├── screens/               # UI screens
│   ├── auth/              # Authentication screens
│   ├── dashboard/         # Dashboard screens
│   ├── cases/             # Case management screens
│   ├── appointments/      # Appointment screens
│   ├── documents/         # Document screens
│   ├── tasks/             # Task screens
│   ├── billing/           # Billing screens
│   └── messages/          # Message screens
├── services/              # Business logic
│   ├── api_service.dart   # API communication
│   └── auth_service.dart  # Authentication logic
├── widgets/               # Reusable UI components
└── main.dart             # Application entry point
```

## API Integration

### Base Configuration
- **Base URL**: `http://localhost:8000/api` (configurable)
- **Client Portal Endpoint**: `/client-portal`
- **Timeout**: 30 seconds
- **Content-Type**: `application/json`
- **Authentication**: Bearer Token (JWT)

### Authentication Endpoints

#### 1. Login
- **Endpoint**: `POST /auth/login`
- **Request Body**:
```json
{
  "email": "string",
  "password": "string",
  "device_name": "flutter-client-portal",
  "device_token": "string"
}
```
- **Response**:
```json
{
  "success": true,
  "data": {
    "token": "jwt_token",
    "refresh_token": "refresh_token",
    "user": {
      "id": 1,
      "name": "Client Name",
      "email": "client@example.com",
      "client_id": "CLI-001"
    }
  }
}
```

#### 2. Register
- **Endpoint**: `POST /auth/register`
- **Request Body**:
```json
{
  "name": "string",
  "email": "string",
  "password": "string",
  "password_confirmation": "string",
  "phone": "string",
  "client_id": "string"
}
```

#### 3. Logout
- **Endpoint**: `POST /auth/logout`
- **Headers**: `Authorization: Bearer {token}`

#### 4. Refresh Token
- **Endpoint**: `POST /auth/refresh`
- **Request Body**:
```json
{
  "refresh_token": "string"
}
```

#### 5. Forgot Password
- **Endpoint**: `POST /auth/forgot-password`
- **Request Body**:
```json
{
  "email": "string"
}
```

### Client Portal Endpoints

#### 1. Client Profile
- **Get Profile**: `GET /client-portal/profile`
- **Update Profile**: `PUT /client-portal/profile`
- **Request Body** (Update):
```json
{
  "first_name": "string",
  "last_name": "string",
  "phone": "string",
  "address": "string",
  "city": "string",
  "state": "string",
  "post_code": "string",
  "country": "string",
  "dob": "YYYY-MM-DD",
  "gender": "string",
  "marital_status": "string"
}
```

#### 2. Cases
- **Get Cases**: `GET /client-portal/cases`
- **Get Case Details**: `GET /client-portal/cases/{id}`
- **Response** (Cases List):
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Visa Application",
      "status": "in_progress",
      "case_number": "CASE-001",
      "case_type": "Immigration",
      "description": "Student visa application",
      "priority": "high",
      "estimated_completion": "2024-06-01",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

#### 3. Appointments
- **Get Appointments**: `GET /client-portal/appointments`
- **Book Appointment**: `POST /client-portal/appointments`
- **Update Appointment**: `PUT /client-portal/appointments/{id}`
- **Cancel Appointment**: `DELETE /client-portal/appointments/{id}`
- **Request Body** (Book Appointment):
```json
{
  "title": "string",
  "description": "string",
  "appointment_date": "YYYY-MM-DD",
  "appointment_time": "HH:MM",
  "duration": 60,
  "location": "string",
  "service_id": 1,
  "preferred_language": "string"
}
```

#### 4. Documents
- **Get Documents**: `GET /client-portal/documents`
- **Upload Document**: `POST /client-portal/documents` (multipart/form-data)
- **Download Document**: `GET /client-portal/documents/{id}/download`
- **Delete Document**: `DELETE /client-portal/documents/{id}`
- **Request Body** (Upload):
```json
{
  "title": "string",
  "description": "string",
  "category": "string",
  "urgency": "high|medium|low",
  "file": "file_object"
}
```

#### 5. Tasks
- **Get Tasks**: `GET /client-portal/tasks`
- **Create Task**: `POST /client-portal/tasks`
- **Update Task**: `PUT /client-portal/tasks/{id}`
- **Complete Task**: `PATCH /client-portal/tasks/{id}/complete`
- **Request Body** (Create Task):
```json
{
  "title": "string",
  "description": "string",
  "priority": "high|medium|low",
  "due_date": "YYYY-MM-DD",
  "task_group": "string",
  "tags": ["string"]
}
```

#### 6. Messages
- **Get Messages**: `GET /client-portal/messages`
- **Send Message**: `POST /client-portal/messages`
- **Mark as Read**: `PATCH /client-portal/messages/{id}/read`
- **Request Body** (Send Message):
```json
{
  "subject": "string",
  "message": "string",
  "message_type": "urgent|important|normal|low_priority",
  "attachments": ["file_paths"]
}
```

#### 7. Invoices/Billing
- **Get Invoices**: `GET /client-portal/invoices`
- **Get Invoice Details**: `GET /client-portal/invoices/{id}`
- **Download Invoice**: `GET /client-portal/invoices/{id}/download`
- **Response** (Invoices List):
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "invoice_number": "INV-001",
      "status": "pending",
      "due_date": "2024-02-01",
      "total_amount": 1500.00,
      "paid_amount": 0.00,
      "balance_due": 1500.00,
      "currency": "USD",
      "notes": "Legal consultation fees",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

## Data Models

### Client Model
```dart
class Client {
  final int id;
  final String clientId;
  final String name;
  final String email;
  final String phone;
  final String city;
  final String address;
  final DateTime? dob;
  final DateTime? weddingAnniversary;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String? age;
  final String? maritalStatus;
  final String? phoneNumber1;
  final String? phoneNumber2;
  final String? phoneNumber3;
  final String? state;
  final String? postCode;
  final String? country;
  final String? contactType1;
  final String? contactType2;
  final String? contactType3;
  final String? emailType;
  final String? email2;
  final bool? phoneVerify;
  final bool? emailVerify;
  final String? visaType;
  final String? visaExpiry;
  final String? preferredIntake;
  final String? passportCountry;
  final String? passportNumber;
  final String? nominatedOccupation;
  final String? skillAssessment;
  final String? highestQualificationAus;
  final String? highestQualificationOverseas;
  final String? workExpAus;
  final String? workExpOverseas;
  final String? englishScore;
  final String? themeMode;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Case Model
```dart
class Case {
  final int id;
  final String name;
  final String status;
  final int? packageId;
  final int? userId;
  final int? agentId;
  final int? assignTo;
  final String? caseNumber;
  final String? caseType;
  final String? description;
  final String? priority;
  final DateTime? estimatedCompletion;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Appointment Model
```dart
class Appointment {
  final int id;
  final int? userId;
  final int? clientId;
  final String? clientUniqueId;
  final String? timezone;
  final String? email;
  final int? noeId;
  final int? serviceId;
  final int? assignee;
  final String? fullName;
  final DateTime? date;
  final String? time;
  final String? title;
  final String? description;
  final int? invites;
  final String? status;
  final String? relatedTo;
  final String? preferredLanguage;
  final String? inpersonAddress;
  final String? timeslotFull;
  final String? appointmentDetails;
  final String? orderHash;
  final int? duration;
  final String? location;
  final String? notes;
  final String? serviceName;
  final String? staffName;
  final List<String>? attendees;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Document Model
```dart
class Document {
  final int id;
  final String? title;
  final String? description;
  final String? filePath;
  final String? fileType;
  final String? status;
  final int? clientId;
  final int? uploadedBy;
  final DateTime? uploadedAt;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final String? category;
  final String? urgency;
  final String? notes;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Invoice Model
```dart
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
}

class InvoiceItem {
  final int id;
  final String? description;
  final int? quantity;
  final double? unitPrice;
  final double? totalPrice;
  final String? itemType;
  final Map<String, dynamic>? metadata;
}
```

### Task Model
```dart
class Task {
  final int id;
  final int? userId;
  final int? clientId;
  final String? title;
  final String? mailId;
  final String? type;
  final int? assignedTo;
  final bool? pin;
  final DateTime? followupDate;
  final bool? followup;
  final String? status;
  final String? description;
  final String? taskGroup;
  final String? priority;
  final DateTime? dueDate;
  final String? assignedByName;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;
  final List<String>? attachments;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Message Model
```dart
class Message {
  final int id;
  final String? subject;
  final String? message;
  final String? sender;
  final String? recipient;
  final int? senderId;
  final int? recipientId;
  final DateTime? sentAt;
  final DateTime? readAt;
  final bool isRead;
  final String? messageType;
  final int? caseId;
  final int? taskId;
  final List<String>? attachments;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

## Authentication & Security

### JWT Token Management
- **Access Token**: Short-lived (15 minutes)
- **Refresh Token**: Long-lived (7 days)
- **Auto-refresh**: 5 minutes before expiry
- **Storage**: Secure storage (flutter_secure_storage)

### Password Requirements
- **Minimum Length**: 8 characters
- **Required**: Special characters, numbers, uppercase letters
- **Validation**: Client-side and server-side

### Biometric Authentication
- **Supported**: Fingerprint, Face ID, Touch ID
- **Fallback**: PIN/Password
- **Platform Support**: Android, iOS

## File Upload & Management

### Supported File Types
- **Documents**: PDF, DOC, DOCX
- **Images**: JPG, JPEG, PNG, GIF
- **Spreadsheets**: XLS, XLSX
- **Presentations**: PPT, PPTX
- **Archives**: ZIP, RAR

### File Size Limits
- **Maximum Size**: 10MB per file
- **Multiple Files**: Supported
- **Progress Tracking**: Real-time upload progress

### File Categories
- **Immigration Documents**: Passport, visa, certificates
- **Legal Documents**: Contracts, agreements, court papers
- **Financial Documents**: Bank statements, tax returns
- **Personal Documents**: ID, birth certificate, marriage certificate

## Push Notifications

### Firebase Cloud Messaging (FCM)
- **Platform Support**: Android, iOS, Web
- **Notification Types**:
  - Appointment reminders
  - Document approval notifications
  - Case status updates
  - Payment reminders
  - Message notifications

### Notification Categories
- **Urgent**: Case deadlines, payment overdue
- **Important**: Document requests, appointment confirmations
- **Normal**: General updates, status changes
- **Low Priority**: Informational messages

## Laravel Backend Requirements

### Database Tables

#### Users Table
```sql
CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    client_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    email_verified_at TIMESTAMP NULL,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(255),
    city VARCHAR(255),
    address TEXT,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    gender ENUM('male', 'female', 'other'),
    age INT,
    marital_status ENUM('single', 'married', 'divorced', 'widowed'),
    phone_number1 VARCHAR(255),
    phone_number2 VARCHAR(255),
    phone_number3 VARCHAR(255),
    state VARCHAR(255),
    post_code VARCHAR(255),
    country VARCHAR(255),
    contact_type1 VARCHAR(255),
    contact_type2 VARCHAR(255),
    contact_type3 VARCHAR(255),
    email_type VARCHAR(255),
    email2 VARCHAR(255),
    phone_verify BOOLEAN DEFAULT FALSE,
    email_verify BOOLEAN DEFAULT FALSE,
    dob DATE,
    wedding_anniversary DATE,
    visa_type VARCHAR(255),
    visa_expiry DATE,
    preferred_intake VARCHAR(255),
    passport_country VARCHAR(255),
    passport_number VARCHAR(255),
    nominated_occupation VARCHAR(255),
    skill_assessment VARCHAR(255),
    highest_qualification_aus VARCHAR(255),
    highest_qualification_overseas VARCHAR(255),
    work_exp_aus VARCHAR(255),
    work_exp_overseas VARCHAR(255),
    english_score VARCHAR(255),
    theme_mode ENUM('light', 'dark') DEFAULT 'light',
    is_admin BOOLEAN DEFAULT FALSE,
    remember_token VARCHAR(100),
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);
```

#### Cases Table
```sql
CREATE TABLE cases (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    status ENUM('pending', 'in_progress', 'completed', 'cancelled', 'under_review', 'on_hold') DEFAULT 'pending',
    package_id BIGINT UNSIGNED,
    user_id BIGINT UNSIGNED,
    agent_id BIGINT UNSIGNED,
    assign_to BIGINT UNSIGNED,
    case_number VARCHAR(255) UNIQUE,
    case_type VARCHAR(255),
    description TEXT,
    priority ENUM('high', 'medium', 'low') DEFAULT 'medium',
    estimated_completion DATE,
    tags JSON,
    metadata JSON,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (agent_id) REFERENCES users(id),
    FOREIGN KEY (assign_to) REFERENCES users(id)
);
```

#### Appointments Table
```sql
CREATE TABLE appointments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED,
    client_id BIGINT UNSIGNED,
    client_unique_id VARCHAR(255),
    timezone VARCHAR(255),
    email VARCHAR(255),
    noe_id BIGINT UNSIGNED,
    service_id BIGINT UNSIGNED,
    assignee BIGINT UNSIGNED,
    full_name VARCHAR(255),
    appointment_date DATE,
    appointment_time TIME,
    title VARCHAR(255),
    description TEXT,
    invites INT DEFAULT 0,
    status ENUM('pending', 'confirmed', 'cancelled', 'rescheduled', 'completed', 'no_show') DEFAULT 'pending',
    related_to VARCHAR(255),
    preferred_language VARCHAR(255),
    inperson_address TEXT,
    timeslot_full VARCHAR(255),
    appointment_details TEXT,
    order_hash VARCHAR(255),
    duration INT,
    location VARCHAR(255),
    notes TEXT,
    service_name VARCHAR(255),
    staff_name VARCHAR(255),
    attendees JSON,
    metadata JSON,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (client_id) REFERENCES users(id)
);
```

#### Documents Table
```sql
CREATE TABLE documents (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255),
    description TEXT,
    file_path VARCHAR(255),
    file_type VARCHAR(255),
    status ENUM('pending', 'approved', 'rejected', 'under_review', 'processing') DEFAULT 'pending',
    client_id BIGINT UNSIGNED,
    uploaded_by BIGINT UNSIGNED,
    uploaded_at TIMESTAMP NULL,
    file_name VARCHAR(255),
    file_size BIGINT,
    mime_type VARCHAR(255),
    category VARCHAR(255),
    urgency ENUM('critical', 'high', 'medium', 'low') DEFAULT 'medium',
    notes TEXT,
    tags JSON,
    metadata JSON,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    FOREIGN KEY (client_id) REFERENCES users(id),
    FOREIGN KEY (uploaded_by) REFERENCES users(id)
);
```

#### Invoices Table
```sql
CREATE TABLE invoices (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT UNSIGNED,
    invoice_number VARCHAR(255) UNIQUE,
    status ENUM('draft', 'pending', 'paid', 'overdue', 'cancelled', 'partial') DEFAULT 'draft',
    due_date DATE,
    issued_date DATE,
    paid_date DATE,
    subtotal DECIMAL(10,2),
    tax_amount DECIMAL(10,2),
    total_amount DECIMAL(10,2),
    paid_amount DECIMAL(10,2),
    balance_due DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'USD',
    notes TEXT,
    metadata JSON,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    FOREIGN KEY (customer_id) REFERENCES users(id)
);

CREATE TABLE invoice_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    invoice_id BIGINT UNSIGNED,
    description TEXT,
    quantity INT DEFAULT 1,
    unit_price DECIMAL(10,2),
    total_price DECIMAL(10,2),
    item_type VARCHAR(255),
    metadata JSON,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
);
```

#### Tasks Table
```sql
CREATE TABLE tasks (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED,
    client_id BIGINT UNSIGNED,
    title VARCHAR(255),
    mail_id VARCHAR(255),
    type VARCHAR(255),
    assigned_to BIGINT UNSIGNED,
    pin BOOLEAN DEFAULT FALSE,
    followup_date DATE,
    followup BOOLEAN DEFAULT FALSE,
    status ENUM('pending', 'in_progress', 'completed', 'cancelled', 'on_hold', 'deferred') DEFAULT 'pending',
    description TEXT,
    task_group VARCHAR(255),
    priority ENUM('urgent', 'high', 'medium', 'low') DEFAULT 'medium',
    due_date DATE,
    assigned_by_name VARCHAR(255),
    tags JSON,
    metadata JSON,
    attachments JSON,
    notes TEXT,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (client_id) REFERENCES users(id),
    FOREIGN KEY (assigned_to) REFERENCES users(id)
);
```

#### Messages Table
```sql
CREATE TABLE messages (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    subject VARCHAR(255),
    message TEXT,
    sender VARCHAR(255),
    recipient VARCHAR(255),
    sender_id BIGINT UNSIGNED,
    recipient_id BIGINT UNSIGNED,
    sent_at TIMESTAMP NULL,
    read_at TIMESTAMP NULL,
    read BOOLEAN DEFAULT FALSE,
    message_type ENUM('urgent', 'important', 'normal', 'low_priority') DEFAULT 'normal',
    case_id BIGINT UNSIGNED,
    task_id BIGINT UNSIGNED,
    attachments JSON,
    metadata JSON,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    FOREIGN KEY (sender_id) REFERENCES users(id),
    FOREIGN KEY (recipient_id) REFERENCES users(id),
    FOREIGN KEY (case_id) REFERENCES cases(id),
    FOREIGN KEY (task_id) REFERENCES tasks(id)
);
```

### API Controllers Required

1. **AuthController**
   - `login()`
   - `register()`
   - `logout()`
   - `refresh()`
   - `forgotPassword()`
   - `resetPassword()`

2. **ClientController**
   - `getProfile()`
   - `updateProfile()`

3. **CaseController**
   - `index()` - List cases
   - `show($id)` - Show case details
   - `update($id)` - Update case

4. **AppointmentController**
   - `index()` - List appointments
   - `store()` - Create appointment
   - `show($id)` - Show appointment
   - `update($id)` - Update appointment
   - `destroy($id)` - Cancel appointment

5. **DocumentController**
   - `index()` - List documents
   - `store()` - Upload document
   - `show($id)` - Show document
   - `download($id)` - Download document
   - `destroy($id)` - Delete document

6. **TaskController**
   - `index()` - List tasks
   - `store()` - Create task
   - `show($id)` - Show task
   - `update($id)` - Update task
   - `complete($id)` - Complete task

7. **MessageController**
   - `index()` - List messages
   - `store()` - Send message
   - `show($id)` - Show message
   - `markAsRead($id)` - Mark as read

8. **InvoiceController**
   - `index()` - List invoices
   - `show($id)` - Show invoice
   - `download($id)` - Download invoice

### Middleware Required

1. **Authentication Middleware**
   - JWT token validation
   - Refresh token handling
   - User authentication

2. **Authorization Middleware**
   - Client portal access
   - Resource ownership validation
   - Permission checks

3. **Rate Limiting Middleware**
   - API rate limiting
   - File upload limits
   - Message sending limits

### File Storage

1. **Document Storage**
   - Local storage or cloud storage (AWS S3, Google Cloud)
   - File path management
   - Access control

2. **Image Storage**
   - Profile pictures
   - Document thumbnails
   - Optimized image delivery

### Notification System

1. **Email Notifications**
   - Appointment confirmations
   - Document approval notifications
   - Payment reminders

2. **Push Notifications**
   - Firebase Cloud Messaging setup
   - Device token management
   - Notification scheduling

### Security Considerations

1. **API Security**
   - CORS configuration
   - Rate limiting
   - Input validation
   - SQL injection prevention

2. **File Security**
   - File type validation
   - Virus scanning
   - Access control
   - Secure file serving

3. **Data Protection**
   - GDPR compliance
   - Data encryption
   - Secure storage
   - Privacy controls

## Development Setup

### Prerequisites
- Flutter SDK 3.x
- Dart SDK 3.x
- Android Studio / VS Code
- Git

### Installation
```bash
# Clone the repository
git clone <repository-url>
cd client-portal

# Install dependencies
flutter pub get

# Generate code
flutter packages pub run build_runner build

# Run the application
flutter run
```

### Configuration
1. Update `lib/config/api_config.dart` with your backend URL
2. Configure Firebase for notifications
3. Set up file storage paths
4. Configure authentication settings

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

## Deployment

### Web Deployment
```bash
flutter build web
# Deploy the build/web directory to your web server
```

### Android Deployment
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS Deployment
```bash
flutter build ios --release
```

## Support

For technical support or questions about the Laravel backend integration, please contact:
- **Email**: support@legicomply.com
- **Phone**: +1-800-LEGI-HELP
- **Website**: https://legicomply.com

## License

This project is proprietary software owned by LegiComply. All rights reserved.

---

**Note**: This documentation is comprehensive and should be used as a reference for implementing the Laravel backend. All API endpoints, data models, and database schemas are designed to work seamlessly with the Flutter client portal application.
```