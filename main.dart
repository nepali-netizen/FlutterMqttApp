import 'package:flutter/material.dart';
import 'package:flutter_new/src/mqtt_handler/mqtt_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyStatefulWidget(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  bool _isSwitchOn = true;
  double _sliderValue = 255.0;
  MqttHandler mqttHandler = MqttHandler();

  @override
  void initState() {
    super.initState();
    mqttHandler.connect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Smart Bulb'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text("Data received:",
                  style: TextStyle(color: Colors.black, fontSize: 25)),
              ValueListenableBuilder<String>(
                builder: (BuildContext context, String value, Widget? child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text(value, style: const TextStyle(fontSize: 30))
                    ],
                  );
                },
                valueListenable: mqttHandler.data,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 200.0,
                  child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        overlayShape: SliderComponentShape.noOverlay,
                        trackShape: const RoundedRectSliderTrackShape(),
                        trackHeight: 20,
                      ),
                      child: Slider(
                        value: _sliderValue,
                        min: 0.0,
                        max: 255.0,
                        allowedInteraction: SliderInteraction.slideOnly,
                        onChanged: (value) {
                          setState(() {
                            _sliderValue = value;
                          });
                        },
                        onChangeEnd: (value) => {
                          mqttHandler.publishMessage(
                              "${(value / 255.0 * 100).toInt()}")
                        },
                      )),
                ),
              )
            ],
          ),
        ),
        floatingActionButton: SizedBox(
            height: 80,
            width: 80,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isSwitchOn = !_isSwitchOn;
                });
                if (_isSwitchOn) {
                  mqttHandler.publishMessage("ON");
                } else {
                  mqttHandler.publishMessage("OFF");
                }
              },
              backgroundColor: _isSwitchOn ? Colors.yellow : Colors.grey,
              child: const Icon(
                Icons.lightbulb,
                size: 40,
              ),
            )));
  }
}
