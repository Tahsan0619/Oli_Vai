class Teacher {
  final String id;
  final String name;
  final String initial;
  final String designation;
  final String phone;
  final String email;
  final String homeDepartment;
  final String? profilePic;
  final String? password; // Added for login (null after user changes it)
  final bool hasChangedPassword; // Track if user changed password
  final bool notificationsEnabled; // Super admin permission
  final bool emailEnabled; // Super admin permission

  Teacher({
    required this.id,
    required this.name,
    required this.initial,
    required this.designation,
    required this.phone,
    required this.email,
    required this.homeDepartment,
    this.profilePic,
    this.password,
    this.hasChangedPassword = false,
    this.notificationsEnabled = false,
    this.emailEnabled = false,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) => Teacher(
        id: json['id'],
        name: json['name'],
        initial: json['initial'],
        designation: json['designation'],
        phone: json['phone'],
        email: json['email'],
        homeDepartment: json['home_department'],
        profilePic: json['profile_pic'],
        password: json['password'],
        hasChangedPassword: json['has_changed_password'] ?? false,
        notificationsEnabled: json['notifications_enabled'] ?? false,
        emailEnabled: json['email_enabled'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initial': initial,
        'designation': designation,
        'phone': phone,
        'email': email,
        'home_department': homeDepartment,
        'profile_pic': profilePic,
        'password': password,
        'has_changed_password': hasChangedPassword,
        'notifications_enabled': notificationsEnabled,
        'email_enabled': emailEnabled,
      };

  Teacher copyWith({
    String? id,
    String? name,
    String? initial,
    String? designation,
    String? phone,
    String? email,
    String? homeDepartment,
    String? profilePic,
    String? password,
    bool? hasChangedPassword,
    bool? notificationsEnabled,
    bool? emailEnabled,
  }) {
    return Teacher(
      id: id ?? this.id,
      name: name ?? this.name,
      initial: initial ?? this.initial,
      designation: designation ?? this.designation,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      homeDepartment: homeDepartment ?? this.homeDepartment,
      profilePic: profilePic ?? this.profilePic,
      password: password ?? this.password,
      hasChangedPassword: hasChangedPassword ?? this.hasChangedPassword,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
    );
  }
}
