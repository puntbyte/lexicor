// lib/src/enums/domain_category.dart

import 'package:lexicor/src/enums/part_of_speech.dart';
import 'package:meta/meta.dart';

/// Topical or semantic domains for concepts.
///
/// Domain categories group concepts by topic or field (for example `noun.food` contains
/// food-related concepts). Descriptions here are user-
enum DomainCategory {
  /// General adjectives (all kinds of adjective senses).
  adjAll(0, 'adj.all', PartOfSpeech.adjective),

  /// Adjectives that pertain to something (pertainyms), e.g. "wooden".
  adjPert(1, 'adj.pert', PartOfSpeech.adjective),

  /// General adverbs (all adverb senses).
  advAll(2, 'adv.all', PartOfSpeech.adverb),

  /// Top-level noun categories — very broad, high-level noun senses.
  nounTops(3, 'noun.tops', PartOfSpeech.noun),

  /// Nouns for actions, activities, or events (acts).
  nounAct(4, 'noun.act', PartOfSpeech.noun),

  /// Animal-related nouns (species, animals).
  nounAnimal(5, 'noun.animal', PartOfSpeech.noun),

  /// Human-made objects and artifacts.
  nounArtifact(6, 'noun.artifact', PartOfSpeech.noun),

  /// Nouns describing attributes, qualities or properties.
  nounAttribute(7, 'noun.attribute', PartOfSpeech.noun),

  /// Body parts and anatomical terms.
  nounBody(8, 'noun.body', PartOfSpeech.noun),

  /// Cognition, thought and mental processes.
  nounCognition(9, 'noun.cognition', PartOfSpeech.noun),

  /// Communication and language-related nouns.
  nounCommunication(10, 'noun.communication', PartOfSpeech.noun),

  /// Event-related nouns (occurrences, happenings).
  nounEvent(11, 'noun.event', PartOfSpeech.noun),

  /// Feelings and emotional states.
  nounFeeling(12, 'noun.feeling', PartOfSpeech.noun),

  /// Food and edible items.
  nounFood(13, 'noun.food', PartOfSpeech.noun),

  /// Groups, collectives and social group nouns.
  nounGroup(14, 'noun.group', PartOfSpeech.noun),

  /// Places, locations and spatial concepts.
  nounLocation(15, 'noun.location', PartOfSpeech.noun),

  /// Motives, reasons, and purposes.
  nounMotive(16, 'noun.motive', PartOfSpeech.noun),

  /// Physical objects and things.
  nounObject(17, 'noun.object', PartOfSpeech.noun),

  /// People and person-related nouns.
  nounPerson(18, 'noun.person', PartOfSpeech.noun),

  /// Natural phenomena (weather, physical events).
  nounPhenomenon(19, 'noun.phenomenon', PartOfSpeech.noun),

  /// Plants and botanical concepts.
  nounPlant(20, 'noun.plant', PartOfSpeech.noun),

  /// Possessions and ownership-related nouns.
  nounPossession(21, 'noun.possession', PartOfSpeech.noun),

  /// Processes and sequences (procedures, operations).
  nounProcess(22, 'noun.process', PartOfSpeech.noun),

  /// Quantities, measures and numeric concepts.
  nounQuantity(23, 'noun.quantity', PartOfSpeech.noun),

  /// Relational nouns (relations between things).
  nounRelation(24, 'noun.relation', PartOfSpeech.noun),

  /// Shape and form related nouns.
  nounShape(25, 'noun.shape', PartOfSpeech.noun),

  /// States and conditions (temporary or permanent states).
  nounState(26, 'noun.state', PartOfSpeech.noun),

  /// Substances and materials (liquids, solids, compounds).
  nounSubstance(27, 'noun.substance', PartOfSpeech.noun),

  /// Time concepts (periods, moments, durations).
  nounTime(28, 'noun.time', PartOfSpeech.noun),

  /// Body-related verbs (actions involving the body).
  verbBody(29, 'verb.body', PartOfSpeech.verb),

  /// Change verbs (transformations, transitions).
  verbChange(30, 'verb.change', PartOfSpeech.verb),

  /// Verbs of cognition (thinking, believing).
  verbCognition(31, 'verb.cognition', PartOfSpeech.verb),

  /// Verbs for communication (say, tell, ask).
  verbCommunication(32, 'verb.communication', PartOfSpeech.verb),

  /// Competitive verbs (compete, challenge).
  verbCompetition(33, 'verb.competition', PartOfSpeech.verb),

  /// Consumption verbs (eat, drink).
  verbConsumption(34, 'verb.consumption', PartOfSpeech.verb),

  /// Contact verbs (touch, hit).
  verbContact(35, 'verb.contact', PartOfSpeech.verb),

  /// Creation verbs (make, build).
  verbCreation(36, 'verb.creation', PartOfSpeech.verb),

  /// Emotion verbs (feel, grieve).
  verbEmotion(37, 'verb.emotion', PartOfSpeech.verb),

  /// Motion verbs (move, walk, run).
  verbMotion(38, 'verb.motion', PartOfSpeech.verb),

  /// Perception verbs (see, hear, notice).
  verbPerception(39, 'verb.perception', PartOfSpeech.verb),

  /// Possession verbs (have, own).
  verbPossession(40, 'verb.possession', PartOfSpeech.verb),

  /// Social interaction verbs (meet, interact).
  verbSocial(41, 'verb.social', PartOfSpeech.verb),

  /// Stative verbs (exist, seem).
  verbStative(42, 'verb.stative', PartOfSpeech.verb),

  /// Weather-related verbs (rain, snow).
  verbWeather(43, 'verb.weather', PartOfSpeech.verb),

  /// Adjectives describing people or roles (e.g. "pestilent people" style).
  adjPpl(44, 'adj.ppl', PartOfSpeech.adjective)
  ;

  /// Numeric id stored in the DB (kept for compatibility).
  @protected
  final int id;

  /// Canonical label used by WordNet-style datasets.
  final String label;

  /// The part of speech associated with this domain.
  final PartOfSpeech pos;

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
