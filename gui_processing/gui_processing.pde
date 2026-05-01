import http.requests.*;
import processing.serial.*;

// Communication variables
Serial port;
String tskey = "";

// Game constants
int CANVAS_X = 900;
int CANVAS_Y = 900;
int MARGIN = 50;
int DOT_SIZE = 10;
int DOT_X = 8;
int DOT_Y = 8;
int GAMESTATE = 0;
int DOT_OFFSET_X, DOT_OFFSET_Y, DOT_GAP_X, DOT_GAP_Y;
int SHIP_NUMBER = 3;
int SHIP_SIZES[] = {2, 3, 4};
int FRAMERATE = 60;

// Game variables
int curr_x, curr_y;
int x_read, y_read, button_press;
int rotate_ctr = 0, x_ctr = 0, y_ctr = 0;
int x_left, x_right, y_top, y_bottom;
int curr_ships = 0;
int[][] ship_details = new int[SHIP_NUMBER][3];
int[][] ship_grid = new int[DOT_X][DOT_Y];
int[][] opp_grid = new int[DOT_X][DOT_Y];
boolean[][] guess_grid = new boolean[DOT_X][DOT_Y];
int ship_x, ship_y, ship_rotate;

// File and display variables
String[] SHIP_FILES = new String[SHIP_NUMBER];
String LOADING_FILE = "loading_screen.png";
PImage[] ShipImages = new PImage[SHIP_NUMBER];
PImage loadingImage;
PFont font;
String msg;

// Keyboard variables
char ENTER_KEY = 10;
char ROTATE_KEY = 'r';
char LEFT_KEY = 'a', RIGHT_KEY = 'd', UP_KEY = 'w', DOWN_KEY = 's';

// Joystick variables
int JOYSTICK_SENS = 20;

void precomp() {
  DOT_OFFSET_X = (CANVAS_X - MARGIN*2) / (DOT_X*2);
  DOT_OFFSET_Y = (CANVAS_Y - MARGIN*2) / (DOT_Y*2);
  DOT_GAP_X = DOT_OFFSET_X*2;
  DOT_GAP_Y = DOT_OFFSET_Y*2;
}

void drawGrid() {
  background(255);
  for (int i = 0; i < DOT_X; i++) { 
    for (int j = 0; j < DOT_Y; j++) {
      fill(100);
      curr_x = MARGIN + DOT_GAP_X*i + DOT_OFFSET_X;
      curr_y = MARGIN + DOT_GAP_Y*j + DOT_OFFSET_Y;
      ellipse(curr_x, curr_y, DOT_SIZE, DOT_SIZE);
    }
  }
}

void drawShips() {
  int cx, cy;

  for (int i = 0; i < curr_ships; i++) {
    pushMatrix();
    if (ship_details[i][2] == 0) {
      cx = MARGIN + ship_details[i][0]*DOT_GAP_X;
      cy = MARGIN + ship_details[i][1]*DOT_GAP_Y;
    }
    else {
      cx = MARGIN + DOT_GAP_X + ship_details[i][0]*DOT_GAP_X;
      cy = MARGIN + ship_details[i][1]*DOT_GAP_Y;
    }
    translate(cx, cy);
    rotate(HALF_PI*ship_details[i][2]); 
    if (ship_details[i][2] == 0) image(ShipImages[i], 0, 0, DOT_GAP_X*SHIP_SIZES[i], DOT_GAP_Y);
    else image(ShipImages[i], 0, 0, DOT_GAP_Y*SHIP_SIZES[i], DOT_GAP_X);
    popMatrix();
  }
}

void parseBoardState(String state) {
  for (int i = 0; i < DOT_X; i++) {
    for (int j = 0; j < DOT_Y; j++) {
      if (state.charAt(i*DOT_X + j) == '0') continue;
      opp_grid[i][j] = (state.charAt(i*DOT_X + j) - 'a' + 1);
    }
  }
}

void settings() {
  size(CANVAS_X, CANVAS_Y);
  smooth();
  pixelDensity(1);
}

public void setup()
{
  // Open the port that the board is connected to and use the same speed (9600 bps)
  // port = new Serial(this, Serial.list()[0], 9600);
  
  precomp();
  frameRate(FRAMERATE);
  imageMode(CORNER);
  shapeMode(CORNER);
  SHIP_FILES[0] = "2x1_ship.png";
  SHIP_FILES[1] = "3x1_ship.png";
  SHIP_FILES[2] = "4x1_ship.png";
  for (int i = 0; i < SHIP_NUMBER; i++) ShipImages[i] = loadImage(SHIP_FILES[i]);
  loadingImage = loadImage(LOADING_FILE);
  
  font = createFont("Arial", MARGIN/2, true);
  textFont(font);
  textAlign(CENTER);
  println("Welcome to Battleship!");
}

void draw() 
{ 
  // get input from joystick
  /**
  while (port.available() > 2) {
    x_read = port.read();
    y_read = port.read();
    button_press = port.read();
  }*/
  
  // loading screen
  if (GAMESTATE == 0) {
    image(loadingImage, 0, 0);
    loadingImage.resize(CANVAS_X, CANVAS_Y);
    if (button_press == 1) GAMESTATE = 1;
    if (keyPressed) {
       if (key == ENTER_KEY) GAMESTATE = 1;
       key = 0;
    }
  }
  
  // setup phase
  else if (GAMESTATE == 1) {
    // redraw grid with ship
    drawGrid();
    drawShips();
    pushMatrix();
    
    text("Setup Phase", CANVAS_X/2, MARGIN/2);
    
    if (rotate_ctr == 0) {
      curr_x = MARGIN + x_ctr*DOT_GAP_X;
      curr_y = MARGIN + y_ctr*DOT_GAP_Y;
      x_left = curr_x;
      x_right = curr_x + DOT_GAP_X*SHIP_SIZES[curr_ships];
      y_top = curr_y;
      y_bottom = curr_y + DOT_GAP_Y;
    }
    else {
      curr_x = MARGIN + DOT_GAP_X + x_ctr*DOT_GAP_X;
      curr_y = MARGIN + y_ctr*DOT_GAP_Y;
      x_left = curr_x - DOT_GAP_X;
      x_right = curr_x;
      y_top = curr_y;
      y_bottom = curr_y + DOT_GAP_Y*SHIP_SIZES[curr_ships];
    }
    translate(curr_x, curr_y);
    rotate(HALF_PI*rotate_ctr); 
    if (rotate_ctr == 0) image(ShipImages[curr_ships], 0, 0, DOT_GAP_X*SHIP_SIZES[curr_ships], DOT_GAP_Y);
    else image(ShipImages[curr_ships], 0, 0, DOT_GAP_Y*SHIP_SIZES[curr_ships], DOT_GAP_X);
    popMatrix();
    
    
    
    if ((keyPressed)) {
      if (key == ROTATE_KEY) rotate_ctr = (rotate_ctr <= 0) ? 1 : 0;
      else if ((key == LEFT_KEY) || (x_read < -JOYSTICK_SENS)) {
        x_ctr--;
        x_left -= DOT_GAP_X;
        x_right -= DOT_GAP_X;
      }
      else if ((key == RIGHT_KEY) || (x_read > JOYSTICK_SENS)) {
        x_ctr++;
        x_left += DOT_GAP_X;
        x_right += DOT_GAP_X;
      }
      else if ((key == UP_KEY) || (y_read < -JOYSTICK_SENS)) {
        y_ctr--;
        y_top -= DOT_GAP_Y;
        y_bottom -= DOT_GAP_Y;
      }
      else if ((key == DOWN_KEY) || (y_read > JOYSTICK_SENS)) {
        y_ctr++;
        y_top += DOT_GAP_Y;
        y_bottom += DOT_GAP_Y;
      }
      else if ((key == ENTER_KEY)) {
        // check for collisions
        boolean valid = true;
        if (rotate_ctr == 0) {
          for (int i = x_ctr; i < x_ctr + SHIP_SIZES[curr_ships]; i++) {
            if (ship_grid[i][y_ctr] > 0) {
              valid = false;
              fill(240, 0, 0);
              ellipse(MARGIN + i*DOT_GAP_X + DOT_OFFSET_X, MARGIN + y_ctr*DOT_GAP_Y + DOT_OFFSET_Y, DOT_SIZE, DOT_SIZE);
              fill(100);
            }
          }
        }
        else {
          for (int i = y_ctr; i < y_ctr + SHIP_SIZES[curr_ships]; i++) {
            if (ship_grid[x_ctr][i] > 0) {
              valid = false;
              fill(240, 0, 0);
              ellipse(MARGIN + x_ctr*DOT_GAP_X + DOT_OFFSET_X, MARGIN + i*DOT_GAP_Y + DOT_OFFSET_Y, DOT_SIZE, DOT_SIZE);
              fill(100);
            }
          }
        }
        if (valid) {
          ship_details[curr_ships][0] = x_ctr;
          ship_details[curr_ships][1] = y_ctr;
          ship_details[curr_ships][2] = rotate_ctr;
          if (rotate_ctr == 0) {
            for (int i = x_ctr; i < x_ctr + SHIP_SIZES[curr_ships]; i++) ship_grid[i][y_ctr] = curr_ships + 1;
          }
          else { 
            for (int i = y_ctr; i < y_ctr + SHIP_SIZES[curr_ships]; i++) ship_grid[x_ctr][i] = curr_ships + 1;
          }
          
          x_ctr = 0;
          y_ctr = 0;
          curr_ships++;
          
          if (curr_ships >= SHIP_NUMBER) GAMESTATE = 2;
        }
      }
      
      // bounds checking 
      if (x_left < MARGIN) x_ctr++;
      if (x_right > CANVAS_X - MARGIN) x_ctr--;
      if (y_top < MARGIN) y_ctr++;
      if (y_bottom > CANVAS_Y - MARGIN) y_ctr--;
      key = 0;
    }
  }
  
  // guessing phase
  else if (GAMESTATE == 2) {
    drawGrid();
    drawShips();
    text("Guessing Phase", CANVAS_X/2, MARGIN/2);
    int time = 16 - ((frameCount % (FRAMERATE*16)) / FRAMERATE);
    msg = "Requesting guess from server in " + time + " seconds";
    text(msg, CANVAS_X/2, MARGIN);
    
    //for free, you can only send (fastest) at 15 sec or more, setting 16 sec interval for writing  
    if (frameCount % (FRAMERATE*16) == 0) {
      String s = "http://api.thingspeak.com/update?api_key="+tskey;
      GetRequest get = new GetRequest(s);
      get.send();
      println("Reponse Content: " + get.getContent());
      println("Reponse Content-Length Header: " + get.getHeader("Content-Length"));
    }
    
    
  }
}
