import http.requests.*;
import processing.serial.*;

// Communication variables
Serial port;
String WRITE_KEY_P1 = "K0M5M9E5SKGYF15A";
//String READ_KEY_P1 = "7HS7C4DNV6P9EPE4";
String WRITE_KEY_P2 = "79ZR9765YVIEVIS6";
int CHANNEL_P1 = 3364309;
int CHANNEL_P2 = 3368248;
String p1_gs = "", p2_gs = "", p1_bs = "", p2_bs = "", p1_g = "", p2_g = "";

// Game constants
int CANVAS_X = 700;
int CANVAS_Y = 700;
int MARGIN = 50;
int DOT_SIZE = (min(CANVAS_X, CANVAS_Y) - MARGIN*2) / 80;
int DOT_X = 8;
int DOT_Y = 8;
int GAMESTATE = 0;
int DOT_OFFSET_X, DOT_OFFSET_Y, DOT_GAP_X, DOT_GAP_Y;
int SHIP_NUMBER = 3;
int SHIP_SIZES[] = {2, 3, 4};
int FRAMERATE = 60;

// Game variables
int player = 0;
int turn = 1;
int curr_x, curr_y;
int rotate_ctr = 0, x_ctr = 0, y_ctr = 0;
int x_left, x_right, y_top, y_bottom;
int curr_ships = 0;
int[][] ship_details = new int[SHIP_NUMBER][3];
int[] opp_hits = new int[SHIP_NUMBER];
int[][] ship_grid = new int[DOT_Y][DOT_X];
int[][] opp_grid = new int[DOT_Y][DOT_X];
boolean[][] guess_grid = new boolean[DOT_Y][DOT_X];
boolean[][] opp_guess_grid = new boolean[DOT_Y][DOT_X];
int opp_x, opp_y, opp_burning;

// File and display variables
String[] SHIP_FILES = new String[SHIP_NUMBER];
String[] SUNK_FILES = new String[SHIP_NUMBER];
String LOADING_FILE = "screen_loading.png";
String BURNING_FILE = "burning.png";
String WON_FILE = "screen_won.png";
String LOST_FILE = "screen_lost.png";
PImage[] ShipImages = new PImage[SHIP_NUMBER];
PImage[] SunkImages = new PImage[SHIP_NUMBER];
PImage loadingImage, burningImage, wonImage, lostImage;
PFont font;
String msg;
boolean playerWon = false;

// Keyboard variables
char ENTER_KEY = 10;
char ROTATE_KEY = 'r';
char LEFT_KEY = 'a', RIGHT_KEY = 'd', UP_KEY = 'w', DOWN_KEY = 's';

// Joystick variables
int input_1, input_2;

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
    if (opp_hits[i] >= SHIP_SIZES[i]) {
      if (ship_details[i][2] == 0) image(SunkImages[i], 0, 0, DOT_GAP_X*SHIP_SIZES[i], DOT_GAP_Y);
      else image(SunkImages[i], 0, 0, DOT_GAP_Y*SHIP_SIZES[i], DOT_GAP_X);
    }
    else {
      if (ship_details[i][2] == 0) image(ShipImages[i], 0, 0, DOT_GAP_X*SHIP_SIZES[i], DOT_GAP_Y);
      else image(ShipImages[i], 0, 0, DOT_GAP_Y*SHIP_SIZES[i], DOT_GAP_X);
    }
    popMatrix();
  }
}

void drawGuessed() { 
  int cx, cy;
  for (int i = 0; i < DOT_Y; i++) {
    for (int j = 0; j < DOT_X; j++) { 
      cx = MARGIN + j*DOT_GAP_X + DOT_OFFSET_X;
      cy = MARGIN + i*DOT_GAP_Y + DOT_OFFSET_Y;
      fill(255, 0, 0);
      if (opp_guess_grid[i][j] == true) {
        if (opp_grid[i][j] != 0) image(burningImage, cx-(DOT_SIZE*2), cy-(DOT_SIZE*2), DOT_SIZE*4, DOT_SIZE*4);
        else ellipse(cx-(DOT_SIZE*2), cy-(DOT_SIZE*2), DOT_SIZE*4, DOT_SIZE*4);
      }
      fill(100);
    }
  }
}

void parseBoardState(String state) {
  if (state.length() < DOT_X*DOT_Y) return;
  for (int i = 0; i < DOT_Y; i++) {
    for (int j = 0; j < DOT_X; j++) {
      opp_grid[i][j] = 0;
      if (state.charAt(i*DOT_X + j) == '0') {
        continue;
      }
      opp_grid[i][j] = (state.charAt(i*DOT_X + j) - 'a' + 1);
    }
    println();
  }
}

String encodeBoardState() {
  String ans = "";
  for (int i = 0; i < DOT_Y; i++) {
    for (int j = 0; j < DOT_X; j++) {
      if (ship_grid[i][j] == 0) ans += '0';
      else ans += (char)(ship_grid[i][j] + 'a' - 1);
    }
  }
  return ans;
}

void parseGuess(String guess) {
  if (guess.length() < 3) return;
  opp_x = (int)guess.charAt(0) - 'a';
  opp_y = (int)guess.charAt(1) - 'a';
  opp_burning = (int)guess.charAt(2) - 'a';
}

boolean burnCheck(int x, int y) {
  return (opp_grid[y][x] != 0);
}

void settings() {
  size(CANVAS_X, CANVAS_Y);
  smooth();
  pixelDensity(1);
}

public void setup()
{
  // Open the port that the board is connected to and use the same speed (9600 bps)
  port = new Serial(this, Serial.list()[0], 9600);
  
  precomp();
  frameRate(FRAMERATE);
  imageMode(CORNER);
  shapeMode(CORNER);
  SHIP_FILES[0] = "2x1_ship.png";
  SHIP_FILES[1] = "3x1_ship.png";
  SHIP_FILES[2] = "4x1_ship.png";
  SUNK_FILES[0] = "2x1_sunk.png";
  SUNK_FILES[1] = "3x1_sunk.png";
  SUNK_FILES[2] = "4x1_sunk.png";
  for (int i = 0; i < SHIP_NUMBER; i++) ShipImages[i] = loadImage(SHIP_FILES[i]);
  for (int i = 0; i < SHIP_NUMBER; i++) SunkImages[i] = loadImage(SUNK_FILES[i]);
  loadingImage = loadImage(LOADING_FILE);
  burningImage = loadImage(BURNING_FILE);
  wonImage = loadImage(WON_FILE);
  lostImage = loadImage(LOST_FILE);
  
  font = createFont("Arial", MARGIN/2, true);
  textFont(font);
  textAlign(CENTER);
  println("Welcome to Battleship!");
}

void draw() 
{ 
  // loading screen
  if (GAMESTATE == 0) {
    port.write('R');
    port.write('\n');
    
    // get input from joystick
    while (port.available() > 0) {
      input_1 = port.read();
      println("Input: ", input_1);
    }
  
    image(loadingImage, 0, 0);
    loadingImage.resize(CANVAS_X, CANVAS_Y);
    if ((keyPressed) || (input_1 != 0)) {
       if ((key == UP_KEY) || (input_1 == 'u')) {
         GAMESTATE = 1;
         player = 1;
       }
       if ((key == DOWN_KEY) || (input_1 == 'd')) {
         GAMESTATE = 1;
         player = 2;
       }
       key = 0;
       input_1 = 0;
    }
  }
  
  // setup phase
  else if (GAMESTATE == 1) {
    // get input from joystick
    while (port.available() > 0) {
      input_1 = port.read();
      println("Input: ", input_1);
    }
    
    // redraw grid with ship
    drawGrid();
    drawShips();
    pushMatrix();
    
    text("Player " + player + " Setup Phase", CANVAS_X/2, MARGIN/2);
    
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
    
    if ((keyPressed) || (input_1 != 0)) {
      if ((key == ROTATE_KEY) || (input_1 == 'R')) rotate_ctr = (rotate_ctr <= 0) ? 1 : 0;
      else if ((key == LEFT_KEY) || (input_1 == 'l')) {
        x_ctr--;
        x_left -= DOT_GAP_X;
        x_right -= DOT_GAP_X;
      }
      else if ((key == RIGHT_KEY) || (input_1 == 'r')) {
        x_ctr++;
        x_left += DOT_GAP_X;
        x_right += DOT_GAP_X;
      }
      else if ((key == UP_KEY) || (input_1 == 'u')) {
        y_ctr--;
        y_top -= DOT_GAP_Y;
        y_bottom -= DOT_GAP_Y;
      }
      else if ((key == DOWN_KEY) || (input_1 == 'd')) {
        y_ctr++;
        y_top += DOT_GAP_Y;
        y_bottom += DOT_GAP_Y;
      }
      else if ((key == ENTER_KEY) || (input_1 == 'C')) {
        // check for collisions
        boolean valid = true;
        if (rotate_ctr == 0) {
          for (int i = x_ctr; i < x_ctr + SHIP_SIZES[curr_ships]; i++) {
            if (ship_grid[y_ctr][i] > 0) {
              valid = false;
              fill(240, 0, 0);
              ellipse(MARGIN + i*DOT_GAP_X + DOT_OFFSET_X, MARGIN + y_ctr*DOT_GAP_Y + DOT_OFFSET_Y, DOT_SIZE, DOT_SIZE);
              fill(100);
            }
          }
        }
        else {
          for (int i = y_ctr; i < y_ctr + SHIP_SIZES[curr_ships]; i++) {
            if (ship_grid[i][x_ctr] > 0) {
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
            for (int i = x_ctr; i < x_ctr + SHIP_SIZES[curr_ships]; i++) ship_grid[y_ctr][i] = curr_ships + 1;
          }
          else { 
            for (int i = y_ctr; i < y_ctr + SHIP_SIZES[curr_ships]; i++) ship_grid[i][x_ctr] = curr_ships + 1;
          }
          
          x_ctr = 0;
          y_ctr = 0;
          curr_ships++;
          
          if (curr_ships >= SHIP_NUMBER) {
            GAMESTATE = 2;
            port.write('G');
            port.write('\n');
            if (player == 1) {
              p1_bs = encodeBoardState();
              println("Encoded board state: ", p1_bs);
            }
            else if (player == 2) {
              p2_bs = encodeBoardState();
              println("Encoded board state: ", p2_bs);
            }
            
            if (turn == player) {
              port.write('Y');
              port.write('\n');
            }
            else {
              port.write('N');
              port.write('\n');
            }
            
            input_1 = input_2 = -1;
            
            String write_s = "";
            if (player == 1) write_s = "https://api.thingspeak.com/update?api_key="+WRITE_KEY_P1+"&field2=&field4=&field6=";
            else if (player == 2) write_s = "https://api.thingspeak.com/update?api_key="+WRITE_KEY_P2+"&field1=&field3=&field5=";
            GetRequest write_req = new GetRequest(write_s);
            write_req.send();
          }
        }
      }
      
      // bounds checking 
      if (x_left < MARGIN) x_ctr++;
      if (x_right > CANVAS_X - MARGIN) x_ctr--;
      if (y_top < MARGIN) y_ctr++;
      if (y_bottom > CANVAS_Y - MARGIN) y_ctr--;
      key = 0;
      input_1 = 0;
    }
  }
  
  // guessing phase
  else if (GAMESTATE == 2) {
    boolean is_burning = false;
    
    // get input from joystick
    while (port.available() > 1) {
      input_1 = port.read();
      input_2 = port.read();
      println("Input: ", input_1, " ", input_2);
      
      if (!guess_grid[input_2][input_1]) {
        guess_grid[input_2][input_1] = true;
        is_burning = burnCheck(input_1, input_2);
        port.write(input_1 + " " + input_2 + " " + ((is_burning) ? "1" : "0"));
        port.write("\nN\n");
        if (player == 1) p1_g = "" + (char)(input_1 + 'a') + (char)(input_2 + 'a') + ((is_burning) ? "b" : "a");
        else if (player == 2) p2_g = "" + (char)(input_1 + 'a') + (char)(input_2 + 'a') + ((is_burning) ? "b" : "a");
      }
      input_1 = input_2 = -1;
    }
    
    String write_s = "", read_s1 = "", read_s2 = "";
    read_s1 = "https://api.thingspeak.com/channels/" + CHANNEL_P1 + "/feeds.json?results=1";
    read_s2 = "https://api.thingspeak.com/channels/" + CHANNEL_P2 + "/feeds.json?results=1";

    drawGrid();
    drawShips();
    drawGuessed();
    text("Guessing Phase", CANVAS_X/2, MARGIN/2);
    int time = 16 - ((frameCount % (FRAMERATE*16)) / FRAMERATE);
    msg = "Player " + turn + ": " + time + " seconds";
    text(msg, CANVAS_X/2, MARGIN);
    
    //for free, you can only send (fastest) at 15 sec or more, setting 16 sec interval for writing  
    if (frameCount % (FRAMERATE*16) == 0) {         
      // Read channel p1
      JSONArray feeds = (loadJSONObject(read_s1)).getJSONArray("feeds");
      JSONObject latest_entry = feeds.getJSONObject(0, null);
      
      // Read channel p2
      JSONArray feeds_2 = (loadJSONObject(read_s2)).getJSONArray("feeds");
      JSONObject latest_entry_2 = feeds_2.getJSONObject(0, null);
      
      if (player == 1) {
        if (latest_entry_2 != null) {
          p2_gs = latest_entry.getString("field2", p2_gs);
          p2_bs = latest_entry.getString("field4", p2_bs);
          p2_g = latest_entry.getString("field6", p2_g);
          println("Received: " + p2_gs + " " + p2_bs + " " + p2_g);
        }
        parseBoardState(p2_bs);
        parseGuess(p2_g);
      }
      else if (player == 2) {
        if (latest_entry != null) {
          p1_gs = latest_entry.getString("field1", p1_gs);
          p1_bs = latest_entry.getString("field3", p1_bs);
          p1_g = latest_entry.getString("field5", p1_g);
          println("Received: " + p1_gs + " " + p1_bs + " " + p1_g);
        }
        parseBoardState(p1_bs);
        parseGuess(p1_g);
      }
      if ((opp_burning == 1) && (!opp_guess_grid[opp_y][opp_x])) opp_hits[opp_grid[opp_y][opp_x] - 1]++;
      if ((opp_x >= 0) && (opp_y >= 0)) opp_guess_grid[opp_y][opp_x] = true;
      
      // Write
      if (turn == player) {
        if (player == 1) write_s = "https://api.thingspeak.com/update?api_key="+WRITE_KEY_P1+"&field1="+p1_gs+"&field3="+p1_bs+"&field5="+p1_g;
        else if (player == 2) write_s = "https://api.thingspeak.com/update?api_key="+WRITE_KEY_P2+"&field2="+p2_gs+"&field4="+p2_bs+"&field6="+p2_g;
        GetRequest write_req = new GetRequest(write_s);
        write_req.send();
        println("Sending to: " + write_s);
        println("Reponse Content: " + write_req.getContent());
        println("Reponse Content-Length Header: " + write_req.getHeader("Content-Length"));
      }
      turn = (turn == 1) ? 2 : 1;
      println("Player " + turn + "'s turn");
      if (turn == player) {
        port.write('Y');
        port.write('\n');
      }
      else {
        port.write('N');
        port.write('\n');
      }
      
      for (int i = 0; i < 3; i++) println(opp_hits[i], SHIP_SIZES[i]);
    }
  }
  
  // end phase
  else if (GAMESTATE == 3) {
    if (playerWon) {
      image(wonImage, 0, 0);
      wonImage.resize(CANVAS_X, CANVAS_Y);
    } else {
      image(lostImage, 0, 0);
      lostImage.resize(CANVAS_X, CANVAS_Y);
    }
  }
}
