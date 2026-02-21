#include <Arduino.h>
#include <ArduinoJson.h>

// Protótipos das funções
void sendTelemetry();

void setup() {
    Serial.begin(115200);
    // Aqui no futuro entrará a config de WiFi e AWS
}

void loop() {
    sendTelemetry();
    delay(5000); // Envia a cada 5 segundos para o teste de 1h
}

void sendTelemetry() {
    StaticJsonDocument<256> doc;

    // Simulação de valores reais
    float tensao = 215.0 + (rand() % 100) / 10.0; 
    float corrente = (rand() % 500) / 100.0; 
    float fator_potencia = 0.85 + (rand() % 15) / 100.0;
    float potencia = tensao * corrente * fator_potencia;
    float frequencia = 59.8 + (rand() % 4) / 10.0;

    // --- CORREÇÃO DE SINCRONIZAÇÃO ---
    // O campo "device_id" deve ser IDENTICO ao definido no Terraform variables.tf
    doc["device_id"] = "medidor-esp32c6-01"; 
    
    // O campo "timestamp" é a sua Sort Key no DynamoDB (main.tf)
    // No futuro, usaremos o tempo real da rede (NTP)
    doc["timestamp"] = millis(); 

    // Mapeando grandezas (usando nomes consistentes para o Dashboard)
    doc["voltage"] = tensao;
    doc["current"] = corrente;
    doc["power"] = potencia;
    doc["frequency"] = frequencia;
    doc["pf"] = fator_potencia;

    serializeJson(doc, Serial);
    Serial.println();
}