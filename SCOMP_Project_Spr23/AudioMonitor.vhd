-- AudioMonitor.vhd
-- 3/30/23
-- This SCOMP peripheral monitors audio to detect snaps and loud noises

library IEEE;
library lpm;

use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
--use IEEE.numeric_std.all;
use IEEE.std_logic_signed.all;
use lpm.lpm_components.all;

entity AudioMonitor is
port(
    CS          : in  std_logic;
    IO_WRITE    : in  std_logic;
    SYS_CLK     : in  std_logic;  -- SCOMP's clock
    RESETN      : in  std_logic;
    AUD_DATA    : in  std_logic_vector(15 downto 0); --audio data from audio monitor
    AUD_NEW     : in  std_logic; --high when audio data is being written from audio monitor
    IO_DATA     : inout  std_logic_vector(15 downto 0)
);
end AudioMonitor;

architecture a of AudioMonitor is
    --output/input variables
    signal out_en      : std_logic; --from CS and IO_DATA
    signal parsed_data : std_logic_vector(15 downto 0); --data from audio monitor 16 bit signed audio data
    signal output_data : std_logic_vector(15 downto 0); --output data, 16 bits available
    --intermediate variables
    signal snap        : std_logic; --is high when snap has been detected, is the 0th bit of output data/io data when out
    signal threshold   : std_logic_vector (15 downto 0); --audio threshold variable
    
    signal min_time    : std_logic_vector (23 downto 0); --is the max amount of time a snap can take to go low,is a constant, num clock cycles
    signal time_high   : std_logic_vector (23 downto 0); --time that snap stays high, is a constant, the number of SCOMP clock cyles
    signal timer1      : std_logic_vector (23 downto 0); --timer for the fall state, counts the number of SCOMP clock cycles
    signal timer_snap  : std_logic_vector (23 downto 0); --timer for the snap_high output duration, counts number of SCOMP clock cycles (0.1 microseconds per cycle)
    signal one 		  : std_logic_vector (23 downto 0); -- constant equal to 1
    
    
    
    type state_type is (reset, check, fall); --state machine states
    signal state    : state_type; -- state signal

begin

    -- Latch data on rising edge of CS to keep it stable during IN
    process (CS) begin
        if rising_edge(CS) then
            output_data <= x"0000"; --this will be changed
            output_data(0) <= snap; -- makes the 0th bit the snap signal
	end if;
    end process;
    -- Drive IO_DATA when needed.
    out_en <= CS AND ( NOT IO_WRITE );
    with out_en select IO_DATA <=
        output_data        when '1',
        "ZZZZZZZZZZZZZZZZ" when others;
    in_en <= CS AND IO_WRITE;
    with in_en select IO_DATA

   --process statement to do audio processing
    process (RESETN, AUD_NEW) --activated whevener resetn or AUD_NEW change
    begin
        if (RESETN = '0') then --resets audio data to 0 when low
            parsed_data <= x"0000";
				state <= reset;
        elsif (rising_edge(AUD_NEW)) then
					parsed_data <= AUD_DATA; --updates audio data
					--updates counter variables
            	timer1 <= std_logic_vector(timer1+one);
            	timer_snap <= std_logic_vector(timer_snap+one);
				
		case state is --case statement for the states
            		when reset=> --reset state, initializes variables
               			timer_snap <= x"000000";
               			timer1 <= x"000000";
								snap <= '0';
								state <= check;
            		when check=> --checks to see if the audio has gone above the threshold
                		if(parsed_data >= threshold) then
                    			state <= fall;
                		else
                    			timer1 <= x"000000";
                    			state <= check; 
                		end if;
							
            		when fall=> --waits and then checks to see if the audio has gone back below the threshold
						-- ADVANCED (DOUBLE CLAPS) --
--               	 		if(min_time < timer1) then
--                    			if(parsed_data >= threshold) then
--                        			state <= check;
--                    			else --if the audio has gone down then a 1 is output
--                        			snap <= '1';
--                        			timer_snap <= x"000000";
--                        			state <= check;
--                    			end if;
--                		else
--                    			state <= fall;
--                		end if;
						snap <= '1';
						timer_snap <= x"000000";
						state <= check;
		end case;
		if (timer_snap >= time_high) then --this will set the snap variable equal to 0 if the time has elapsed
			snap <= '0';
		end if;
        end if;
        
			
    end process;
    
    --updating all variables concurrently
    threshold <= x"1F40";
    min_time <= x"002E80"; --equivalent to a 0.25s time before audio signal is checked to be below threshold
    time_high <= x"005D01"; --equivalent to a 0.5s time for snap output to be high
    one <= x"000001"; -- constant 1
end a;
