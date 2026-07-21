import 'dart:math';

import 'numbering_models.dart';

class FormulaProblem {
  const FormulaProblem({
    required this.digitString,
    required this.knownSolution,
  });

  final String digitString;
  final String knownSolution;

  List<String> get digits => digitString.split('');
}

FormulaProblem generateFormulaProblem(
  Random random,
  NumberingDifficulty difficulty,
) {
  switch (difficulty) {
    case NumberingDifficulty.easy:
      final left = 2 + random.nextInt(8);
      final right = 2 + random.nextInt(8);
      final result = left + right;
      return FormulaProblem(
        digitString: '$left$right$result',
        knownSolution: '$left+$right=$result',
      );
    case NumberingDifficulty.normal:
      final left = 10 + random.nextInt(40);
      final right = 2 + random.nextInt(8);
      final result = left + right;
      return FormulaProblem(
        digitString: '$left$right$result',
        knownSolution: '$left+$right=$result',
      );
    case NumberingDifficulty.hard:
      final left = 10 + random.nextInt(30);
      final right = 4 + random.nextInt(12);
      final tail = 2 + random.nextInt(8);
      final other = left + right - tail;
      return FormulaProblem(
        digitString: '$left$right$other$tail',
        knownSolution: '$left+$right=$other+$tail',
      );
  }
}
