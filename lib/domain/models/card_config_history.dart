import 'card_config.dart';

class CardConfigHistory {
  static const int maxSize = 50;
  final List<CardConfig> _undo = [];
  final List<CardConfig> _redo = [];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void push(CardConfig snapshot) {
    _undo.add(snapshot);
    if (_undo.length > maxSize) _undo.removeAt(0);
    _redo.clear();
  }

  CardConfig? undo(CardConfig current) {
    if (!canUndo) return null;
    _redo.add(current);
    return _undo.removeLast();
  }

  CardConfig? redo(CardConfig current) {
    if (!canRedo) return null;
    _undo.add(current);
    return _redo.removeLast();
  }

  void clear() {
    _undo.clear();
    _redo.clear();
  }
}
