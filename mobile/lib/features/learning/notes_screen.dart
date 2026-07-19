import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';

/// Notes Screen
/// API: GET    /api/v1/notes
///      POST   /api/v1/notes    { lessonId, content, videoTimestampSeconds }
///      PUT    /api/v1/notes/{noteId}  { content }
///      DELETE /api/v1/notes/{noteId}
class NotesScreen extends StatefulWidget {
  final String? lessonId;
  const NotesScreen({super.key, this.lessonId});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<dynamic> _notes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final url = widget.lessonId != null
          ? '${AppConstants.notesUrl}?lessonId=${widget.lessonId}'
          : AppConstants.notesUrl;
      final resp = await ApiClient.get(url);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        setState(() {
          _notes = body['data']?['content'] ?? body['data'] ?? [];
          _loading = false;
        });
      } else {
        setState(() { _loading = false; _error = 'Something went wrong. Please try again.'; });
      }
    } catch (_) {
      setState(() { _loading = false; _error = 'You are offline.'; });
    }
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      await ApiClient.delete('${AppConstants.notesUrl}/$noteId');
      setState(() => _notes.removeWhere((n) => n['id']?.toString() == noteId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Note deleted'),
          backgroundColor: AppTheme.textHeading,
        ));
      }
    } catch (_) {}
  }

  void _openNoteDialog({dynamic note}) {
    final contentCtrl = TextEditingController(text: note?['content'] ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgMain,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusSheet)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppTheme.sp24, right: AppTheme.sp24,
          top: AppTheme.sp24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppTheme.sp24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(note == null ? 'Add Note' : 'Edit Note',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.sp16),
            TextField(
              controller: contentCtrl,
              maxLines: 5,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Write your note content here...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppTheme.sp24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final text = contentCtrl.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(ctx);
                  
                  if (note == null) {
                    // Create note expects lessonId and videoTimestampSeconds
                    final lid = widget.lessonId ?? '00000000-0000-0000-0000-000000000000';
                    await ApiClient.post(AppConstants.notesUrl, {
                      'lessonId': lid,
                      'content': text,
                      'videoTimestampSeconds': 0,
                    });
                  } else {
                    // Update note expects content in UpdateNoteRequest
                    await ApiClient.put(
                      '${AppConstants.notesUrl}/${note['id']}',
                      {'content': text},
                    );
                  }
                  _load();
                },
                child: Text(note == null ? 'Save Note' : 'Update Note'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: const Text('My Notes'),
        backgroundColor: AppTheme.bgMain,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNoteDialog(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Note',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? _shimmer()
          : _error != null
              ? _errorState()
              : _notes.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(AppTheme.sp16,
                            AppTheme.sp16, AppTheme.sp16, 100),
                        itemCount: _notes.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppTheme.sp8),
                        itemBuilder: (_, i) {
                          final n = _notes[i];
                          final timeStr = _formatTimestamp(n['videoTimestampSeconds'] ?? 0);
                          return _NoteCard(
                            note: n,
                            timeLabel: 'Note at $timeStr',
                            onEdit: () => _openNoteDialog(note: n),
                            onDelete: () => _deleteNote(
                                n['id']?.toString() ?? ''),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _shimmer() => Padding(
    padding: const EdgeInsets.all(AppTheme.sp16),
    child: Shimmer.fromColors(
      baseColor: AppTheme.bgSection,
      highlightColor: AppTheme.bgSecondary,
      child: Column(children: List.generate(4, (_) => Container(
        margin: const EdgeInsets.only(bottom: AppTheme.sp8),
        height: 90,
        decoration: BoxDecoration(color: AppTheme.bgSection,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard)),
      ))),
    ),
  );

  Widget _errorState() => Center(child: Padding(
    padding: const EdgeInsets.all(AppTheme.sp48),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textDisabled),
      const SizedBox(height: AppTheme.sp16),
      Text(_error!, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
      const SizedBox(height: AppTheme.sp16),
      OutlinedButton(onPressed: _load, child: const Text('Retry')),
    ]),
  ));

  Widget _emptyState() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.notes_rounded, size: 56, color: AppTheme.textDisabled),
      const SizedBox(height: AppTheme.sp16),
      Text('No notes yet.', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppTheme.sp8),
      Text('Tap + to add your first note.', style: Theme.of(context).textTheme.bodyMedium),
    ],
  ));
}

class _NoteCard extends StatelessWidget {
  final dynamic note;
  final String timeLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _NoteCard({required this.note, required this.timeLabel, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.sp16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            ),
            child: const Icon(Icons.sticky_note_2_outlined,
                color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: AppTheme.sp16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timeLabel, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(note['content']?.toString() ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 4, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
            icon: const Icon(Icons.more_vert_rounded,
                color: AppTheme.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }
}
