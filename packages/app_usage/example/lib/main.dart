import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';

void main() => runApp(const AppUsageApp());

class AppUsageApp extends StatefulWidget {
  const AppUsageApp({super.key});

  @override
  AppUsageAppState createState() => AppUsageAppState();
}

class AppUsageAppState extends State<AppUsageApp> {
  List<AppUsageInfo> _infos = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  void getUsageStats() async {
    try {
      final DateTime endDate = DateTime.now();
      final DateTime startDate = endDate.subtract(const Duration(hours: 1));
      final List<AppUsageInfo> infoList =
          await AppUsage().getAppUsage(startDate, endDate);
      setState(() {
        _infos = infoList;
        _errorMessage = null;
      });
    } catch (exception) {
      setState(() {
        _infos = [];
        _errorMessage = exception.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('App Usage Example'),
          backgroundColor: Colors.green,
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          key: const Key('load_usage_button'),
          onPressed: getUsageStats,
          child: const Icon(Icons.file_download),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          key: const Key('usage_error_message'),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_infos.isEmpty) {
      return const Center(
        child: Text(
          'No usage data loaded yet.',
          key: Key('usage_empty_state'),
        ),
      );
    }

    return ListView.builder(
      itemCount: _infos.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(_infos[index].appName),
          subtitle: Text(_infos[index].packageName),
          trailing: Text(_infos[index].usage.toString()),
        );
      },
    );
  }
}
