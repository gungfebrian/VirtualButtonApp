
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// ---------- Konfigurasi pin ----------
// ESP32-C3 tidak memiliki GPIO 25/26. Pada board C3 yang terhubung, GPIO 8
// dipakai untuk LED bawaan dan GPIO 9 untuk tombol BOOT (keduanya active-low).
// ESP32 klasik tetap memakai wiring asli dari proyek.
#if CONFIG_IDF_TARGET_ESP32C3
static const uint8_t PIN_LED    = 8;
static const uint8_t PIN_BUTTON = 9;
static const uint8_t LED_ON     = LOW;
static const uint8_t LED_OFF    = HIGH;
#else
static const uint8_t PIN_LED    = 26;
static const uint8_t PIN_BUTTON = 25;
static const uint8_t LED_ON     = HIGH;
static const uint8_t LED_OFF    = LOW;
#endif

// ---------- Konfigurasi BLE ----------
#define DEVICE_NAME         "IOT101-8"
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// ---------- Debounce button ----------
static const unsigned long DEBOUNCE_MS = 50;

BLECharacteristic *ledChar = nullptr;
bool deviceConnected = false;
bool ledState        = false;

int  lastRawButton    = HIGH;   // pull-up: HIGH = lepas, LOW = ditekan
int  stableButton     = HIGH;
unsigned long lastDebounceAt = 0;

// Tulis state ke LED + kirim notify ke app (kalau ada yang connect)
void applyLedState(bool on, const char *source) {
  ledState = on;
  digitalWrite(PIN_LED, ledState ? LED_ON : LED_OFF);

  if (ledChar != nullptr) {
    uint8_t value = ledState ? 1 : 0;
    ledChar->setValue(&value, 1);
    if (deviceConnected) {
      ledChar->notify();
    }
  }

  Serial.printf("[LED] %s (dari: %s)\n", ledState ? "ON" : "OFF", source);
}

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *server) override {
    deviceConnected = true;
    Serial.println("[BLE] Client connected");
  }

  void onDisconnect(BLEServer *server) override {
    deviceConnected = false;
    Serial.println("[BLE] Client disconnected, advertising ulang...");
    // kasih jeda sebentar biar stack BLE beres-beres dulu
    delay(300);
    server->startAdvertising();
  }
};

class LedCharCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *characteristic) override {
    // getData()/getLength() jalan di arduino-esp32 core 2.x maupun 3.x
    // (getValue() beda return type antar versi: std::string vs String)
    uint8_t *data = characteristic->getData();
    size_t len = characteristic->getLength();
    if (data == nullptr || len == 0) return;

    uint8_t cmd = data[0];

    // Support angka mentah (0/1/2) maupun karakter ASCII '0'/'1' dari app lain
    switch (cmd) {
      case 0x00:
      case '0':
        applyLedState(false, "BLE");
        break;
      case 0x01:
      case '1':
        applyLedState(true, "BLE");
        break;
      case 0x02:
      case '2':
        applyLedState(!ledState, "BLE toggle");
        break;
      default:
        Serial.printf("[BLE] Command ga dikenal: 0x%02X\n", cmd);
        break;
    }
  }
};

void setupBLE() {
  BLEDevice::init(DEVICE_NAME);

  BLEServer *server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());

  BLEService *service = server->createService(SERVICE_UUID);

  ledChar = service->createCharacteristic(
      CHARACTERISTIC_UUID,
      BLECharacteristic::PROPERTY_READ |
      BLECharacteristic::PROPERTY_WRITE |
      BLECharacteristic::PROPERTY_WRITE_NR |
      BLECharacteristic::PROPERTY_NOTIFY);

  // Descriptor 0x2902 wajib ada supaya client bisa subscribe notify
  ledChar->addDescriptor(new BLE2902());

  uint8_t initial = ledState ? 1 : 0;
  ledChar->setValue(&initial, 1);
  ledChar->setCallbacks(new LedCharCallbacks());

  service->start();

  // Payload advertising diisi manual, bukan lewat addServiceUUID().
  //
  // Alasannya: satu paket BLE cuma muat 31 byte, dan service UUID 128-bit udah
  // makan 18. Kalau pakai jalur default, BLEAdvertising::start() nyalin seluruh
  // isi paket advertising (termasuk UUID 18 byte itu) ke scan response, lalu
  // nambahin nama + TX power di sana -- totalnya lewat 31 byte, jadi namanya
  // kepotong atau ilang. Padahal nama itu yang dibaca iOS lewat
  // CBAdvertisementDataLocalNameKey dan ditampilin di device picker.
  //
  // Jadi dipisah: UUID di paket advertising (dipakai iOS buat filter scan),
  // nama sendirian di scan response (muat sampai 29 karakter).
  BLEAdvertising *advertising = BLEDevice::getAdvertising();

  BLEAdvertisementData advData;
  advData.setFlags(ESP_BLE_ADV_FLAG_GEN_DISC | ESP_BLE_ADV_FLAG_BREDR_NOT_SPT);
  advData.setCompleteServices(BLEUUID(SERVICE_UUID));   // 3 + 18 = 21 byte
  advertising->setAdvertisementData(advData);

  BLEAdvertisementData scanResponse;
  scanResponse.setName(DEVICE_NAME);                    // 2 + panjang nama
  advertising->setScanResponseData(scanResponse);

  BLEDevice::startAdvertising();

  Serial.println("[BLE] Advertising sebagai \"" DEVICE_NAME "\"");
}

void handleButton() {
  int raw = digitalRead(PIN_BUTTON);

  if (raw != lastRawButton) {
    lastRawButton = raw;
    lastDebounceAt = millis();
    return;
  }

  if (millis() - lastDebounceAt < DEBOUNCE_MS) return;

  if (raw != stableButton) {
    stableButton = raw;
    // Toggle pas transisi ditekan (HIGH -> LOW)
    if (stableButton == LOW) {
      applyLedState(!ledState, "button fisik");
    }
  }
}

void setup() {
  Serial.begin(115200);
  delay(200);

  pinMode(PIN_LED, OUTPUT);
  digitalWrite(PIN_LED, LED_OFF);
  pinMode(PIN_BUTTON, INPUT_PULLUP);

  lastRawButton = digitalRead(PIN_BUTTON);
  stableButton  = lastRawButton;

  setupBLE();
  Serial.println("[SYS] Siap. LED bisa dikontrol button fisik atau Swift app.");
}

void loop() {
  handleButton();
  delay(5);
}
