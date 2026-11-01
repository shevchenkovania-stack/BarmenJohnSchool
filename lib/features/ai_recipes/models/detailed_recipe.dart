import 'package:coin/core/models/cocktail.dart';

enum RecipeMode { starter, expert }

/// Detailed step-by-step recipe with AI-generated instructions.
class DetailedRecipe {
  final String mode; // 'starter' or 'expert'
  Cocktail? baseCocktail; // Set after creation via setter

  // Timing
  final int prepTimeSeconds;
  final int totalTimeSeconds;

  // For Starter mode
  final List<String> toolsNeeded;
  final List<RecipeStep> steps;
  final List<String> commonMistakes;
  final List<String> proTips;

  // For Expert mode — existing
  final String? history;
  final String? difficulty;
  final List<String>? techniques;
  final List<PremiumIngredient>? premiumIngredients;
  final List<String>? proSecrets;
  final List<String>? variations;
  final List<String>? foodPairing;
  final int? estimatedCostMdl;
  final int? suggestedPriceMdl;

  // For Expert mode — new premium fields
  final List<String>?
      servicePresentation; // Glass/garnish/ice/temperature ritual steps
  final Map<String, String>? sensoryProfile; // {aroma, taste, texture, finish}

  // Error handling
  final String? fallbackError;

  DetailedRecipe({
    required this.mode,
    this.baseCocktail,
    required this.prepTimeSeconds,
    required this.totalTimeSeconds,
    this.toolsNeeded = const [],
    this.steps = const [],
    this.commonMistakes = const [],
    this.proTips = const [],
    this.history,
    this.difficulty,
    this.techniques,
    this.premiumIngredients,
    this.proSecrets,
    this.variations,
    this.foodPairing,
    this.estimatedCostMdl,
    this.suggestedPriceMdl,
    this.servicePresentation,
    this.sensoryProfile,
    this.fallbackError,
  });

  /// Create a fallback recipe when AI fails
  factory DetailedRecipe.fallback({
    required Cocktail cocktail,
    required RecipeMode mode,
    required String error,
  }) {
    return DetailedRecipe(
      mode: mode.name,
      baseCocktail: cocktail,
      prepTimeSeconds: 30,
      totalTimeSeconds: 60,
      toolsNeeded: ['Shaker', 'Strainer'],
      steps: [
        RecipeStep(
          stepNumber: 1,
          title: 'Prepare ingredients',
          description: 'Gather all ingredients and tools',
          durationSeconds: 10,
          tip: 'Read the full recipe first',
        ),
        RecipeStep(
          stepNumber: 2,
          title: 'Mix and serve',
          description: cocktail.strInstructions,
          durationSeconds: 50,
          tip: 'Taste and adjust if needed',
        ),
      ],
      fallbackError: error,
    );
  }

  factory DetailedRecipe.fromJson(Map<String, dynamic> json) {
    // Parse sensory_profile map
    Map<String, String>? sensory;
    if (json['sensory_profile'] != null) {
      final raw = json['sensory_profile'] as Map<String, dynamic>;
      sensory = raw.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    }

    return DetailedRecipe(
      mode: json['mode'] ?? 'starter',
      baseCocktail: null,
      prepTimeSeconds: json['prep_time_seconds'] ?? 30,
      totalTimeSeconds: json['total_time_seconds'] ?? 90,
      toolsNeeded: json['tools_needed'] != null
          ? List<String>.from(json['tools_needed'])
          : [],
      steps: json['steps'] != null
          ? (json['steps'] as List).map((s) => RecipeStep.fromJson(s)).toList()
          : [],
      commonMistakes: json['common_mistakes'] != null
          ? List<String>.from(json['common_mistakes'])
          : [],
      proTips:
          json['pro_tips'] != null ? List<String>.from(json['pro_tips']) : [],
      history: json['history'],
      difficulty: json['difficulty'],
      techniques: json['techniques'] != null
          ? List<String>.from(json['techniques'])
          : [],
      premiumIngredients: json['premium_ingredients'] != null
          ? (json['premium_ingredients'] as List)
              .map((p) => PremiumIngredient.fromJson(p))
              .toList()
          : null,
      proSecrets: json['pro_secrets'] != null
          ? List<String>.from(json['pro_secrets'])
          : [],
      variations: json['variations'] != null
          ? List<String>.from(json['variations'])
          : [],
      foodPairing: json['food_pairing'] != null
          ? List<String>.from(json['food_pairing'])
          : [],
      estimatedCostMdl: json['estimated_cost_mdl'] is int
          ? json['estimated_cost_mdl']
          : (json['estimated_cost_mdl'] as num?)?.toInt(),
      suggestedPriceMdl: json['suggested_price_mdl'] is int
          ? json['suggested_price_mdl']
          : (json['suggested_price_mdl'] as num?)?.toInt(),
      servicePresentation: json['service_presentation'] != null
          ? List<String>.from(json['service_presentation'])
          : null,
      sensoryProfile: sensory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'prep_time_seconds': prepTimeSeconds,
      'total_time_seconds': totalTimeSeconds,
      'tools_needed': toolsNeeded,
      'steps': steps.map((s) => s.toJson()).toList(),
      'common_mistakes': commonMistakes,
      'pro_tips': proTips,
      if (history != null) 'history': history,
      if (difficulty != null) 'difficulty': difficulty,
      if (techniques != null) 'techniques': techniques,
      if (premiumIngredients != null)
        'premium_ingredients':
            premiumIngredients!.map((p) => p.toJson()).toList(),
      if (proSecrets != null) 'pro_secrets': proSecrets,
      if (variations != null) 'variations': variations,
      if (foodPairing != null) 'food_pairing': foodPairing,
      if (estimatedCostMdl != null) 'estimated_cost_mdl': estimatedCostMdl,
      if (suggestedPriceMdl != null) 'suggested_price_mdl': suggestedPriceMdl,
      if (servicePresentation != null)
        'service_presentation': servicePresentation,
      if (sensoryProfile != null) 'sensory_profile': sensoryProfile,
    };
  }

  bool get isStarter => mode == 'starter';
  bool get isExpert => mode == 'expert';
}

/// Single step in the recipe
class RecipeStep {
  final int stepNumber;
  final String title;
  final String description;
  final int durationSeconds;
  final String? tip;

  RecipeStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.durationSeconds,
    this.tip,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      stepNumber: json['step_number'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      durationSeconds: json['duration_seconds'] ?? 0,
      tip: json['tip'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step_number': stepNumber,
      'title': title,
      'description': description,
      'duration_seconds': durationSeconds,
      if (tip != null) 'tip': tip,
    };
  }
}

/// Premium ingredient recommendation for expert mode
class PremiumIngredient {
  final String name;
  final String recommendation;
  final String reason;

  PremiumIngredient({
    required this.name,
    required this.recommendation,
    required this.reason,
  });

  factory PremiumIngredient.fromJson(Map<String, dynamic> json) {
    return PremiumIngredient(
      name: json['name'] ?? '',
      recommendation: json['recommendation'] ?? '',
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'recommendation': recommendation,
      'reason': reason,
    };
  }
}
