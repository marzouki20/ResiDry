enum LaundryRole {
  resident,
  driver,
  pressing,
  admin,
}

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