import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generic write method
  Future<void> setDocument(String collection, String uid, String docId, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection(collection)
        .doc(docId)
        .set({...data, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  // Generic read method
  Future<Map<String, dynamic>?> getDocument(String collection, String uid, String docId) async {
    final doc = await _firestore.collection('users').doc(uid).collection(collection).doc(docId).get();
    return doc.exists ? doc.data() : null;
  }

  // Get WriteBatch for bulk operations
  WriteBatch getBatch() {
    return _firestore.batch();
  }

  // Commit batch
  Future<void> commitBatch(WriteBatch batch) async {
    await batch.commit();
  }

  DocumentReference getDocRef(String collection, String uid, String docId) {
    return _firestore.collection('users').doc(uid).collection(collection).doc(docId);
  }
}
