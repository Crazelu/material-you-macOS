import 'package:flutter/material.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  int _counter = 0;
  bool _switchActive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Wallpaper Theme Demo')),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(onPressed: () {}, child: Text('Elevated Button')),
            SizedBox(height: 8),
            FilledButton(onPressed: () {}, child: Text('Filled Button')),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Switch(
                  value: _switchActive,
                  onChanged: (value) {
                    setState(() {
                      _switchActive = value;
                    });
                  },
                ),
                SizedBox(width: 8),
                RadioGroup(
                  groupValue: true,
                  onChanged: (_) {},
                  child: Radio(value: true),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text('$_counter', style: Theme.of(context).textTheme.displayLarge),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _counter++),
        child: const Icon(Icons.add),
      ),
    );
  }
}
