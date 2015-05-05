/*
  Ilker Çam - 211CS2010 CSE342
*/
#include <Wire.h>
#include <LSM303.h>
#include <EnableInterrupt.h>

//Compass Arrangement
LSM303 compass;
LSM303::vector<int16_t> running_min = {-3204,-2460,-1848}, running_max = {+281,+2031,+2528};

//Constant Pin Settings
const int motorLeft = 11;
const int motorRight = 3;
const int directionMotorLeft = 12;
const int directionMotorRight = 13;
const int pinLeft = 16;
const int pinRight = 17;

//class variables
String command;
int compasIsWorking = 0;
int encoderIsWorking = 0;
long previousMillis = 0;
long previousMillis2 = 0;
long interval = 1000;
long interval2 = 1100;
volatile uint16_t  leftcount=0;    // a counter to see how many times the pin has changed
volatile uint16_t  rightcount=0;    // a counter to see how many times the pin has changed

//Function Identifiers
void parseCommand(String com);
void gotoEncoder(int val);
void gotoCompass(int val);
float readCompass();
void rightCount();
void leftCount();
void checkCompass2();

void setup(){
  Serial.begin(115200);
  pinMode(motorLeft, OUTPUT);  //Set control pins to be outputs
  pinMode(motorRight, OUTPUT);
  pinMode(directionMotorLeft, OUTPUT);
  pinMode(directionMotorRight, OUTPUT);
  pinMode(pinLeft, INPUT_PULLUP);     //set the pin to input
  pinMode(pinRight, INPUT_PULLUP);     //set the pin to input
  enableInterrupt(pinLeft, leftCount,FALLING); // attach a PinChange Interrupt to our pin on the falling edge
  enableInterrupt(pinRight, rightCount,FALLING); // attach a PinChange Interrupt to our pin on the falling edge
  Wire.begin();
  compass.init();
  compass.enableDefault();
}

void loop(){
  if(Serial.available()){
    char c = Serial.read();
    if(c == 'x'){ //x is the EO char of my commands
      parseCommand(command);
      command = "";
    }else{
      if(compasIsWorking == 1 || encoderIsWorking == 1){
        command = ""; //don't accept commands when compass is arranging position or encoder is running to take position
      }else{
        command += c;
      }
    }
  }
  delay(5);
  sendInfos();
}

void checkCompass2(){
  float x = readCompass();
  if(x>50 && x<100){
    digitalWrite(directionMotorLeft,HIGH);
    digitalWrite(directionMotorRight,LOW);
    analogWrite(motorLeft,255);
    analogWrite(motorRight,255);
    delay(1000);
    analogWrite(motorLeft,0);
    analogWrite(motorRight,0);
  }
}

void parseCommand(String com){
  String part1;
  String part2;
  //divide the command into two parts
  part1 = com.substring(0, com.indexOf(" "));
  part2 = com.substring(com.indexOf(" ") + 1, com.length());
  if(part1.equalsIgnoreCase("MD1")){
    int directionMD1 = part2.toInt(); //0 or 1
    digitalWrite(directionMotorLeft, directionMD1);
  }else if(part1.equalsIgnoreCase("MDA")){
    int directionAll = part2.toInt(); //0 or 1
    digitalWrite(directionMotorRight, directionAll);
    digitalWrite(directionMotorLeft, directionAll);
  }else if(part1.equalsIgnoreCase("MD2")){
    int directionMD2 = part2.toInt(); //0 or 1
    digitalWrite(directionMotorRight, directionMD2);
  }else if(part1.equalsIgnoreCase("MS1")){
    int speedMD1 = part2.toInt(); //0 or 1
    analogWrite(motorLeft,speedMD1);
    analogWrite(motorRight,0);
  }else if(part1.equalsIgnoreCase("MS2")){
    int speedMD2 = part2.toInt(); //0 or 1
    analogWrite(motorRight,speedMD2);
    analogWrite(motorLeft,0);
  }else if(part1.equalsIgnoreCase("MSA")){
    String split1,split2;
    split1 = part2.substring(0, part2.indexOf(" "));
    split2 = part2.substring(part2.indexOf(" ") + 1, part2.length());
    analogWrite(motorLeft,split1.toInt());
    analogWrite(motorRight,split2.toInt());
  }else if(part1.equalsIgnoreCase("BALL")){
    analogWrite(motorLeft,0);
    analogWrite(motorRight,0);
  }else if(part1.equalsIgnoreCase("COM")){
    int compassAddedValue = part2.toInt();
    compasIsWorking = 1;
    gotoCompass(compassAddedValue);
  }else if(part1.equalsIgnoreCase("ENC")){
    int encoderValueAdded = part2.toInt();
    encoderIsWorking = 1;
    gotoEncoder(encoderValueAdded);
  }
}

void gotoEncoder(int val){
  int newLeft = val + leftcount;
  int newRight = val + rightcount;
  int counter = 255;
  analogWrite(motorLeft,0);
  analogWrite(motorRight,0);
  delay(1000);
  //go forward is low on my code
  digitalWrite(directionMotorRight, LOW);
  digitalWrite(directionMotorLeft, LOW);
  while(newLeft>leftcount && newRight>rightcount){
   analogWrite(motorLeft,counter);
   analogWrite(motorRight,counter);
   delay(500);
   analogWrite(motorLeft,0);
   analogWrite(motorRight,0);
   delay(500);
    Serial.print("L ");
    Serial.print(leftcount);
    Serial.print(" R ");
    Serial.print(rightcount);
  }
  encoderIsWorking = 0;
  command = "";
}

void gotoCompass(int val){
  analogWrite(motorLeft,0);
  analogWrite(motorRight,0);
  delay(1000);
  int counter = 10;
  int i = 0;
  float thisValue = readCompass();
  digitalWrite(directionMotorRight, HIGH);
  digitalWrite(directionMotorLeft, LOW);
  while(abs(val - (int)thisValue) > 15.0 || abs(val - (int)thisValue) > 345.0){
    for(i = 0; i<counter; i++){
      goABit(65,130);
    }
    delay(1500);
    thisValue = readCompass();
    Serial.print("COM");
    Serial.print((int)thisValue);
    counter -= 1;
    if(counter<5){
      counter = 10;
    }
  }
  compasIsWorking = 0;
}

void goABit(int wait, int speedat){
  analogWrite(motorLeft,speedat);
  analogWrite(motorRight,speedat);
  delay(wait);
  analogWrite(motorLeft,0);
  analogWrite(motorRight,0);
  delay(wait);
}

void sendInfos(){
  unsigned long currentMillis = millis();
  if(currentMillis - previousMillis > interval) {
    // save the last time you blinked the LED 
    checkCompass2();
    previousMillis = currentMillis;
    float comp = readCompass();
    Serial.print("COM");
    Serial.print(comp);
  }
  if(currentMillis - previousMillis2 > (interval2)){
    previousMillis2 = millis();
    Serial.print("L ");
    Serial.print(leftcount);
    Serial.print(" R ");
    Serial.print(rightcount);
  }
}

float readCompass(){
  compass.read(); 
  float h = compass.heading();
  return h;
}

void rightCount()
{
  rightcount++;
}

void leftCount()
{
  leftcount++;
}
