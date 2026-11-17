import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String hostDeviceName = "আমার হটস্পট ফোন";
  String wifiPassword = "hospo_secret_pass";
  bool showPassword = false;

  List> connectedDevices = [
    {
      'ip': '192.168.43.15',
      'name': 'রহিমের ফোন',
      'usedMB': 45.5,
      'limitMB': 100,
    },
    {
      'ip': '192.168.43.22',
      'name': 'সাকিবের ফোন',
      'usedMB': 92.0,
      'limitMB': 100,
    }
  ];

  void _generateRandomPassword() {
    setState(() {
      wifiPassword = "Hsp_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('পাসওয়ার্ড সফলভাবে পরিবর্তন করা হয়েছে!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospo Control Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: _editHostDeviceName,
            tooltip: "নিজের ফোন রিনেম",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Host Info & Password Manager Card
            Card(
              color: const Color(0xFF1E1E1E),
              child: ListTile(
                title: Text(hostDeviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text(showPassword ? "পাসওয়ার্ড: $wifiPassword" : "পাসওয়ার্ড: ••••••••"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => showPassword = !showPassword),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.greenAccent),
                      onPressed: _generateRandomPassword,
                      tooltip: "এক ক্লিকে পাসওয়ার্ড চেঞ্জ",
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Dynamic QR Code Card
            Card(
              color: const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('কানেক্ট করতে স্ক্যান করুন (WiFi + Proxy)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: QrImageView(
                        data: 'WIFI:S:Hospo-Network;T:WPA;P:$wifiPassword;PROXY:192.168.43.1:8080;;',
                        version: QrVersions.auto,
                        size: 160.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('ম্যানুয়াল আইপি: 192.168.43.1  |  পোর্ট: 8080', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Connected Devices Header
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('কানেক্টেড ডিভাইসসমূহ (Data Monitor)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),

            // Connected Devices List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: connectedDevices.length,
              itemBuilder: (context, index) {
                final device = connectedDevices[index];
                double progress = device['usedMB'] / device['limitMB'];
                return Card(
                  color: const Color(0xFF1E1E1E),
                  child: ListTile(
                    title: Text(device['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text('আইপি: ${device['ip']} | ব্যবহার: ${device['usedMB']} MB / ${device['limitMB']} MB'),
                        const SizedBox(height: 5),
                        LinearProgressIndicator(
                          value: progress > 1.0 ? 1.0 : progress,
                          color: progress >= 0.9 ? Colors.red : Colors.blueAccent,
                          backgroundColor: Colors.grey[800],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                      onPressed: () => _renameDevice(index),
                      tooltip: "ডিভাইস রিনেম করুন",
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editHostDeviceName() {
    TextEditingController controller = TextEditingController(text: hostDeviceName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('নিজের ডিভাইসের নাম পরিবর্তন'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "নতুন নাম লিখুন")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () {
              setState(() => hostDeviceName = controller.text);
              Navigator.pop(context);
            },
            child: const Text('সেভ'),
          ),
        ],
      ),
    );
  }

  void _renameDevice(int index) {
    TextEditingController controller = TextEditingController(text: connectedDevices[index]['name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('কানেক্টেড ডিভাইস রিনেম করুন'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "যেমন: রহিমের ফোন")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () {
              setState(() => connectedDevices[index]['name'] = controller.text);
              Navigator.pop(context);
            },
            child: const Text('সেভ'),
          ),
        ],
      ),
    );
  }
}
