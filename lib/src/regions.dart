import 'models.dart';

const ukrainianRegions = <Region>[
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-05',
    oblastName: 'Вінницька область',
    agroclimaticZone: AgroclimaticZone.forestSteppe,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-07',
    oblastName: 'Волинська область',
    agroclimaticZone: AgroclimaticZone.polissia,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-12',
    oblastName: 'Дніпропетровська область',
    agroclimaticZone: AgroclimaticZone.steppe,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-14',
    oblastName: 'Донецька область',
    agroclimaticZone: AgroclimaticZone.steppe,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-18',
    oblastName: 'Житомирська область',
    agroclimaticZone: AgroclimaticZone.polissia,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-21',
    oblastName: 'Закарпатська область',
    agroclimaticZone: AgroclimaticZone.carpathian,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-23',
    oblastName: 'Запорізька область',
    agroclimaticZone: AgroclimaticZone.steppe,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-26',
    oblastName: 'Івано-Франківська область',
    agroclimaticZone: AgroclimaticZone.carpathian,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-32',
    oblastName: 'Київська область',
    agroclimaticZone: AgroclimaticZone.forestSteppe,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-35',
    oblastName: 'Кіровоградська область',
    agroclimaticZone: AgroclimaticZone.forestSteppe,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-44',
    oblastName: 'Луганська область',
    agroclimaticZone: AgroclimaticZone.steppe,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-46',
    oblastName: 'Львівська область',
    agroclimaticZone: AgroclimaticZone.carpathian,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-48',
    oblastName: 'Миколаївська область',
    agroclimaticZone: AgroclimaticZone.steppe,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-51',
    oblastName: 'Одеська область',
    agroclimaticZone: AgroclimaticZone.steppe,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-53',
    oblastName: 'Полтавська область',
    agroclimaticZone: AgroclimaticZone.forestSteppe,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-56',
    oblastName: 'Рівненська область',
    agroclimaticZone: AgroclimaticZone.polissia,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-59',
    oblastName: 'Сумська область',
    agroclimaticZone: AgroclimaticZone.forestSteppe,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-61',
    oblastName: 'Тернопільська область',
    agroclimaticZone: AgroclimaticZone.forestSteppe,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-63',
    oblastName: 'Харківська область',
    agroclimaticZone: AgroclimaticZone.forestSteppe,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-65',
    oblastName: 'Херсонська область',
    agroclimaticZone: AgroclimaticZone.steppe,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-68',
    oblastName: 'Хмельницька область',
    agroclimaticZone: AgroclimaticZone.forestSteppe,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-71',
    oblastName: 'Черкаська область',
    agroclimaticZone: AgroclimaticZone.forestSteppe,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-73',
    oblastName: 'Чернівецька область',
    agroclimaticZone: AgroclimaticZone.carpathian,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-74',
    oblastName: 'Чернігівська область',
    agroclimaticZone: AgroclimaticZone.polissia,
  ),
  Region(
    countryCode: 'UA',
    oblastCode: 'UA-43',
    oblastName: 'Автономна Республіка Крим',
    agroclimaticZone: AgroclimaticZone.crimeanMountains,
  ),
];

Region? regionByCode(String code) =>
    ukrainianRegions.where((region) => region.oblastCode == code).firstOrNull;

Region? regionByLegacyName(String name) {
  final normalized = name.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  return ukrainianRegions.where((region) {
    final oblast = region.oblastName.toLowerCase();
    return oblast == normalized ||
        oblast.replaceAll(' область', '') ==
            normalized.replaceAll(' область', '');
  }).firstOrNull;
}
