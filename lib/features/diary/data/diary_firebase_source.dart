// This owns remote persistence for match diary entries.
// Firestore for document CRUD, Firebase Storage for photo uploads.
// This source does not know about Riverpod, Drift, or widget state.
library;

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../domain/entities/match_entry.dart' as domain;

class DiaryFirebaseSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  DiaryFirebaseSource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // Firestore collection path for user's match entries.
  CollectionReference<Map<String, dynamic>> _entriesRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('match_entries');

  // Write a match entry document to Firestore.
  Future<void> createEntry(domain.MatchEntry entry) async {
    await _entriesRef(entry.userId).doc(entry.id).set(_toFirestore(entry));
  }

  // Fetch all match entries for a user from Firestore.
  Future<List<domain.MatchEntry>> fetchEntries(String userId) async {
    final snapshot =
        await _entriesRef(userId).orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => _fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // Fetch single entry by ID from Firestore.
  Future<domain.MatchEntry?> fetchEntryById({
    required String userId,
    required String entryId,
  }) async {
    final doc = await _entriesRef(userId).doc(entryId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _fromFirestore(doc.data()!, doc.id);
  }

  // Delete match entry document from Firestore.
  Future<void> deleteEntry({
    required String userId,
    required String entryId,
  }) async {
    await _entriesRef(userId).doc(entryId).delete();
  }

  // Delete all remote photos for match entry from Storage.
  Future<void> deleteEntryPhotos({
    required String userId,
    required String entryId,
  }) async {
    try {
      final ref = _storage.ref('users/$userId/match_photos/$entryId');
      final result = await ref.listAll();
      await Future.wait(result.items.map((item) => item.delete()));
    } on FirebaseException {
      // Swallow — photos may not exist yet if entry was never synced.
    }
  }

  // Upload local photo files to Firebase Storage.
  // Returns list of remote download URLs in the same order.
  Future<List<String>> uploadPhotos({
    required String userId,
    required String entryId,
    required List<String> localPaths,
  }) async {
    final urls = <String>[];
    for (var i = 0; i < localPaths.length; i++) {
      final file = File(localPaths[i]);
      if (!file.existsSync()) continue;

      final ref = _storage.ref(
        'users/$userId/match_photos/$entryId/photo_$i.jpg',
      );
      await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  // Convert domain MatchEntry to Firestore-compatible map.
  Map<String, dynamic> _toFirestore(domain.MatchEntry entry) {
    return {
      'userId': entry.userId,
      'sport': entry.sport,
      'fixtureId': entry.fixtureId,
      'homeTeam': entry.homeTeam,
      'awayTeam': entry.awayTeam,
      'score': entry.score,
      'league': entry.league,
      'watchType': entry.watchType,
      'rating': entry.rating,
      'review': entry.review,
      'photos': entry.photos,
      'venue': entry.venue,
      'sportMetadata': entry.sportMetadata,
      'geoVerified': entry.geoVerified,
      'createdAt': Timestamp.fromDate(entry.createdAt),
      'updatedAt':
          entry.updatedAt != null ? Timestamp.fromDate(entry.updatedAt!) : null,
    };
  }

  // Convert Firestore document to domain MatchEntry.
  domain.MatchEntry _fromFirestore(Map<String, dynamic> data, String docId) {
    return domain.MatchEntry(
      id: docId,
      userId: data['userId'] as String? ?? '',
      sport: data['sport'] as String? ?? 'football',
      fixtureId: data['fixtureId'] as String? ?? '',
      homeTeam: data['homeTeam'] as String? ?? '',
      awayTeam: data['awayTeam'] as String?,
      score: data['score'] as String? ?? '',
      league: data['league'] as String? ?? '',
      watchType: data['watchType'] as String? ?? 'tv',
      rating: (data['rating'] as num?)?.toInt() ?? 3,
      review: data['review'] as String?,
      photos: (data['photos'] as List<dynamic>?)?.cast<String>() ?? [],
      venue: data['venue'] as String?,
      sportMetadata:
          (data['sportMetadata'] as Map<String, dynamic>?) ?? const {},
      geoVerified: data['geoVerified'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
