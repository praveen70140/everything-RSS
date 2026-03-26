import 'package:hive_ce/hive.dart';

part 'third_party_server.g.dart';

@HiveType(typeId: 3)
class ThirdPartyServer extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String url;

  @HiveField(2)
  String name;

  @HiveField(3)
  List<String> supportedDomains;

  ThirdPartyServer({
    required this.id,
    required this.url,
    required this.name,
    this.supportedDomains = const [],
  });
}
