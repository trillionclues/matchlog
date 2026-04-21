import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchlog/core/database/app_database.dart';
import 'package:matchlog/core/database/type_converters.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  BookieGroupsCompanion groups({
    String id = 'group_1',
    String adminId = 'user_1',
    String inviteCode = 'MNC25X',
  }) {
    return BookieGroupsCompanion.insert(
      id: id,
      name: 'Monday Night Crew',
      adminId: adminId,
      privacy: GroupPrivacy.inviteOnly,
      inviteCode: inviteCode,
      createdAt: DateTime.now(),
    );
  }

  GroupMembersCompanion member({
    String groupId = 'group_1',
    String userId = 'user_1',
    GroupRole role = GroupRole.admin,
  }) {
    return GroupMembersCompanion.insert(
      groupId: groupId,
      userId: userId,
      role: role,
      joinedAt: DateTime.now(),
    );
  }

  group('GroupDao', () {
    test('insertGroup then getGroupById returns the group', () async {
      await db.groupDao.insertGroup(groups());
      final result = await db.groupDao.getGroupById('group_1');
      expect(result, isNotNull);
      expect(result!.name, 'Monday Night Crew');
      expect(result.inviteCode, 'MNC25X');
    });

    test('getGroupByInviteCode returns the correct group', () async {
      await db.groupDao.insertGroup(groups());
      final result = await db.groupDao.getGroupByInviteCode('MNC25X');
      expect(result, isNotNull);
      expect(result!.id, 'group_1');
    });

    test('insertMember then getMembersForGroup returns the member', () async {
      await db.groupDao.insertGroup(groups());
      await db.groupDao.insertMember(member());
      final members = await db.groupDao.getMembersForGroup('group_1');
      expect(members.length, 1);
      expect(members.first.userId, 'user_1');
      expect(members.first.role, GroupRole.admin);
    });

    test('isMember returns true for existing member', () async {
      await db.groupDao.insertGroup(groups());
      await db.groupDao.insertMember(member());
      expect(await db.groupDao.isMember('group_1', 'user_1'), true);
    });

    test('isMember returns false for non-member', () async {
      await db.groupDao.insertGroup(groups());
      expect(await db.groupDao.isMember('group_1', 'user_999'), false);
    });

    test('removeMember removes the member', () async {
      await db.groupDao.insertGroup(groups());
      await db.groupDao.insertMember(member());
      await db.groupDao.removeMember('group_1', 'user_1');
      final members = await db.groupDao.getMembersForGroup('group_1');
      expect(members.length, 0);
    });

    test('getGroupById returns null for non-existent group', () async {
      final result = await db.groupDao.getGroupById('nonexistent');
      expect(result, isNull);
    });
  });
}
