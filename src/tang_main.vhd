library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tang_main is
port( 
	CLOCK_24    : in std_logic;

	ps2_clk    : IN  STD_LOGIC;
	ps2_data   : IN  STD_LOGIC;
	
	VGA_HS		: out std_logic;
	VGA_VS		: out std_logic;
	VGA_R			: out std_logic_vector(3 downto 0);
	VGA_G			: out std_logic_vector(3 downto 0);
	VGA_B			: out std_logic_vector(3 downto 0);

	CS          : out std_logic;
	MOSI        : out std_logic;
	MISO        : in  std_logic;
	SCLK        : out std_logic
	);
end tang_main;

architecture rtl of tang_main is

	signal PROG_N, PROG_FLAG : std_logic;
	signal PROG_ADDR : std_logic_vector(11 downto 0);
	signal PROG_DATA : std_logic_vector(7 downto 0);

	signal VIDEO_X : std_logic_vector(5 downto 0);
	signal VIDEO_Y : std_logic_vector(4 downto 0);
	signal VIDEO_OUT, BEEP_OUT : std_logic;
	signal VIDEO_COLOR : std_logic_vector(1 downto 0);

	signal R, G, B : std_logic_vector(3 downto 0);

	signal X_EN : std_logic;
	signal Y_EN : std_logic;
	signal X_ZERO : std_logic;
	signal Y_ZERO : std_logic;

	signal CHANGE_GAME : std_logic;
	signal GAME_NUM : unsigned(5 downto 0) := "000000";

	signal KEY_RES : std_logic_vector(15 downto 0);
	signal KEY_CONTROL : std_logic_vector(3 downto 0);

	signal CLOCK_48 : std_logic;
	
	signal timer : integer := 0;      
	signal can_press : std_logic := '0';      
	signal first_time : std_logic := '1';      
	signal first_time_timer : integer := 0;

begin

	c8 : entity work.chip8 port map(CLOCK_48, KEY_RES, PROG_N, PROG_ADDR, PROG_DATA, VIDEO_X, VIDEO_Y, VIDEO_OUT, BEEP_OUT, PROG_FLAG);

	c8p : entity work.c8_progfull port map(CLOCK_48, CHANGE_GAME, GAME_NUM, PROG_FLAG, PROG_ADDR, PROG_DATA, PROG_N, CS, MOSI, MISO, SCLK);

	vga : entity work.std_vga port map(CLOCK_48, R, G, B, open, open, X_EN, Y_EN, X_ZERO, Y_ZERO, VGA_HS, VGA_VS, VGA_R, VGA_G, VGA_B);

	c8_to_vga : entity work.c8video_to_vga port map(CLOCK_48, X_EN, Y_EN, X_ZERO, Y_ZERO, VIDEO_COLOR, VIDEO_OUT, VIDEO_X, VIDEO_Y, R, G, B);

	ps2:  entity work.ps2_keyboard_to_ascii port map(CLOCK_48, ps2_clk, ps2_data, KEY_CONTROL, KEY_RES);

	pll_gen: entity work.pll port map(
		refclk => CLOCK_24,
		reset => '0',
		stdby => '0',
		clk0_out => CLOCK_48);
			
	process(CLOCK_48)
	begin
		if rising_edge(CLOCK_48) then   
			
			CHANGE_GAME <= '0';

			if can_press = '0' then				
				timer <= timer + 1;      
					
				if timer = 6000000 then			         
					can_press <= '1';
				end if;	

			else

				if KEY_CONTROL(3) = '1' then
					VIDEO_COLOR <= std_logic_vector(unsigned(VIDEO_COLOR) + 1);             
				end if;
				
				if KEY_CONTROL(2) = '1' then 
					CHANGE_GAME <= '1';             
				end if;
				
				if KEY_CONTROL(1) = '1' then
					GAME_NUM <= GAME_NUM + 1;
					
					if GAME_NUM = 16#3F# then
						GAME_NUM <= (others => '0');
					end if;               
						
				elsif KEY_CONTROL(0) = '1' then
					GAME_NUM <= (GAME_NUM - 1);
					
					if GAME_NUM = 0 then
						GAME_NUM <= to_unsigned(16#3F#, 6);
					end if;               
					
				end if;
				
				if KEY_CONTROL /= "0000" then
					can_press <= '0';   
					timer <= 0;
				end if;
			end if;				
						
			if first_time = '1' then --Triger game load on poer on.
				first_time_timer <= first_time_timer + 1;      
					
				if first_time_timer = 48000000 then			         
					CHANGE_GAME <= '1';
					first_time <= '0';
				end if;	
			end if;
		end if;
	end process;

end rtl;