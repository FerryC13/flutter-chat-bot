// ignore_for_file: prefer_const_constructors, avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:chat_gpt/model/message_model.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:core';

/// api_key
const apiKey = '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';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final _txtMessage = TextEditingController();
  final _scrollController = ScrollController();
  bool isLoading = false;
  String megaPrompt =
      "The following is a conversation with an AI assistant. The assistant is helpful, creative, clever, and very friendly \n. Human: Hello, who are you?\n AI: I am an AI created by OpenAI. How can I help you today?\n Human: ";

  /// variable for sizing
  double kDefault = 15.0;
  String kUrlProfile =
      "https://images.unsplash.com/photo-1511367461989-f85a21fda167?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1931&q=80";

  /// chatGPT variable
  late ChatGPT openAI;
  StreamSubscription? subscription;

  ///list of messages
  final messages = [
    MessageModel(false, "Hello, who are you?"),
    MessageModel(
        true, " I am an AI created by OpenAI. How can I help you today?")
  ];

  Future<String> generateResponse(String miniPrompt) async {
    var url = Uri.https("api.openai.com", "/v1/completions");
    final resp = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey'
        },
        body: jsonEncode({
          'model': 'text-davinci-003',
          'prompt': miniPrompt,
          'temperature': 0.9,
          "max_tokens": 500,
          "top_p": 1,
          "frequency_penalty": 0.0,
          "presence_penalty": 0.6,
          "stop": [" Human:", " AI:"],
        }));
    Map<String, dynamic> newResp = jsonDecode(resp.body);
    return newResp['choices'][0]['text'];
  }

  @override
  void initState() {
    // print("Initializing");
    // print("Api key :" + apiKey);
    // openAI = ChatGPT.instance
    //     .builder(apiKey, baseOption: HttpSetup(receiveTimeout: 7000));
    super.initState();
  }

  // void sendMessage(String message) async {
  //   final request = CompleteReq(
  //     prompt: message,
  //     model: kTranslateModelV3,
  //     max_tokens: 200,
  //   );

  //   openAI.onCompleteStream(request: request).listen((response) {
  //     print(response?.choices.last.text ?? "Error");
  //     setState(() {
  //       messages
  //           .add(MessageModel(true, response?.choices.last.text ?? "Error"));
  //     });
  //   });
  // }

  @override
  void dispose() {
    // openAI.close();
    _txtMessage.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _sendMessage() {
    String prompt = _txtMessage.text.toString();
    // Display user input
    setState(() {
      messages.add(MessageModel(false, prompt));
      _txtMessage.clear();
      isLoading = true;
    });
    megaPrompt = "$megaPrompt $prompt \n AI: ";
    Future.delayed(const Duration(milliseconds: 50)).then((_) => _scrollDown());
    // call GPT api
    generateResponse(megaPrompt).then((value) {
      setState(() {
        megaPrompt = "$megaPrompt $value \n Human: ";
        isLoading = false;
        messages.add(MessageModel(true, value));
        Future.delayed(const Duration(milliseconds: 50))
            .then((_) => _scrollDown());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _appBar(context),
              _messageList(),
              _bottomNavigation(context)
            ],
          ),
        ],
      ),
    );
  }

  Expanded _messageList() {
    return Expanded(
      flex: 7,
      child: Scrollbar(
        child: ListView.builder(
          controller: _scrollController,
          itemCount: messages.length,
          itemBuilder: (context, ind) {
            return messages[ind].isBot
                ? _botCard(index: ind)
                : _userCard(index: ind);
          },
        ),
      ),
    );
  }

  Container _userCard({required int index}) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      padding: EdgeInsets.symmetric(horizontal: kDefault),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: kDefault * 1.1, vertical: kDefault / 1.2),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background,
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(kDefault * 1.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.12),
                          offset: Offset(0.5, kDefault / 1.6),
                          blurRadius: kDefault * 2,
                        ),
                      ]),
                  child: Text(
                    (messages[index].message),
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: CircleAvatar(
              child: Icon(
                Icons.person,
                size: kDefault * 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container _botCard({required int index}) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      padding: EdgeInsets.symmetric(horizontal: kDefault, vertical: kDefault),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(kUrlProfile),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.all(3),
                  padding: EdgeInsets.symmetric(
                      horizontal: kDefault * 1.1, vertical: kDefault / 1.2),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(kDefault * 1.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.12),
                          offset: Offset(kDefault / 1.2, kDefault / 2),
                          blurRadius: kDefault * 2,
                        ),
                      ]),
                  child: Text(
                    (messages[index].message).trim(),
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Container _bottomNavigation(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Expanded(
        flex: 1,
        child: Container(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Visibility(
                visible: isLoading,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: kDefault,
                  ),
                  width: double.maxFinite,
                  child: Text(
                    "ChatGPT is typing...",
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.secondary),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              Container(
                height: MediaQuery.of(context).size.height *
                    (isLoading ? 0.06 : 0.07),
                width: double.maxFinite,
                padding: EdgeInsets.symmetric(horizontal: kDefault),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(kDefault),
                    topLeft: Radius.circular(kDefault),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.23),
                      offset: Offset(.5, kDefault / 1.2),
                      blurRadius: kDefault,
                    ),
                  ],
                ),
                child: Container(
                  margin: EdgeInsets.only(bottom: kDefault * 0.5),
                  padding: EdgeInsets.only(
                      left: kDefault * 0.5, right: kDefault * 0.5),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSecondary,
                      borderRadius: BorderRadius.circular(kDefault)),
                  child: TextField(
                    textInputAction: TextInputAction.newline,
                    onSubmitted: (value) {
                      _sendMessage();
                    },
                    controller: _txtMessage,
                    decoration: InputDecoration(
                      suffixIcon: GestureDetector(
                        onTap: () {
                          _sendMessage();
                          // sendMessage(_txtMessage.text.toString());
                        },
                        child: Icon(
                          Icons.send,
                          size: kDefault * 1.4,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      hintText: "Message",
                      disabledBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.onSecondary,
      title: Expanded(
        flex: 1,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: kDefault,
            vertical: kDefault / 3,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSecondary,
            // borderRadius: BorderRadius.only(
            //   bottomRight: Radius.circular(kDefault),
            //   bottomLeft: Radius.circular(kDefault),
            // ),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.grey.withOpacity(0.23),
            //     offset: Offset(kDefault / 1.2, 0.5),
            //     blurRadius: kDefault,
            //   ),
            // ],
          ),
          child: Row(
            children: [
              // Icon(
              //   Icons.arrow_back_rounded,
              //   color: Colors.black,
              //   size: kDefault * 1.6,
              // ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: kDefault),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(kUrlProfile),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Chat GPT",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                  Text(
                    "Online",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.green),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
