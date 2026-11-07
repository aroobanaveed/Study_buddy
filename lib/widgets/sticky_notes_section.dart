import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sticky_note.dart';
import '../providers/study_provider.dart';

class StickyNotesSection extends StatelessWidget {
  const StickyNotesSection({super.key});

  static const List<Color> noteColors = [
    Color(0xFFF1D98A), // Butter yellow
    Color(0xFFE3EBDD), // Sage light
    Color(0xFFF8DFD5), // Soft peach
    Color(0xFFE7E2F5), // Lavender
    Color(0xFFF5E8E8), // Soft pink
  ];

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<StudyProvider>().notes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Sticky Notes 🌼',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF344438),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showNoteEditor(context),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Add note'),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (notes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F1E8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.sticky_note_2_outlined,
                  size: 34,
                  color: Color(0xFF91A88B),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your little space for thoughts',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF344438),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Save reminders, dreams and little ideas here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF777D72),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showNoteEditor(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Create your first note'),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notes.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.12,
            ),
            itemBuilder: (context, index) {
              final note = notes[index];
              return _NoteCard(
                note: note,
                backgroundColor: noteColors[
                    note.color.clamp(0, noteColors.length - 1).toInt()],
                onEdit: () => _showNoteEditor(context, note: note),
                onPin: () => context
                    .read<StudyProvider>()
                    .toggleNotePin(note),
                onDelete: () => _confirmDelete(context, note),
              );
            },
          ),
      ],
    );
  }

  Future<void> _showNoteEditor(
    BuildContext context, {
    StickyNote? note,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFAF8EF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (_) => _NoteEditor(note: note),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    StickyNote note,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text(
          'Are you sure you want to delete this note?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<StudyProvider>().deleteNote(note);
    }
  }
}

class _NoteCard extends StatelessWidget {
  final StickyNote note;
  final Color backgroundColor;
  final VoidCallback onEdit;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.backgroundColor,
    required this.onEdit,
    required this.onPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.isPinned ? '📌 Pinned' : 'My note',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF52624F),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert,
                    size: 19,
                    color: Color(0xFF344438),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'pin') onPin();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit note'),
                    ),
                    PopupMenuItem(
                      value: 'pin',
                      child: Text(
                        note.isPinned ? 'Unpin note' : 'Pin note',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete note'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              note.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFF344438),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                note.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Color(0xFF52624F),
                ),
              ),
            ),
            Text(
              '${note.updatedAt.day}/${note.updatedAt.month}/${note.updatedAt.year}',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF777D72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteEditor extends StatefulWidget {
  final StickyNote? note;

  const _NoteEditor({this.note});

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  int _selectedColor = 0;
  bool _saving = false;

  static const List<Color> colors = [
    Color(0xFFF1D98A),
    Color(0xFFE3EBDD),
    Color(0xFFF8DFD5),
    Color(0xFFE7E2F5),
    Color(0xFFF5E8E8),
  ];

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.note?.title ?? '',
    );

    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );

    _selectedColor = widget.note?.color ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty || _saving) return;

    setState(() => _saving = true);

    try {
      final provider = context.read<StudyProvider>();

      if (widget.note == null) {
        await provider.addNote(
          StickyNote(
            title: title,
            content: content,
            color: _selectedColor,
          ),
        );
      } else {
        await provider.updateNote(
          widget.note!.copyWith(
            title: title,
            content: content,
            color: _selectedColor,
          ),
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save note: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 22,
        bottom: MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEditing ? 'Edit your note ✏️' : 'Create a little note 🌼',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF344438),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              maxLength: 50,
              decoration: const InputDecoration(
                labelText: 'Note title',
                hintText: 'e.g. Important reminder',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contentController,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Your thoughts',
                hintText: 'Write something here...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Choose your note color',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF344438),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: List.generate(colors.length, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = index);
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors[index],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == index
                            ? const Color(0xFF344438)
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: _selectedColor == index
                        ? const Icon(
                            Icons.check,
                            size: 18,
                            color: Color(0xFF344438),
                          )
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _saveNote,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF91A88B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _saving
                      ? 'Saving...'
                      : isEditing
                          ? 'Save changes'
                          : 'Save note',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
