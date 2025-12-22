// lib/src/enums/domain_category.dart

import 'package:lexicor/lexicor.dart';

/// Topical or semantic domains for concepts.
///
/// Domain categories group concepts by topic or field (for example `noun.food` contains
/// food-related concepts). Descriptions here are user-
enum DomainCategory {
  /// General adjectives (all kinds of adjective senses).
  adjAll(0, 'adj.all', SpeechPart.adjective),

  /// Adjectives that pertain to something (pertainyms), e.g. "wooden".
  adjPert(1, 'adj.pert', SpeechPart.adjective),

  /// General adverbs (all adverb senses).
  advAll(2, 'adv.all', SpeechPart.adverb),

  /// Top-level noun categories — very broad, high-level noun senses.
  nounTops(3, 'noun.tops', SpeechPart.noun),

  /// Nouns for actions, activities, or events (acts).
  nounAct(4, 'noun.act', SpeechPart.noun),

  /// Animal-related nouns (species, animals).
  nounAnimal(5, 'noun.animal', SpeechPart.noun),

  /// Human-made objects and artifacts.
  nounArtifact(6, 'noun.artifact', SpeechPart.noun),

  /// Nouns describing attributes, qualities or properties.
  nounAttribute(7, 'noun.attribute', SpeechPart.noun),

  /// Body parts and anatomical terms.
  nounBody(8, 'noun.body', SpeechPart.noun),

  /// Cognition, thought and mental processes.
  nounCognition(9, 'noun.cognition', SpeechPart.noun),

  /// Communication and language-related nouns.
  nounCommunication(10, 'noun.communication', SpeechPart.noun),

  /// Event-related nouns (occurrences, happenings).
  nounEvent(11, 'noun.event', SpeechPart.noun),

  /// Feelings and emotional states.
  nounFeeling(12, 'noun.feeling', SpeechPart.noun),

  /// Food and edible items.
  nounFood(13, 'noun.food', SpeechPart.noun),

  /// Groups, collectives and social group nouns.
  nounGroup(14, 'noun.group', SpeechPart.noun),

  /// Places, locations and spatial concepts.
  nounLocation(15, 'noun.location', SpeechPart.noun),

  /// Motives, reasons, and purposes.
  nounMotive(16, 'noun.motive', SpeechPart.noun),

  /// Physical objects and things.
  nounObject(17, 'noun.object', SpeechPart.noun),

  /// People and person-related nouns.
  nounPerson(18, 'noun.person', SpeechPart.noun),

  /// Natural phenomena (weather, physical events).
  nounPhenomenon(19, 'noun.phenomenon', SpeechPart.noun),

  /// Plants and botanical concepts.
  nounPlant(20, 'noun.plant', SpeechPart.noun),

  /// Possessions and ownership-related nouns.
  nounPossession(21, 'noun.possession', SpeechPart.noun),

  /// Processes and sequences (procedures, operations).
  nounProcess(22, 'noun.process', SpeechPart.noun),

  /// Quantities, measures and numeric concepts.
  nounQuantity(23, 'noun.quantity', SpeechPart.noun),

  /// Relational nouns (relations between things).
  nounRelation(24, 'noun.relation', SpeechPart.noun),

  /// Shape and form related nouns.
  nounShape(25, 'noun.shape', SpeechPart.noun),

  /// States and conditions (temporary or permanent states).
  nounState(26, 'noun.state', SpeechPart.noun),

  /// Substances and materials (liquids, solids, compounds).
  nounSubstance(27, 'noun.substance', SpeechPart.noun),

  /// Time concepts (periods, moments, durations).
  nounTime(28, 'noun.time', SpeechPart.noun),

  /// Body-related verbs (actions involving the body).
  verbBody(29, 'verb.body', SpeechPart.verb),

  /// Change verbs (transformations, transitions).
  verbChange(30, 'verb.change', SpeechPart.verb),

  /// Verbs of cognition (thinking, believing).
  verbCognition(31, 'verb.cognition', SpeechPart.verb),

  /// Verbs for communication (say, tell, ask).
  verbCommunication(32, 'verb.communication', SpeechPart.verb),

  /// Competitive verbs (compete, challenge).
  verbCompetition(33, 'verb.competition', SpeechPart.verb),

  /// Consumption verbs (eat, drink).
  verbConsumption(34, 'verb.consumption', SpeechPart.verb),

  /// Contact verbs (touch, hit).
  verbContact(35, 'verb.contact', SpeechPart.verb),

  /// Creation verbs (make, build).
  verbCreation(36, 'verb.creation', SpeechPart.verb),

  /// Emotion verbs (feel, grieve).
  verbEmotion(37, 'verb.emotion', SpeechPart.verb),

  /// Motion verbs (move, walk, run).
  verbMotion(38, 'verb.motion', SpeechPart.verb),

  /// Perception verbs (see, hear, notice).
  verbPerception(39, 'verb.perception', SpeechPart.verb),

  /// Possession verbs (have, own).
  verbPossession(40, 'verb.possession', SpeechPart.verb),

  /// Social interaction verbs (meet, interact).
  verbSocial(41, 'verb.social', SpeechPart.verb),

  /// Stative verbs (exist, seem).
  verbStative(42, 'verb.stative', SpeechPart.verb),

  /// Weather-related verbs (rain, snow).
  verbWeather(43, 'verb.weather', SpeechPart.verb),

  /// Adjectives describing people or roles (e.g. "pestilent people" style).
  adjPpl(44, 'adj.ppl', SpeechPart.adjective)
  ;

  /// Numeric id stored in the DB (kept for compatibility).
  final int id;

  /// Canonical label used by WordNet-style datasets.
  final String label;

  /// The part of speech associated with this domain.
  final SpeechPart pos;

  const DomainCategory(this.id, this.label, this.pos);

  static final Map<int, DomainCategory> _byId = {
    for (var category in DomainCategory.values) category.id: category,
  };

  /// Returns the [DomainCategory] matching the given id.
  static DomainCategory fromId(int id) {
    final result = _byId[id];
    if (result == null) throw ArgumentError('Unknown DomainCategory ID: $id');
    return result;
  }

  @override
  String toString() => 'DomainCategory(label: $label, pos: ${pos.name})';
}
