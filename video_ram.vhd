------------------------------------------------------------
-- CHIP-8 Video Memory.
-- By Vitor Vilela (2018-11-03)
--
------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity video_ram is
   port( CLK            : in std_logic;
         X_IN           : in std_logic_vector(5 downto 0);
         Y_IN           : in std_logic_vector(4 downto 0);
         DATA_IN        : in std_logic;
         DATA_EN        : in std_logic;
         X_OUT          : in std_logic_vector(5 downto 0);
         Y_OUT          : in std_logic_vector(4 downto 0);
         PREV_DATA      : out std_logic;
         DATA_OUT       : out std_logic);
end video_ram;

architecture rtl of video_ram is
   signal READ_ADDR, WRITE_ADDR : std_logic_vector(10 downto 0);
   signal DATA, Q, AD : std_logic_vector(0 downto 0);   
   
	TYPE ram_type IS ARRAY(0 to 2047) of STD_LOGIC_VECTOR (0 DOWNTO 0);
	SIGNAL ram : ram_type;
begin
   WRITE_ADDR(5 downto 0) <= X_IN;
   WRITE_ADDR(10 downto 6) <= Y_IN;
   
   READ_ADDR(5 downto 0) <= X_OUT;
   READ_ADDR(10 downto 6) <= Y_OUT;
   
   DATA(0) <= DATA_IN;
   DATA_OUT <= Q(0);
   PREV_DATA <= AD(0);
	
	PROCESS (CLK)
   	BEGIN
      IF rising_edge(CLK) THEN
      
         IF (DATA_EN = '1') THEN
            ram(to_integer(unsigned(WRITE_ADDR))) <= DATA;
         else
         	AD <= ram(to_integer(unsigned(WRITE_ADDR)));
         END IF;
         
         Q <= ram(to_integer(unsigned(READ_ADDR)));
         
      END IF;
   END PROCESS;
end rtl;