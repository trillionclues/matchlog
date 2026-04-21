// Bookie Groups DAO. Typed queries for BookieGroups and GroupMembers tables.
// Used by GroupRepositoryImpl for social features.

library;

import 'package:drift/drift.dart';
import '../app_database.dart';

part 'group_dao.g.dart';

@DriftAccessor(tables: [BookieGroups, GroupMembers])
class GroupDao extends DatabaseAccessor<AppDatabase> with _$GroupDaoMixin {
  GroupDao(super.db);

  Future<void> insertGroup(BookieGroupsCompanion group) =>
      into(bookieGroups).insert(group);

  Future<void> upsertGroup(BookieGroupsCompanion group) =>
      into(bookieGroups).insertOnConflictUpdate(group);

  Future<bool> updateGroup(BookieGroupsCompanion group) =>
      update(bookieGroups).replace(group);

  Future<int> deleteGroup(String id) =>
      (delete(bookieGroups)..where((t) => t.id.equals(id))).go();

  Future<void> markGroupSynced(String id) =>
      (update(bookieGroups)..where((t) => t.id.equals(id)))
          .write(const BookieGroupsCompanion(synced: Value(true)));

  // Increment member count by 1 when a new member joins.
  Future<void> incrementMemberCount(String groupId) async {
    final group = await getGroupById(groupId);
    if (group == null) return;
    await (update(bookieGroups)..where((t) => t.id.equals(groupId))).write(
      BookieGroupsCompanion(memberCount: Value(group.memberCount + 1)),
    );
  }


  Future<BookieGroup?> getGroupById(String id) =>
      (select(bookieGroups)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<BookieGroup?> getGroupByInviteCode(String code) =>
      (select(bookieGroups)..where((t) => t.inviteCode.equals(code)))
          .getSingleOrNull();

  // Watch all groups where the user is a member.
  Stream<List<BookieGroup>> watchGroupsForUser(String userId) {
    final memberGroupIds = selectOnly(groupMembers)
      ..addColumns([groupMembers.groupId])
      ..where(groupMembers.userId.equals(userId));

    return (select(bookieGroups)
          ..where((t) => t.id.isInQuery(memberGroupIds))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<List<BookieGroup>> getUnsyncedGroups() =>
      (select(bookieGroups)..where((t) => t.synced.equals(false))).get();

  Future<void> insertMember(GroupMembersCompanion member) =>
      into(groupMembers).insert(member);

  Future<void> upsertMember(GroupMembersCompanion member) =>
      into(groupMembers).insertOnConflictUpdate(member);

  Future<int> removeMember(String groupId, String userId) =>
      (delete(groupMembers)
            ..where((t) =>
                t.groupId.equals(groupId) & t.userId.equals(userId)))
          .go();

  // Update a member's prediction stats after a prediction settles.
  Future<void> updateMemberStats({
    required String groupId,
    required String userId,
    required int totalPredictions,
    required int correctPredictions,
    required double winRate,
  }) =>
      (update(groupMembers)
            ..where((t) =>
                t.groupId.equals(groupId) & t.userId.equals(userId)))
          .write(GroupMembersCompanion(
            totalPredictions: Value(totalPredictions),
            correctPredictions: Value(correctPredictions),
            winRate: Value(winRate),
          ));

  Future<List<GroupMember>> getMembersForGroup(String groupId) =>
      (select(groupMembers)..where((t) => t.groupId.equals(groupId))).get();

  Stream<List<GroupMember>> watchMembersForGroup(String groupId) =>
      (select(groupMembers)..where((t) => t.groupId.equals(groupId))).watch();

  Future<GroupMember?> getMember(String groupId, String userId) =>
      (select(groupMembers)
            ..where((t) =>
                t.groupId.equals(groupId) & t.userId.equals(userId)))
          .getSingleOrNull();

  Future<bool> isMember(String groupId, String userId) async {
    final member = await getMember(groupId, userId);
    return member != null;
  }
}
