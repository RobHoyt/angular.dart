library change_detection;

typedef EvalExceptionHandler(error, stack);

/**
 * An interface for [ChangeDetectorGroup] groups related watches together. It
 * guarantees that within the group all watches will be reported in the order in
 * which they were registered. It also provides an efficient way of removing the
 * watch group.
 */
abstract class ChangeDetectorGroup<H> {
  /**
   * Watch a specific [field] on an [object].
   *
   * If the [field] is:
   *   - _name_ - Name of the field to watch. (If the [object] is a Map then
   *   treat it as a key.)
   *   - _[]_ - Watch all items in an array.
   *   - _{}_ - Watch all items in a Map.
   *   - _._ - Watch the actual object identity.
   *
   *
   * Parameters:
   * - [object] to watch.
   * - [field] to watch on the [object].
   * - [handler] an opaque object passed on to [ChangeRecord].
   */
  WatchRecord<H> watch(Object object, String field, H handler);

  /** Use to remove all watches in the group in an efficient manner. */
  void remove();

  /** Create a child [ChangeDetectorGroup] */
  ChangeDetectorGroup<H> newGroup();
}

/**
 * An interface for [ChangeDetector]. An application can have multiple instances
 * of the [ChangeDetector] to be used for checking different application domains.
 *
 * [ChangeDetector] works by comparing the identity of the objects not by
 * calling the `.equals()` method. This is because ChangeDetector needs to have
 * predictable performance, and the developer can implement `.equals()` on top
 * of identity checks.
 *
 * - [H] A [ChangeRecord] has associated handler object. The handler object is
 * opaque to the [ChangeDetector] but it is meaningful to the code which
 * registered the watcher. It can be a data structure, an object, or a function.
 * It is up to the developer to attach meaning to it.
 */
abstract class ChangeDetector<H> extends ChangeDetectorGroup<H> {
  /**
   * This method does the work of collecting the changes and returns them as a
   * linked list of [ChangeRecord]s. The [ChangeRecord]s are to be returned in
   * the same order as they were registered.
   */
  ChangeRecord<H> collectChanges([EvalExceptionHandler exceptionHandler]);
}

abstract class Record<H> {
  /** The observed object. */
  Object get object;

  /**
   * The field which is being watched:
   *   - _name_ - Name of the field to watch.
   *   - _[]_ - Watch all items in an array.
   *   - _{}_ - Watch all items in a Map.
   *   - _._ - Watch the actual object identity.
   */
  String get field;

  /**
   * An application provided object which contains the specific logic which
   * needs to be applied when the change is detected. The handler is opaque to
   * the ChangeDetector and as such can be anything the application desires.
   */
  H get handler;

  /** Current value of the [field] on the [object] */
  get currentValue;
  /** Previous value of the [field] on the [object] */
  get previousValue;
}

/**
 * [WatchRecord] API which allows changing what object is being watched and
 * manually triggering the checking.
 */
abstract class WatchRecord<H> extends Record<H> {
  /** Set a new object for checking */
  set object(value);

  /**
   * Check to see if the field on the object has changed. Returns [null] if no
   * change, or a [ChangeRecord] if the change has been detected.
   */
  ChangeRecord<H> check();

  void remove();
}

/**
 * Provides information about the changes which were detected in objects.
 *
 * It exposes a `nextChange` method for traversing all of the changes.
 */
abstract class ChangeRecord<H> extends Record<H> {
  /** Next [ChangeRecord] */
  ChangeRecord<H> get nextChange;
}

/**
 * If [ChangeDetector] is watching a an [Map] then the
 * [currentValue] of [Record] will contain this object. The object contains a
 * summary of changes to the map since the last execution. The changes
 * are reported as a list of [MapKeyValue]s which contain the current
 * and previous value in the list as well as the key.
 */
abstract class MapChangeRecord<K, V> {
  /// The underlying iterable object
  Map get map;

  /// A list of [CollectionKeyValue]s which are in the iteration order. */
  KeyValue<K, V> get mapHead;
  /// A list of changed items.
  ChangedKeyValue<K, V> get changesHead;
  /// A list of new added items.
  AddedKeyValue<K, V> get additionsHead;
  /// A list of removed items
  RemovedKeyValue<K, V> get removalsHead;

  void forEachChange(void f(ChangedKeyValue<K, V> change));
  void forEachAddition(void f(AddedKeyValue<K, V> addition));
  void forEachRemoval(void f(RemovedKeyValue<K, V> removal));
}

/**
 * Each item in map is wrapped in [MapKeyValue], which can track
 * the [item]s [currentValue] and [previousValue] location.
 */
abstract class MapKeyValue<K, V> {
  /// The item.
  K get key;

  /// Previous item location in the list or [null] if addition.
  V get previousValue;

  /// Current item location in the list or [null] if removal.
  V get currentValue;
}

abstract class KeyValue<K, V> extends MapKeyValue<K, V> {
  KeyValue<K, V> get nextKeyValue;
}

abstract class AddedKeyValue<K, V> extends MapKeyValue<K, V> {
  AddedKeyValue<K, V> get nextAddedKeyValue;
}

abstract class RemovedKeyValue<K, V> extends MapKeyValue<K, V> {
  RemovedKeyValue<K, V> get nextRemovedKeyValue;
}

abstract class ChangedKeyValue<K, V> extends MapKeyValue<K, V> {
  ChangedKeyValue<K, V> get nextChangedKeyValue;
}


/**
 * If [ChangeDetector] is watching a an [Iterable] then the
 * [currentValue] of [Record] will contain this object. The object contains a
 * summary of changes to the collection since the last execution. The changes
 * are reported as a list of [CollectionChangeItem]s which contain the current
 * and previous position in the list as well as the item.
 */
abstract class CollectionChangeRecord<K, V> {
  /** The underlying iterable object */
  Iterable get iterable;

  /** A list of [CollectionItem]s which are in the iteration order. */
  CollectionItem<K, V> get collectionHead;
  /** A list of new [AddedItem]s. */
  AddedItem<K, V> get additionsHead;
  /** A list of [MovedItem]s. */
  MovedItem<K, V> get movesHead;
  /** A list of [RemovedItem]s. */
  RemovedItem<K, V> get removalsHead;

  void forEachAddition(void f(AddedItem<K, V> addition));
  void forEachMove(void f(MovedItem<K, V> move));
  void forEachRemoval(void f(RemovedItem<K, V> removal));
}

/**
 * Each item in collection is wrapped in [CollectionChangeItem], which can track
 * the [item]s [currentKey] and [previousKey] location.
 */
abstract class CollectionChangeItem<K, V> { // TODO(misko): change <K,V> to <V> since K is int.
  /** Previous item location in the list or [null] if addition. */
  K get previousKey; // TODO(misko): rename to previousIndex

  /** Current item location in the list or [null] if removal. */
  K get currentKey; // TODO(misko): rename to CurrentIndex

  /** The item. */
  V get item;
}

/**
 * Used to create a linked list of collection items.
 * These items are always in the iteration order of the collection.
 */
abstract class CollectionItem<K, V> extends CollectionChangeItem<K, V> {
  CollectionItem<K, V> get nextCollectionItem;
}

/**
 * A linked list of new items added to the collection.
 * These items are always in the iteration order of the collection.
 */
abstract class AddedItem<K, V> extends CollectionChangeItem<K, V> {
  AddedItem<K, V> get nextAddedItem;
}

/**
 * A linked list of moved items in to the collection.
 * These items are always in the iteration order of the collection.
 */
abstract class MovedItem<K, V> extends CollectionChangeItem<K, V> {
  MovedItem<K, V> get nextMovedItem;
}

/**
 * A linked list of removed items in to the collection.
 * These items are always in the iteration order of the collection.
 */
abstract class RemovedItem<K, V> extends CollectionChangeItem<K, V> {
  RemovedItem<K, V> get nextRemovedItem;
}
