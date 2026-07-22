/// Cross-platform deterministic PRNG used by official Numbering puzzles.
///
/// Park-Miller values stay below JavaScript's exact-integer limit, so the same
/// seed produces the same sequence on Flutter web and native platforms.
class NumberingPrng {
  NumberingPrng(int seed) : _state = _normalizeSeed(seed);

  static const int _modulus = 2147483647;
  static const int _multiplier = 48271;

  int _state;

  static int _normalizeSeed(int seed) {
    final normalized = seed % _modulus;
    return normalized <= 0 ? normalized + _modulus - 1 : normalized;
  }

  int nextInt(int upperBound) {
    if (upperBound <= 0) {
      throw RangeError.range(upperBound, 1, null, 'upperBound');
    }
    _state = (_state * _multiplier) % _modulus;
    return _state % upperBound;
  }
}

/// Builds eight deterministic random digits for the official daily puzzle.
String generateDailyNumberingPuzzle(int seed) {
  final random = NumberingPrng(seed);
  return List<String>.generate(
    8,
    (_) => '${1 + random.nextInt(9)}',
    growable: false,
  ).join();
}
