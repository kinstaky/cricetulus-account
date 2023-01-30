import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'numberic_panel.dart';
import 'tag.dart';
import 'account_entry.dart';

void main() {
  runApp(const CricetulusApp());
}

class CricetulusApp extends StatelessWidget {
  const CricetulusApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cricetulus Demo',
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
           seedColor: Colors.blue,
          // primarySwatch: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const CricetulusHomePage(),
    );
  }
}

class CricetulusHomePage extends StatefulWidget {
  const CricetulusHomePage({super.key});

  @override
  State<CricetulusHomePage> createState() => _CricetulusHomePageState();
}

class _CricetulusHomePageState extends State<CricetulusHomePage> {
  /// current index of the primary navigation
  int _currentIndex = 0;
  int _displayYear = DateTime.now().year;
  int _displayMonth = DateTime.now().month;

  Map<int, List<AccountEntry>> _accountEntries = {};

  @override
  void initState() {
    super.initState();
    _updateAccountEntries();
  }


  Future<void> _updateAccountEntries() async {
    var entries = await AccountEntryManager.queryAccountByYearMonth(
      _displayYear, _displayMonth
    );
    setState(() {
      _accountEntries = entries;
    });
  }

  void _changeDisplayYearMonth() async {
    var selectableYearMonth = await AccountEntryManager.queryYearMonth();
    var selected = await showModalBottomSheet(
      context: context,
      builder: (context) {
        return YearMonthPicker(
          selectedYear: _displayYear,
          selectedMonth: _displayMonth,
          selectableMonth: selectableYearMonth,
        );
      }
    );
    setState(() {
      _displayYear = selected?['year'] ?? _displayYear;
      _displayMonth = selected?['month'] ?? _displayMonth;
    });

    await _updateAccountEntries();
  }

  Future<void> _navigateAndAddEntry(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
          ChangeNotifierProvider(
            create: (context) => AccountTagManager(),
            child: AddEntryPage(
              selectedDate: DateTime.now(),
              amount: '',
              selectedTag: null,
              comment: '',
            ),
          ),
      )
    );

    // User didn't add entry.
    if (result == null) return;
    // Insert new entry to database.
    await AccountEntryManager.insert(result);

    // Only change the UI when displaying data changes.
    if (result!.date.year != _displayYear) return;
    if (result!.date.month != _displayMonth) return;

    setState(() {
      _updateAccountEntries();
    });
  }

  void _deleteEntry(int id) async {
    await AccountEntryManager.delete(id);
    await _updateAccountEntries();
  }

  void _editEntry(BuildContext context, AccountEntry entry) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (contet) => ChangeNotifierProvider(
          create: (context) => AccountTagManager(),
          child: AddEntryPage(
            entryId: entry.data.id,
            selectedDate: entry.data.date,
            amount: entry.data.amount.toString(),
            selectedTag: entry.data.tag,
            comment: entry.data.comment,
          ),
        ),
      )
    );

    // User cancel editing.
    if (result == null) return;

    print(result.toMap());

    await AccountEntryManager.update(result);
    await _updateAccountEntries();
  }


  void _onPressDeleteAll(BuildContext context) async {
    var result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('重要'),
        content: const Text('确认删除所有数据？'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('否'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('是'),
          )
        ],
      ),
    );
    if (result ?? false) {
      _deleteAllData();
    }
  }

  void _deleteAllData() async {
    AccountEntryManager.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('account_entry_id', 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: <Widget>[
          Row(
            children: [
              const Text('明细'),
              Expanded(
                child: Center(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      textStyle: Theme.of(context).textTheme.titleMedium,
                    ),
                    onPressed: _changeDisplayYearMonth,
                    child: Text(
                      '$_displayYear-$_displayMonth'
                    ),
                  ),
                ),
              )
            ],
          ),
          const Text('统计'),
          const Text('设置')
        ][_currentIndex],
      ),
      body: <Widget>[
        ListView(
          children: [
            for (var day in _accountEntries.keys)
              DailySummary(
                date: DateTime(
                  _displayYear,
                  _displayMonth,
                  day,
                ),
                entries: _accountEntries[day]!,
                deleteEntryCallback: _deleteEntry,
                editEntryCallback: _editEntry,
              ),
          ],
        ),
        const Placeholder(),
        Column(
          children: [
            SizedBox(
              height: 50,
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: () => _onPressDeleteAll(context),
                child: const Text('删除所有数据'),
              ),
            ),
          ],
        ),
      ][_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const <Widget>[
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.list),
            label: '明细',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.chartPie),
            // selectedIcon: Icon(Icons.pie_chart_rounded),
            label: '统计',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.gear),
            label: '设置',
          )
        ],
      ),
      floatingActionButton: <Widget?> [
        FloatingActionButton.extended(
          onPressed: () => _navigateAndAddEntry(context),
          label: const Text('Add'),
          icon: const Icon(Icons.add),
        ),
        null,
        null,
      ][_currentIndex],
      // floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}


class AddEntryPage extends StatefulWidget {
  final int? entryId;
  final DateTime selectedDate;
  final String amount;
  final AccountTag? selectedTag;
  final String comment;

  const AddEntryPage({
    super.key,
    this.entryId,
    required this.selectedDate,
    required this.amount,
    this.selectedTag,
    required this.comment,
  });

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  String _amount = '';
  AccountTag? _selectedTag;
  DateTime _selectedDate = DateTime.now();
  String _comment = '';

  @override
  void initState() {
    super.initState();
    setState(() {
      _selectedDate = widget.selectedDate;
      _amount = widget.amount;
      _selectedTag = widget.selectedTag;
      _comment = widget.comment;
    });
  }

  void _appendAmount(String number) {
    setState(() {
      _amount += number;
    });
  }

  void _deleteAmount() {
    setState(() {
      _amount = _amount.isNotEmpty
        ?  _amount.substring(0, _amount.length-1)
        : '';
    });
  }

  void Function() _handleSelectTag(AccountTag tag) {
    return () => setState(() {
      if (
        _selectedTag != null
        && _selectedTag!.name == tag.name
      ) {
        _selectedTag = null;
      } else {
        _selectedTag = tag;
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitComment(String value) {
    setState(() {
      _comment = value;
    });
  }

  Future<int> _incrementEntryId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getInt('account_entry_id') ?? 0;
    prefs.setInt('account_entry_id', id+1);
    return id;
  }

  void _navigateAndIncrementEntryId() async{
    bool validEntry = _selectedTag != null && _amount.isNotEmpty;
    Navigator.pop(
      context,
      validEntry
        ? AccountEntryData(
          id: widget.entryId ?? await _incrementEntryId(),
          tag: _selectedTag!,
          amount: double.parse(_amount),
          date: _selectedDate,
          comment: _comment,
        )
        : null
    );
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    TextStyle amountDisplay = theme.textTheme.displayLarge!.copyWith(
      color: theme.colorScheme.onPrimaryContainer,
    );

    return Card(
      color: theme.colorScheme.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(100),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5)
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Icon(Icons.close),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              children: [
                TextButton(
                  onPressed: () => _selectDate(context),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    )
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_calendar_outlined),
                      Text(
                        '  ${_selectedDate.toLocal()}'.substring(0, 12),
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text(' ¥  ', style: amountDisplay),
                      Text(_amount, style: amountDisplay),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Consumer<AccountTagManager>(
                    builder: (context, manager, child) {
                      return Wrap(
                        alignment: WrapAlignment.start,
                        direction: Axis.horizontal,
                        crossAxisAlignment: WrapCrossAlignment.start,
                        children: [
                          for (var tag in manager.tags)
                            AccountTagButton(
                              tag: tag,
                              active: _selectedTag != null
                                && _selectedTag!.name == tag.name,
                              onChanged: _handleSelectTag(tag),
                            ),
                        ],
                      );
                    }
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 6.0,
                  ),
                  child: TextField(
                    onSubmitted: _submitComment,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: _comment.isNotEmpty ? _comment : '添加备注',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 2.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          NumbericPanel(
            numberOnPressed: _appendAmount,
            backspaceOnPressed: _deleteAmount,
            submitOnPressed: _navigateAndIncrementEntryId,
          ),
        ],
      ),
    );
  }
}

Map<int, List<bool>> appendThisYearMonth(Map<int, List<bool>> map) {
  Map<int, List<bool>> result = {};
  result.addAll(map);
  int thisYear = DateTime.now().year;
  int thisMonth = DateTime.now().month;
  if (!result.containsKey(thisYear)) {
    result[thisYear] = [];
    for (int m = 0; m < 12; ++m) {
      result[thisYear]!.add(m+1 == thisMonth);
    }
  } else {
    result[thisYear]![thisMonth-1] = true;
  }
  return result;
}


class YearMonthPicker extends StatefulWidget {
  final Map<int, List<bool>> selectable;

  final int selectedYear;
  final int selectedMonth;

  static const List<String> _monthNames = [
    '一月', '二月', '三月', '四月',
    '五月', '六月', '七月', '八月',
    '九月', '十月', '十一月', '十二月',
  ];

  YearMonthPicker({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required selectableMonth,
  }): selectable = appendThisYearMonth(selectableMonth);


  @override
  State<YearMonthPicker> createState() => _YearMonthPickerState();
}

class _YearMonthPickerState extends State<YearMonthPicker> {
  int? _selectedYear;

  void Function()? _onPressMonth(BuildContext context, int month) {
    // Disable the button if this month is not selectable.
    if (!widget.selectable[
      _selectedYear ?? widget.selectedYear
    ]![month]) {
      return null;
    }
    return () {
      Navigator.pop(
        context,
        {
          'year': _selectedYear ?? widget.selectedYear,
          'month': month+1,
        }
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Column(
      children: [
        DropdownButton(
          style: Theme.of(context).textTheme.titleLarge,
          hint: Text('${widget.selectedYear}'),
          value: _selectedYear,
          onChanged: (int? value) {
            setState(() {
              _selectedYear = value;
            });
          },
          items: [
            for (var year in widget.selectable.keys)
              DropdownMenuItem(
                value: year,
                child: Text('$year'),
              )
          ],
        ),
        Table(
          children: <TableRow>[
            for (var row = 0; row < 3; ++row)
              TableRow(
                children: [
                  for (var column = 0; column < 4; ++column)
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromRadius(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        textStyle: theme.textTheme.titleLarge,
                        foregroundColor:
                          widget.selectedMonth == row*4+column+1
                            && widget.selectedYear == _selectedYear
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                        backgroundColor:
                          widget.selectedMonth == row*4+column+1
                          && widget.selectedYear == _selectedYear 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onPrimary,
                      ),
                      onPressed: _onPressMonth(context, row*4+column),
                      child: Text(YearMonthPicker._monthNames[row*4+column]),
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}