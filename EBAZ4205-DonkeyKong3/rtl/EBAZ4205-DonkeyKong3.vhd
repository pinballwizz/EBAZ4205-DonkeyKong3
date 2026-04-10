---------------------------------------------------------------------------------
--                         Donkey Kong 3 - EBAZ4205
--                            Code from gaz68
--
--                          Modified for EBAZ4205 
--                            by pinballwiz.org 
--                               28/03/2026
---------------------------------------------------------------------------------
-- Keyboard inputs :
--   5            : Add coin
--   2            : Start 2 players
--   1            : Start 1 player
--   LCtrl        : Jump
--   UP arrow     : Move Up
--   DOWN arrow   : Move Down
--   RIGHT arrow  : Move Right
--   LEFT arrow   : Move Left
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;
---------------------------------------------------------------------------------
entity dkong3_ebaz4205 is
port(
	clock_50    : in std_logic;
   	I_RESET     : in std_logic;
	O_VIDEO_R	: out std_logic_vector(2 downto 0); 
	O_VIDEO_G	: out std_logic_vector(2 downto 0);
	O_VIDEO_B	: out std_logic_vector(1 downto 0);
	O_HSYNC	    : out std_logic;
	O_VSYNC	    : out std_logic;
	O_AUDIO_L 	: out std_logic;
	O_AUDIO_R 	: out std_logic;
	greenLED 	: out std_logic;
	redLED 	    : out std_logic;
    ps2_clk     : in std_logic;
	ps2_dat     : inout std_logic;
	led         : out std_logic_vector(7 downto 0)
 );
end dkong3_ebaz4205;
------------------------------------------------------------------------------
architecture struct of dkong3_ebaz4205 is

 signal clock_24  : std_logic;
 signal clock_12  : std_logic;
 signal clock_9   : std_logic;
 signal clock_6   : std_logic;
 signal clock_4   : std_logic;
 signal div3_clk : unsigned(1 downto 0) := "00";
 --
 signal reset     : std_logic;
 --
 signal oSND        : std_logic_vector(15 downto 0);
 signal dac_in      : std_logic_vector(15 downto 0);
 signal audio_pwm   : std_logic;
 --
 signal video_r     : std_logic_vector(3 downto 0);
 signal video_g     : std_logic_vector(3 downto 0);
 signal video_b     : std_logic_vector(3 downto 0);
 --
 signal video_ri    : std_logic_vector(5 downto 0);
 signal video_gi    : std_logic_vector(5 downto 0);
 signal video_bi    : std_logic_vector(5 downto 0);
 --
 signal video_r_x2  : std_logic_vector(5 downto 0);
 signal video_g_x2  : std_logic_vector(5 downto 0);
 signal video_b_x2  : std_logic_vector(5 downto 0);
 --
 signal M_HSYNC     : std_logic;
 signal M_VSYNC	    : std_logic;
 --
 signal h_blank     : std_logic;
 signal v_blank	    : std_logic;
  --
 signal INP0        : std_logic_vector(7 downto 0);
 signal INP1        : std_logic_vector(7 downto 0);

  --
 signal kbd_intr        : std_logic;
 signal kbd_scancode    : std_logic_vector(7 downto 0);
 signal joy_BBBBFRLDU   : std_logic_vector(9 downto 0);
 --
 constant CLOCK_FREQ    : integer := 27E6;
 signal counter_clk     : std_logic_vector(25 downto 0);
 signal clock_4hz       : std_logic;
 signal AD              : std_logic_vector(15 downto 0);
------------------------------------------------------------------------- 
 component dkong3_clocks
port (
  clk_in1           : in     std_logic;
  clk_out1          : out    std_logic;
  clk_out2          : out    std_logic
 );
end component;
--------------------------------------------------------------------------
begin

 reset <= not I_RESET;
 greenLED <= '1'; -- turn off leds
 redLED   <= '1';
 ---------------------------------------------------------------------------
clocks : dkong3_clocks
   port map ( 
   clk_in1  => clock_50, 
   clk_out1 => clock_24,
   clk_out2 => clock_9
 );
--------------------------------------------------------------------------
-- Clocks Divide

process (Clock_24)
begin
 if rising_edge(Clock_24) then
	clock_12  <= not clock_12;
 end if;
end process;
--
process(clock_12)
begin
	if rising_edge(clock_12) then
		if div3_clk = 2 then
			div3_clk <= to_unsigned(0,2);
		else
			div3_clk <= div3_clk + 1;
		end if;
		clock_6 <= not clock_6;
		clock_4 <= div3_clk(0);
	end if;
end process;
--------------------------------------------------------------------------
INP0  <= '1' & not joy_BBBBFRLDU(6) & not joy_BBBBFRLDU(5) & not joy_BBBBFRLDU(4) & not joy_BBBBFRLDU(1) & not joy_BBBBFRLDU(0) & not joy_BBBBFRLDU(2) & not joy_BBBBFRLDU(3);
INP1  <= '1' & '1' & not joy_BBBBFRLDU(7) & not joy_BBBBFRLDU(4) & not joy_BBBBFRLDU(1) & not joy_BBBBFRLDU(0) & not joy_BBBBFRLDU(2) & not joy_BBBBFRLDU(3);
--------------------------------------------------------------------------
-- Main

dkong3 : entity work.dkong3_top
  port map (  
	I_RESETn		=> I_RESET,
    I_CLK_24M		=> clock_24,
    I_SUBCLK		=> clock_12,
    I_CLK_4M		=> clock_4,
    O_VGA_R			=> video_r,
    O_VGA_G			=> video_g,
    O_VGA_B 		=> video_b,
    O_VGA_HSYNCn 	=> M_HSYNC,
    O_VGA_VSYNCn 	=> M_VSYNC,
    O_HBLANK        => h_blank,
    O_VBLANK        => v_blank,
    H_OFFSET        => "000000000",
    V_OFFSET        => "000000000",
    O_PIX           => open,
    O_SOUND_DAT     => oSND,
    I_SW1           => INP0,
    I_SW2           => INP1,
    I_DIP_SW1       => "00000000",
    I_DIP_SW2       => "00000000",
    flip_screen     => '0',
	AD              => AD
   );
------------------------------------------------------------------------------
-- dblscan input

  video_ri <= video_r & video_r(3 downto 2) when h_blank = '0' and v_blank = '0' else "000000";
  video_gi <= video_g & video_g(3 downto 2) when h_blank = '0' and v_blank = '0' else "000000";
  video_bi <= video_b & video_b(3 downto 2) when h_blank = '0' and v_blank = '0' else "000000";
------------------------------------------------------------------------------
-- scan doubler

dblscan: entity work.scandoubler
	port map(
		clk_sys => clock_24,
		scanlines => "00",
		r_in   => video_ri,
		g_in   => video_gi,
		b_in   => video_bi,
		hs_in  => M_HSYNC,
		vs_in  => M_VSYNC,
		r_out  => video_r_x2,
		g_out  => video_g_x2,
		b_out  => video_b_x2,
		hs_out => O_HSYNC,
		vs_out => O_VSYNC
	);
-------------------------------------------------------------------------
-- vga output

	O_VIDEO_R 	<= video_r_x2(5 downto 3);
	O_VIDEO_G 	<= video_g_x2(5 downto 3);
	O_VIDEO_B 	<= video_b_x2(5 downto 4);
------------------------------------------------------------------------------
-- get scancode from keyboard

keyboard : entity work.io_ps2_keyboard
port map (
  clk       => clock_9,
  kbd_clk   => ps2_clk,
  kbd_dat   => ps2_dat,
  interrupt => kbd_intr,
  scancode  => kbd_scancode
);
------------------------------------------------------------------------------
-- translate scancode to joystick

joystick : entity work.kbd_joystick
port map (
  clk         => clock_9,
  kbdint      => kbd_intr,
  kbdscancode => std_logic_vector(kbd_scancode), 
  joy_BBBBFRLDU  => joy_BBBBFRLDU 
);
---------------------------------------------------------------
 -- Audio DAC

dac_in <= std_logic_vector(unsigned(oSND) + to_unsigned(16#8000#, 16)); -- snd convert

u_dac : entity work.dac
  generic map(
    msbi_g => 15
  )
port  map(
    clk_i   => clock_12,
    res_n_i => I_RESET,
    dac_i   => dac_in,
    dac_o   => audio_pwm
);

 O_AUDIO_L <= audio_pwm; 
 O_AUDIO_R <= audio_pwm;
------------------------------------------------------------------------------
-- debug

process(reset, clock_24)
begin
  if reset = '1' then
   clock_4hz <= '0';
   counter_clk <= (others => '0');
  else
    if rising_edge(clock_24) then
      if counter_clk = CLOCK_FREQ/8 then
        counter_clk <= (others => '0');
        clock_4hz <= not clock_4hz;
        led(7 downto 0) <= not AD(11 downto 4);
      else
        counter_clk <= counter_clk + 1;
      end if;
    end if;
  end if;
end process;	
------------------------------------------------------------------------
end struct;