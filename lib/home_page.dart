import 'dart:io';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ChatUser currentUser = ChatUser(
    id: "0",
    firstName: "Raka",
  );

  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "Gemini AI",
    profileImage:
        "https://static.promediateknologi.id/crop/0x0:0x0/0x0/webp/photo/p2/106/2024/03/28/202403271806-maincropped_1711537586-457414092.jpg",
  );

  List<ChatMessage> messages = [];

  final Gemini gemini = Gemini.instance;

  void sendMessage(ChatMessage chatMessage) async {
    setState(() {
      messages.insert(0, chatMessage);
    });

    try {
      // variable tampungan dari object chatMessage
      String question = chatMessage.text;
      List<Uint8List>? images = [];

      if (chatMessage.medias?.isNotEmpty == true) {
        images = [
          File(chatMessage.medias!.first.url).readAsBytesSync(),
        ];
      }
      gemini
          .streamGenerateContent(
        question,
        images: images,
      )
          .listen(
        (event) {
          ChatMessage? lastMessage = messages.firstOrNull;

          if (lastMessage != null && lastMessage.user == geminiUser) {
            lastMessage = messages.removeAt(0);
            String response = event.content?.parts?.fold(
                  "",
                  (previousValue, element) => "$previousValue${element.text}",
                ) ??
                "";

            lastMessage.text += response;

            setState(() {
              messages.insert(0, lastMessage!);
            });
          } else {
            String response = event.content?.parts?.fold(
                  "",
                  (previousValue, element) => "$previousValue${element.text}",
                ) ??
                "";

            ChatMessage message = ChatMessage(
              user: geminiUser,
              createdAt: DateTime.now(),
              text: response,
            );

            setState(() {
              messages.insert(0, message);
            });
          }
        },
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DashChat(
        currentUser: currentUser,
        onSend: sendMessage,
        messages: messages,
        inputOptions: InputOptions(
          trailing: [
            IconButton(
              onPressed: () {
                _sendMediaMessage();
              },
              icon: const Icon(
                Icons.image,
              ),
            )
          ],
        ),
      ),
    );
  }

  void _sendMediaMessage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? file = await imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: 'Gambar apakah ini?',
        medias: [
          ChatMedia(
            url: file.path,
            fileName: "",
            type: MediaType.image,
          ),
        ],
      );

      sendMessage(chatMessage);
    }
  }
}
