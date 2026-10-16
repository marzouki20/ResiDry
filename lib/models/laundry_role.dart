enum LaundryRole { resident, driver, pressing, admin }

extension LaundryRoleLabel on LaundryRole {
  String get label {
    switch (this) {
      case LaundryRole.resident:
        return 'Résident';
      case LaundryRole.driver:
        return 'Livreur';
      case LaundryRole.pressing:
        return 'Société de pressing';
      case LaundryRole.admin:
        return 'Administrateur';
    }
  }
}

/// Maps the stored role string from the central User model to a [LaundryRole].
LaundryRole? laundryRoleFromUserRole(String role) {
  switch (role) {
    case 'Résident':
      return LaundryRole.resident;
    case 'Livreur':
      return LaundryRole.driver;
    case 'Société de lavage':
      return LaundryRole.pressing;
    case 'Administrateur':
      return LaundryRole.admin;
    default:
      return null;
  }
}

/// Returns the official stored role string corresponding to a [LaundryRole].
String userRoleFromLaundryRole(LaundryRole role) {
  switch (role) {
    case LaundryRole.resident:
      return 'Résident';
    case LaundryRole.driver:
      return 'Livreur';
    case LaundryRole.pressing:
      return 'Société de lavage';
    case LaundryRole.admin:
      return 'Administrateur';
  }
}
