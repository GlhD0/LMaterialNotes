part of '../note.dart';

/// Rich text note.
@JsonSerializable()
@Collection()
class RichTextNote extends Note {
  /// Empty content in fleather data representation.
  static const _emptyContent = '[{"insert":"\\n"}]';

  /// The content of the note, as rich text in the fleather representation.
  @JsonKey(defaultValue: _emptyContent)
  String content;

  /// A note with rich text content.
  RichTextNote({
    required super.archived,
    required super.deleted,
    required super.pinned,
    super.locked,
    required super.createdTime,
    required super.editedTime,
    super.deletedTime,
    required super.title,
    super.type = NoteType.richText,
    required this.content,
  });

  /// Rich text note with empty title and content.
  factory RichTextNote.empty() => RichTextNote(
    archived: false,
    deleted: false,
    pinned: false,
    createdTime: DateTime.now(),
    editedTime: DateTime.now(),
    title: '',
    content: _emptyContent,
  );

  /// Rich text note with the provided [content].
  factory RichTextNote.content(String content) => RichTextNote(
    archived: false,
    deleted: false,
    pinned: false,
    createdTime: DateTime.now(),
    editedTime: DateTime.now(),
    title: '',
    content: content,
  );

  /// Rich text note from [json] data.
  factory RichTextNote.fromJson(Map<String, dynamic> json) => _$RichTextNoteFromJson(json);

  /// Rich text note from [json] data, encrypted with [password].
  factory RichTextNote.fromJsonEncrypted(Map<String, dynamic> json, String password) => _$RichTextNoteFromJson(json)
    ..title = (json['title'] as String).isEmpty ? '' : EncryptionUtils().decrypt(password, json['title'] as String)
    ..content = EncryptionUtils().decrypt(password, json['content'] as String);

  /// Rich text note to JSON.
  @override
  Map<String, dynamic> toJson() => _$RichTextNoteToJson(this);

  @override
  Note encrypted(String password) => this
    ..title = isTitleEmpty ? '' : EncryptionUtils().encrypt(password, title)
    ..content = EncryptionUtils().encrypt(password, content);

  /// Returns whether the [contentAsJson] is fleather data.
  ///
  /// If the content is encrypted the [encryptionPassword] should be provided.
  static bool isFleatherData(dynamic contentAsJson, [String? encryptionPassword]) {
    try {
      final content = jsonDecode(
        encryptionPassword != null ? EncryptionUtils().decrypt(encryptionPassword, contentAsJson) : contentAsJson,
      );
      ParchmentDocument.fromJson(content);
    } catch (_) {
      return false;
    }

    return true;
  }

  /// Document containing the fleather content representation.
  @ignore
  ParchmentDocument get document {
    try {
      return ParchmentDocument.fromJson(jsonDecode(content) as List);
    } catch (exception, stackTrace) {
      logger.e('Failed to decode the content of a rich text note, deleting it.', exception, stackTrace);

      NotesService().delete(this);

      return ParchmentDocument();
    }
  }

  @ignore
  @override
  String get contentAsText => document.toPlainText();

  @ignore
  @override
  String get contentAsMarkdown => parchmentMarkdownCodec.encode(document);

  /// The plain text representation of the document, up to [maxLength] characters if set.
  String _toPlainText([int? maxLength]) {
    var content = '';

    for (final child in document.root.children) {
      if (maxLength != null && content.length >= maxLength) {
        break;
      }

      final operations = child.toDelta().toList();

      for (var i = 0; i < operations.length; i++) {
        final operation = operations[i];

        // Skip horizontal rules
        if (operation.data is Map &&
            (operation.data as Map).containsKey('_type') &&
            (operation.data as Map)['_type'] == 'hr') {
          continue;
        }

        final nextOperation = i == operations.length - 1 ? null : operations[i + 1];

        final checklist =
            nextOperation != null &&
            nextOperation.attributes != null &&
            nextOperation.attributes!.containsKey('block') &&
            nextOperation.attributes!['block'] == 'cl';

        if (checklist) {
          final checked = nextOperation.attributes!.containsKey('checked');
          content += '${checked ? '✅' : '⬜'} ${operation.value}';
        } else {
          content += operation.value.toString();
        }
      }
    }

    // A single block may exceed the limit, as the content is accumulated block by block
    if (maxLength != null && content.length > maxLength) {
      return content.substring(0, maxLength);
    }

    return content;
  }

  @ignore
  @override
  String get contentPreview => _toPlainText().trim();

  /// The [content] from which [_contentSnippetCache] was computed.
  ///
  /// The cache is invalidated whenever [content] is reassigned, as a reassignment
  /// always produces a new string instance.
  String? _contentSnippetCacheSource;

  /// The cached [contentSnippet].
  String? _contentSnippetCache;

  @ignore
  @override
  String get contentSnippet {
    final source = content;

    if (!identical(source, _contentSnippetCacheSource)) {
      _contentSnippetCacheSource = source;
      _contentSnippetCache = _toPlainText(Note.contentSnippetLength).trim();
    }

    return _contentSnippetCache!;
  }

  @ignore
  @override
  bool get isContentEmpty => content == _emptyContent;
}
