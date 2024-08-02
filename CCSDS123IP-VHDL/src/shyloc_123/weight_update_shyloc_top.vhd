--============================================================================--
-- Copyright 2017 University of Las Palmas de Gran Canaria 
--
-- Institute for Applied Microelectronics (IUMA)
-- Campus Universitario de Tafira s/n
-- 35017, Las Palmas de Gran Canaria
-- Canary Islands, Spain
--
-- This code may be freely used, copied, modified, and redistributed
-- by the European Space Agency for the Agency's own requirements.
--============================================================================--
-- ESA IP-CORE LICENSE
--
-- This code is provided under the terms of the
-- ESA Licence (Agreement) on Synthesisable HDL Models,
-- which you have signed prior to receiving the code.
--
-- The code is provided "as is", there is no warranty that
-- the code is correct or suitable for any purpose,
-- neither implicit nor explicit. The code and the information in it
-- contained do not necessarily reflect the policy of the
-- European Space Agency or of <originator>.
--
-- No technical support is available from ESA for this IP core,
-- however, news on the IP will be posted on the web page:
-- http://www.esa.int/TEC/Microelectronics
--
-- Any feedback (bugs, improvements etc.) shall be reported to ESA
-- at E-Mail IpCoreRequest@esa.int
--============================================================================--
-- Design unit  : Weight update top module.
--
-- File name    : weight_update_shyloc_top.vhd
--
-- Purpose      : This module performes the update or initilization of a weight vector. 
--
-- Note         : 
--
-- Library      : 
--
-- Author       : Lucana Santos
--                Institute for Applied Microelectronics (IUMA)
--                University of Las Palmas de Gran Canaria
--                Campus Universitario de Tafira s/n
--          35017, Las Palmas de Gran Canaria
--                Canary Islands, Spain
--
-- Contact      : lsfalcon@iuma.ulpgc.es
--                
-- Instantiates: weight_update_shyloc, weight_init_shyloc
--============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library shyloc_123; 
use shyloc_123.ccsds123_constants.all;

library shyloc_utils;    
use shyloc_utils.shyloc_functions.all;

--!@file #weight_update_shyloc_top.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief This module performs the update or initialization of a weight vector. 

entity weight_update_shyloc_top is 
  generic (
      DRANGE: integer := 16;          --! Dynamic range of the input samples.
      W_WEI: integer := 19;           --! Bit width of the weights (OMEGA + 3).
      W_LD:  integer := 20;         --! Bit width of the local differences signal (DRANGE+4)
      W_SCALED: integer := 34;        --! Bit width of the scaled predictor (R+2)
      W_RO:  integer := 4;          --! Bit width of the weight update scaling exponent.
      WE_MIN: integer := -32768;        --! Minimum possible value of the weight components (-2**(OMEGA+2)).
      WE_MAX: integer := 32767;         --! Maximum possible value of the weight components (2**(OMEGA+2) -1).
      MAX_RO: integer := 9;           --! Maximum possible value of the weight update scaling exponent.
      Cz: integer := 6;           --! Size of the local differences and weight vector.
      TABLE: integer := 0;          --! Weights are initialized from user-selected values (1); or from the default values (0).
      PREDICTION_MODE: integer := 0;      --! Full (0) or reduced (1) prediction.
      OMEGA: integer := 13;         --! Weight component resolution
      RESET_TYPE : integer := 1       --! Reset type
      );        
  
  port (                                
    clk: in std_logic;                        --! Clock signal.
    rst_n: in std_logic;                      --! Reset signal. Active low.
    en_update: in std_logic;                    --! Enable signal.
    en_init: in std_logic;                      --! Enable initialization
    clear : in std_logic;                     --! Synchronous clear.
    config_predictor: in config_123_predictor;            --! Predictor configuration values.
    config_valid: in std_logic;                   --! Flag that validates the configuration.
    s_signed: in std_logic_vector (DRANGE downto 0);        --! Current sample to be compressed, represented as a signed value.
    s_scaled: in std_logic_vector (W_SCALED-1 downto 0);      --! Scaled predicted sample.
    ld_vector: in ld_array_type(0 to Cz-1);             --! Array of local differences
    custom_wei_vector: in wei_array_type(0 to Cz-1);        --! Array of custon weight init values (from configuration)
    wei_vector: in wei_array_type(0 to Cz-1);           --! Array of weight values
    ro: in std_logic_vector (W_RO - 1 downto 0);          --! Weight update scaling exponent.
    valid : out std_logic;                      --! Validates output for one clk.
    updated_weight: out wei_array_type(0 to Cz-1)         --! Array of weight updated values
    );
    
end weight_update_shyloc_top;


architecture arch_bip of weight_update_shyloc_top is
  constant W_INIT_TABLE: integer := log2(Cz);
  constant N_STAGES_INIT: integer := 1;
  constant N_STAGES_UPDATE: integer := 1;
  signal  def_init_weight_value_vector, updated_weight_value_vector, updated_weight_reg, updated_weight_out: wei_array_type(0 to Cz-1); 
  signal din_valid_init, dout_valid_init: std_logic_vector (N_STAGES_INIT downto 0);
  signal din_valid_update, dout_valid_update: std_logic_vector (N_STAGES_UPDATE downto 0);
  signal valid_update, valid_init: std_logic;
  
begin
  
  ---------------------------------------------------------------------------
  --! Generates Cz initialization units
  ---------------------------------------------------------------------------
  init_unit: for j in 0 to Cz-1 generate
      signal address: std_logic_vector(W_INIT_TABLE-1 downto 0);
  begin
    address <= std_logic_vector (to_unsigned(j, address'length));
    default_init: entity shyloc_123.weight_init_shyloc(arch)
    generic map(
      W_WEI => W_WEI, 
      W_INIT_TABLE => W_INIT_TABLE, 
      PREDICTION_MODE => PREDICTION_MODE, 
      OMEGA => OMEGA,
      RESET_TYPE => RESET_TYPE
      ) 
    port map(
      clk => clk, 
      rst_n => rst_n, 
      en => en_init, 
      clear => clear, 
      config_valid => config_valid, 
      config_predictor => config_predictor, 
      address => address,
      def_init_weight_value => def_init_weight_value_vector(j)
    );
  end generate init_unit; 
  
  ---------------------------------------------------------------------------
  --! Generates Cz udpate units
  ---------------------------------------------------------------------------
  update_unit: for j in 0 to Cz-1 generate
    update_unit: entity shyloc_123.weight_update_shyloc(arch)
    generic map(
      DRANGE => DRANGE, 
      W_WEI => W_WEI, 
      W_LD => W_LD, 
      W_SCALED => W_SCALED, 
      W_RO => W_RO, 
      
      WE_MIN => WE_MIN, 
      WE_MAX => WE_MAX, 
      MAX_RO => MAX_RO,
      RESET_TYPE => RESET_TYPE
    ) 
    port map(
      clk => clk, 
      rst_n => rst_n, 
      en => en_update, 
      clear => clear, 
      config_valid => config_valid, 
      config_predictor => config_predictor, 
      s_signed => s_signed,
      s_scaled => s_scaled, 
      ld => ld_vector(j), 
      weight => wei_vector(j), 
      ro => ro, 
      updated_weight => updated_weight_value_vector(j)
    );
  end generate update_unit;
  
  ---------------------------------------------------------------------------
  -- Generate valid bit for init
  ---------------------------------------------------------------------------
  sr_init: for j in 0 to N_STAGES_INIT generate
    assign_initial: if (j = 0) generate
      din_valid_init(0) <= en_init;
      check_size: if (N_STAGES_INIT > 0) generate
        din_valid_init(1) <= dout_valid_init(0);
      end generate check_size;
    end generate assign_initial;
    ff1bit_init: entity shyloc_123.ff1bit(arch)
      generic map (RESET_TYPE => RESET_TYPE)
      port map(
        clk => clk, 
        rst_n => rst_n,
        clear => clear,
        din => din_valid_init(j),
        dout => dout_valid_init(j)
      );
      
    reassign_output: if (j < N_STAGES_INIT and j > 0) generate
      din_valid_init(j+1) <= dout_valid_init(j);
    end generate reassign_output;
      
    assing_out_valid: if (j = N_STAGES_INIT) generate
      valid_init <= dout_valid_init(j);
    end generate assing_out_valid;
  end generate;
  
  ---------------------------------------------------------------------------
  -- Generate valid bit for update
  ---------------------------------------------------------------------------
  sr_update: for j in 0 to N_STAGES_UPDATE generate
    assign_initial: if (j = 0) generate
      din_valid_update(0) <= en_update;
      din_valid_update(1) <= dout_valid_update(0);
    end generate assign_initial;
    ff1bit_init: entity shyloc_123.ff1bit(arch)
      generic map (RESET_TYPE => RESET_TYPE)
      port map(
        clk => clk, 
        rst_n => rst_n,
        clear => clear,
        din => din_valid_update(j),
        dout => dout_valid_update(j)
      );
      
    reassign_output: if (j < N_STAGES_UPDATE and j > 0) generate
      din_valid_update(j+1) <= dout_valid_update(j);
    end generate reassign_output;
      
    assing_out_valid: if (j = N_STAGES_UPDATE) generate
      valid_update <= dout_valid_update(j);
    end generate assing_out_valid;
  end generate;
  
  ---------------------------------------------------------------------------
  -- Output selection (init or update) and assignment
  ---------------------------------------------------------------------------
  valid <= valid_init or valid_update;
  updated_weight <= updated_weight_out;
  updated_weight_out <= def_init_weight_value_vector when valid_init = '1' else updated_weight_value_vector 
  when valid_update = '1' else updated_weight_reg;
  
  --------------------------------------------------------------------------- 
  -- Registered output to mantain value while not enabled
  ---------------------------------------------------------------------------
  process(clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      updated_weight_reg <=  (others => (others => '0'));
    elsif clk'event and clk ='1' then
      if clear = '1' or (rst_n = '0' and RESET_TYPE = 1) then
        updated_weight_reg <=  (others => (others => '0'));   
      else
        updated_weight_reg <= updated_weight_out;
      end if;
    end if;
  end process;
end arch_bip;