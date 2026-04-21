/// QOTD difficulty reactions: stored in Firestore as [QotdReactionOption.id] keys.
class QotdReactionOption {
  const QotdReactionOption({
    required this.id,
    required this.label,
    required this.emoji,
  });

  final String id;
  final String label;
  final String emoji;
}

const List<QotdReactionOption> qotdReactionOptions = [
  QotdReactionOption(
    id: 'easy_peasy',
    label: 'Easy-peasy',
    emoji: '😎',
  ),
  QotdReactionOption(
    id: 'hard',
    label: 'Hard',
    emoji: '😰',
  ),
  QotdReactionOption(
    id: 'very_tough',
    label: 'Very tough',
    emoji: '🤯',
  ),
  QotdReactionOption(
    id: 'impossible',
    label: 'Impossible',
    emoji: '💀',
  ),
];

final Set<String> qotdReactionIds = {
  for (final o in qotdReactionOptions) o.id,
};
