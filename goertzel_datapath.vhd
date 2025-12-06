library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity goertzel_datapath is
    Port (
        clk         : in STD_LOGIC;
        reset       : in STD_LOGIC;
        enable      : in STD_LOGIC;

        coeff_in    : in SIGNED(15 downto 0);
        sample_in   : in SIGNED(15 downto 0);

        energy_out  : out SIGNED(31 downto 0);
        valid_out   : out STD_LOGIC
    );
end goertzel_datapath;

architecture Dataflow of goertzel_datapath is

    signal Q1, Q2 : SIGNED(31 downto 0) := (others => '0');
    signal count  : integer range 0 to 255 := 0;

    function calc_feedback_loop(
        input_sample : signed; 
        coeff_val    : signed; 
        q1_val       : signed; 
        q2_val       : signed
    ) return signed is
        variable term1 : signed(95 downto 0);
        variable result : signed(31 downto 0);
    begin
        term1 := resize(q1_val, 48) * resize(coeff_val, 48);
        result := resize(input_sample, 32) + resize(term1(38 downto 7), 32) - q2_val;
        return result;
    end function;

begin

    process(clk, reset)
        variable calc_q : signed(31 downto 0);
        variable q1_squared : signed(63 downto 0);
        variable q2_squared : signed(63 downto 0);
        variable energy_temp : signed(63 downto 0);
    begin
        if reset = '1' then
            Q1 <= (others => '0');
            Q2 <= (others => '0');
            count <= 0;
            valid_out <= '0';
            energy_out <= (others => '0');
        elsif rising_edge(clk) then
            if enable = '1' then
                if count < 100 then
                    calc_q := calc_feedback_loop(sample_in, coeff_in, Q1, Q2);
                    Q2 <= Q1;
                    Q1 <= calc_q;
                    count <= count + 1;
                    valid_out <= '0';
                else
                    q1_squared := Q1 * Q1;
                    q2_squared := Q2 * Q2;

                    energy_out <= resize((q1_squared(63 downto 10) + q2_squared(63 downto 10)), 32);
                  
                    valid_out <= '1';
                    count <= 0;
                    Q1 <= (others => '0');
                    Q2 <= (others => '0');
                end if;
            else
                valid_out <= '0';
            end if;
        end if;
    end process;

end Dataflow;