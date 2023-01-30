import 'package:flutter/material.dart';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


import 'tag.dart';

/// 账单中的单条账目，包含了账目的标签（及其图标）、备注以及数额。
class AccountEntry extends StatelessWidget {
  /// 单条账目的详细信息，包括金额、所属类别、备注
  final AccountEntryData data;

  /// create a new account entry
  const AccountEntry({
    super.key,
    required this.data
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return ListTile(
      leading: data.tag.icon,
      title: Text(
        data.comment.isEmpty
        ? data.tag.name
        : data.comment
      ),
      subtitle: data.comment.isEmpty
        ? const Text(' ')
        : Text(data.tag.name),
      trailing: Text(
        '${data.amount}',
        style: theme.textTheme.titleLarge,
      ),
    );
  }
}


class DailySummary extends StatefulWidget {
  final DateTime date;
  final List<AccountEntry> entries;
  final void Function(int) deleteEntryCallback;
  final void Function(BuildContext, AccountEntry) editEntryCallback;

  /// create daily summary
  const DailySummary({
    super.key,
    required this.date,
    required this.entries,
    required this.deleteEntryCallback,
    required this.editEntryCallback,
  });

  @override
  State<DailySummary> createState() => _DailySummaryState();
}

class _DailySummaryState extends State<DailySummary> {
  int currentExpanded = -1;

  void _onPressExpansion(int index, bool expanded) {
    setState(() {
      currentExpanded = expanded ? -1 : index;
    });
  }

  void Function() _deleteEntry(int id) {
    return () {
      widget.deleteEntryCallback(id);
      setState(() {
        currentExpanded = -1;
      });
    };
  }

  void Function() _editEntry(BuildContext context, AccountEntry entry) {
    return () {
      widget.editEntryCallback(context, entry);
    };
  }

  double _totalOutput() {
    double result = 0.0;
    for (var entry in widget.entries) {
      result += entry.data.amount;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      borderOnForeground: true,
      margin: const EdgeInsets.all(10.0),
      child: Column(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 2,
                horizontal: 20,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${widget.date.year}/${widget.date.month}/${widget.date.day}'),
                  Text('${_totalOutput()}'),
                ],
              ),
            ),
          ),
          ExpansionPanelList(
            expansionCallback: _onPressExpansion,
            children: [
              for (var i = 0; i < widget.entries.length; ++i)
                ExpansionPanel(
                  isExpanded: i == currentExpanded,
                  canTapOnHeader: true,
                  headerBuilder: (context, isExpanded) {
                    return widget.entries[i];
                  },
                  body: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            textStyle: Theme.of(context).textTheme.titleMedium,
                          ),
                          onPressed: _editEntry(context, widget.entries[i]),
                          child: const Text('编辑'),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            textStyle: Theme.of(context).textTheme.titleMedium,
                          ),
                          onPressed: _deleteEntry(widget.entries[i].data.id),
                          child: Text(
                            '删除',
                            style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(
                                color: Theme.of(context).colorScheme.error,
                              )
                          ),
                        ),
                      ),
                    ],
                  ),
                )
            ],
          ),
        ]
        ),
    );
  }
}



class AccountEntryManager {

  static Future<void> deleteAll() async {
    deleteDatabase(
      join(await getDatabasesPath(), 'cricetulus_account.db')
    );
  }

  static Future<void> insert(AccountEntryData entry) async {
    final db = await openAccountDatabase();
    await db.insert(
      'account',
      entry.toMap(),
    );
    db.close();
  }

  static Future<void> update(AccountEntryData entry) async {
    final db = await openAccountDatabase();
    await db.update(
      'account',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id]
    );
    db.close();
  }

  static Future<void> delete(int id) async {
    final db = await openAccountDatabase();
    await db.delete(
      'account',
      where: 'id = ?',
      whereArgs: [id],
    );
    db.close();
  }

  static Future<Map<int, List<AccountEntry>>> queryAccountByYearMonth(
    int year,
    int month
  ) async {
    final db = await openAccountDatabase();
    List<Map> data = await db.rawQuery(
      '''
      SELECT
        id, tag, amount, comment, day, icon
      FROM
        account
      INNER JOIN tag
        ON account.tag = tag.name
      WHERE
        year = $year AND month = $month
      ORDER BY
        day DESC;
      '''
    );
    db.close();

    Map<int, List<AccountEntry>> result = {};
    for (var entry in data) {
      result[entry['day']] ??= [];
      result[entry['day']]!.add(AccountEntry(
        data: AccountEntryData(
          id: entry['id'],
          tag: AccountTag(
            icon: AccountTagManager.icon[entry['icon']],
            name: entry['tag'],
          ),
          amount: entry['amount'].toDouble() / 100.0,
          comment: entry['comment'] ?? '',
          date: DateTime(year, month, entry['day']),
        ),
      ));
    }
    return result;
  }


  static Future<Map<int, List<bool>>> queryYearMonth() async {
    final db = await openAccountDatabase();
    List<Map> data = await db.rawQuery(
      '''
      SELECT DISTINCT
        year, month
      FROM
        account
      ORDER BY
        year DESC;
      '''
    );
    db.close();

    for (var yearMonth in data) {
      print('year ${yearMonth["year"]}, month ${yearMonth["month"]}');
    }
    Map<int, List<bool>> result = {};
    for (var yearMonth in data) {
      result[yearMonth['year']] ??= [
        false, false, false, false,
        false, false, false, false,
        false, false, false, false,
      ];
      result[yearMonth['year']]![yearMonth['month']-1] = true;
    }
    return result;
  }
}

/// 账单中一笔账的信息，即类别、金额、日期、备注
class AccountEntryData {
  final int id;
  /// 所属类别
  final AccountTag tag;
  /// 金额
  final double amount;
  /// 日期
  final DateTime date;
  /// 备注
  final String comment;

  AccountEntryData({
    required this.id,
    required this.tag,
    required this.amount,
    required this.date,
    this.comment = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tag': tag.name,
      'amount': (amount*100).round(),
      'comment': comment.isEmpty ? null : comment,
      'year': date.year,
      'month': date.month,
      'day': date.day,
    };
  }
}
