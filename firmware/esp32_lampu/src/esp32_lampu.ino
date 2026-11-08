#include <WiFi.h>
#include <PubSubClient.h>

#include "secrets.h"

// ==================== KONFIGURASI ====================
// WIFI_SSID / WIFI_PASSWORD ada di src/secrets.h (tidak di-commit).

// IP LAN komputer yang menjalankan broker MQTT (bukan 127.0.0.1).
// Cek IP terbaru dengan `ipconfig`; nilai ini harus sama dengan IP WiFi PC.
const char* MQTT_HOST = "192.168.18.51";
const uint16_t MQTT_PORT = 1883;

// Harus sama dengan Device ID yang didaftarkan di aplikasi.
const char* DEVICE_ID = "esp32-lampu";

const int LED_PIN = 2;
const bool LED_ACTIVE_HIGH = true;

// Sensor kelembapan tidak digunakan pada scope ini.
const unsigned long STATUS_INTERVAL_MS = 10000;
// =====================================================

WiFiClient wifiClient;
PubSubClient mqtt(wifiClient);

bool ledOn = false;
unsigned long lastStatus = 0;

String topic(const char* suffix) {
  return String("kebun/") + DEVICE_ID + "/" + suffix;
}

void applyLed(bool on) {
  ledOn = on;
  digitalWrite(LED_PIN, (on == LED_ACTIVE_HIGH) ? HIGH : LOW);
}

void publishState() {
  String payload = String("{\"on\":") + (ledOn ? "true" : "false") +
                   ",\"state\":\"" + (ledOn ? "ON" : "OFF") + "\"}";
  mqtt.publish(topic("lampu/state").c_str(), payload.c_str(), true);
}

void publishStatus(bool online) {
  String payload = String("{\"online\":") + (online ? "true" : "false") + "}";
  mqtt.publish(topic("status").c_str(), payload.c_str(), true);
}

void onMessage(char* topicName, byte* payload, unsigned int length) {
  String message;

  for (unsigned int index = 0; index < length; index++) {
    message += (char)payload[index];
  }

  if (String(topicName) != topic("lampu/command")) {
    return;
  }

  if (message.indexOf("LED_ON") >= 0) {
    applyLed(true);
    publishState();
  } else if (message.indexOf("LED_OFF") >= 0) {
    applyLed(false);
    publishState();
  }
}

void connectMqtt() {
  mqtt.setServer(MQTT_HOST, MQTT_PORT);
  mqtt.setCallback(onMessage);
  mqtt.setBufferSize(512);

  String clientId = String("esp32-lampu-") + String((uint32_t)ESP.getEfuseMac(), HEX);
  String willTopic = topic("status");

  if (!mqtt.connect(clientId.c_str(), nullptr, nullptr, willTopic.c_str(), 1, true,
                    "{\"online\":false}")) {
    return;
  }

  mqtt.subscribe(topic("lampu/command").c_str(), 1);
  publishStatus(true);
  publishState();
  lastStatus = millis();
}

void setup() {
  pinMode(LED_PIN, OUTPUT);
  applyLed(false);

  Serial.begin(115200);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.print("Terhubung ke WiFi, IP: ");
  Serial.println(WiFi.localIP());

  connectMqtt();
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    WiFi.reconnect();
    delay(1000);
    return;
  }

  if (!mqtt.connected()) {
    connectMqtt();
    delay(2000);
    return;
  }

  mqtt.loop();

  unsigned long now = millis();

  if (now - lastStatus >= STATUS_INTERVAL_MS) {
    publishStatus(true);
    lastStatus = now;
  }
}
