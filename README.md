**ESP32 Camera Motion Detection and Remote Control System**  

1. **Motion Detection with PIR Sensor**
When motion is detected by the sensor:  
The flash light will be turned on.  
A photo will be captured using the ESP32 camera.  
The photo and notification will be sent to Telegram.  

2. **Sending Notifications and Photos via Telegram**  
**The information sent includes**:  
**Area Name**: For example, "Hallway."  
**IP Address**: The IP address of the ESP32-CAM in the WiFi network.  
**Time**: Retrieved from the NTP server.  
The captured photo will be sent along with the notification.  

3. **Streaming Video**  
Use an HTTP server to stream live video from the camera.  
**Access URL**: http://<ESP32_IP>/stream  

4. **Controlling the Light and Servo**  
**Light Control**:   
Control the flash light (GPIO 4) or auxiliary light (GPIO 2).  
**Turn on/off using these URIs**:  
/toggle-light – Controls the flash light.  
/toggle-light2 – Controls the auxiliary light.  
**Servo Control**:  
Control the servo motor via URI /servo using HTTP POST, providing the angle (0-180 degrees).  


**Key Interfaces in the Mobile Application**  
<img src="https://github.com/user-attachments/assets/100fb567-974c-4d62-81cd-63d0df3a9759" alt="ALI GIF" width="350">
