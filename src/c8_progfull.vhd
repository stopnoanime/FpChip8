library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library std;

entity c8_progfull is
port( 
	CLK         : in std_logic;
	START       : in std_logic;
	GM_SEL      : in unsigned(5 downto 0);
	PROG_FLAG   : in std_logic;
	
	PROG_ADDR   : out std_logic_vector(11 downto 0);
	PROG_DATA   : out std_logic_vector(7 downto 0);
	PROG_N      : out std_logic;

	CS          : out std_logic;
	MOSI        : out std_logic;
	MISO        : in  std_logic;
	SCLK        : out std_logic
	);
end c8_progfull;

architecture rtl of c8_progfull is

	-- Data structures.
	type nib_t is array (natural range <>) of std_logic_vector(3 downto 0);

	-- Base font. Only high nibble is uploaded.
	signal FONT : nib_t(0 to 127) := (
		x"F", x"9", x"9", x"9", x"F", -- 0
		x"2", x"6", x"2", x"2", x"7", -- 1
		x"F", x"1", x"F", x"8", x"F", -- 2
		x"F", x"1", x"F", x"1", x"F", -- 3
		x"9", x"9", x"F", x"1", x"1", -- 4
		x"F", x"8", x"F", x"1", x"F", -- 5
		x"F", x"8", x"F", x"9", x"F", -- 6
		x"F", x"1", x"2", x"4", x"4", -- 7
		x"F", x"9", x"F", x"9", x"F", -- 8
		x"F", x"9", x"F", x"1", x"F", -- 9
		x"F", x"9", x"F", x"9", x"9", -- A
		x"E", x"9", x"E", x"9", x"E", -- B
		x"F", x"8", x"8", x"8", x"F", -- C
		x"E", x"9", x"9", x"9", x"E", -- D
		x"F", x"8", x"F", x"8", x"F", -- E
		x"F", x"8", x"F", x"8", x"8", -- F
		
		x"0", x"0", x"0", x"0", x"0", -- fill rest of space with zeros.
		x"0", x"0", x"0", x"0", x"0", 
		x"0", x"0", x"0", x"0", x"0", 
		x"0", x"0", x"0", x"0", x"0", 
		x"0", x"0", x"0", x"0", x"0", 
		x"0", x"0", x"0", x"0", x"0", 
		x"0", x"0", x"0", x"0", x"0", 
		x"0", x"0", x"0", x"0", x"0", 
		x"0", x"0", x"0", x"0", x"0", 
		x"0", x"0", x"0"
	);

	type state_type is ( s_idle, s_wait, s_font, s_program_init, s_program1, s_program2); 
	signal state : state_type := s_idle;

	signal sd_read_req : std_logic;
	signal sd_data_valid : std_logic;
	signal sd_read_occured : std_logic;
	signal sd_busy : std_logic;
	signal sd_adress : std_logic_vector(31 downto 0);
	signal sd_data : std_logic_vector(7 downto 0);

	signal PROG_DATA_del : std_logic_vector(7 downto 0);
		
	signal main_mem_addr : integer;
	signal block_number : integer;
	signal block_counter : integer;
	signal font_adress : integer;
	signal byte_counter : integer;

begin

	sd_contrl: entity work.sd_controller port map(
		cs => CS,
		mosi => MOSI,
		miso => MISO,
		sclk => SCLK,
				
		rd => sd_read_req,
		dout_avail => sd_data_valid,
		dout_taken => sd_read_occured,
		sd_busy => sd_busy,
		addr => sd_adress,
		dout => sd_data,

		clk => CLK,

		reset => '0',	
		wr => '0',
		rd_multiple => '0',
		wr_multiple => '0',
		din => "00000000",
		din_valid => '0',
		erase_count => "00000000",
		card_present => '1',
		card_write_prot => '0'
	);

	process(clk)
	begin
		if rising_edge(clk) then

			PROG_DATA <= PROG_DATA_del;
			
			case state is
				when s_idle =>
				
					PROG_N <= '1';
					PROG_ADDR <= x"000";
					PROG_DATA <= x"00";
					sd_read_req <= '0';

					if START = '1' then
						state <= s_wait;
					end if;
				
				when s_wait =>
				
					PROG_N <= '0';

					if PROG_FLAG = '1' then
						font_adress <= 0;
						STATE <= s_font;
					end if;
				
				when s_font =>
				
					PROG_ADDR <= std_logic_vector(to_unsigned(font_adress,PROG_ADDR'length));
					PROG_DATA_del <= FONT(font_adress) & x"0";
					
					if font_adress = 127 then
						block_counter <= 0;
						block_number <= to_integer(GM_SEL * 7);
						main_mem_addr <= 16#200#;
						state <= s_program_init;
					end if;

					font_adress <= font_adress + 1;
				
				when s_program_init =>
				
					if sd_busy = '0' then

						byte_counter <= 0;
						sd_adress <= std_logic_vector(to_unsigned(block_number,sd_adress'length));
						sd_read_req <= '1';		
						
						state <= s_program1;
					
					end if;

				when s_program1 =>
				
					if sd_data_valid = '1' then
						
						PROG_DATA_del <= sd_data;
						PROG_ADDR <= std_logic_vector(to_unsigned(main_mem_addr,PROG_ADDR'length));
						
						main_mem_addr <= main_mem_addr + 1;

						sd_read_occured <= '1';
						
						state <= s_program2;
						
					end if;

				when s_program2 =>
				
					if sd_data_valid = '0' then
					
						sd_read_occured <= '0';
							
						state <= s_program1;
						byte_counter <= byte_counter +1;

						if byte_counter = 511 then --End of block
							state <= s_program_init ;            
							sd_read_req <= '0';
							block_counter <= block_counter + 1;
							block_number <= block_number + 1;

							if block_counter = 6 then --End of transfer
								state <= s_idle;
							end if;
						end if;
					end if;

			end case;
		end if;
	end process;

end rtl;   