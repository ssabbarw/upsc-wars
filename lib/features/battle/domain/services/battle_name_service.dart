class BattleNameService {
  static const List<String> _names = [
    'Aarav',
    'Vivaan',
    'Aditya',
    'Ishaan',
    'Arjun',
    'Reyansh',
    'Saanvi',
    'Aadhya',
    'Ananya',
    'Diya',
    'Myra',
    'Kiara',
    'Kabir',
    'Rudra',
    'Vihaan',
    'Nitya',
    'Ira',
    'Meera',
    'Riya',
    'Anika',
  ];

  static String pickFromSeed(String seed) {
    return _names[seed.hashCode.abs() % _names.length];
  }
}
