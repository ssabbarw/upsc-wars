/// Firebase Auth emails treated as in-app super users (question editor, etc.).
///
/// Keep in sync with Cloud Function env **`QUESTION_EDITOR_EMAILS`** so publish
/// works for the same accounts.
abstract final class SuperUserEmails {
  SuperUserEmails._();

  static const emails = <String>[
    'sachinsabbarwal@gmail.com',
    'upscwars@gmail.com',
    'tinyminyapps@gmail.com',
    'upscmcqpractice@gmail.com',
  ];

  static final Set<String> _normalized = {
    for (final e in emails) e.trim().toLowerCase(),
  };

  static bool contains(String? email) {
    if (email == null) return false;
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return _normalized.contains(normalized);
  }
}
