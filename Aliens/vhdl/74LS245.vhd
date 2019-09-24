----------------------------------------------------------------------------------
-- Create Date:    09:59:36 08/02/2009 
-- Module Name:    74LS245 - Behavioral 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity CPLD_74LS245 is
    Port ( nE  : in  STD_LOGIC;
           dir : in  STD_LOGIC;
           B   : inout  STD_LOGIC_VECTOR (7 downto 0);
           A   : inout  STD_LOGIC_VECTOR (7 downto 0));
end CPLD_74LS245;

architecture Behavioral of CPLD_74LS245 is
begin

    -- Wenn nE = 1 oder dir = '1' dann HighZ
    -- Sonst B
    A <= (7 downto 0 => 'Z') when nE = '1' OR dir = '1' else B;
    
    -- Wenn nE = 1 oder dir = '1' dann HighZ
    -- Sonst A
    B <= (7 downto 0 => 'Z') when nE = '1' OR dir = '0' else A;

end Behavioral;