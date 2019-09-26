----------------------------------------------------------------------------------
-- Create Date:    09:47:43 08/02/2009 
-- Module Name:    74LS573 - Behavioral 
----------------------------------------------------------------------------------
library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity CPLD_74LS573 is
    Port ( nOE : in  STD_LOGIC;
           LE  : in  STD_LOGIC;
           D   : in  STD_LOGIC_VECTOR (7 downto 0);
           Q   : out  STD_LOGIC_VECTOR (7 downto 0));
end CPLD_74LS573;

architecture Behavioral of CPLD_74LS573 is
signal latch : std_logic_vector(7 downto 0);
begin

    -- Solange LE High werden die Daten durchgereicht
    -- bei Low wird der alte Zustand beibehalten
    latch <= D when LE = '1' else latch;
    
    -- Wenn nOE = LOW erscheint latch Data am Ausgang
    -- Sonst High-Z
    Q <= latch when nOE = '0' else (7 downto 0 => 'Z');

end Behavioral;