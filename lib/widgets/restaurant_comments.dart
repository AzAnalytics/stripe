import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stripe/models/comment_model.dart';
import 'package:stripe/service/comment_service.dart';

class RestaurantComments extends StatefulWidget {
  final String restaurantId;

  const RestaurantComments({super.key, required this.restaurantId});

  @override
  State<RestaurantComments> createState() => _RestaurantCommentsState();
}

class _RestaurantCommentsState extends State<RestaurantComments> {
  final CommentService _commentService = CommentService();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double _rating = 5.0;
  bool _isSubmitting = false;
  final User? user = FirebaseAuth.instance.currentUser;

  /// 🔥 Ajouter un commentaire
  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez écrire un commentaire avant d'envoyer.")),
      );
      return;
    }

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vous devez être connecté pour laisser un avis.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String commentId = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(widget.restaurantId)
        .collection('comments')
        .doc()
        .id;

    Comment comment = Comment(
      id: commentId,
      userId: user!.uid,
      name: user!.displayName ?? "Utilisateur",
      restaurantId: widget.restaurantId,
      text: _commentController.text.trim(),
      rating: _rating,
      createdAt: DateTime.now(),
    );

    await _commentService.addComment(comment);
    _commentController.clear();
    setState(() => _isSubmitting = false);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Votre commentaire a été ajouté avec succès !")),
    );
  }

  /// 🔥 Supprimer un commentaire
  Future<void> _deleteComment(String commentId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer ce commentaire ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm) {
      await _commentService.deleteComment(widget.restaurantId, commentId);
    }
  }

  /// 🔥 Ajouter une réponse à un commentaire
  Future<void> _addReply(String commentId) async {
    if (_replyController.text.trim().isEmpty) return;

    await _commentService.addReply(
      widget.restaurantId,
      commentId,
      user!.uid,
      user!.displayName ?? "Utilisateur",
      _replyController.text.trim(),
    );

    _replyController.clear();
  }

  /// 🔥 Supprimer une réponse à un commentaire
  Future<void> _deleteReply(String commentId, String replyId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer cette réponse ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm) {
      await _commentService.deleteReply(widget.restaurantId, commentId, replyId);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Avis des clients",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        /// 🔹 Formulaire d'ajout de commentaire
        if (user != null)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Partagez votre avis...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Votre note :"),
                      Row(
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () => setState(() => _rating = (index + 1).toDouble()),
                            child: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            ),
                          );
                        }),
                      ),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _addComment,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                        child: _isSubmitting
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : const Text("Envoyer"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        /// 🔹 Liste des commentaires existants
        StreamBuilder<List<Comment>>(
          stream: _commentService.getComments(widget.restaurantId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Aucun avis pour ce restaurant. Soyez le premier à donner votre avis !"),
              );
            }

            List<Comment> comments = snapshot.data!;
            return ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                Comment comment = comments[index];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  elevation: 2,
                  child: Column(
                    children: [
                      ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(comment.name, style: const TextStyle(fontWeight: FontWeight.bold)), // ✅ Affichage du vrai nom de l'utilisateur
                            if (user != null && user!.uid == comment.userId) // ✅ Vérification de l'utilisateur
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editComment(comment),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteComment(comment.id),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < comment.rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 18,
                                );
                              }),
                            ),
                            const SizedBox(height: 5),
                            Text(comment.text),
                          ],
                        ),
                      ),

                      /// 🔹 Affichage des réponses
                      StreamBuilder<List<Comment>>(
                        stream: _commentService.getReplies(widget.restaurantId, comment.id),
                        builder: (context, replySnapshot) {
                          if (!replySnapshot.hasData || replySnapshot.data!.isEmpty) {
                            return const SizedBox.shrink(); // ✅ Ne rien afficher s'il n'y a pas de réponses
                          }
                          List<Comment> replies = replySnapshot.data!;

                          return Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Column(
                              children: replies.map((reply) {
                                return Card(
                                  elevation: 1,
                                  margin: const EdgeInsets.symmetric(vertical: 3),
                                  child: ListTile(
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(reply.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), // ✅ Affichage du nom de l'utilisateur de la réponse
                                        if (user != null && user!.uid == reply.userId) // ✅ Vérification utilisateur
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                                                onPressed: () => _editReply(comment.id, reply),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                                onPressed: () => _deleteReply(comment.id, reply.id),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(reply.text),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),

                      /// 🔹 Ajout d'une réponse
                      if (user != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Column(
                            children: [
                              TextField(
                                controller: _replyController,
                                decoration: const InputDecoration(
                                  hintText: "Répondre...",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 5),
                              ElevatedButton(
                                onPressed: () => _addReply(comment.id),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                                child: const Text("Répondre", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),

      ],
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 🔥 Modifier un commentaire
  Future<void> _editComment(Comment comment) async {
    TextEditingController editController = TextEditingController(text: comment.text);

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Modifier votre commentaire"),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Enregistrer", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (confirm == true && editController.text.trim().isNotEmpty) {
      await _commentService.updateComment(widget.restaurantId, comment.id, editController.text.trim());
    }
  }

  /// 🔥 Modifier une réponse
  Future<void> _editReply(String commentId, Comment reply) async {
    TextEditingController editController = TextEditingController(text: reply.text);

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Modifier votre réponse"),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Enregistrer", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (confirm == true && editController.text.trim().isNotEmpty) {
      await _commentService.updateReply(widget.restaurantId, commentId, reply.id, editController.text.trim());
    }
  }


}
