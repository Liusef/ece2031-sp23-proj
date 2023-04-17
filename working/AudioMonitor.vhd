-- AudioMonitor.vhd
-- Created 2023
--
-- This SCOMP peripheral passes data from an input bus to SCOMP's I/O bus.

library IEEE;
library lpm;

use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use lpm.lpm_components.all;

entity AudioMonitor is
port(
    CS          : in  std_logic;
    IO_WRITE    : in  std_logic;
    SYS_CLK     : in  std_logic;  -- SCOMP's clock
    RESETN      : in  std_logic;
    AUD_DATA    : in  std_logic_vector(15 downto 0);
    AUD_NEW     : in  std_logic;
    IO_DATA     : inout  std_logic_vector(15 downto 0)
);
end AudioMonitor;

architecture a of AudioMonitor is

	-- Known working
	-- v1 (not sensitive, inconsistent)
	-- 0x4ff, 0x3a00, 0x100
	
	-- v2 (good with snaps, can't detect claps reliably)
	-- 0x4ff, 0x3d00, 0xe0
	
	-- v3 (quite good, misses a couple snaps and claps every once in a while)
	-- 0x4ff, 0x4800, 0xa0
	
	-- v4 (almost perfect with snaps, claps are meh, occasionally double counts)
	-- 0x4ff, 0x4200, 0xa0
	
	-- v5 (similar to v4, reduced double counts)
	-- 0x580, 0x4200, 0xa0
	
	-- v6 (most consistent with snaps and slaps, not great with claps)
	-- final
	-- 0x560, 0x4200, 0xa0
	

    -- Constants
    signal threshold   : std_logic_vector(15 downto 0) := x"0560";
    signal soundLength : std_logic_vector(31 downto 0) := x"00004200";
    signal decayLength : std_logic_vector(31 downto 0) := x"000000a0";

    --IO
    signal out_en      : std_logic;
    signal parsed_data : std_logic_vector(15 downto 0);
    signal output_data : std_logic_vector(15 downto 0);

    -- Variables
    signal snapCount   : std_logic_vector(15 downto 0);
    signal decayTime   : std_logic_vector(31 downto 0);
    signal soundTime   : std_logic_vector(31 downto 0);

    -- States
    type state_type is (reset, idle, rise, decay, final);
    signal state       : state_type;

begin

    -- Latch data on rising edge of CS to keep it stable during IN
    process (CS) begin
        if rising_edge(CS) then
            output_data <= snapCount;
        end if;
    end process;

    -- Drive IO_DATA when needed.
    out_en <= CS AND ( NOT IO_WRITE );
    with out_en select IO_DATA <=
        snapCount        when '1',
        "ZZZZZZZZZZZZZZZZ" when others;

    process (RESETN, SYS_CLK)
    begin
        if (RESETN = '0') then
            state <= reset;
				snapCount <= x"0000";
--         elsif ((CS AND IO_WRITE) = '1') then
--             threshold <= IO_DATA;
--             state <= reset;
--         elsif ((CS AND (NOT IO_WRITE)) = '1') then
--             --snapCount <= x"0000";
--             state <= idle;
		  elsif ((CS AND IO_WRITE) = '1') then
				  snapCount <= x"0000";
				  state <= idle;
        elsif (rising_edge(AUD_NEW)) then
            parsed_data <= AUD_DATA;

--            if(parsed_data(15) = '1') then
--                parsed_data <= not parsed_data;
--                parsed_data <= parsed_data + '1';
--            end if;

            case state is  
                --On Reset, We set snap output to 0
                when reset=>
                    snapCount <= x"0000";
                    state <= idle;

                -- Stay in this state until the parsed_data is greater than the threshold
                when idle=>    
                    
                    soundTime <= x"00000000";
                    decayTime <= x"00000000";
                    if(signed(parsed_data) > signed(threshold)) then
                        state <= rise;
                    end if;
                
                --Now, when the signal is above the threshold start timers
                when rise =>
                    soundTime <= soundTime + '1';

                    --Wait until parsed_data is less than threshold
                    if(parsed_data < threshold) then
								decayTime <= x"00000000";
                        state <= decay;
                    end if;

                --Handles Oscillations
                when decay =>

                    --Continue Counting up for timers
                    decayTime <= decayTime + '1';
                    soundTime <= soundTime + '1';

                    --If we go back above the threshold before decay time reaches decay length
                    if(parsed_data > threshold) then
                        state <= rise;    
                    elsif(decayTime > decayLength) then
                        state <= final;
                    end if;

                when final =>

                    if (soundTime < soundLength) then
                        snapCount <= snapCount + '1';
                    end if;

                    state <= idle;

            end case;
        end if;
    end process;
end a;
