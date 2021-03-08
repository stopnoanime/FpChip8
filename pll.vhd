LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.std_logic_arith.ALL;
LIBRARY eagle_macro;
USE eagle_macro.EAGLE_COMPONENTS.ALL;

ENTITY pll IS
	PORT ( refclk	: IN	STD_LOGIC;
		reset	: IN	STD_LOGIC;
		stdby	: IN	STD_LOGIC;
		extlock	: OUT	STD_LOGIC;
		clk0_out	: OUT	STD_LOGIC);
END pll;

ARCHITECTURE rtl OF pll IS
	SIGNAL clk0_buf	: STD_LOGIC;
	SIGNAL fbk_wire	: STD_LOGIC;
	SIGNAL clkc_wire	: STD_LOGIC_VECTOR (4 DOWNTO 0);
BEGIN
	bufg_feedback : EG_LOGIC_BUFG
		PORT MAP ( i => clk0_buf, o => fbk_wire );

	pll_inst : EG_PHY_PLL	GENERIC MAP ( DPHASE_SOURCE => "DISABLE",
		DYNCFG => "DISABLE",
		FIN => "24.000",
		FEEDBK_MODE => "NORMAL",
		FEEDBK_PATH => "CLKC0_EXT",
		STDBY_ENABLE => "ENABLE",
		PLLRST_ENA => "ENABLE",
		SYNC_ENABLE => "DISABLE",
		DERIVE_PLL_CLOCKS => "DISABLE",
		GEN_BASIC_CLOCK => "DISABLE",
		GMC_GAIN => 2,
		ICP_CURRENT => 9,
		KVCO => 2,
		LPF_CAPACITOR => 1,
		LPF_RESISTOR => 8,
		REFCLK_DIV => 1,
		FBCLK_DIV => 2,
		CLKC0_ENABLE => "ENABLE",
		CLKC0_DIV => 21,
		CLKC0_CPHASE => 20,
		CLKC0_FPHASE => 0)
		PORT MAP ( refclk => refclk,
			reset => reset,
			stdby => stdby,
			extlock => extlock,
			psclk => '0',
			psdown => '0',
			psstep => '0',
			psclksel => "000",
			dclk => '0',
			dcs => '0',
			dwe => '0',
			di => "00000000",
			daddr => "000000",
			fbclk => fbk_wire,
			clkc => clkc_wire);

		clk0_buf <= clkc_wire(0);
		clk0_out <= fbk_wire;

END rtl;
