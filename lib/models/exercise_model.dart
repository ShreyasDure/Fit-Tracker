class ExerciseCategory {
  final int id;
  final String name;

  const ExerciseCategory({required this.id, required this.name});

  factory ExerciseCategory.fromJson(Map<String, dynamic> json) {
    return ExerciseCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  // Icon mapping for UI
  String get icon {
    switch (name.toLowerCase()) {
      case 'abs': return '🔥';
      case 'arms': return '💪';
      case 'back': return '🔙';
      case 'calves': return '🦵';
      case 'cardio': return '❤️';
      case 'chest': return '🫁';
      case 'legs': return '🦿';
      case 'shoulders': return '🏋️';
      default: return '💪';
    }
  }
}

class Exercise {
  final int id;
  final String name;
  final String description;
  final String categoryName;
  final List<String> muscles;
  final List<String> equipment;
  final List<String> images;

  const Exercise({
    required this.id,
    required this.name,
    this.description = '',
    this.categoryName = '',
    this.muscles = const [],
    this.equipment = const [],
    this.images = const [],
  });

  factory Exercise.fromExerciseInfo(Map<String, dynamic> json) {
    // Parse name from translations (language=2 is English)
    String name = 'Unknown Exercise';
    final translations = json['translations'] as List? ?? [];
    for (final t in translations) {
      if (t['language'] == 2) {
        name = t['name'] ?? name;
        break;
      }
    }
    // Fallback: try any translation
    if (name == 'Unknown Exercise' && translations.isNotEmpty) {
      name = translations.first['name'] ?? name;
    }

    // Parse description
    String description = '';
    for (final t in translations) {
      if (t['language'] == 2 && t['description'] != null) {
        description = _stripHtml(t['description']);
        break;
      }
    }

    // Parse category
    final category = json['category'] ?? {};
    final categoryName = category['name'] ?? '';

    // Parse muscles
    final musclesList = (json['muscles'] as List? ?? [])
        .map((m) => (m['name_en']?.toString().isNotEmpty == true ? m['name_en'] : m['name'])?.toString() ?? '')
        .where((m) => m.isNotEmpty)
        .toList();

    final musclesSecondary = (json['muscles_secondary'] as List? ?? [])
        .map((m) => (m['name_en']?.toString().isNotEmpty == true ? m['name_en'] : m['name'])?.toString() ?? '')
        .where((m) => m.isNotEmpty)
        .toList();

    // Parse equipment
    final equipmentList = (json['equipment'] as List? ?? [])
        .map((e) => e['name']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    // Parse images
    final imagesList = (json['images'] as List? ?? [])
        .map((img) => img['image']?.toString() ?? '')
        .where((img) => img.isNotEmpty)
        .toList();

    return Exercise(
      id: json['id'] ?? 0,
      name: name,
      description: description,
      categoryName: categoryName,
      muscles: [...musclesList, ...musclesSecondary],
      equipment: equipmentList,
      images: imagesList,
    );
  }

  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}
