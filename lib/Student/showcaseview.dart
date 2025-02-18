import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

class ShowCaseView extends StatelessWidget {
  const ShowCaseView({
    super.key,
    required this.globalKey,
    required this.title,
    required this.description,
    required this.child,
    required String showcaseId,
    required Null Function() onStart,
    required Null Function() onComplete,
    required builder,
  });

  final GlobalKey globalKey;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Showcase(
      key: globalKey,
      title: title,
      description: description,
      child: child,
    );
  }

  static void start(
      BuildContext context, List<GlobalKey<State<StatefulWidget>>> list) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var key in list) {
        ShowCaseWidget.of(context).startShowCase([key]);
      }
    });
  }
}
