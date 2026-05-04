import '../models/artifact.dart';

/// Provides locally-sourced artifact data from the CSV dataset, with
/// matching asset images from assets/artifacts/artiticats/.
/// Used as the primary data source for the indoor map category sheet.
class LocalArtifactService {
  static const String _base = 'assets/artifacts/artiticats';

  // ── Image lists per type ─────────────────────────────────────────────────
  static const _potteryImages = [
    '$_base/potery.png',
    '$_base/potery2.png',
    '$_base/potery3.png',
    '$_base/potery4.png',
  ];
  static const _weaponImages = [
    '$_base/wepon.png',
    '$_base/wepon2.png',
    '$_base/wepon3.png',
    '$_base/wepon4.png',
  ];
  static const _coinImages = [
    '$_base/coin.png',
    '$_base/coin2.png',
    '$_base/coin3.png',
    '$_base/coin4.png',
  ];
  static const _archImages = [
    '$_base/arcitecture.png',
    '$_base/arcitecture2.png',
    '$_base/arcitecture4.png',
  ];

  // ── Artifact data from CSV ───────────────────────────────────────────────

  static List<Artifact> _make(
      List<_ArtifactData> data, List<String> images) {
    return List.generate(data.length, (i) {
      final d = data[i];
      return Artifact(
        name: d.name,
        category: d.category,
        description: '${d.era} · Made from ${d.material}. ${d.detail}',
        isOnDisplay: true,
        localImagePath: images[i % images.length],
      );
    });
  }

  static final List<Artifact> _pottery = _make([
    _ArtifactData('Ancient Ceramic Bowls', 'Pottery Vases',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Ceramic',
        'Ancient unglazed earthenware bowls used for daily domestic purposes in early Sri Lankan households.'),
    _ArtifactData('Ancient Ceramic Storage Jar', 'Pottery Vases',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Ceramic',
        'Large storage vessel used to preserve grains and liquids, reflecting sophisticated ancient pottery techniques.'),
    _ArtifactData('Ancient Unglazed Pottery Vessel', 'Pottery Vases',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Ceramic',
        'Functional vessel demonstrating early Sri Lankan ceramic craftsmanship before glazing techniques arrived.'),
    _ArtifactData('Dragon-Decorated Porcelain Vase', 'Pottery Vases',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Ceramic',
        'Exquisite imported porcelain vase with dragon motifs, evidence of ancient trade routes with East Asia.'),
    _ArtifactData('Chinese vs. Japanese Porcelain Motifs Vase', 'Pottery Vases',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Ceramic',
        'Rare comparative piece showing distinct artistic traditions, discovered in the Colombo museum collection.'),
    _ArtifactData('Megalithic Burial Urn or Jar', 'Pottery Vases',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Ceramic',
        'Burial urn from the megalithic era, used in ancient funerary rites to inter the remains of the deceased.'),
    _ArtifactData('Portuguese Porcelain Vase', 'Pottery Vases',
        'Colonial Period (1505–1658 CE)', 'Ceramic',
        'Portuguese-influenced ceramic vase showcasing the cultural exchange between Sri Lanka and early European colonisers.'),
    _ArtifactData('Traditional Ceramic Storage Jar', 'Pottery Vases',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Ceramic',
        'Everyday storage jar from the classical period, hand-thrown on a wheel and fired in traditional kilns.'),
    _ArtifactData('The Vase', 'Pottery Vases',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Ceramic',
        'Iconic museum piece celebrated for its balanced form and fine surface decoration representative of the era.'),
    _ArtifactData('Antique Set of Dining Furniture', 'Pottery Vases',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Ceramic',
        'Collection of ancient tableware illustrating the dining customs and social rituals of Sri Lankan royalty.'),
  ], _potteryImages);

  static final List<Artifact> _weapons = _make([
    _ArtifactData('Kastana Swords', 'Royal Swords',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Steel',
        'Traditional Sinhalese sword with a distinctive curved blade, historically carried by royalty and high-ranking warriors.'),
    _ArtifactData('Malay Daggers', 'Royal Swords',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Steel',
        'Ornate daggers of Malay origin, reflecting the multi-cultural nature of ancient Sri Lankan royal courts.'),
    _ArtifactData('Ancient Axe Heads', 'Royal Weapons',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Polished stone axe heads from the prehistoric period, used both as tools and ceremonial objects.'),
    _ArtifactData('Ancient Bronze Sickles', 'Royal Weapons',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Bronze',
        'Bronze sickles demonstrating early metal-working skills and agricultural practices of ancient Sri Lanka.'),
    _ArtifactData('Ornamental Cannon of the Kandyan Kingdom', 'Royal Weapons',
        'Kandyan Period (1592–1815 CE)', 'Iron',
        'Decorative cannon used during ceremonial processions of the Kandyan Kingdom, a symbol of royal power.'),
  ], _weaponImages);

  static final List<Artifact> _architecture = _make([
    _ArtifactData('A Part of Decorated Pillar', 'Architecture',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Carved stone pillar fragment with intricate scroll and floral patterns characteristic of Anuradhapura period temples.'),
    _ArtifactData('Ancient Moonstone and Carved Balustrades', 'Architecture',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Ornate moonstone threshold stone depicting concentric bands of flames, elephants, horses, lions, and lotuses.'),
    _ArtifactData('Ancient Stone Architectural Fragment', 'Architecture',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Structural fragment from a royal or religious building, showcasing the geometric precision of classical Sri Lankan masonry.'),
    _ArtifactData('Fragment of a Carved Base of Building', 'Architecture',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Lower building plinth decorated with elaborate relief carvings, providing evidence of monumental palace architecture.'),
    _ArtifactData('Pillar Capital with the Curved Dwarfs', 'Architecture',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Distinctive pillar capital bearing dwarf figures (makaras) supporting the weight of the canopy above.'),
    _ArtifactData('Stone Pillar Capital', 'Architecture',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Classical pillar capital from a Buddhist monastery, exhibiting the refined sculptural style of the period.'),
    _ArtifactData('Traditional Architectural Foundation Element', 'Architecture',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Stone foundation block used to support wooden superstructures of ancient palace and temple buildings.'),
    _ArtifactData('Buddhist Stupas (Miniature)', 'Architecture',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Small votive stupa model, likely placed as offerings at sacred sites or used in private Buddhist worship.'),
    _ArtifactData('Carved Stone Pillar', 'Architecture',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Tall monolithic pillar inscribed with royal edicts and decorated with stylised capital carvings.'),
    _ArtifactData('Makara-Shaped Architectural Element', 'Architecture',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Mythical sea-creature ornament used as decorative finial on temple gateways and water spouts.'),
  ], _archImages);

  static final List<Artifact> _coins = _make([
    _ArtifactData('Punch-Marked Silver Coins', 'Coins',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Silver',
        'Among the earliest coins minted in Sri Lanka, bearing punch-mark symbols of the sun, moon, and swastika used as currency in ancient trade.'),
    _ArtifactData('Lakshmi Plaque Coins', 'Coins',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Gold',
        'Flat gold plaques depicting the goddess Lakshmi flanked by elephants, used as votive offerings and ceremonial currency.'),
    _ArtifactData('Kahavanu Gold Coins', 'Coins',
        'Polonnaruwa Period (1070–1232 CE)', 'Gold',
        'High-purity gold coins issued by Polonnaruwa kings; one of the most sought-after numismatic items from medieval Sri Lanka.'),
    _ArtifactData('Dutch VOC Copper Coins', 'Coins',
        'Colonial Period (1658–1796 CE)', 'Copper',
        'Coins minted by the Dutch East India Company (VOC) for circulation in Ceylon, bearing the VOC monogram and lion motif.'),
    _ArtifactData('Kandyan Copper Coins (Massa)', 'Coins',
        'Kandyan Period (1592–1815 CE)', 'Copper',
        'Small copper coins called Massa issued by Kandyan kings, decorated with elephant and conch symbols of the realm.'),
    _ArtifactData('British Ceylon Silver Rixdollar', 'Coins',
        'Colonial Period (1796–1948 CE)', 'Silver',
        'Silver rixdollar issued by the British colonial administration, transitioning Ceylon currency from local to imperial standards.'),
    _ArtifactData('Lion Coin of King Parakramabahu', 'Coins',
        'Polonnaruwa Period (1070–1232 CE)', 'Bronze',
        'Bronze coin depicting a rampant lion under a parasol, the royal emblem of King Parakramabahu the Great.'),
    _ArtifactData('Ruhuna Kingdom Copper Coin', 'Coins',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Copper',
        'Copper coin from the ancient sub-kingdom of Ruhuna in southern Sri Lanka, bearing a stylised tree and crescent motif.'),
  ], _coinImages);

  static final List<Artifact> _royalKandyan = _make([
    _ArtifactData('Royal Throne of King Wimaladharmasuriya', 'Statues',
        'Kandyan Period (1592–1815 CE)', 'Wood',
        'Elaborately carved wooden throne used by the Kandyan king during royal audiences and ceremonial occasions.'),
    _ArtifactData('Blood-Stained Royal Garment of King Sri Vikrama Rajasinha', 'Statues',
        'Kandyan Period (1592–1815 CE)', 'Textile',
        'Historically significant garment worn by the last king of Kandy, stained during the events preceding British capture.'),
    _ArtifactData('The Royal Sandal', 'Statues',
        'Kandyan Period (1592–1815 CE)', 'Leather',
        'Ornate ceremonial sandal belonging to Kandyan royalty, decorated with gold thread and precious stones.'),
    _ArtifactData('A Statue of Nagaraja, the Cobra King', 'Statues',
        'Kandyan Period (1592–1815 CE)', 'Stone',
        'Imposing statue of the serpent deity Nagaraja, guardian figure placed at temple entrances and water sources.'),
    _ArtifactData('Portuguese Stone Inscription', 'Statues',
        'Kandyan Period (1592–1815 CE)', 'Stone',
        'Carved stone slab bearing the royal coat of arms of Portugal, marking colonial territorial claims.'),
    _ArtifactData('Sigiriya Frescoes', 'Statues',
        'Anuradhapura Period (377–495 CE)', 'Stone',
        'Fragments of the world-famous Sigiriya fresco paintings depicting celestial maidens (Apsaras) in vivid colours.'),
    _ArtifactData('Palanquins (or Sedans)', 'Statues',
        'Kandyan Period (1592–1815 CE)', 'Wood',
        'Carved portable seat carried by bearers, used by Kandyan nobility and high dignitaries during processions.'),
    _ArtifactData('Satin Wood Cupboard', 'Statues',
        'Kandyan Period (1592–1815 CE)', 'Wood',
        'Elegant cupboard crafted from prized Sri Lankan satinwood, used to store royal valuables and regalia.'),
  ], _archImages);

  static final List<Artifact> _generalStatues = _make([
    _ArtifactData('12th Century Statue of Ganesha', 'Statues',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Intricately carved image of the elephant-headed deity Ganesha, revered as the remover of obstacles.'),
    _ArtifactData('Sandakada Pahana', 'Statues',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Iconic moonstone threshold slab with symbolic bands representing the cycle of existence in Buddhism.'),
    _ArtifactData('Standing Tara', 'Statues',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Elegant stone figure of the Bodhisattva Tara, goddess of compassion, in the Tribhanga (three-bend) posture.'),
    _ArtifactData('Bodhisattva Avalokiteshvara Figure', 'Statues',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Graceful carved figure of Avalokiteshvara, the Bodhisattva of infinite compassion in Mahayana Buddhism.'),
    _ArtifactData('Head of God Vishnu', 'Statues',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Carved stone head of Lord Vishnu showing the characteristic cylindrical crown (kiritamukuta) of Vaishnava iconography.'),
    _ArtifactData('Headless Buddha Statue', 'Statues',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Torso of a large Buddha image displaying fine drapery folds typical of the Gupta-influenced Anuradhapura style.'),
    _ArtifactData('Hindu Goddess Durga', 'Statues',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Multi-armed stone image of Goddess Durga in her warrior aspect, carrying divine weapons and symbols.'),
    _ArtifactData('Samadhi Buddha Statue Seated in the Makara Arch', 'Statues',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Renowned seated meditating Buddha framed by a Makara torana arch, exemplifying supreme Anuradhapura sculptural art.'),
    _ArtifactData('Siva Statue', 'Statues',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Stone image of the Hindu deity Shiva displaying the third eye and characteristic crescent moon headdress.'),
    _ArtifactData('Vajrapani Bodhisattva', 'Statues',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Carved figure of Vajrapani, guardian Bodhisattva holding the thunderbolt (vajra) as a symbol of spiritual power.'),
    _ArtifactData('Stone Sculpture of Ganesha', 'Statues',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Finely detailed sculpture of Ganesha in a seated posture, displaying four arms holding sacred attributes.'),
    _ArtifactData('Bull Nandi Statue', 'Statues',
        'Anuradhapura Period (377 BCE – 1017 CE)', 'Stone',
        'Recumbent stone bull Nandi, the sacred vehicle of Lord Shiva, typically placed at the entrance of Shiva temples.'),
  ], _archImages);

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns artifacts whose images and content match the given [mapCategoryName].
  static List<Artifact> getByMapCategory(String mapCategoryName) {
    final lower = mapCategoryName.toLowerCase();

    if (_isPottery(lower)) return _pottery;
    if (_isWeapon(lower)) return _weapons;
    if (_isArchitecture(lower)) return _architecture;
    if (_isCoin(lower)) return _coins;
    if (_isRoyalKandyan(lower)) return _royalKandyan;
    return _generalStatues;
  }

  static bool _isPottery(String s) =>
      s.contains('potter') ||
      s.contains('vase') ||
      s.contains('ceramic') ||
      s.contains('jar') ||
      s.contains('urn') ||
      s.contains('traditional') ||
      s.contains('culture');

  static bool _isWeapon(String s) =>
      s.contains('sword') ||
      s.contains('weapon') ||
      s.contains('dagger') ||
      s.contains('kastana') ||
      s.contains('malay') ||
      s.contains('cannon') ||
      s.contains('axe') ||
      s.contains('king') ||
      s.contains('royal');

  static bool _isArchitecture(String s) =>
      s.contains('architect') ||
      s.contains('pillar') ||
      s.contains('column') ||
      s.contains('building') ||
      s.contains('stupa') ||
      s.contains('moonstone');

  static bool _isCoin(String s) =>
      s.contains('coin') ||
      s.contains('numismat') ||
      s.contains('gold') ||
      s.contains('bronze') ||
      s.contains('silver');

  static bool _isRoyalKandyan(String s) =>
      s.contains('royal') ||
      s.contains('kandyan') ||
      s.contains('king') ||
      s.contains('queen') ||
      s.contains('throne') ||
      s.contains('sigiri');
}

// ── Internal data holder ──────────────────────────────────────────────────
class _ArtifactData {
  final String name;
  final String category;
  final String era;
  final String material;
  final String detail;
  const _ArtifactData(
      this.name, this.category, this.era, this.material, this.detail);
}
