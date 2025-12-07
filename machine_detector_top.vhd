library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity machine_detector_top is
    Port ( 
        clk         : in STD_LOGIC;
        reset       : in STD_LOGIC;

        write_en    : in STD_LOGIC;
        addr_in     : in STD_LOGIC_VECTOR(1 downto 0);
        data_in     : in SIGNED(15 downto 0);

        sensor_in   : in SIGNED(15 downto 0);

        ALARM_LED   : out STD_LOGIC 
    );
end machine_detector_top;

architecture Structural of machine_detector_top is

    signal w_coeff      : SIGNED(15 downto 0);
    signal w_threshold  : SIGNED(31 downto 0);
    signal w_energy     : SIGNED(31 downto 0);
    signal w_start      : STD_LOGIC;
    signal w_valid      : STD_LOGIC;
    
    signal alarm_status : STD_LOGIC := '0';

    component control_unit
        Port ( clk, reset, write_en : in STD_LOGIC;
               addr_in : in STD_LOGIC_VECTOR(1 downto 0);
               data_in : in SIGNED(15 downto 0);
               coeff_out : out SIGNED(15 downto 0);
               thresh_out : out SIGNED(31 downto 0);
               start_calc : out STD_LOGIC);
    end component;

    component goertzel_datapath
        Port ( clk, reset, enable : in STD_LOGIC;
               coeff_in, sample_in : in SIGNED(15 downto 0);
               energy_out : out SIGNED(31 downto 0);
               valid_out : out STD_LOGIC);
    end component;

begin

    U_BRAIN: control_unit port map (
        clk => clk, reset => reset,
        write_en => write_en, addr_in => addr_in, data_in => data_in,
        coeff_out => w_coeff, 
        thresh_out => w_threshold,
        start_calc => w_start
    );

    U_MUSCLE: goertzel_datapath port map (
        clk => clk, reset => reset, 
        enable => w_start,
        coeff_in => w_coeff, 
        sample_in => sensor_in,
        energy_out => w_energy, 
        valid_out => w_valid
    );

    process(clk, reset)
    begin
        if reset = '1' then
            alarm_status <= '0';
        elsif rising_edge(clk) then
            if w_valid = '1' then
       
                if w_energy > w_threshold then
                    alarm_status <= '1'; 
                else
                    alarm_status <= '0'; 
                end if;
            end if;
        end if;
    end process;
    
    ALARM_LED <= alarm_status;

end Structural;
