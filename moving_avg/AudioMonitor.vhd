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

    -- This works on very specific cases (clapping very loudly from approx. 1 foot away)
    -- We should probably tune this more later
    constant threshold  : std_logic_vector (15 downto 0) := x"0800";
    constant N : integer := 16; -- number of samples in the filter
    constant S : integer := 4; 

    --signals related to moving average
    type mvarr is array (0 to N-1) of std_logic_vector(15 downto 0); --declare moving array type - N std logic that are 16 bit
    signal samples      : mvarr;  --array of the past N samples
    signal sum          : std_logic_vector (31 downto 0); --sum variable for all the samples
    signal mvavg_inter	: std_logic_vector (31 downto 0); --interim variable
    signal mvavg        : std_logic_vector (15 downto 0); --moving average

    --output/input variables
    signal out_en       : std_logic; --from CS and IO_DATA
    signal parsed_data  : std_logic_vector(15 downto 0); --data from audio monitor 16 bit signed audio data
    signal output_data  : std_logic_vector(15 downto 0); --output data, 16 bits available
    --intermediate variables
    signal snap         : std_logic; --is high when snap has been detected, is the 0th bit of output data/io data when out
    
    signal min_time     : std_logic_vector (23 downto 0); --is the max amount of time a snap can take to go low,is a constant, num clock cycles
    signal time_high    : std_logic_vector (23 downto 0); --time that snap stays high, is a constant, the number of SCOMP clock cyles
    signal timer        : std_logic_vector (23 downto 0); --timer for the fall state, counts the number of AUD_NEW cycles    

    signal checking     : std_logic; -- This is so we only increment the timer when we have to
    
    type state_type is (reset, waiting, check, fall, latched); --state machine states
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

   --process statement to do audio processing
    process (RESETN, AUD_NEW) --activated whevener resetn or AUD_NEW change
    begin
        if (RESETN = '0') then --resets audio data to 0 when low
            parsed_data <= x"0000";
            state <= reset;
            checking <= '0';
            samples <= (others => (others => '0')); -- initializes sample set to 0s 
            sum <= (others => '0'); -- initializes sum to 0s
        elsif (rising_edge(AUD_NEW)) then --every time there is new audio data
            parsed_data <= AUD_DATA; --updates audio data
		
	    --do the absolute value of the data - invert 2s complement
            if (parsed_data(15) = '1') then
                parsed_data <= not parsed_data;
                parsed_data <= std_logic_vector(parsed_data + x"0001");
            end if;
	    --update the moving average
            sum <= sum + parsed_data - samples(N-1); -- from the running sum, add the new data and subtract the last sample
            samples <= parsed_data & samples(0 to N-2); --concatenate the parsed data to the end of samples, exclude the oldest sample
            mvavg_inter <= sum; -- sum goes to interim
            mvavg <= sum (15 + S downto S); -- what does this do
               
            -- Update the counter when we're checking for duration
            if (checking = '1') then
                timer <= std_logic_vector(timer + x"000001");
            end if;
				
		    case state is --case statement for the states
                when reset=> --reset state, initializes variables
                    timer <= x"000000";
                    snap <= '0';
                    state <= waiting;

                when waiting => --waiting to see if the audio is above the threshold
                    if(mvavg > threshold) then
			--reset timer while in waiting
                        timer <= x"000000";
                        checking <= '1'; 

                        state <= check;
                    end if;

                when check=> --checks to see if the audio has gone below the threshold
                    if (mvavg < threshold) then
                        checking <= '0'; --stop counting time when below threshold
                        state <= fall; -- go to fall 
                    end if;
							
                when fall=> --checks to see if the snap happened in a short enough time
                    if (timer < min_time) then --if the audio peaked in a short enough time then it was a snap
                        snap <= '1';
                        state <= latched;
                    else
                        state <= reset;
                    end if;
		 when latched => 
                    -- this is a placeholder bc i don't know if we have the other addresses implemented
                    snap <= '1';
                end case;
        end if;
    end process;
    
    --updating all variables concurrently
    min_time <= x"001240"; --equivalent to a 0.25s time before audio signal is checked to be below threshold
    time_high <= x"005D01"; --equivalent to a 0.5s time for snap output to be high
end a;
