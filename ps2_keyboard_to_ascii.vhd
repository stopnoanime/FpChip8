--------------------------------------------------------------------------------
--
--   FileName:         ps2_keyboard_to_ascii.vhd
--   Dependencies:     ps2_keyboard.vhd, debounce.vhd
--   Design Software:  Quartus II 32-bit Version 12.1 Build 177 SJ Full Version
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 11/29/2013 Scott Larson
--     Initial Public Release
--    
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY ps2_keyboard_to_ascii IS
  GENERIC(
      clk_freq                  : INTEGER := 48_000_000; --system clock frequency in Hz
      ps2_debounce_counter_size : INTEGER := 8);         --set such that 2^size/clk_freq = 5us (size = 8 for 50MHz)
  PORT(
      clk         : IN  STD_LOGIC;                     --system clock input
      ps2_clk     : IN  STD_LOGIC;                     --clock signal from PS2 keyboard
      ps2_data    : IN  STD_LOGIC;                     --data signal from PS2 keyboard
      key_control_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      key_main_out    : OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
END ps2_keyboard_to_ascii;

ARCHITECTURE behavior OF ps2_keyboard_to_ascii IS

	signal key_control : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal key_main    : STD_LOGIC_VECTOR(15 DOWNTO 0);	
  SIGNAL pressed_ps2_code : STD_LOGIC_VECTOR(7 DOWNTO 0);

  TYPE machine IS(ready, new_code, translate, output);              --needed states
  SIGNAL state             : machine;                               --state machine
  SIGNAL ps2_code_new      : STD_LOGIC;                             --new PS2 code flag from ps2_keyboard component
  SIGNAL ps2_code          : STD_LOGIC_VECTOR(7 DOWNTO 0);          --PS2 code input form ps2_keyboard component
  SIGNAL prev_ps2_code_new : STD_LOGIC := '1';                      --value of ps2_code_new flag on previous clock
  SIGNAL break             : STD_LOGIC := '0';                      --'1' for break code, '0' for make code
  SIGNAL e0_code           : STD_LOGIC := '0';                      --'1' for multi-code commands, '0' for single code commands
  SIGNAL caps_lock         : STD_LOGIC := '0';                      --'1' if caps lock is active, '0' if caps lock is inactive
  SIGNAL control_r         : STD_LOGIC := '0';                      --'1' if right control key is held down, else '0'
  SIGNAL control_l         : STD_LOGIC := '0';                      --'1' if left control key is held down, else '0'
  SIGNAL shift_r           : STD_LOGIC := '0';                      --'1' if right shift is held down, else '0'
  SIGNAL shift_l           : STD_LOGIC := '0';                      --'1' if left shift is held down, else '0'
  SIGNAL ascii             : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"FF"; --internal value of ASCII translation

  --declare PS2 keyboard interface component
  COMPONENT ps2_keyboard IS
    GENERIC(
      clk_freq              : INTEGER;  --system clock frequency in Hz
      debounce_counter_size : INTEGER); --set such that 2^size/clk_freq = 5us (size = 8 for 50MHz)
    PORT(
      clk          : IN  STD_LOGIC;                     --system clock
      ps2_clk      : IN  STD_LOGIC;                     --clock signal from PS2 keyboard
      ps2_data     : IN  STD_LOGIC;                     --data signal from PS2 keyboard
      ps2_code_new : OUT STD_LOGIC;                     --flag that new PS/2 code is available on ps2_code bus
      ps2_code     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)); --code received from PS/2
  END COMPONENT;

BEGIN

  --instantiate PS2 keyboard interface logic
  ps2_keyboard_0:  ps2_keyboard
    GENERIC MAP(clk_freq => clk_freq, debounce_counter_size => ps2_debounce_counter_size)
    PORT MAP(clk => clk, ps2_clk => ps2_clk, ps2_data => ps2_data, ps2_code_new => ps2_code_new, ps2_code => ps2_code);

  PROCESS(clk)
  BEGIN
    IF(clk'EVENT AND clk = '1') THEN
      prev_ps2_code_new <= ps2_code_new; --keep track of previous ps2_code_new values to determine low-to-high transitions
      CASE state IS
      
        --ready state: wait for a new PS2 code to be received
        WHEN ready =>
          IF(prev_ps2_code_new = '0' AND ps2_code_new = '1') THEN --new PS2 code received
            state <= new_code;                                      --proceed to new_code state
          ELSE                                                    --no new PS2 code received yet
            state <= ready;                                         --remain in ready state
          END IF;
          
        --new_code state: determine what to do with the new PS2 code  
        WHEN new_code =>
          IF(ps2_code = x"F0") THEN    --code indicates that next command is break
            break <= '1';                --set break flag
            state <= ready;              --return to ready state to await next PS2 code
          ELSIF(ps2_code = x"E0") THEN --code indicates multi-key command
            e0_code <= '1';              --set multi-code command flag
            state <= ready;              --return to ready state to await next PS2 code
          ELSE                         --code is the last PS2 code in the make/break code
            state <= translate;          --proceed to translate state
          END IF;

        --translate state: translate PS2 code to ASCII value
        WHEN translate =>
          break <= '0';    --reset break flag
          e0_code <= '0';  --reset multi-code command flag

          if break = '1' then

            if ps2_code = pressed_ps2_code then
              key_control <= x"0";
              key_main <= x"0000";
            end if;

          else
            
            key_control <= x"0";
            key_main <= x"0000";
            pressed_ps2_code <= ps2_code;

            CASE ps2_code IS

              WHEN x"16" => key_main <= x"0002"; --1
              WHEN x"1E" => key_main <= x"0004"; --2
              WHEN x"26" => key_main <= x"0008"; --3
              WHEN x"25" => key_main <= x"1000"; --4
              WHEN x"15" => key_main <= x"0010"; --q
              WHEN x"1D" => key_main <= x"0020"; --w
              WHEN x"24" => key_main <= x"0040"; --e
              WHEN x"2D" => key_main <= x"2000"; --r
              WHEN x"1C" => key_main <= x"0080"; --a
              WHEN x"1B" => key_main <= x"0100"; --s
              WHEN x"23" => key_main <= x"0200"; --d
              WHEN x"2B" => key_main <= x"4000"; --f
              WHEN x"1A" => key_main <= x"0400"; --z                  
              WHEN x"22" => key_main <= x"0001"; --x
              WHEN x"21" => key_main <= x"0800"; --c
              WHEN x"2A" => key_main <= x"8000"; --v

              WHEN x"41" => key_control <= x"1"; --<
              WHEN x"49" => key_control <= x"2"; -->
              WHEN x"4B" => key_control <= x"4"; --l
              WHEN x"42" => key_control <= x"8"; --k

              WHEN OTHERS => null;
            END CASE;

          end if;      
    
          state <= output;      --proceed to output state
              
        --output state: verify the code is valid and output the ASCII value
        WHEN output =>        
          key_control_out <= key_control;      
          key_main_out <= key_main;			

        	state <= ready;                    --return to ready state to await next PS2 code

      END CASE;
    END IF;
  END PROCESS;

END behavior;



