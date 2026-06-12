// Usage: docViewer(context, 'https://example.com/privacy', 'Privacy Policy')
// Pass a hosted document URL and the title to show in the sheet.
//
// Typically used in Settings screen.
//
// showCupertinoSheet docs: ~/.claude/skills/skill-flutter-cupertino-sheet/skill.md
//
// Required packages:
//   - webview_flutter

import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';

void docViewer(BuildContext context, String url, String title) {
  showCupertinoSheet(
    context: context,
    enableDrag: false,
    builder: (context) {
      return DocViewerWidget(url: url, title: title);
    },
  );
}

class DocViewerWidget extends StatefulWidget {
  const DocViewerWidget({super.key, required this.url, required this.title});

  final String url;
  final String title;

  @override
  State<DocViewerWidget> createState() => _DocViewerWidgetState();
}

class _DocViewerWidgetState extends State<DocViewerWidget> {
  late WebViewController _docViewController;
  late Uri _initialUri;
  late String _allowedDomain;

  @override
  void initState() {
    super.initState();

    _initialUri = Uri.parse(widget.url);
    _allowedDomain = _initialUri.host;

    _docViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final requestUri = Uri.parse(request.url);
            final requestDomain = requestUri.host;

            if (requestDomain == _allowedDomain ||
                requestDomain.endsWith('.$_allowedDomain') ||
                _allowedDomain.endsWith('.$requestDomain')) {
              return NavigationDecision.navigate;
            }

            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(_initialUri);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGrey6,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGrey6,
        middle: Text(widget.title),
        automaticallyImplyLeading: false,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.xmark),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
        child: WebViewWidget(controller: _docViewController),
      ),
    );
  }
}
