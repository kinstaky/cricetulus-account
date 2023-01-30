import 'dart:collection';
import 'package:flutter/material.dart';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class AccountTagManager extends ChangeNotifier {
  /// Internal, private state of the tags.
  final List<AccountTag> _tags = [];

  /// Const mapping of icon and index.
  static const List<Widget> icon = [
    FaIcon(FontAwesomeIcons.bowlRice),
    FaIcon(FontAwesomeIcons.book),
    FaIcon(FontAwesomeIcons.gamepad),
    FaIcon(FontAwesomeIcons.personSkiing),
    FaIcon(FontAwesomeIcons.busSimple),
    FaIcon(FontAwesomeIcons.shirt),
    FaIcon(FontAwesomeIcons.bolt),
    FaIcon(FontAwesomeIcons.house),
    FaIcon(FontAwesomeIcons.syringe),
    FaIcon(FontAwesomeIcons.map),
    FaIcon(FontAwesomeIcons.circleHalfStroke),
    FaIcon(FontAwesomeIcons.ban),
  ];

  AccountTagManager() {
    _initial();
  }

  UnmodifiableListView<AccountTag> get tags {
    return UnmodifiableListView(_tags);
  }

  /// Get current tags in database.
  Future<void> loadTags() async {
    // open database
    final db = await openAccountDatabase();
    // query tag data from database
    List<Map> response = await db.rawQuery(
      '''
      SELECT
        name, icon
      FROM
        tag
      ORDER BY
        display_order ASC;
      '''
    );
    db.close();
    // update _tags based on response
    _tags.clear();
    for (var tag in response) {
      _tags.add(
        AccountTag(
          name: tag['name'],
          icon: icon[tag['icon']],
        )
      );
    }
    print('tags length is ${_tags.length}');
  }


  /// Default tags.
  void _initial() async {
    await loadTags();
    notifyListeners();
  }

  /// Adds a new [AccountTag] to the list
  void add(AccountTag tag) {
    _tags.add(tag);
    notifyListeners();
  }
}

class AccountTag {
  final String name;
  final Widget icon;

  AccountTag({
    required this.name,
    required this.icon,
  });

  // AccountTag.empty()
  //   : name = ''
  //   , icon = const Icon(Icons.cancel);
}

class AccountTagButton extends StatelessWidget {
  const AccountTagButton({
    super.key,
    required this.tag,
    this.active = false,
    required this.onChanged,
  });

  final AccountTag tag;
  final bool active;
  final void Function() onChanged;

  void _handlePressed() {
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: 0.0
          ),
          child: IconButton(
            icon: tag.icon,
            color: active
              ? theme.colorScheme.primary
              : theme.colorScheme.secondary,
            onPressed: _handlePressed,
          ),
        ),
        Text(
          tag.name,
          style: theme.textTheme.bodyMedium!.copyWith(
            color: active
              ? theme.colorScheme.primary
              : theme.colorScheme.secondary
          ),
        )
      ],
    );
  }
}


Future<Database> openAccountDatabase() async {
  const List<String> initialTagNames = [
    '餐饮', '学习', '娱乐', '运动',
    '交通', '服饰', '水电', '日用',
    '医疗', '旅行', '其它',
  ];
  return openDatabase(
    join(await getDatabasesPath(), 'cricetulus_account.db'),
    onCreate: (db, version) async {
      await db.execute(
        '''
        CREATE TABLE account(
          id INTEGER PRIMARY KEY,
          amount INTEGER NOT NULL,
          tag TEXT NOT NULL,
          comment TEXT,
          year INTEGER NOT NULL,
          month INTEGER NOT NULL,
          day INTERGER NOT NULL
        )
        '''
      );
      await db.execute(
        '''
        CREATE TABLE tag(
          name TEXT PRIMARY KEY,
          icon INTEGER NOT NULL,
          display_order INTERGER NOT NULL
        )
        '''
      );
      var batch = db.batch();
      for (var i = 0; i < initialTagNames.length; ++i) {
        batch.insert(
          'tag',
          {
            'name': initialTagNames[i],
            'icon': i,
            'display_order': i,
          }
        );
      }
      await batch.commit();
    },
    version: 1,
  );
}