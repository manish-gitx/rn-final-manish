import 'dart:collection';

/// LRU (Least Recently Used) cache implementation for in-memory caching
class LRUCache<K, V> {
  final int _maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();
  int _hits = 0;
  int _misses = 0;

  LRUCache(this._maxSize);

  /// Gets a value from cache, returns null if not found
  V? get(K key) {
    if (!_cache.containsKey(key)) {
      _misses++;
      return null;
    }

    // Move to end (most recently used)
    final value = _cache.remove(key);
    _cache[key] = value as V;
    _hits++;
    return value;
  }

  /// Puts a value into cache, evicts LRU item if cache is full
  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      // Update existing entry (move to end)
      _cache.remove(key);
    } else if (_cache.length >= _maxSize) {
      // Evict least recently used (first item)
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = value;
  }

  /// Removes a specific key from cache
  void remove(K key) {
    _cache.remove(key);
  }

  /// Clears the entire cache
  void clear() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  /// Checks if a key exists in cache
  bool containsKey(K key) {
    return _cache.containsKey(key);
  }

  /// Returns the number of items in cache
  int get length => _cache.length;

  /// Returns true if cache is empty
  bool get isEmpty => _cache.isEmpty;

  /// Returns true if cache is at max capacity
  bool get isFull => _cache.length >= _maxSize;

  /// Returns the cache hit rate (0.0 to 1.0)
  double get hitRate {
    final total = _hits + _misses;
    return total == 0 ? 0.0 : _hits / total;
  }

  /// Returns cache statistics
  Map<String, dynamic> get stats => {
        'size': _cache.length,
        'maxSize': _maxSize,
        'hits': _hits,
        'misses': _misses,
        'hitRate': hitRate,
        'utilization': _cache.length / _maxSize,
      };

  /// Resets statistics (hits/misses) without clearing cache
  void resetStats() {
    _hits = 0;
    _misses = 0;
  }

  /// Gets all keys in the cache (ordered by LRU)
  Iterable<K> get keys => _cache.keys;

  /// Gets all values in the cache (ordered by LRU)
  Iterable<V> get values => _cache.values;
}