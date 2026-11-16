import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_map_flow/features/profile/domain/models/user_profile.dart';

class UserProfileDto {
  static UserProfile fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final updatedAt =
        (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return UserProfile(
      id: doc.id,
      displayName: data['displayName'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      githubUrl: data['githubUrl'] as String? ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static Map<String, dynamic> toFirestore(UserProfile profile) {
    return {
      'id': profile.id,
      'displayName': profile.displayName,
      'bio': profile.bio,
      'githubUrl': profile.githubUrl,
      'createdAt': Timestamp.fromDate(profile.createdAt),
      'updatedAt': Timestamp.fromDate(profile.updatedAt),
    };
  }
}
