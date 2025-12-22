// lib/src/enums/relation_type.dart

/// Types of lexical and semantic relations between concepts and words.
///
/// These correspond to common relation types in lexical resources:
/// - *semantic* relations connect concepts (e.g. hypernym/hyponym),
/// - *lexical* relations connect word forms (e.g. antonym).
/// The labels are short descriptions for quick understanding.
enum RelationType {
  /// Generalization / parent relation: the target is a more general concept
  /// (e.g. "animal" is a hypernym of "dog").
  hypernym(1, 'hypernym', isRecursive: true),

  /// Specialization / child relation: the target is a more specific concept
  /// (e.g. "dog" is a hyponym of "animal").
  hyponym(2, 'hyponym', isRecursive: true),

  /// Instance hypernym: class-of relationship where target is the class.
  instanceHypernym(3, 'instance hypernym', isRecursive: true),

  /// Instance hyponym: inverse of instanceHypernym (instance -> class).
  instanceHyponym(4, 'instance hyponym', isRecursive: true),

  /// Whole -> part relation (holonym): target is the whole of which the
  /// source is a part (e.g. "car" is a holonym of "wheel").
  partHolonym(11, 'part holonym', isRecursive: true),

  /// Part -> whole relation (meronym): target is a part of the source.
  partMeronym(12, 'part meronym', isRecursive: true),

  /// Member holonym: whole -> member group relation.
  memberHolonym(13, 'member holonym', isRecursive: true),

  /// Member meronym: member -> whole group relation.
  memberMeronym(14, 'member meronym', isRecursive: true),

  /// Substance holonym: whole -> substance relation.
  substanceHolonym(15, 'substance holonym', isRecursive: true),

  /// Substance meronym: substance -> whole relation.
  substanceMeronym(16, 'substance meronym', isRecursive: true),

  /// Entailment: verb A entails verb B (A implies B).
  entails(21, 'entails', isRecursive: true),

  /// Inverse of entails.
  isEntailedBy(22, 'is entailed by', isRecursive: true),

  /// Causation: source tends to cause the target.
  causes(23, 'causes', isRecursive: true),

  /// Inverse of causes.
  isCausedBy(24, 'is caused by', isRecursive: true),

  /// Opposite meaning (antonym).
  antonym(30, 'antonym'),

  /// Closely related meaning (similar).
  similar(40, 'similar'),

  /// "Also" relation — see also / related term.
  also(50, 'also'),

  /// Attribute link (links nouns to attribute adjectives).
  attribute(60, 'attribute'),

  /// Verb group — verbs that form a closely related group.
  verbGroup(70, 'verb group'),

  /// Participle relation (verb/adjective participle links).
  participle(71, 'participle'),

  /// Pertains-to (adjective pertainym).
  pertainym(80, 'pertainym'),

  /// Morphological derivation relation.
  derivation(81, 'derivation'),

  /// Topical domain relation (topic-related).
  domainTopic(91, 'domain topic'),

  /// Inverse: has domain topic.
  hasDomainTopic(92, 'has domain topic'),

  /// Regional domain.
  domainRegion(93, 'domain region'),

  /// Inverse regional domain.
  hasDomainRegion(94, 'has domain region'),

  /// Exemplifies relation (example-of).
  exemplifies(95, 'exemplifies'),

  /// Inverse of exemplifies.
  isExemplifiedBy(96, 'is exemplified by'),

  /// General domain relation.
  domain(97, 'domain'),

  /// Membership relation.
  member(98, 'member'),

  /// Other / miscellaneous relation.
  other(99, 'other'),

  /// State relation.
  state(100, 'state'),

  /// Result relation (action -> result).
  result(101, 'result'),

  /// Event relation.
  event(102, 'event'),

  /// Property relation.
  property(110, 'property'),

  /// Location relation.
  location(120, 'location'),

  /// Destination relation.
  destination(121, 'destination'),

  /// Agent relation (actor of action).
  agent(130, 'agent'),

  /// Undergoer relation (recipient/target of action).
  undergoer(131, 'undergoer'),

  /// Uses relation (uses something).
  uses(140, 'uses'),

  /// Instrument relation (tool used).
  instrument(141, 'instrument'),

  /// By means of relation.
  byMeansOf(142, 'by means of'),

  /// Material relation.
  material(150, 'material'),

  /// Vehicle relation.
  vehicle(160, 'vehicle'),

  /// Body part relation.
  bodyPart(170, 'body part'),

  /// Collocation — words that frequently appear together.
  collocation(200, 'collocation')
  ;

  /// Numeric DB id for the relation.
  final int id;

  /// Human-friendly label.
  final String label;

  /// Whether the relation is recursive (meaningful to traverse repeatedly).
  final bool isRecursive;

  const RelationType(this.id, this.label, {this.isRecursive = false});

  static final Map<int, RelationType> _byId = {
    for (var type in RelationType.values) type.id: type,
  };

  /// Convert an integer id to a [RelationType].
  /// Throws [ArgumentError] if the id is unknown.
  static RelationType fromId(int id) {
    final result = _byId[id];
    if (result == null) throw ArgumentError('Unknown RelationType ID: $id');
    return result;
  }

  @override
  String toString() => 'RelationType(label: $label)';
}
