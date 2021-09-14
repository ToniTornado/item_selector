// MIT License
//
// Copyright (c) 2020 J-P Nurmi
//
// The ItemSelector library is based on:
// Multi Select GridView in Flutter - by Simon Lightfoot:
// https://gist.github.com/slightfoot/a002dd1e031f5f012f810c6d5da14a11
//
// Copyright (c) 2019 Simon Lightfoot
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// Thanks to Hugo Passos.
//
import 'dart:collection';

import 'item_selection_notifier.dart';

/// Manages a selection of items.
///
/// ItemSelection is an [Iterable] collection offering all standard iterable
/// operations, such as querying whether it [contains] specific indexes, easily
/// accessing the [first] or [last] index, or iterating all indexes in the
/// selection with [iterator].
///
/// It is often not necessary to create an ItemSelection instance yourself,
/// because [ItemSelectionController] will create one internally if necessary.
/// However, creating an ItemSelection instance gives you more control over the
/// selection. First of all, it allows you to specify an initial selection, and
/// secondly, you can listen to selection state changes for individual items.
///
/// ### Example
///
///     Widget build(BuildContext context) {
///       // specify initial selection
///       final mySelection = ItemSelection(0, 9);
///
///       // listen to selection changes
///       mySelection.addListener((int index, bool selected) {
///         print('$index: $selected');
///       });
///
///       // pass the selection to the controller
///       return ItemSelectionController(
///         selection: mySelection,
///         // ...
///       );
///     }
class ItemSelection extends ItemSelectionNotifier with IterableMixin<int?> {
  /// Creates a selection, optionally with an initial selection range from
  /// [start] to [end].
  ItemSelection([int? start, int? end]) {
    end ??= start;
    if (start != null) {
      final s = (start < end!) ? start : end;
      final e = (start < end) ? end : start;
      for (var i = s; i <= e; i++) {
        if (!_selection.contains(i)) {
          _selection.add(i);
        }
      }
    }
  }

  /// Creates a copy of the [other] selection.
  factory ItemSelection.copy(ItemSelection other) => ItemSelection()..addAll(other);

  /// Returns `true` if this selection is empty.
  bool get isEmpty => _selection.isEmpty;

  /// Returns `true` if this selection is not empty.
  bool get isNotEmpty => _selection.isNotEmpty;

  /// Returns the first index in this selection.
  int get first => _selection.first;

  /// Returns the last index in this selection.
  int get last => _selection.last;

  /// Returns an iterator for iterating the indexes this selection.
  Iterator<int?> get iterator => _selection.iterator;

  /// Returns `true` if this selection contains the specified [index].
  bool contains(covariant int? index) {
    return _selection.contains(index);
  }

  /// Adds a selection range from [start] to [end].
  void add(int start, [int? end]) {
    end ??= start;
    final s = (start < end) ? start : end;
    final e = (start < end) ? end : start;
    for (var i = s; i <= e; i++) {
      if (!_selection.contains(i)) {
        _selection.add(i);
        notifyListeners(i, true);
      }
    }
    // final addition = IntervalTree([start, end]);
    // addition.removeAll(_tree.intersection(addition));
    // for (final range in addition) {
    //   for (int i = range.start; i <= range.end; ++i) {
    //     notifyListeners(i, true);
    //   }
    // }
    // _tree.add([start, end]);
  }

  /// Adds all selection ranges to this selection,
  /// that are in the [other] selection.
  void addAll(ItemSelection other) {
    for (final i in other._selection) {
      _selection.add(i);
      notifyListeners(i, true);
    }
  }

  /// Removes the selection range from [start] to [end].
  void remove(int start, [int? end]) {
    end ??= start;
    final s = (start < end) ? start : end;
    final e = (start < end) ? end : start;
    for (var i = s; i <= e; i++) {
      if (_selection.contains(i)) {
        _selection.remove(i);
        notifyListeners(i, false);
      }
    }
    // if (_selection.isEmpty) return;
    // start = max(start, first);
    // end = min(end ?? start, last);
    // final removal = _tree.intersection(IntervalTree([start, end]));
    // for (final range in removal) {
    //   for (int i = range.start; i <= range.end; ++i) {
    //     notifyListeners(i, false);
    //   }
    // }
    // // Remove single node
    // if (start == end) {
    //   _tree.remove([start, end]);
    //   return;
    // }
    // final startAtBounds = _tree.contains([start - 1, start - 1]) && !_tree.contains([start - 2, start - 2]);
    // final endAtBounds = _tree.contains([end + 1, end + 1]) && !_tree.contains([end + 2, end + 2]);
    // _tree.remove([start - 1, end + 1]);
    // if (startAtBounds) _tree.add([start - 1, start - 1]);
    // if (endAtBounds) _tree.add([end + 1, end + 1]);
  }

  /// Removes all selection ranges from this selection,
  /// that are in the [other] selection.
  void removeAll(ItemSelection other) {
    for (final i in other._selection) {
      _selection.remove(i);
      notifyListeners(i, false);
    }
  }

  /// Replaces the existing selection with a selection range from [start] to
  /// [end] so that no changes are notified for the overlapping range.
  void replace(int start, [int? end]) {
    end ??= start;
    final s = (start < end) ? start : end;
    final e = (start < end) ? end : start;
    final newSelection = <int>{};

    for (final i in _selection) {
      if (i < s || i > e) {
        notifyListeners(i, false);
      }
    }
    for (var i = s; i <= e; i++) {
      newSelection.add(i);
      if (!_selection.contains(i)) {
        notifyListeners(i, true);
      }
    }
    _selection = newSelection;
    //
    // final newTree = IntervalTree([start, end]);
    // final overlap = _tree.intersection(newTree);
    //
    // final removal = IntervalTree.of(_tree);
    // removal.removeAll(newTree);
    // for (final range in removal) {
    //   for (int i = range.start; i <= range.end; ++i) {
    //     if (!overlap.contains([i, i])) {
    //       notifyListeners(i, false);
    //     }
    //   }
    // }
    //
    // final addition = IntervalTree.of(newTree);
    // addition.removeAll(removal);
    // for (final range in addition) {
    //   for (int i = range.start; i <= range.end; ++i) {
    //     if (!overlap.contains([i, i])) {
    //       notifyListeners(i, true);
    //     }
    //   }
    // }
    //
    // _tree = newTree;
  }

  /// Clears this selection.
  void clear() {
    for (final i in _selection) {
      notifyListeners(i, false);
    }
    _selection.clear();
  }

  var _selection = <int>{};
}
