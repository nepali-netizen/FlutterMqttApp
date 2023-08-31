import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart' '';

class MqttHandler with ChangeNotifier {
  final ValueNotifier<String> data = ValueNotifier<String>("");
  late MqttServerClient client;

  Future<Object> connect() async {
    client = MqttServerClient.withPort('broker.emqx.io', 'nitesh', 1883);
    client.logging(on: true);
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onUnsubscribed = onUnsubscribed;
    client.onSubscribed = onSubscribed;
    client.onSubscribeFail = onSubscribeFail;
    client.pongCallback = pong;
    client.keepAlivePeriod = 60;
    client.logging(on: true);

    /// Set the correct MQTT protocol for mosquito
    client.setProtocolV311();

    final connMessage = MqttConnectMessage()
        .withWillTopic('willtopic')
        .withWillMessage('Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    developer.log('MQTT_LOGS::Mosquitto client connecting....');

    client.connectionMessage = connMessage;
    try {
      await client.connect();
    } catch (e) {
      developer.log('Exception: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      developer.log('MQTT_LOGS::Mosquitto client connected');
    } else {
      developer.log(
          'MQTT_LOGS::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
      return -1;
    }

    developer.log('MQTT_LOGS::Subscribing to the test/lol topic');
    const topic = 'test/led';
    client.subscribe(topic, MqttQos.atMostOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      data.value = pt;
      notifyListeners();
      developer.log(
          'MQTT_LOGS:: New data arrived: topic is <${c[0].topic}>, payload is $pt');
      developer.log('');
    });

    return client;
  }

  void onConnected() {
    developer.log('MQTT_LOGS:: Connected');
  }

  void onDisconnected() {
    developer.log('MQTT_LOGS:: Disconnected');
  }

  void onSubscribed(String topic) {
    developer.log('MQTT_LOGS:: Subscribed topic: $topic');
  }

  void onSubscribeFail(String topic) {
    developer.log('MQTT_LOGS:: Failed to subscribe $topic');
  }

  void onUnsubscribed(String? topic) {
    developer.log('MQTT_LOGS:: Unsubscribed topic: $topic');
  }

  void pong() {
    developer.log('MQTT_LOGS:: Ping response client callback invoked');
  }

  void publishMessage(String message) {
    const pubTopic = "test/led";
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.publishMessage(pubTopic, MqttQos.atMostOnce, builder.payload!);
    }
  }
}
