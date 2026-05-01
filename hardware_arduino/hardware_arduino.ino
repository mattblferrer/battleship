/*
 * Bernardo, Ferrer, Malubag
 * ENGG 124.02 Final Project
 * Battleships
 */

#include "Arduino_LED_Matrix.h"

#define button_x A1
#define button_y A0
#define button_pin 2

ArduinoLEDMatrix matrix;

byte burning[8][12] = {0};
byte guess[8][12] = {0};
byte frame[8][12] = {0};

// cursor position
int x = 0;
int y = 0;

// direction tracking
int last_dx = 0;
int last_dy = 0;

bool lastButtonState = LOW;
bool pressButtonState = LOW;
unsigned long buttonPress;

// 0 = planning phase, 1 = guess phase
bool gameState = false;
String input = "";

void setup() {
  pinMode(button_pin, INPUT_PULLUP);
  Serial.begin(9600);
  matrix.begin();
}

void loop() {
  readSerial();
  readSensors();

  if (gameState) {
    refreshScreen();
  }

  delay(150);
}

void readSerial() {
  while (Serial.available()) {
    char c = Serial.read();

    if (c == '\n') {
      processCommand(input);
      input = "";  // clear AFTER processing
    } else {
      input += c;
    }
  }
}

void processCommand(String cmd) {
  cmd.trim();

  if (cmd[0] == 'G') {
    gameState = true;
  }
  else if (cmd[0] == 'R') {
    gameState = false;
    memset(guess, 0, sizeof(guess));
    memset(frame, 0, sizeof(frame));
    memset(burning, 0, sizeof(burning));
    matrix.renderBitmap(frame, 8, 12);
  }
  else if (gameState) {
    int l, m, n;
    if (sscanf(cmd.c_str(), "%d %d %d", &l, &m, &n) == 3) {
      if (m >= 0 && m < 8 && l >= 0 && l < 12) {
        if (n == 1) {
          burning[m][l] = 1;
        }
      }
    }
  }
}


void readSensors() {
  int raw_x = map(analogRead(button_x), 0, 1023, 0, 255);
  int raw_y = map(analogRead(button_y), 0, 1023, 255, 0);

  int dx = 0, dy = 0;

  bool currentButtonState = digitalRead(button_pin);
  // Serial.print(currentButtonState);

  // FALLING EDGE (press)
  if (lastButtonState == HIGH && currentButtonState == LOW) {

    if (gameState == true) {
      guess[y][x] = 1;
      Serial.print(x);
      Serial.println(y); 
    } else {
      buttonPress = millis();
      pressButtonState = HIGH; // mark as pressed
    }

  }

  // RISING EDGE (release)
  if (lastButtonState == LOW && currentButtonState == HIGH && gameState == false) {
    // check if 2 seconds have passed
    if ((millis() - buttonPress) > 1500 && pressButtonState == HIGH) {
      Serial.println("C");
    } else {
      Serial.println("R");
    }
    pressButtonState = LOW;
  }

  lastButtonState = currentButtonState;
  
  if (raw_x < 85)       dx = -1;  // left
  else if (raw_x > 170) dx =  1;  // right

  if (raw_y < 85)       dy = -1;  // down
  else if (raw_y > 170) dy =  1;  // up

  static int prev_dx = 0;
  static int prev_dy = 0;

  if (!gameState && (dx != prev_dx || dy != prev_dy)) {
    if (dx == -1) Serial.println("l");
    else if (dx == 1) Serial.println("r");
    else if (dy == -1) Serial.println("u");
    else if (dy == 1) Serial.println("d");
  }

  prev_dx = dx;
  prev_dy = dy;

  // move cursor only when joystick is pushed
  if (dx != 0 || dy != 0) {
    // clear old position
    frame[y][x] = 0;

    x = constrain(x + dx, 0, 7);  // 8 cols (0–7)
    y = constrain(y + dy, 0, 7);  // 8 rows (0–7)
  }
}

void refreshScreen() {
  // clear frame
  memcpy(frame, guess, sizeof(guess));

  // draw burning ships
  bool blinkState = (millis() % 2000) < 1500;
  for (int i = 0; i < 8; i++) {
    for (int j = 0; j < 12; j++) {
      if (burning[i][j] == 1) {
        frame[i][j] = blinkState ? 1 : 0;
      }
    }
  }

  // draw cursor
  if (millis() % 1000 < 500)
    frame[y][x] = 1;
  else
    frame[y][x] = 0;

  matrix.renderBitmap(frame, 8, 12);
}