#include <Arduino.h>
#include <WiFi.h>
#include "http_camera.h"
#include "camera_pins.h"
#include <ESP32Servo.h>
#include <WiFiClientSecure.h>
#include <UniversalTelegramBot.h>
#include <HTTPClient.h>
#include <time.h>

#define SERVO_PIN 13 // Chân nối servo
#define LIGHT_GPIO_NUM_2 2 // Chân nối đèn thứ 2


Servo myServo;

const String botToken = "7838451197:AAFaugMzynM_nIEeAcA6EaNbURCkjo1uWi8";
const String chatId = "7775135796";

// Constructor for HTTPCamera class
HTTPCamera::HTTPCamera() {}

// Method to begin camera and server setup
void HTTPCamera::begin(httpd_handle_t server) {
    Serial.begin(115200);
    Serial.setDebugOutput(true);
    Serial.println();

    myServo.attach(SERVO_PIN);
    myServo.write(90);
    
    // Cấu hình camera
    camera_config_t config;
    config.ledc_channel = LEDC_CHANNEL_0;
    config.ledc_timer = LEDC_TIMER_0;
    config.pin_d0 = Y2_GPIO_NUM;
    config.pin_d1 = Y3_GPIO_NUM;
    config.pin_d2 = Y4_GPIO_NUM;
    config.pin_d3 = Y5_GPIO_NUM;
    config.pin_d4 = Y6_GPIO_NUM;
    config.pin_d5 = Y7_GPIO_NUM;
    config.pin_d6 = Y8_GPIO_NUM;
    config.pin_d7 = Y9_GPIO_NUM;
    config.pin_xclk = XCLK_GPIO_NUM;
    config.pin_pclk = PCLK_GPIO_NUM;
    config.pin_vsync = VSYNC_GPIO_NUM;
    config.pin_href = HREF_GPIO_NUM;
    config.pin_sccb_sda = SIOD_GPIO_NUM;
    config.pin_sccb_scl = SIOC_GPIO_NUM;
    config.pin_pwdn = PWDN_GPIO_NUM;
    config.pin_reset = RESET_GPIO_NUM;
    config.xclk_freq_hz = 20000000;

    config.pixel_format = PIXFORMAT_JPEG;
    config.frame_size = FRAMESIZE_XGA;
    config.jpeg_quality = 12;
    config.fb_count = 1;

    // Khởi động camera
    esp_err_t err = esp_camera_init(&config);
    if (err != ESP_OK) {
        Serial.printf("Camera init failed with error 0x%x", err);
        return;
    }

    // Initialize flash GPIO pins
    pinMode(FLASH_GPIO_NUM, OUTPUT);
    pinMode(LIGHT_GPIO_NUM_2, OUTPUT);

    digitalWrite(FLASH_GPIO_NUM, LOW);
    digitalWrite(LIGHT_GPIO_NUM_2, LOW);

    // Bắt đầu server camera
    startCameraServer(server);

    Serial.print("Camera Stream Ready! Go to: http://");
    Serial.print(WiFi.localIP());
    Serial.println("/stream");

    
}

// Method to start the camera server and define routes
void HTTPCamera::startCameraServer(httpd_handle_t server) {
    httpd_uri_t stream_uri = {
        .uri = "/stream",
        .method = HTTP_GET,
        .handler = stream_handler,
        .user_ctx = NULL
    };

    if (httpd_register_uri_handler(server, &stream_uri) != ESP_OK) {
        Serial.println("Failed to register stream URI");
    }

    // Register the toggle-light URI
    httpd_uri_t toggle_light_uri = {
        .uri = "/toggle-light",
        .method = HTTP_GET,
        .handler = toggle_light_handler,
        .user_ctx = NULL
    };

    if (httpd_register_uri_handler(server, &toggle_light_uri) != ESP_OK) {
        Serial.println("Failed to register toggle-light URI");
    }

        // Register the toggle-light2 URI
    httpd_uri_t toggle_light2_uri = {
        .uri = "/toggle-light2",
        // .method = HTTP_GET,
        .handler = toggle_light2_handler,
        .user_ctx = NULL
    };

    if (httpd_register_uri_handler(server, &toggle_light2_uri) != ESP_OK) {
        Serial.println("Failed to register toggle-light2 URI");
    }




        // Register the servo control URI
    httpd_uri_t servo_uri = {
        .uri = "/servo",
        .method = HTTP_POST,
        .handler = servo_handler,
        .user_ctx = NULL
    };

    if (httpd_register_uri_handler(server, &servo_uri) != ESP_OK) {
        Serial.println("Failed to register servo URI");
    }

    httpd_uri_t capture_image_uri = {
        .uri = "/capture-image",
        .method = HTTP_GET,
        .handler = capture_image_handler,
        .user_ctx = NULL
    };

    if (httpd_register_uri_handler(server, &capture_image_uri) != ESP_OK) {
        Serial.println("Đăng ký URI chụp ảnh thất bại");
    }

}


// Hàm gửi ảnh vào Telegram
void sendPhotoToTelegram(uint8_t *imageData, size_t imageSize) {
    HTTPClient http;

    // URL để gửi ảnh qua Telegram API
    String url = "https://api.telegram.org/bot" + botToken + "/sendPhoto";

    // Bắt đầu kết nối HTTP
    http.begin(url);

    // Thiết lập loại dữ liệu (multipart form-data) để gửi ảnh
    String boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW";
    http.addHeader("Content-Type", "multipart/form-data; boundary=" + boundary);

    // Tạo request body với các thông tin cần thiết
    String body = "--" + boundary + "\r\n";
    body += "Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n" + chatId + "\r\n";
    body += "--" + boundary + "\r\n";
    body += "Content-Disposition: form-data; name=\"photo\"; filename=\"image.jpg\"\r\n";
    body += "Content-Type: image/jpeg\r\n\r\n";

    // Tính toán độ dài của toàn bộ yêu cầu
    String postData = body + String((char*)imageData, imageSize) + "\r\n--" + boundary + "--\r\n";

    // Thiết lập chiều dài của dữ liệu trong yêu cầu
    http.addHeader("Content-Length", String(postData.length()));

    // Gửi yêu cầu HTTP POST
    int httpResponseCode = http.POST(postData);
    Serial.println("Image size: " + String(imageSize));
    if (httpResponseCode > 0) {
        Serial.println("Ảnh đã gửi thành công!");
    } else {
        Serial.print("Lỗi khi gửi ảnh: ");
        Serial.println(httpResponseCode);
    }

    http.end();
}

void sendMessageToTelegram(const String &zoneName) {
    HTTPClient http;

    // Lấy địa chỉ IP hiện tại của ESP32
    String ipAddress = WiFi.localIP().toString();  // Lấy địa chỉ IP hiện tại

    // Thiết lập NTP để lấy thời gian hiện tại
    configTime(7 * 3600, 0, "pool.ntp.org", "time.nist.gov"); // Múi giờ UTC+7 (Việt Nam)
    struct tm timeinfo;
    if (!getLocalTime(&timeinfo)) {
        Serial.println("Không thể lấy thời gian từ NTP server");
        return;
    }

    // Lấy ngày giờ hiện tại
    char timeString[50];
    strftime(timeString, sizeof(timeString), "%d/%m/%Y %H:%M:%S", &timeinfo);

    // Tạo thông điệp để gửi đến Telegram
    String message = "Tên khu vực: " + zoneName + "\n";
    message += "Địa chỉ IP camera: " + ipAddress + "\n";
    message += "Phát hiện chuyển động\n";
    message += "Thời gian: " + String(timeString);

    // URL để gửi tin nhắn qua Telegram API
    String url = "https://api.telegram.org/bot" + botToken + "/sendMessage";

    // Bắt đầu kết nối HTTP
    http.begin(url);

    // Thiết lập loại dữ liệu (application/x-www-form-urlencoded)
    http.addHeader("Content-Type", "application/x-www-form-urlencoded");

    // Nội dung yêu cầu gửi tin nhắn
    String postData = "chat_id=" + chatId + "&text=" + message;

    // Gửi yêu cầu HTTP POST
    int httpResponseCode = http.POST(postData);
    if (httpResponseCode > 0) {
        Serial.println("Tin nhắn đã gửi thành công!");
    } else {
        Serial.print("Lỗi khi gửi tin nhắn: ");
        Serial.println(httpResponseCode);
    }

    http.end();
}



esp_err_t HTTPCamera::capture_image_handler(httpd_req_t *req) {
    camera_fb_t *fb = NULL;
    esp_err_t res = ESP_OK;
    size_t _jpg_buf_len = 0;
    uint8_t *_jpg_buf = NULL;
    char part_buf[64];

    // Chụp ảnh từ camera
    fb = esp_camera_fb_get();
    if (!fb) {
        Serial.println("Chụp ảnh từ camera thất bại");
        res = ESP_FAIL;
        return res;
    }

    // Chuyển đổi ảnh sang định dạng JPEG nếu cần
    if (fb->format != PIXFORMAT_JPEG) {
        bool jpeg_converted = frame2jpg(fb, 80, &_jpg_buf, &_jpg_buf_len);
        esp_camera_fb_return(fb);
        fb = NULL;
        if (!jpeg_converted) {
            Serial.println("Chuyển đổi JPEG thất bại");
            res = ESP_FAIL;
        }
    } else {
        _jpg_buf_len = fb->len;
        _jpg_buf = fb->buf;
    }

    // Gửi tin nhắn thông báo
    sendMessageToTelegram("Hành lang");

    // Gửi ảnh đến Telegram
    sendPhotoToTelegram(_jpg_buf, _jpg_buf_len);



    // Đặt kiểu dữ liệu cho phản hồi
    if (res == ESP_OK) {
        res = httpd_resp_set_type(req, "image/jpeg");
    }

    // Trả lại ảnh đã chụp dưới dạng phản hồi
    if (res == ESP_OK) {
        res = httpd_resp_send(req, (const char *)_jpg_buf, _jpg_buf_len);
    }

    // Giải phóng bộ nhớ
    if (fb) {
        esp_camera_fb_return(fb);
    } else if (_jpg_buf) {
        free(_jpg_buf);
    }

    return res;
}



esp_err_t HTTPCamera::stream_handler(httpd_req_t *req) {
    camera_fb_t *fb = NULL;
    esp_err_t res = ESP_OK;
    size_t _jpg_buf_len = 0;
    uint8_t *_jpg_buf = NULL;
    char part_buf[64];
    int64_t last_frame = 0;

    // Đặt header kiểu dữ liệu cho luồng video
    res = httpd_resp_set_type(req, "multipart/x-mixed-replace;boundary=frame");
    if (res != ESP_OK) {
        return res;
    }

    while (true) {
        // Ghi thời gian bắt đầu khung hình
        if (last_frame == 0) {
            last_frame = esp_timer_get_time();
        }

        // Lấy khung hình từ camera
        fb = esp_camera_fb_get();
        if (!fb) {
            Serial.println("Camera capture failed");
            res = ESP_FAIL;
            break;
        }

        // Kiểm tra định dạng khung hình và chuyển đổi nếu cần
        if (fb->format != PIXFORMAT_JPEG) {
            bool jpeg_converted = frame2jpg(fb, 80, &_jpg_buf, &_jpg_buf_len);
            esp_camera_fb_return(fb);
            fb = NULL;
            if (!jpeg_converted) {
                Serial.println("JPEG compression failed");
                res = ESP_FAIL;
                break;
            }
        } else {
            _jpg_buf_len = fb->len;
            _jpg_buf = fb->buf;
        }

        // Gửi header cho khung hình
        if (res == ESP_OK) {
            size_t hlen = snprintf((char *)part_buf, 64,
                                   "Content-Type: image/jpeg\r\nContent-Length: %u\r\n\r\n",
                                   _jpg_buf_len);
            res = httpd_resp_send_chunk(req, (const char *)part_buf, hlen);
        }

        // Gửi dữ liệu ảnh JPEG
        if (res == ESP_OK) {
            res = httpd_resp_send_chunk(req, (const char *)_jpg_buf, _jpg_buf_len);
        }

        // Gửi phần kết thúc của khung hình
        if (res == ESP_OK) {
            res = httpd_resp_send_chunk(req, "\r\n--frame\r\n", 12);
        }

                // Lật khung hình nếu cần
        sensor_t *s = esp_camera_sensor_get();
        if (s != NULL) {
            s->set_vflip(s, 1); // Lật dọc khung hình
        }

        // Giải phóng bộ nhớ khung hình
        if (fb) {
            esp_camera_fb_return(fb);
            fb = NULL;
            _jpg_buf = NULL;
        } else if (_jpg_buf) {
            free(_jpg_buf);
            _jpg_buf = NULL;
        }

        // Kiểm tra lỗi
        if (res != ESP_OK) {
            break;
        }

        // Giới hạn tốc độ khung hình
        int64_t frame_time = esp_timer_get_time() - last_frame;
        last_frame = esp_timer_get_time();
        frame_time /= 1000; // Chuyển sang mili giây
        Serial.printf("MJPG: %uKB %ums (%.1ffps)\n", 
                      (uint32_t)(_jpg_buf_len / 1024), 
                      (uint32_t)frame_time, 
                      1000.0 / (uint32_t)frame_time);
        delay(50); // Tăng giá trị nếu muốn giảm FPS
    }

    return res;
}





// Handler function for servo control
esp_err_t HTTPCamera::servo_handler(httpd_req_t *req) {
    char content[10];
    int len = httpd_req_recv(req, content, sizeof(content));
    if (len <= 0) {
        httpd_resp_send_408(req);
        return ESP_FAIL;
    }

    content[len] = '\0';
    int angle = atoi(content);

    if (angle < 0 || angle > 180) {
        httpd_resp_sendstr(req, "Invalid angle! Must be between 0 and 180.");
        return ESP_FAIL;
    }

    myServo.write(angle);
    String response = "Servo angle set to " + String(angle);
    httpd_resp_sendstr(req, response.c_str());

    return ESP_OK;
}

// Hàm handler cho việc bật/tắt đèn 1
esp_err_t HTTPCamera::toggle_light_handler(httpd_req_t *req) {
    static bool is_light_on = false; // Trạng thái của đèn 1

    // Bật/tắt đèn 1
    is_light_on = !is_light_on;
    digitalWrite(FLASH_GPIO_NUM, is_light_on ? HIGH : LOW); // Chuyển trạng thái của đèn 1

    // Phản hồi
    String response = is_light_on ? "Light is ON" : "Light is OFF";
    httpd_resp_sendstr(req, response.c_str());

    return ESP_OK;
}

// Hàm handler cho việc bật/tắt đèn 2
esp_err_t HTTPCamera::toggle_light2_handler(httpd_req_t *req) {
    static bool is_light_on_2 = false; // Trạng thái của đèn 2

    // Bật/tắt đèn 2
    is_light_on_2 = !is_light_on_2;
    digitalWrite(LIGHT_GPIO_NUM_2, is_light_on_2 ? HIGH : LOW); // Chuyển trạng thái của đèn 2

    // Phản hồi
    String response = is_light_on_2 ? "Light 2 is ON" : "Light 2 is OFF";
    httpd_resp_sendstr(req, response.c_str());

    return ESP_OK;
}

