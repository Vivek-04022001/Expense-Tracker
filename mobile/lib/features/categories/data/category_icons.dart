import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Maps the string icon keys stored on a category to Phosphor icons.
///
/// Categories store their icon as a stable string key (e.g. "forkKnife") so the
/// same value round-trips through the API and database. The built-in keys here
/// must stay in sync with server/src/constants/categorySeed.js.
abstract class CategoryIcons {
  /// Curated set offered in the icon picker for custom categories, plus every
  /// key used by the seeded built-ins. Order is the picker display order.
  static const List<String> pickerKeys = [
    'forkKnife',
    'coffee',
    'hamburger',
    'car',
    'bus',
    'airplane',
    'gasPump',
    'receipt',
    'lightning',
    'house',
    'bag',
    'shoppingCart',
    'tShirt',
    'heartbeat',
    'pill',
    'ticket',
    'gameController',
    'filmSlate',
    'bookOpen',
    'graduationCap',
    'briefcase',
    'laptop',
    'trendUp',
    'gift',
    'piggyBank',
    'wallet',
    'creditCard',
    'pawPrint',
    'barbell',
    'wrench',
    'dotsThree',
  ];

  static PhosphorIconData resolve(String key) {
    final style = PhosphorIconsStyle.fill;
    return switch (key) {
      'forkKnife' => PhosphorIcons.forkKnife(style),
      'coffee' => PhosphorIcons.coffee(style),
      'hamburger' => PhosphorIcons.hamburger(style),
      'car' => PhosphorIcons.car(style),
      'bus' => PhosphorIcons.bus(style),
      'airplane' => PhosphorIcons.airplane(style),
      'gasPump' => PhosphorIcons.gasPump(style),
      'receipt' => PhosphorIcons.receipt(style),
      'lightning' => PhosphorIcons.lightning(style),
      'house' => PhosphorIcons.house(style),
      'bag' => PhosphorIcons.bag(style),
      'shoppingCart' => PhosphorIcons.shoppingCart(style),
      'tShirt' => PhosphorIcons.tShirt(style),
      'heartbeat' => PhosphorIcons.heartbeat(style),
      'pill' => PhosphorIcons.pill(style),
      'ticket' => PhosphorIcons.ticket(style),
      'gameController' => PhosphorIcons.gameController(style),
      'filmSlate' => PhosphorIcons.filmSlate(style),
      'bookOpen' => PhosphorIcons.bookOpen(style),
      'graduationCap' => PhosphorIcons.graduationCap(style),
      'briefcase' => PhosphorIcons.briefcase(style),
      'laptop' => PhosphorIcons.laptop(style),
      'trendUp' => PhosphorIcons.trendUp(style),
      'gift' => PhosphorIcons.gift(style),
      'piggyBank' => PhosphorIcons.piggyBank(style),
      'wallet' => PhosphorIcons.wallet(style),
      'creditCard' => PhosphorIcons.creditCard(style),
      'pawPrint' => PhosphorIcons.pawPrint(style),
      'barbell' => PhosphorIcons.barbell(style),
      'wrench' => PhosphorIcons.wrench(style),
      'dotsThree' => PhosphorIcons.dotsThree(PhosphorIconsStyle.bold),
      _ => PhosphorIcons.tag(style),
    };
  }

  /// Palette offered in the color picker (stored as hex strings, e.g. #FF6B4A).
  static const List<String> palette = [
    '#FF6B4A',
    '#FF4D9D',
    '#B66BFF',
    '#5B8DEF',
    '#3DB6FF',
    '#00C48C',
    '#7AC74F',
    '#FFB020',
    '#FF8A3D',
    '#E5484D',
    '#9AA0B4',
    '#8A90A0',
  ];
}
