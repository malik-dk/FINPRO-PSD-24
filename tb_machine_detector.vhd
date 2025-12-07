library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL; 

entity tb_machine_detector is
end tb_machine_detector;

architecture Sim of tb_machine_detector is

    component machine_detector_top
        Port ( clk, reset, write_en : in STD_LOGIC;
               addr_in : in STD_LOGIC_VECTOR(1 downto 0);
               data_in, sensor_in : in SIGNED(15 downto 0);
               ALARM_LED : out STD_LOGIC);
    end component;

    signal clk, reset, write_en, alarm_led : STD_LOGIC := '0';
    signal addr_in : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal data_in, sensor_in : SIGNED(15 downto 0) := (others => '0');
    constant CLK_PERIOD : time := 10 ns;

begin

    UUT: machine_detector_top port map (
        clk => clk,
        reset => reset,
        write_en => write_en,
        addr_in => addr_in,
        data_in => data_in,
        sensor_in => sensor_in,
        ALARM_LED => alarm_led
    );

    clk_process: process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    stim_proc: process
        variable real_val : real;
        variable seed1 : positive := 123;
        variable seed2 : positive := 456;
        variable rand_val : real;
    begin
        reset <= '1'; wait for 50 ns;
        reset <= '0';
        wait for 20 ns;
        
        report "=== PHASE 1: Configuration & Setup ===";
        write_en <= '1';

        addr_in <= "01"; 
        data_in <= to_signed(250, 16);
        wait for CLK_PERIOD;

        addr_in <= "10";  
        data_in <= to_signed(2000, 16);
        wait for CLK_PERIOD;

        write_en <= '0';
        wait for 100 ns;
        
        report "=== PHASE 2: Testing SAFE frequency ===";
        for i in 0 to 150 loop
            real_val := 600.0 * sin(real(i) * 0.05);
            sensor_in <= to_signed(integer(real_val), 16);
            wait for CLK_PERIOD;
        end loop;

        report "Expected: ALARM_LED = '0' (SAFE)";
        wait for 100 ns;

        report "=== PHASE 3: Testing Random Noise ===";
        for i in 0 to 150 loop
            uniform(seed1, seed2, rand_val);
            real_val := (rand_val * 2000.0) - 1000.0;
            sensor_in <= to_signed(integer(real_val), 16);
            wait for CLK_PERIOD;

            if alarm_led = '1' then
                report "FAILURE: Random noise triggered the Alarm at "
                    & time'image(now)
                    severity error;
            end if;
        end loop;

        report "Expected: ALARM_LED = '0' (SAFE)";
        wait for 100 ns;

        report "=== PHASE 4: Testing DANGER frequency ===";
        for i in 0 to 200 loop
            real_val := 9000.0 * sin(real(i) * 0.22); 
            sensor_in <= to_signed(integer(real_val), 16);
            wait for CLK_PERIOD;
        end loop;

        report "Expected: ALARM_LED = '1' (DANGER)";
        wait for 200 ns;

        report "=== PHASE 5: Testing reprogramming (higher threshold) ===";
        write_en <= '1';
        addr_in <= "10";
        data_in <= to_signed(32000, 16);
        wait for CLK_PERIOD;
        write_en <= '0';
        wait for CLK_PERIOD;

        for i in 0 to 500 loop
            real_val := 3500.0 * sin(real(i) * 0.22);
            sensor_in <= to_signed(integer(real_val), 16);
            wait for CLK_PERIOD;
        end loop;

        report "Expected: ALARM_LED = '0' (threshold too high)";
        wait for 100 ns;

        report "=== SIMULATION COMPLETED SUCCESSFULLY ===";
        wait;
    end process;

end Sim;
