/*
 * Test for using a PSX2 Dual Shock gamepad with Teensy 3.2 microntroller
 * for sending buttons state on change over a serial link with CLK and DAT
 * lines inspired by PS/2 keyboard protocol with 16 data bits instead of 8.
 * The CLK and DAT pins are configured as open drain type usin pin mode INPUT_DISABLE.
 * This lines can be driven HIGH using pull up resistor tied to VCC voltage.
 * This project is intended to be used with a FPGA (DE10-Nano FPGA board to
 * read the gamepad status using a minimal number of signals and using a simple scheme to
 * easy decoding using a modified PS/2 protocol decoder for 16 bits of data. 
 * 
 *  -----    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    ----
 *       |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  Idle
 *CLK    |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  

 * ---        ----  ----  ----  ----  ----  ----  ----  ----  ----  ----  ----  ----  ----  ----  ----  ----  ----  --------   
 *    \      /    \/    \/    \/    \/    \/    \/    \/    \/    \/    \/    \/    \/    \/    \/    \/    \/    \/    Idle 
 *DAT  \____/\____/\____/\____/\____/\____/\____/\____/\____/\____/\____/\____/\____/\____/\____/\____/\____/\____/  
       START  D0    D1    D2    D3    D4    D5    D6    D7    D8    D9    D10   D11   D12   D13   D14   D15   PAR   STOP
 *      
 * @RndMnkIII. 27/11/2019
 */
//These are our button constants
//#define PSB_SELECT      0x0001
//#define PSB_L3          0x0002
//#define PSB_R3          0x0004
//#define PSB_START       0x0008
//#define PSB_PAD_UP      0x0010
//#define PSB_PAD_RIGHT   0x0020
//#define PSB_PAD_DOWN    0x0040
//#define PSB_PAD_LEFT    0x0080
//#define PSB_L2          0x0100
//#define PSB_R2          0x0200
//#define PSB_L1          0x0400
//#define PSB_R1          0x0800
//#define PSB_GREEN       0x1000
//#define PSB_RED         0x2000
//#define PSB_BLUE        0x4000
//#define PSB_PINK        0x8000
//#define PSB_TRIANGLE    0x1000
//#define PSB_CIRCLE      0x2000
//#define PSB_CROSS       0x4000
//#define PSB_SQUARE      0x8000

#include <PS2X_lib.h>  //for v1.6

PS2X ps2x; // create PS2 Controller Class

int error = 0; 
unsigned int estado_btn=0;
const int CLK_PIN = 3; //GPIOA bit 12
const int DAT_PIN =4; //GPIOA bit 13
const int DBG_PIN = 5;
const int COUNT_PIN = 6;
const int START_BIT = 0;
const int STOP_BIT = 1;
unsigned int parity_bit;
int bitval_arr[16];
volatile unsigned int valor;

// Compute the parity of a 
// number using XOR 
// Generating the look-up table while pre-processing 
#define P2(n) n, n ^ 1, n ^ 1, n 
#define P4(n) P2(n), P2(n ^ 1), P2(n ^ 1), P2(n) 
#define P6(n) P4(n), P4(n ^ 1), P4(n ^ 1), P4(n) 
#define LOOK_UP P6(0), P6(1), P6(1), P6(0) 

// LOOK_UP is the macro expansion to generate the table 
unsigned int table[256] = { LOOK_UP }; 

// Function to find the parity 
int Parity(int num) 
{ 
  // Number is considered to be of 32 bits 
  int max = 16; 

  // Dividing the number into 8-bit 
  // chunks while performing X-OR 
  while (max >= 8) { 
    num = num ^ (num >> max); 
    max = max / 2; 
  } 

  // Masking the number with 0xff (11111111) 
  // to produce valid 8-bit result 
  return table[num & 0xff]; 
} 

void write_value()
{
  unsigned int i;
  unsigned int CLK;
  unsigned int D_OUT; 
  
  parity_bit = Parity(valor);
  for (i=0; i<16; i++)
  {
    bitval_arr[i] = (valor >> i) & 1UL;
  }
  
  noInterrupts(); //disnable interrupts
  digitalWriteFast(DBG_PIN, 1); 
  
 //START bit
  pinMode(DAT_PIN, OUTPUT); // START
  digitalWriteFast(DAT_PIN,START_BIT);
  delayMicroseconds(15);
  pinMode(CLK_PIN, OUTPUT); //CLK FALLING-EDGE
  digitalWriteFast(CLK_PIN, 0); //get data pin value
  delayMicroseconds(28); //compensate for get a |_| negative clock width of 30us
  pinMode(CLK_PIN,INPUT_DISABLE); //CLK RISING-EDGE OPEN-DRAIN
  delayMicroseconds(15);

  //Send data bits
  for(i=0; i<16; i++){
    if(bitval_arr[i]){
      pinMode(DAT_PIN,INPUT_DISABLE);
    }
    else{  
      pinMode(DAT_PIN, OUTPUT);
      digitalWriteFast(DAT_PIN,0);
    }
    delayMicroseconds(15);
    pinMode(CLK_PIN, OUTPUT);//CLK FALLING-EDGE
    digitalWriteFast(CLK_PIN, 0); //get data pin value
    delayMicroseconds(28); //compensate for get a |_| negative clock width of 30us
    pinMode(CLK_PIN,INPUT_DISABLE); //CLK RISING-EDGE OPEN-DRAIN
    delayMicroseconds(15);  
  }

  //--- PARITY BIT
  if(parity_bit){
    pinMode(DAT_PIN,INPUT_DISABLE);
  } else {
    pinMode(DAT_PIN, OUTPUT);
    digitalWriteFast(DAT_PIN,0);
  }
  delayMicroseconds(15);
  pinMode(CLK_PIN, OUTPUT); //CLK FALLING-EDGE
  digitalWriteFast(CLK_PIN, 0); //get data pin value
  delayMicroseconds(28); //compensate for get a |_| negative clock width of 30us
  pinMode(CLK_PIN,INPUT_DISABLE); //CLK RISING-EDGE OPEN-DRAIN
  delayMicroseconds(15);   
  
  //-- STOP
  pinMode(DAT_PIN,INPUT_DISABLE);
  delayMicroseconds(15);
  pinMode(CLK_PIN, OUTPUT); //CLK FALLING-EDGE
  digitalWriteFast(CLK_PIN, 0); //get data pin value
  delayMicroseconds(28); //compensate for get a |_| negative clock width of 30us
  pinMode(CLK_PIN,INPUT_DISABLE); //CLK RISING-EDGE OPEN-DRAIN
  
  digitalWriteFast(DBG_PIN, 0); 
  interrupts(); //enable interrupts
}

void setup(){
 pinMode(DBG_PIN, OUTPUT);
 digitalWriteFast(DBG_PIN, 0); 

 pinMode(COUNT_PIN, OUTPUT);
 digitalWriteFast(COUNT_PIN, 0); 
 
 //pinMode(CLK_PIN, OUTPUT);
 pinMode(CLK_PIN, INPUT_DISABLE); 
 //digitalWriteFast(CLK_PIN, 1); 
 
 //pinMode(DAT_PIN, OUTPUT);
 pinMode(DAT_PIN, INPUT_DISABLE);  
  
 error = ps2x.config_gamepad(13,11,10,12, false, false);   //setup pins and settings:  GamePad(clock, command, attention, data, Pressures?, Rumble?) check for error  
}

void loop(){
   /* You must Read Gamepad to get new values
   Read GamePad and set vibration values
   ps2x.read_gamepad(small motor on/off, larger motor strenght from 0-255)
   if you don't enable the rumble, use ps2x.read_gamepad(); with no values
   
   you should call this at least once a second
   */
   while(1){
     if(error == 1) //skip loop if no controller found
      return; 
      
    
        digitalWriteFast(COUNT_PIN, 1); 
        ps2x.read_gamepad();       
        digitalWriteFast(COUNT_PIN, 0);  
        if (ps2x.NewButtonState())               //will be TRUE if any button changes state (on to off, or off to on)
        {
          valor = ps2x.ButtonDataByte() & 0xffff; //Teensy 3.x is a 32bit microcontroller with 32bit int's. Get the lower 16 bit value.
          write_value();
        }
          
   }         
         
    //    if(ps2x.Button(PSB_L1) || ps2x.Button(PSB_R1)) // print stick values if either is TRUE
    //    {
    //        Serial.print("Stick Values:");
    //        Serial.print(ps2x.Analog(PSS_LY), DEC); //Left stick, Y axis. Other options: LX, RY, RX  
    //        Serial.print(",");
    //        Serial.print(ps2x.Analog(PSS_LX), DEC); 
    //        Serial.print(",");
    //        Serial.print(ps2x.Analog(PSS_RY), DEC); 
    //        Serial.print(",");
    //        Serial.println(ps2x.Analog(PSS_RX), DEC); 
    //    }      
}
