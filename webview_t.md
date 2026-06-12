void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var prefs = await SharedPreferences.getInstance();

  var m = prefs.getBool('mmm') ?? true;
  if (!m) {
    runApp(const MainApp());
    return;
  }
  String url = jsonDecode(await HttpClient()
      .getUrl(Uri.parse('ССЫЛКА${prefs.getBool('isFirst') ?? true ? "1" : "2"}.json'))
      .then((request) => request.close())
      .then((response) => response.transform(utf8.decoder).join()));
  if (url == '') {
    prefs.setBool('mmm', false);
    runApp(const MainApp());
    return;
  }
  runApp(
    MaterialApp(
      home: WebView(url: url),
    ),
  );
  prefs.setBool('isFirst', false);
}

class WebView extends StatefulWidget {
  const WebView({super.key, required this.url});

  final String url;

  @override
  State<WebView> createState() => _WebViewState();
}

////////////////////////////////////////////////////////////////////

class _WebViewState extends State<WebView> {
  late WebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _webViewController.canGoBack()) {
          await _webViewController.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
          child: WebViewWidget(controller: _webViewController),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController()
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }
}