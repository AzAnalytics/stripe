import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stripe/models/comment_model.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔥 Ajouter un commentaire
  Future<void> addComment(Comment comment) async {
    try {
      // 🔥 Récupérer le document de l'utilisateur
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(comment.userId).get();

      // ✅ Utilisation du champ "name" pour afficher le vrai nom
      String userName = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['name'] ?? "Utilisateur" : "Utilisateur";

      DocumentReference commentRef = _firestore
          .collection('restaurants')
          .doc(comment.restaurantId)
          .collection('comments')
          .doc(); // 🔥 Firestore génère automatiquement l'ID

      await commentRef.set({
        "username": userName, // ✅ Utilisation du vrai nom d'utilisateur
        "comment": comment.text,
        "timestamp": FieldValue.serverTimestamp(),
        "rating": comment.rating,
        "userId": comment.userId,
      });

    } catch (e) {
      print("❌ Erreur lors de l'ajout du commentaire : $e");
    }
  }


  /// 🔥 Supprimer un commentaire
  Future<void> deleteComment(String restaurantId, String commentId) async {
    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  /// 🔥 Ajouter une réponse à un commentaire
  Future<void> addReply(String restaurantId, String commentId, String userId, String name, String replyText) async {
    DocumentReference replyRef = _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .doc();

    await replyRef.set({
      "name": name,
      "reply": replyText,
      "timestamp": FieldValue.serverTimestamp(),
      "userId": userId,
    });
  }

  /// 🔥 Récupérer les commentaires
  Stream<List<Comment>> getComments(String restaurantId) {
    return _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('comments')
        .orderBy('timestamp', descending: true) // ✅ Tri du plus récent au plus ancien
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      return Comment(
        id: doc.id,
        userId: data['userId'] ?? '',
        name: data['username'] ?? 'Utilisateur',
        restaurantId: restaurantId,
        text: data['comment'] ?? '',
        rating: (data['rating'] ?? 0).toDouble(),
        createdAt: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList());
  }


  /// 🔥 Récupérer les réponses à un commentaire
  Stream<List<Comment>> getReplies(String restaurantId, String commentId) {
    return _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      return Comment(
        id: doc.id,
        userId: data['userId'] ?? '',
        name: data['name'] ?? 'Utilisateur',
        restaurantId: restaurantId,
        text: data['reply'] ?? '',
        rating: 0.0, // ✅ Correction : les réponses n'ont pas de note
        createdAt: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList());
  }
  /// 🔥 Supprimer une réponse dans Firestore
  Future<void> deleteReply(String restaurantId, String commentId, String replyId) async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .doc(replyId)
          .delete();
    } catch (e) {
      print("❌ Erreur lors de la suppression de la réponse : $e");
    }
  }

  /// 🔥 Modifier un commentaire dans Firestore
  Future<void> updateComment(String restaurantId, String commentId, String newText) async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('comments')
          .doc(commentId)
          .update({"comment": newText});
    } catch (e) {
      print("❌ Erreur lors de la modification du commentaire : $e");
    }
  }
  /// 🔥 Modifier une réponse dans Firestore
  Future<void> updateReply(String restaurantId, String commentId, String replyId, String newText) async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .doc(replyId)
          .update({"reply": newText});
    } catch (e) {
      print("❌ Erreur lors de la modification de la réponse : $e");
    }
  }


}
