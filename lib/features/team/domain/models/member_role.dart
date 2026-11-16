enum MemberRole {
  owner,
  admin,
  member;

  static MemberRole fromString(String? val) {
    return switch (val?.toLowerCase()) {
      'owner' => MemberRole.owner,
      'admin' => MemberRole.admin,
      _ => MemberRole.member,
    };
  }

  String toFirestoreString() => name;

  bool get isOwner => this == MemberRole.owner;
  bool get isAdmin => this == MemberRole.admin;
  bool get isMember => this == MemberRole.member;
  bool get canManageTeam => isOwner || isAdmin;
  bool get canManageWork => isOwner || isAdmin;
  bool get canManageInvites => isOwner || isAdmin;
}
