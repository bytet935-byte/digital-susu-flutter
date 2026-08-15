import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/models/money.dart';
import '../domain/group_models.dart';
import '../domain/groups_repository.dart';

/// Deterministic mock groups matching the design reference (spec §11):
/// Weekend Susu (10), Project Susu (15), Business Susu (20) and a completed
/// group for the Completed tab. Chat follows the design's conversation.
class MockGroupsRepository implements GroupsRepository {
  static const String currentUserId = 'usr_kwame';

  final List<SusuGroup> _groups = <SusuGroup>[
    SusuGroup(
      id: 'grp_weekend',
      name: 'Weekend Susu',
      type: GroupTypes.rotationalSusu,
      status: GroupStatuses.active,
      pot: const Money(50000),
      memberCount: 10,
      totalMembers: 10,
      description: 'Weekly rotational susu — 10 members, GHS 100 per cycle.',
      nextPayout: DateTime(2026, 8, 25),
    ),
    SusuGroup(
      id: 'grp_project',
      name: 'Project Susu',
      type: GroupTypes.rotationalSusu,
      status: GroupStatuses.active,
      pot: const Money(72000),
      memberCount: 15,
      totalMembers: 15,
      description: 'Saving towards the end-of-year project.',
      nextPayout: DateTime(2026, 9, 10),
    ),
    SusuGroup(
      id: 'grp_business',
      name: 'Business Susu',
      type: GroupTypes.jointBusiness,
      status: GroupStatuses.active,
      pot: const Money(120000),
      memberCount: 20,
      totalMembers: 20,
      description: 'Joint business capital — 20 members.',
      nextPayout: DateTime(2026, 10, 5),
    ),
    SusuGroup(
      id: 'grp_completed',
      name: 'Choir Savings',
      type: GroupTypes.savingsGoal,
      status: GroupStatuses.completed,
      pot: const Money(300000),
      memberCount: 12,
      totalMembers: 12,
      description: 'Completed — goal reached.',
    ),
  ];

  final Map<String, List<GroupMember>> _members = <String, List<GroupMember>>{
    'grp_weekend': <GroupMember>[
      GroupMember(
        userId: 'usr_kwame',
        fullName: 'Kwame Owusu',
        phone: '0241234567',
        role: GroupRoles.owner,
      ),
      GroupMember(
        userId: 'usr_ama',
        fullName: 'Ama Serwaa',
        phone: '0559876543',
        role: GroupRoles.treasurer,
      ),
      GroupMember(
        userId: 'usr_kofi',
        fullName: 'Kofi Mensah',
        phone: '0201112223',
        role: GroupRoles.member,
      ),
      GroupMember(
        userId: 'usr_nana',
        fullName: 'Nana Yeboah',
        phone: '0243334445',
        role: GroupRoles.moderator,
      ),
    ],
    'grp_project': <GroupMember>[
      GroupMember(
        userId: 'usr_kwame',
        fullName: 'Kwame Owusu',
        phone: '0241234567',
        role: GroupRoles.member,
      ),
    ],
    'grp_business': <GroupMember>[
      GroupMember(
        userId: 'usr_kwame',
        fullName: 'Kwame Owusu',
        phone: '0241234567',
        role: GroupRoles.member,
      ),
    ],
    'grp_completed': <GroupMember>[
      GroupMember(
        userId: 'usr_kwame',
        fullName: 'Kwame Owusu',
        phone: '0241234567',
        role: GroupRoles.member,
      ),
    ],
  };

  final Map<String, List<GroupMessage>> _messages =
      <String, List<GroupMessage>>{
    'grp_weekend': <GroupMessage>[
      GroupMessage(
        id: 'msg_1',
        senderId: 'usr_ama',
        senderName: 'Ama Serwaa',
        body: 'Good evening everyone 🌙 Don\'t forget tomorrow\'s contribution.',
        createdAt: DateTime(2026, 8, 16, 20, 5),
      ),
      GroupMessage(
        id: 'msg_2',
        senderId: 'usr_kofi',
        senderName: 'Kofi Mensah',
        body: 'Noted ✅',
        createdAt: DateTime(2026, 8, 16, 20, 12),
      ),
      GroupMessage(
        id: 'msg_3',
        senderId: 'usr_kwame',
        senderName: 'Kwame Owusu',
        body: 'Thanks Ama! I\'ll send mine in the morning.',
        createdAt: DateTime(2026, 8, 16, 20, 15),
      ),
      GroupMessage(
        id: 'msg_4',
        senderId: 'usr_nana',
        senderName: 'Nana Yeboah',
        body: 'Paid already ✔️',
        createdAt: DateTime(2026, 8, 16, 20, 30),
      ),
      GroupMessage(
        id: 'msg_5',
        senderId: 'usr_ama',
        senderName: 'Ama Serwaa',
        body: 'Great work team 💪',
        createdAt: DateTime(2026, 8, 16, 20, 32),
      ),
    ],
  };

  @override
  Future<Result<List<SusuGroup>>> getMyGroups() async =>
      Success<List<SusuGroup>>(_groups);

  @override
  Future<Result<SusuGroup>> getGroup(String groupId) async {
    SusuGroup? group;
    for (final g in _groups) {
      if (g.id == groupId) {
        group = g;
        break;
      }
    }
    if (group == null) {
      return const Failure<SusuGroup>(NotFoundException());
    }
    return Success<SusuGroup>(group);
  }

  @override
  Future<Result<SusuGroup>> createGroup({
    required String name,
    required String type,
    String? description,
  }) async {
    if (name.trim().length < 2) {
      return const Failure<SusuGroup>(
        ValidationException(message: 'Group name is required.'),
      );
    }
    final group = SusuGroup(
      id: 'grp_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      type: type,
      status: GroupStatuses.active,
      pot: Money.zero(),
      memberCount: 1,
      totalMembers: 1,
      description: description?.trim() ?? '',
    );
    _groups.insert(0, group);
    _members[group.id] = <GroupMember>[
      GroupMember(
        userId: currentUserId,
        fullName: 'Kwame Owusu',
        phone: '0241234567',
        role: GroupRoles.owner,
      ),
    ];
    return Success<SusuGroup>(group);
  }

  @override
  Future<Result<SusuGroup>> joinGroup(String inviteCode) async {
    if (inviteCode.trim().isEmpty) {
      return const Failure<SusuGroup>(
        ValidationException(message: 'Enter the invite code.'),
      );
    }
    // Demo: any non-empty code joins Weekend Susu (FLOW 3).
    final group = _groups.firstWhere((g) => g.id == 'grp_weekend');
    final members = _members['grp_weekend']!;
    if (!members.any((m) => m.userId == currentUserId)) {
      members.add(GroupMember(
        userId: currentUserId,
        fullName: 'Kwame Owusu',
        phone: '0241234567',
        role: GroupRoles.member,
      ));
    }
    return Success<SusuGroup>(group);
  }

  @override
  Future<Result<List<GroupMember>>> getMembers(String groupId) async =>
      Success<List<GroupMember>>(_members[groupId] ?? const <GroupMember>[]);

  @override
  Future<Result<List<GroupMessage>>> getMessages(String groupId) async =>
      Success<List<GroupMessage>>(
        (_messages[groupId] ?? const <GroupMessage>[])
            .reversed
            .toList(), // newest first
      );

  @override
  Future<Result<GroupMessage>> sendMessage({
    required String groupId,
    required String body,
    required String senderId,
    required String senderName,
  }) async {
    if (body.trim().isEmpty) {
      return const Failure<GroupMessage>(
        ValidationException(message: 'Message cannot be empty.'),
      );
    }
    final message = GroupMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      body: body.trim(),
      createdAt: DateTime.now(),
    );
    _messages.putIfAbsent(groupId, () => <GroupMessage>[]).add(message);
    return Success<GroupMessage>(message);
  }
}
