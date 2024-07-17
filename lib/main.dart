import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:bubble/bubble.dart';

// CREDENTIALS
const API_KEY =  'bdocs-CqtL0RwpEjhAUtaOMoRaKyAhpGZQ5kX2RS92NquEyPU';// 'bdocs-wIV08x7k2tDl868xOgO82qoEdbjvI_1sTop-_cdMdME';//
const KB_ID =  '9905afb9-3379-46af-ada0-6b9aa250ee82';// '306c3acc-490d-499f-b4e4-3617098f5491';//
const Agent_ID = '18473f2f-8815-4863-84fa-c3c6d63041c3';// '64d09a6f-0ad9-403c-ae27-a19b266a0233';//

const domain = 'localhost:8000';//'app.docs.bynesoft.com';//

const _assistant = types.User(id: '82090008-a484-4a89-ae75-a22bf8d6f3ac');
const _user = types.User(id: '82091008-a484-4a89-ae75-a22bf8d6f3ac');
const byne_header = {
  'X-API-Key': API_KEY,
  'Content-Type': 'application/json'
};


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: MyHomePage(),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<types.Message> _messages = [];
  var _conv_id;
  final agentId = Agent_ID;
  final kbId = KB_ID;

  @override
  void initState() {
    super.initState();
    _initMsg();
  }

  void _initMsg() {
      var uri = Uri.http(domain, '/api/ask/query/agents/$agentId', {
          'kb' : kbId,
          'q': '[You are AutoOwl, an AI car concierge. Respond in the same language as the customer. Begin the chat in English, introduce yourself.]'
      });
      var resp = http.post(
        uri,
        headers: byne_header,
        body: '{}',
    ).then((resp) {
      print(resp.body);
      var resp_json = jsonDecode(utf8.decode(resp.bodyBytes));
        var msg = resp_json['response']['answer'];
        _conv_id = resp_json['conversationId'];
            final assistantMessage = types.CustomMessage(
              author: _assistant,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              id: _randomString(),
              metadata: {
                'text': msg
              }
            );
            setState(() {
              _messages.add(assistantMessage);
            });
      });
  }


  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: [
            _buildChatPanel(),
            Expanded(
              child: Chat(
                messages: _messages,
                onSendPressed: _handleSendPressed,
                user: _user,
                bubbleBuilder: _bubbleBuilder,
                customMessageBuilder: (message, {required messageWidth}) {
                  if (message.metadata?['type'] == 'typing') {
                    return HtmlWidget('');
                  } else if (message.metadata?['image'] != null) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.network(message.metadata!['image']),
                          const SizedBox(height: 8),
                          Text(
                            message.metadata!['title'],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text('Make: ${message.metadata!['make']}'),
                          Text('Model: ${message.metadata!['model']}'),
                          Text('Year: ${message.metadata!['year']}'),
                          Text('Mileage: ${message.metadata!['mileage']}'),
                          Text('Price: ${message.metadata!['price']}'),
                          Text('Fuel Type: ${message.metadata!['fuelType']}'),
                          Text('Transmission: ${message.metadata!['transmission']}'),
                        ],
                      ),
                    );
                  } else {
                    return HtmlWidget('<p style="font-size:1.5em;">' +
                        md.markdownToHtml(message.metadata?['text']) +
                        '</p>');
                  }
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildChatPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue,
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage('https://purple-lake-654a.b-nadykto.workers.dev/https://autoowl.ai/icons/Icon-192.png'),
          ),
          SizedBox(width: 16),
          Text(
            'AutoOwl',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubbleBuilder(
    Widget child, {
    required message,
    required nextMessageInGroup,
  }) {
    if (message is types.CustomMessage && message.metadata?['type'] == 'typing') {
      return Bubble(
        color: const Color(0xfff5f5f7),
        margin: const BubbleEdges.symmetric(horizontal: 6),
        nip: BubbleNip.leftBottom,
        child: const SizedBox(
          width: 50,
          height: 30,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return Bubble(
      color: _user.id != message.author.id || message.type == types.MessageType.image
          ? const Color(0xfff5f5f7)
          : const Color(0xff6f61e8),
      margin: nextMessageInGroup ? const BubbleEdges.symmetric(horizontal: 6) : null,
      nip: nextMessageInGroup
          ? BubbleNip.no
          : _user.id != message.author.id
              ? BubbleNip.leftBottom
              : BubbleNip.rightBottom,
      child: child,
    );
  }


  String convertLinkToMarkdown(String url) {
    Uri uri = Uri.parse(url);
    String host = uri.host;
    
    // Remove 'www.' if present
    if (host.startsWith('www.')) {
      host = host.substring(4);
    }
    
    // Split the host by '.' and capitalize the first part
    List<String> parts = host.split('.');
    String siteName = parts[0][0].toUpperCase() + parts[0].substring(1);
    
    return '[$siteName]($url)';
  }

  Future<void> _handleSendPressed(types.PartialText message) async {
    final userMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: _randomString(),
      text: message.text
    );

    setState(() {
      _messages.insert(0, userMessage);
    });

    final typingMessage = types.CustomMessage(
      author: _assistant,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: _randomString(),
      metadata: const {'type': 'typing'},
    );

    setState(() {
      _messages.insert(0, typingMessage);
    });

    await _getChatCompletion(message.text, typingMessage.id);
  }

  Future<void> _getChatCompletion(String userMessage, String typingMessageId) async {
    print(userMessage);
    print(_conv_id);
    var uri = Uri.http(domain, '/api/ask/query/agents/$agentId', {
          'kb' : kbId,
          'q': userMessage,
          "withReference": 'true'
      });
    print(uri);
    var resp = http.post(
        uri,
        headers: byne_header,
        body: jsonEncode({
          "conversation": {
                "id": _conv_id,
                "priorMessagesCount": 10
          }
        }),
    ).then((resp){
      print(resp.body);
      var resp_json = jsonDecode(utf8.decode(resp.bodyBytes));
      print(resp_json);
      var msg = resp_json['response']['answer'];
      _handleCompletedResponse(msg, typingMessageId);
      if (resp_json['response'].containsKey('reference')){
        var str_source = resp_json['response']['reference'][0]['source'];
        bool isLink = Uri.tryParse(str_source)?.hasAbsolutePath ?? false;
        if (isLink){
          for (var ref in resp_json['response']['reference']){
            var link = ref['source'];
            final assistantMessage = types.CustomMessage(
              author: _assistant,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              id: _randomString(),
              metadata: {
                'text': convertLinkToMarkdown(link),
              }
            );
            setState(() {
              _messages.insert(0, assistantMessage);
            });
          }
        }else{
          var source = jsonDecode(str_source);
          var cars = source['results'];
          _outputCars(cars);
        }

      }
    });
  }

  List<types.Message> _outputCars(List<dynamic> carData) {
    final List<types.Message> carMessages = [];
    for (var car in carData) {
      print(car);
      final carMessage = types.CustomMessage(
        author: _assistant,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: _randomString(),
        metadata: {
          'image': 'https://purple-lake-654a.b-nadykto.workers.dev/'+car['images'][0]['srcset'].split(' ')[0],
          'title': car['description']['title'],
          'make': car['general']['make']['name'],
          'model': car['general']['model']['name'],
          'year': car['general']['year'].toString(),
          'mileage': car['condition']['odometer']['formatted'],
          'price': car['sales_conditions']['pricing']['asking']['consumer']['formatted'],
          'fuelType': car['powertrain']['engine']['energy']['type']['category']['display_value'],
          'transmission': car['powertrain']['transmission']['type']['display_value'],
        },
      );

      carMessages.add(carMessage);
    }

    setState(() {
      _messages.insertAll(0, carMessages);
    });

    return carMessages;
  }

  void _handleCompletedResponse(String responseData, String typingMessageId) {
    setState(() {
      _messages.removeWhere((msg) => msg.id == typingMessageId);
    });

    final assistantMessage = types.CustomMessage(
      author: _assistant,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: _randomString(),
      metadata: {
        'text': responseData,
      }
    );
    setState(() {
      _messages.insert(0, assistantMessage);
    });
  }


  String _randomString() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(255));
    return base64UrlEncode(values);
  }
}