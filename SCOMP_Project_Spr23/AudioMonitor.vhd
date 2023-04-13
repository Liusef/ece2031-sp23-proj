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
    SNAP_OUT          : in  std_logic; --1 when snap data is requested
    IO_WRITE    : in  std_logic;
    SYS_CLK     : in  std_logic;  -- SCOMP's clock
    RESETN      : in  std_logic;
    AUD_DATA    : in  std_logic_vector(15 downto 0); --audio data from audio monitor
    AUD_NEW     : in  std_logic; --high when audio data is being written from audio monitor
    IO_DATA     : inout  std_logic_vector(15 downto 0);
	 COUNTER_RESET		 : in  std_logic; --reset the counter when high
	 MULTI_MODE			 : in  std_logic --1 when in multi snap mode
    COUNTER_OUT : in std_logic; -- 1 when counter data requested
);
end AudioMonitor;

architecture a of AudioMonitor is
    --output/input variables
    signal io_en      : std_logic; --from SNAP_OUT, COUNTER_RESET, MULTI_MODE
    signal parsed_data : std_logic_vector(15 downto 0); --data from audio monitor 16 bit signed audio data
    signal output_data : std_logic_vector(15 downto 0); --output data, 16 bits available
    signal input_data : std_logic_vector(15 downto 0); --input data, 16 bits
    --intermediate variables
    signal snap        : std_logic; --is high when snap has been detected, is the 0th bit of output data/io data when out
    signal threshold   : std_logic_vector (15 downto 0); --audio threshold variable
    signal mode	       : std_logic; --is multisnap(1) or single snap(0)
    signal counter_reset : std_logic; -- high when reset counter, low when not

    signal counter     : std_logic_vector (15 downto 0); -- number of snaps that have occurred
    signal min_time    : std_logic_vector (23 downto 0); --is the max amount of time a snap can take to go low,is a constant, num clock cycles
    signal time_high   : std_logic_vector (23 downto 0); --time that snap stays high, is a constant, the number of SCOMP clock cyles
    signal timer1      : std_logic_vector (23 downto 0); --timer for the fall state, counts the number of SCOMP clock cycles
    signal timer_snap  : std_logic_vector (23 downto 0); --timer for the snap_high output duration, counts number of SCOMP clock cycles (0.1 microseconds per cycle)
    signal one 		  : std_logic_vector (23 downto 0); -- constant equal to 1
    
    
    
    type state_type is (reset, check, fall); --state machine states
    signal state    : state_type; -- state signal

begin
    -- Latch data on rising edge of Snap_out to keep it stable during IN
    process (SNAP_OUT, COUNTER_OUT) begin
        if rising_edge(SNAP_OUT) then
            output_data <= x"0000"; --ensures output data is initialized to 0
            output_data(0) <= snap; -- makes the 0th bit the snap signal
	elsif rising_edge(COUNTER_OUT) then
	    output_data <= x"0000";
	    output_data <= counter;
	end if;
    end process;
	 
--this section handles IO_DATA to ensure there is no conflicting in/out
io_en <= SNAP_OUT OR COUNTER_RESET OR MULTI_MODE OR COUNTER_OUT;
process (io_en) begin
	if (rising_edge(io_en)) then	
		if (SNAP_OUT = '1') then --send snap data to scomp (0 or 1)
			IO_DATA <= output_data;
		elsif (COUNTER_OUT = '1') then
			IO_DATA <= output_data;
		elsif (COUNTER_RESET = '1') then --take in if the counter should be reset (1 is reset)
			input_data <= IO_DATA;
			reset_counter <= input_data(0);
		elsif (MULTI_MODE = '1') then --take in if mode should be switched (1 is multi, 0 is normal)
			input_data <= IO_DATA;
			mode <= input_data(0);
		end if;
	else 
		IO_DATA <= "ZZZZZZZZZZZZZZZZ"; --if a cs is not on a rising edge, it is falling and io_data should be high impedance
	end if;
end process;
	 
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
				counter <= x"0000";
				state <= check;
            		when check=> --checks to see if the audio has gone above the threshold
                		if(parsed_data >= threshold) then
                    			state <= fall;
                		else
                    			timer1 <= x"000000";
                    			state <= check; 
                		end if;
							
            		when fall=> --waits and then checks to see if the audio has gone back below the threshold
				--can switch between multi snap mode and single snap
				if (mode = '1') then --multi snap mode
					if(min_time < timer1) then
                    				if(parsed_data >= threshold) then
                        				state <= check;
                    				else --if the audio has gone down then a 1 is output
                        				snap <= '1';
                        				timer_snap <= x"000000"; --reset snap timer
							counter <= counter + x"0001"; --increment counter variable
                        				state <= check;
                    				end if;
                			else
                    				state <= fall;
                			end if;
				else --if not in multi snap mode, do single snap
					if(parsed_data >= threshold) then --loop while parsed data below threshold
                        			state <= fall;
                    			else --if the audio has gone down then check to see if the time it took was small enough
						if(timer1 < min_time) then --if time small enough
                        				snap <= '1'; 
                        				timer_snap <= x"000000"; --reset snap timer
							counter <= counter + x"0001"; --increment counter
                        				state <= check; --back to check state
						else
							state <= check; --back to check state
						end if;
                    			end if;
				end if;
						--very basic basic functionality - should not have to use
						--snap <= '1';
						--timer_snap <= x"000000";
						--state <= check;
		end case;
		if (timer_snap >= time_high) then --this will set the snap variable equal to 0 if the time has elapsed
			snap <= '0';
		end if;
		if (reset_counter = '1') then --resets counter
			counter <= x"0000";
			reset_counter <= '0';
		end if;
        end if;		
    end process;
    
    --updating all variables concurrently
    threshold <= x"1F40";
    min_time <= x"002E80"; --equivalent to a 0.25s time before audio signal is checked to be below threshold
    time_high <= x"005D01"; --equivalent to a 0.5s time for snap output to be high
    one <= x"000001"; -- constant 1
end a;
