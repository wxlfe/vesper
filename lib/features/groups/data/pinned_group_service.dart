import 'package:shared_preferences/shared_preferences.dart';

class PinnedGroupService {
  const PinnedGroupService();

  static const _key = 'vesper.pinnedGroups';

  Future<Set<String>> readPinnedGroupIds() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_key) ?? const <String>[]).toSet();
  }

  Future<void> togglePinnedGroup(String groupId) async {
    final preferences = await SharedPreferences.getInstance();
    final ids = (preferences.getStringList(_key) ?? const <String>[]).toSet();
    if (!ids.add(groupId)) {
      ids.remove(groupId);
    }
    await preferences.setStringList(_key, ids.toList()..sort());
  }
}
