class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String photoURL;
  final String businessName;
  final String rubro;
  final String logoUrl;
  final String primaryColor;
  final String fontStyle;
  final bool onboardingComplete;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoURL,
    this.businessName = '',
    this.rubro = '',
    this.logoUrl = '',
    this.primaryColor = '#E53935',
    this.fontStyle = 'moderna',
    this.onboardingComplete = false,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: (data['email'] ?? '') as String,
      displayName: (data['displayName'] ?? '') as String,
      photoURL: (data['photoURL'] ?? '') as String,
      businessName: (data['businessName'] ?? '') as String,
      rubro: (data['rubro'] ?? '') as String,
      logoUrl: (data['logoUrl'] ?? '') as String,
      primaryColor: (data['primaryColor'] ?? '#E53935') as String,
      fontStyle: (data['fontStyle'] ?? 'moderna') as String,
      onboardingComplete: (data['onboardingComplete'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'businessName': businessName,
      'rubro': rubro,
      'logoUrl': logoUrl,
      'primaryColor': primaryColor,
      'fontStyle': fontStyle,
      'onboardingComplete': onboardingComplete,
    };
  }
}
