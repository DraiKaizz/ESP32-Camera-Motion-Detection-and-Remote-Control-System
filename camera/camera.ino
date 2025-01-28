#include "http_camera.h"
#include "wifi_config.h"
#include "camera_pins.h"


#define PIR_SENSOR_PIN 12 // Chân GPIO nối cảm biến PIR
unsigned long lastMotionTime = 0; // Lưu thời gian lần cuối gửi ảnh
const unsigned long captureInterval = 5000; // Thời gian chờ giữa hai lần gửi ảnh (ms)

WiFiConfig wifiConfig;
HTTPCamera camera;

httpd_handle_t server = NULL;



void setup() {
    Serial.begin(115200);
    wifiConfig.begin();

    pinMode(FLASH_GPIO_NUM, OUTPUT);
    digitalWrite(FLASH_GPIO_NUM, LOW);

    pinMode(PIR_SENSOR_PIN, INPUT);

    // Start the HTTP server
    httpd_config_t config = HTTPD_DEFAULT_CONFIG();
    config.server_port = 80;
    if (httpd_start(&server, &config) == ESP_OK) {
        wifiConfig.startConfigServer(server);
        camera.begin(server); // Khởi động camera trên cùng một server
    } else {
        Serial.println("Error starting HTTP server");
    }
}

void loop() {
    wifiConfig.handleClient();
    // Kiểm tra tín hiệu cảm biến PIR
    static unsigned long pirHighStartTime = 0;

    if (digitalRead(PIR_SENSOR_PIN) == HIGH) {
        if (pirHighStartTime == 0) {
            pirHighStartTime = millis();
        }

        // Chỉ kích hoạt nếu tín hiệu HIGH duy trì trong 1 giây
        if (millis() - pirHighStartTime > 1000) {
            unsigned long currentTime = millis();
            if (currentTime - lastMotionTime > captureInterval) {
                lastMotionTime = currentTime;

                Serial.println("Chuyển động được phát hiện! Đang chụp ảnh...");



                // Bật đèn flash
                digitalWrite(FLASH_GPIO_NUM, HIGH);

                // Chụp ảnh
                camera.capture_image_handler(NULL);

                // Tắt đèn flash sau khi chụp
                digitalWrite(FLASH_GPIO_NUM, LOW);

            }
        }
    } else {
        pirHighStartTime = 0; // Reset thời gian nếu không phát hiện chuyển động
    }
}
