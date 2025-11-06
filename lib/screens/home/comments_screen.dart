import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_firestore_service.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final FirestoreService _fs = FirestoreService();
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await _fs.addComment(postId: widget.postId, text: text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _fs.getCommentsStream(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No comments yet'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final currentUid = FirestoreService().getCurrentUid();
                    final isAuthor = currentUid != null && currentUid == data['userId'];

                    return ListTile(
                      leading: data['profilePicture'] != null
                          ? CircleAvatar(backgroundImage: MemoryImage(base64Decode(data['profilePicture'])))
                          : CircleAvatar(child: Text((data['userName'] ?? 'A')[0])),
                      title: Text(data['userName'] ?? 'Anonymous'),
                      subtitle: Text(data['text'] ?? ''),
                      trailing: isAuthor
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete comment?'),
                                    content: const Text('Are you sure you want to delete this comment?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await FirestoreService().deleteComment(widget.postId, doc.id);
                                }
                              },
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Write a comment...')),
                  ),
                  IconButton(onPressed: _addComment, icon: const Icon(Icons.send))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
