class UserModel {
  final String uid;
  final String email;
  final int count;

  UserModel({
    required this.uid,
    required this.email,
    required this.count,
  });

  // Firestore'dan gelen Map yapısını UserModel nesnesine çevirir
  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId,
      email: map['email'] ?? '',
      count: map['count'] ?? 0,
    );
  }

  // UserModel nesnesini Firestore'a göndermek için Map'e çevirir
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'count': count,
    };
  }
}