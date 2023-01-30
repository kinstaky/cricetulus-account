import 'package:flutter/material.dart';


class NumbericPanel extends StatelessWidget {
  const NumbericPanel({
    super.key,
    required this.numberOnPressed,
    required this.backspaceOnPressed,
    required this.submitOnPressed,
  });

  final void Function(String) numberOnPressed;
  final void Function()? backspaceOnPressed;
  final void Function()? submitOnPressed;

  @override
  Widget build(BuildContext context) {
    const List<String> panelText = [
      '7', '8', '9',
      '4', '5', '6',
      '1', '2', '3',
      '00', '0', '.',
    ];

    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: [
        Table(
          columnWidths: const <int, TableColumnWidth> {
            0: FlexColumnWidth(),
            1: FlexColumnWidth(),
            2: FlexColumnWidth(),
            3: FlexColumnWidth(),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: <TableRow>[
            for (var row = 0; row < 4; ++row)
              TableRow(
                children: <Widget>[
                  for (var column = 0; column < 3; ++column)
                    PanelButton(
                      minimumSize: 60,
                      onPressed: () {
                        numberOnPressed(panelText[row*3+column]);
                      },
                      child: Text(
                        panelText[row*3+column],
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    PanelButton(
                      minimumSize: 60,
                      onPressed: row == 0
                        ? backspaceOnPressed
                        : null,
                      child: row == 0
                        ? const Icon(Icons.backspace)
                        : null,
                    ),
                ]
              ),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth / 4.0,
              child: PanelButton(
                minimumSize: 180+4,
                onPressed: submitOnPressed,
                reverseColor: true,
                child: const Icon(Icons.keyboard_return),
              ),
            );
          }
        )
      ],
    );
  }
}


class PanelButton extends StatelessWidget {
  const PanelButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.minimumSize,
    this.reverseColor = false,
  });

  /// function when pressed
  final void Function()? onPressed;
  /// Icon or Text of button
  final Widget? child;
  /// minimum size of the button, default is 50
  final double? minimumSize;
  final bool reverseColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 1.0,
        horizontal: 2.0
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.square(minimumSize ?? 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          backgroundColor: reverseColor
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onPrimary,
          foregroundColor: reverseColor
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.primary,
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}
