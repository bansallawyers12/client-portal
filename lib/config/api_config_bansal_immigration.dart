class ApiConfigBansalImmigration {
  // Base API configuration
  static const String baseUrl = 'https://www.bansalimmigration.com.au/api/crm';
  static const String clientPortalEndpoint = '/client-portal';

  // Blog endpoints
  static const String blogListEndpoint = '/blogs/list';
  static const String blogDetailEndpoint = '/blogs/detail';

  // PR point calculator endpoints
  static const String prPointsCalcList = '/pr-point-calc-lists';
  static const String prPointCalcResult = '/pr-point-calc-result';

  // Student fund calculator endpoints
  static const String studentCalcList = '/student-calc-lists';
  static const String studentCalcResult = '/student-calc-result';

  // Postcode checker endpoints
  static const String postCodeAll = '/postcode-all';
  static const String postCodeSearch = '/postcode-search';
  static const String postCodeResult = '/postcode-result';

  // Occupation endpoints
  static const String occupationAll = '/occupation-all';
  static const String searchOccupation = '/search-occupation';
  static const String occupationResult = '/occupation-result';
}