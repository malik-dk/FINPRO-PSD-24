library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity control_unit is
    Port ( 
        clk         : in STD_LOGIC;
        reset       : in STD_LOGIC;

        write_en    : in STD_LOGIC;
        addr_in     : in STD_LOGIC_VECTOR(1 downto 0);
        data_in     : in SIGNED(15 downto 0);

        coeff_out   : out SIGNED(15 downto 0);
        thresh_out  : out SIGNED(31 downto 0);
        start_calc  : out STD_LOGIC
    );
end control_unit;

architecture Behavioral of control_unit is

    signal reg_coeff     : SIGNED(15 downto 0) := to_signed(100, 16);    
    signal reg_threshold : SIGNED(31 downto 0) := to_signed(100000, 32); 

    type state_type is (IDLE, CONFIG_MODE, MONITOR_MODE);
    signal current_state : state_type := IDLE;

begin

    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= IDLE;
            reg_coeff <= to_signed(100, 16);          
            reg_threshold <= to_signed(100000, 32);
        elsif rising_edge(clk) then

            case current_state is
                when IDLE =>
                    if write_en = '1' then
                        current_state <= CONFIG_MODE;
                    else
                        current_state <= MONITOR_MODE;
                    end if;

                when CONFIG_MODE =>

                    if write_en = '1' then
                        case addr_in is
                            when "01" => 
                                reg_coeff <= data_in; 
                            when "10" => 
                                
                                reg_threshold <= resize(data_in * 10, 32); 
                            when others => 
                                null;
                        end case;
                    else
                        current_state <= IDLE; 
                    end if;

                when MONITOR_MODE =>
                  
                    if write_en = '1' then
                        current_state <= CONFIG_MODE; 
                    end if;
            end case;
        end if;
    end process;

    
    coeff_out   <= reg_coeff;
    thresh_out  <= reg_threshold;

    start_calc  <= '1' when current_state = MONITOR_MODE else '0';

end Behavioral;
