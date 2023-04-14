-- IO DECODER for SCOMP
-- This eliminates the need for a lot of AND decoders or Comparators 
--    that would otherwise be spread around the top-level BDF

LIBRARY IEEE;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY IO_DECODER IS

  PORT
  (
    IO_ADDR       : IN STD_LOGIC_VECTOR(10 downto 0);
    IO_CYCLE      : IN STD_LOGIC;
    SWITCH_EN     : OUT STD_LOGIC;
    LED_EN        : OUT STD_LOGIC;
    TIMER_EN      : OUT STD_LOGIC;
    HEX0_EN       : OUT STD_LOGIC;
    HEX1_EN       : OUT STD_LOGIC;
    SNAP_OUT	  : OUT STD_LOGIC;
    COUNTER_RESET : OUT STD_LOGIC;
    MULTI_MODE 	  : OUT STD_LOGIC;
    COUNTER_OUT   : OUT STD_LOGIC;
    THRESHOLD_IN  : OUT STD_LOGIC
  );

END ENTITY;

ARCHITECTURE a OF IO_DECODER IS

  SIGNAL  ADDR_INT  : INTEGER RANGE 0 TO 2047;
  
begin

  ADDR_INT <= TO_INTEGER(UNSIGNED(IO_ADDR));
        
  SWITCH_EN    <= '1' WHEN (ADDR_INT = 16#000#) and (IO_CYCLE = '1') ELSE '0';
  LED_EN       <= '1' WHEN (ADDR_INT = 16#001#) and (IO_CYCLE = '1') ELSE '0';
  TIMER_EN     <= '1' WHEN (ADDR_INT = 16#002#) and (IO_CYCLE = '1') ELSE '0';
  HEX0_EN      <= '1' WHEN (ADDR_INT = 16#004#) and (IO_CYCLE = '1') ELSE '0';
  HEX1_EN      <= '1' WHEN (ADDR_INT = 16#005#) and (IO_CYCLE = '1') ELSE '0';
  SNAP_OUT    <= '1' WHEN (ADDR_INT = 16#050#) and (IO_CYCLE = '1') ELSE '0';
  COUNTER_OUT    <= '1' WHEN (ADDR_INT = 16#051#) and (IO_CYCLE = '1') ELSE '0';
  THRESHOLD_IN    <= '1' WHEN (ADDR_INT = 16#05D#) and (IO_CYCLE = '1') ELSE '0';
  COUNTER_RESET    <= '1' WHEN (ADDR_INT = 16#05E#) and (IO_CYCLE = '1') ELSE '0';    
  MULTI_MODE    <= '1' WHEN (ADDR_INT = 16#05F#) and (IO_CYCLE = '1') ELSE '0';
  			   
END a;
