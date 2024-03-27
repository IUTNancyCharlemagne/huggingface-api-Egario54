import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:empty_widget/empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'widgets.dart';
import 'utils.dart';

final List<String> imgList = [
  'https://github.com/IUTNancyCharlemagne/huggingface-api-Egario54/tree/main/huggingface/name_yet_to_be_found_flutter/img/Puffer/Puffer.jpg',
  'https://github.com/IUTNancyCharlemagne/huggingface-api-Egario54/tree/main/huggingface/name_yet_to_be_found_flutter/img/Penguin/Penguin.jpg',
  'https://github.com/IUTNancyCharlemagne/huggingface-api-Egario54/tree/main/huggingface/name_yet_to_be_found_flutter/img/Octopus/Octopus2.jpg',
  'https://github.com/IUTNancyCharlemagne/huggingface-api-Egario54/tree/main/huggingface/name_yet_to_be_found_flutter/img/Eel/eel2.jpeg',
  'https://github.com/IUTNancyCharlemagne/huggingface-api-Egario54/tree/main/huggingface/name_yet_to_be_found_flutter/img/Eel/eel.jpg',
  'https://github.com/IUTNancyCharlemagne/huggingface-api-Egario54/tree/main/huggingface/name_yet_to_be_found_flutter/img/Dolphin/Dolphin.png',
  'https://github.com/IUTNancyCharlemagne/huggingface-api-Egario54/tree/main/huggingface/name_yet_to_be_found_flutter/img/Squid/squid.jpg',
  'https://github.com/IUTNancyCharlemagne/huggingface-api-Egario54/tree/main/huggingface/name_yet_to_be_found_flutter/img/Seahorse/Seahorse.JPG',
  'https://github.com/IUTNancyCharlemagne/huggingface-api-Egario54/tree/main/huggingface/name_yet_to_be_found_flutter/img/Sea_tortoise/Turtle.jpg',
  'https://github.com/IUTNancyCharlemagne/huggingface-api-Egario54/tree/main/huggingface/name_yet_to_be_found_flutter/img/Shark/Shar.jpg',
  'https://github.com/IUTNancyCharlemagne/huggingface-api-Egario54/tree/main/huggingface/name_yet_to_be_found_flutter/img/Shark/Shark.jpg',
  'https://github.com/IUTNancyCharlemagne/huggingface-api-Egario54/tree/main/huggingface/name_yet_to_be_found_flutter/img/Shark/NotShark.jpg'
];

//Local mais qui ne marche pas (je pense qu'ils ne sont pas inclus)
/**final List<String> imgList = [
  './img/Puffer/Puffer.jpg',
  './img/Penguin/Penguin.jpg',
  './img/Octopus/Octopus2.jpg',
  './img/Eel/eel2.jpeg',
  './img/Eel/eel.jpg',
  './img/Dolphin/Dolphin.png',
  './img/Squid/squid.jpg',
  './img/Seahorse/Seahorse.JPG',
  './img/Sea_tortoise/Turtle.jpg',
  './img/Shark/Shar.jpg',
  './img/Shark/Shark.jpg',
  './img/Shark/NotShark.jpg'
];*/////

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Sea Animals Classifier',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'The Sea Animals Classifier'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final RoundedLoadingButtonController _btnController =
      RoundedLoadingButtonController();

  // ignore: unused_field
  String? _resultString;
  Map _resultDict = {
    "label": "None",
    "confidences": [
      {"label": "None", "confidence": 0.0},
      {"label": "None", "confidence": 0.0},
      {"label": "None", "confidence": 0.0}
    ]
  };

  String _latency = "N/A";

  File? imageURI; // Show on image widget on app
  Uint8List? imgBytes; // Store img to be sent for api inference
  bool isClassifying = false;

  String parseResultsIntoString(Map results) {
    return """
    ${results['confidences'][0]['label']} - ${(results['confidences'][0]['confidence'] * 100.0).toStringAsFixed(2)}% \n
    ${results['confidences'][1]['label']} - ${(results['confidences'][1]['confidence'] * 100.0).toStringAsFixed(2)}% \n
    ${results['confidences'][2]['label']} - ${(results['confidences'][2]['confidence'] * 100.0).toStringAsFixed(2)}% """;
  }

  clearInferenceResults() {
    _resultString = "";
    _latency = "N/A";
    _resultDict = {
      "label": "None",
      "confidences": [
        {"label": "None", "confidence": 0.0},
        {"label": "None", "confidence": 0.0},
        {"label": "None", "confidence": 0.0}
      ]
    };
  }

  Widget buildModalBtmSheetItems() {
    return SizedBox(
      height: 120,
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.camera),
            title: const Text("Camera"),
            onTap: () async {
              final XFile? pickedFile =
                  await ImagePicker().pickImage(source: ImageSource.camera);

              if (pickedFile != null) {
                // Clear result of previous inference as soon as new image is selected
                setState(() {
                  clearInferenceResults();
                });

                File croppedFile = await cropImage(pickedFile);
                final imgFile = File(croppedFile.path);
                // final imgFile = File(pickedFile.path);

                setState(() {
                  imageURI = imgFile;
                  _btnController.stop();
                  isClassifying = false;
                });
                Navigator.pop(context);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text("Gallery"),
            onTap: () async {
              final XFile? pickedFile =
                  await ImagePicker().pickImage(source: ImageSource.gallery);

              if (pickedFile != null) {
                // Clear result of previous inference as soon as new image is selected
                setState(() {
                  clearInferenceResults();
                });

                File croppedFile = await cropImage(pickedFile);
                final imgFile = File(croppedFile.path);

                setState(
                  () {
                    imageURI = imgFile;
                    _btnController.stop();
                    isClassifying = false;
                  },
                );
                Navigator.pop(context);
              }
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> imageSliders = imgList
        .map((item) => Container(
              margin: const EdgeInsets.all(5.0),
              child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                  child: Stack(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () async {
                          context.loaderOverlay.show();

                          String imgUrl = imgList[imgList.indexOf(item)];

                          final File imgFile = await getImage(imgUrl);

                          setState(() {
                            imageURI = imgFile;
                            _btnController.stop();
                            isClassifying = false;
                            clearInferenceResults();
                          });
                          context.loaderOverlay.hide();
                        },
                        child: CachedNetworkImage(
                          imageUrl: item,
                          fit: BoxFit.fill,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                      Positioned(
                        bottom: 0.0,
                        left: 0.0,
                        right: 0.0,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.fromARGB(200, 0, 0, 0),
                                Color.fromARGB(0, 0, 0, 0)
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 20.0),
                          child: Text(
                            'GT: ${imgList[imgList.indexOf(item)].split('/').reversed.elementAt(1)}', // get the class name from url
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
            ))
        .toList();

    return LoaderOverlay(
      child: Scaffold(
        drawer: Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text('The Sea Animals Classifier'),
              ),
              ListTile(
                title: const Text('Hello to my app c:'),
                onTap: () {
                  // Update the state of the app
                  // ...
                  // Then close the drawer
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Version : 0.1'),
                onTap: () {
                  // Update the state of the app
                  // ...
                  // Then close the drawer
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Exit app'),
                onTap: () {
                  // just exitin'
                  exit(0);
                },
              ),
            ],
          ),
        ),
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              imageURI == null
                  ? SizedBox(
                      height: 200,
                      child: EmptyWidget(
                        image: null,
                        packageImage: PackageImage.Image_3,
                        title: 'No image',
                        subTitle: 'Select an image',
                        titleTextStyle: const TextStyle(
                          fontSize: 15,
                          color: Color(0xff9da9c7),
                          fontWeight: FontWeight.w500,
                        ),
                        subtitleTextStyle: const TextStyle(
                          fontSize: 14,
                          color: Color(0xffabb8d6),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        const Spacer(),
                        Image.file(imageURI!, height: 200, fit: BoxFit.cover),
                        const Spacer(),
                      ],
                    ),
              const SizedBox(
                height: 8,
              ),
              Text("Top 3 predictions",
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              FittedBox(child: buildResultsIndicators(_resultDict)),
              const SizedBox(height: 8),
              Text("Latency: $_latency ms",
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text("Samples", style: Theme.of(context).textTheme.titleLarge),
              CarouselSlider(
                options: CarouselOptions(
                  height: 180,
                  autoPlay: true,
                  // aspectRatio: 2.5,
                  viewportFraction: 0.4,
                  enlargeCenterPage: false,
                  enlargeStrategy: CenterPageEnlargeStrategy.height,
                ),
                items: imageSliders,
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: RoundedLoadingButton(
                  width: MediaQuery.of(context).size.width * 0.5,
                  color: Colors.blue,
                  successColor: Colors.green,
                  controller: _btnController,
                  onPressed: isClassifying || imageURI == null
                      ? null // null value disables the button
                      : () async {
                          isClassifying = true;

                          imgBytes = imageURI!.readAsBytesSync();
                          String base64Image = "data:image/png;base64,${base64Encode(imgBytes!)}";

                          try {
                            Stopwatch stopwatch = Stopwatch()..start();
                            final result = await classifyRiceImage(base64Image);

                            setState(() {
                              _resultString = parseResultsIntoString(result);
                              _resultDict = result;
                              _latency =
                                  stopwatch.elapsed.inMilliseconds.toString();
                            });
                            _btnController.success();
                          } catch (e) {
                            _btnController.error();
                          }
                          isClassifying = false;
                        },
                  // resetAfterDuration: true,
                  // resetDuration: const Duration(seconds: 10),
                  child: const Text('Classify!',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              Row(
                children: [
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Linkify(
                      onOpen: (link) async {
                        if (await canLaunchUrl(Uri.parse(link.url))) {
                          await launchUrl(Uri.parse(link.url));
                        } else {
                          throw 'Could not launch $link';
                        }
                      },
                      text: "Made by https://dicksonneoh.com and stolen by myself",
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          label: const Text("Take picture"),
          icon: const Icon(Icons.camera),
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              builder: (BuildContext context) {
                return buildModalBtmSheetItems();
              },
            );
          },
        ),
      ),
    );
  }
}
