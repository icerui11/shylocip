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
-- Design unit  : Weight update initialization unit.
--
-- File name    : weight_init_shyloc.vhd
--
-- Purpose      : This is the module that will take care of the weight initialization.
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
--
--============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library shyloc_utils;
use shyloc_utils.shyloc_functions.all;
library shyloc_123; 
--use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all;    

--!@file #weight_init_shyloc.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief This is the module that will take care of the weight initialization.

entity weight_init_shyloc is 
  generic (
       W_WEI: integer := 19;          --! Bit width of the weights (OMEGA + 3).
       W_INIT_TABLE: integer := 5;      --! Bit width of the address of the weight vectors
       PREDICTION_MODE: integer := 0;     --! Full (0) or reduced (1) prediction.
       OMEGA: integer := 13;          --! Weight component resolution
       RESET_TYPE: integer := 1         --! Reset flavour (0) asynchronoous (1) synchronous
       );         
  
  port (                                
    clk: in std_logic;                            --! Clock signal.
    rst_n: in std_logic;                          --! Reset signal. Active low.
    en: in std_logic;                             --! Enable signal.
    clear : in std_logic;                         --! Clear signal.
    config_valid : in std_logic;                      --! Signal to validate the configuration.
    config_predictor: in config_123_predictor;                --! Configuration values of the predictor.
    address: in std_logic_vector (W_INIT_TABLE-1 downto 0);         --! Address of weight value that we want
    def_init_weight_value: out std_logic_vector (W_WEI - 1 downto 0);   --! Updated weight value (registered). 
    valid: out std_logic                          --! Validates def_init_weight_value.
    );
    
end weight_init_shyloc;

architecture arch of weight_init_shyloc is 
  --this is in fact a ROM with the corresponding initalization values
  
  type mem1 is array (0 to 15-1) of integer;
  type mem2 is array (0 to 18-1) of integer;

  signal full_init: mem2;
  
  signal reduced_init: mem1;
    


  --- Signals used for weight initialization
  --signal init_weight_tmp: signed(W_WEI-1 downto 0); 
  signal address_local: unsigned (W_INIT_TABLE-1 downto 0);
  signal is_valid: std_logic;
  
  
begin
  address_local <= unsigned(address);
  valid <= is_valid;
  
  full_init <= (0 => 0,
      1 => 0,
      2 => 0,
      3 => 7*(2**to_integer(unsigned(config_predictor.OMEGA)))/(2**(3*1)),
      4 => 7*(2**to_integer(unsigned(config_predictor.OMEGA)))/(2**(3*2)),
      5 => 7*(2**to_integer(unsigned(config_predictor.OMEGA)))/(2**(3*3)),
      6 => 7*(2**to_integer(unsigned(config_predictor.OMEGA)))/(2**(3*4)),
      7 => 7*(2**to_integer(unsigned(config_predictor.OMEGA)))/(2**(3*5)),
      8 => 7*(2**to_integer(unsigned(config_predictor.OMEGA)))/(2**(3*6)),
      9 => 7*(2**to_integer(unsigned(config_predictor.OMEGA)))/(2**(3*7)),
      10 => 0,
      11 => 0,
      12 => 0,
      13 => 0,
      14 => 0,
      15 => 0,
      16 => 0,
      17 => 0);
  reduced_init <= (0 => 7*(2**to_integer(unsigned(config_predictor.OMEGA)))/(2**(3*1)),
          1 => 7*(2**to_integer(unsigned(config_predictor.OMEGA)))/(2**(3*2)),
            2 => 7*(2**to_integer(unsigned(config_predictor.OMEGA)))/(2**(3*3)),
            3=> 7*(2**to_integer(unsigned(config_predictor.OMEGA)))/(2**(3*4)),
            4 => 7*(2**to_integer(unsigned(config_predictor.OMEGA)))/(2**(3*5)),
            5 => 7*(2**to_integer(unsigned(config_predictor.OMEGA)))/(2**(3*6)),
            6 => 7*(2**to_integer(unsigned(config_predictor.OMEGA)))/(2**(3*7)),
            7 =>  0,
            8 =>  0,
            9 =>  0,
            10 => 0,
            11 => 0,
            12 => 0,
            13 => 0,
            14 => 0);
  process(clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      def_init_weight_value <= (others => '0');
      is_valid <= '0';
    --  full_init := (others => others '0');
    --  reduced_init := (others => others '0');
    elsif (clk'event and clk='1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        def_init_weight_value <= (others => '0');
        is_valid <= '0';
      --  full_init := (others => others '0');
      --  reduced_init := (others => others '0');
      else
        is_valid <= en;
        if (en = '1') then 
          if (PREDICTION_MODE = 0) then
            def_init_weight_value <= std_logic_vector(to_signed (full_init(to_integer(address_local)), W_WEI));
          else
            def_init_weight_value <= std_logic_vector(to_signed(reduced_init(to_integer(address_local)), W_WEI));
          end if;
        end if;
      end if;
    end if;
  end process;

end arch; --============================================================================

--============================================================================--
-- Design unit  : Weight update unit.
--
-- File name    : weight_update_shyloc.vhd
--
-- Purpose      : This is the module that will take care of the weight update. It updates one weight value.
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
--
--============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library shyloc_utils;
use shyloc_utils.shyloc_functions.all;

library shyloc_123; 
--use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all;    

--!@file #weight_update_shyloc.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief This is a simple weight update unit. To be instantiated by another module that will take care of initialization!
-- I am removing the initialization and all associated signals and generics. 


entity weight_update_shyloc is 
  generic (
       DRANGE: integer := 16;         --! Dynamic range of the input samples.
       W_WEI: integer := 19;          --! Bit width of the weights (OMEGA + 3).
       W_LD:  integer := 20;          --! Bit width of the local differences signal (DRANGE+4)
       W_SCALED: integer := 34;         --! Bit width of the scaled predictor (R+2)
       W_RO:  integer := 4;           --! Bit width of the weight update scaling exponent.
       WE_MIN: integer := -32768;       --! Minimum possible value of the weight components (-2**(OMEGA+2)).
       WE_MAX: integer := 32767;        --! Maximum possible value of the weight components (2**(OMEGA+2) -1).
       MAX_RO: integer := 9;          --! Maximum possible value of the weight update scaling exponent.
       OMEGA: integer := 13;          --! Weight component resolution
       RESET_TYPE: integer := 1 );        --! Reset flavour (0) asynchronous (1) synchronous  
  
  port (                                
    clk: in std_logic;                        --! Clock signal.
    rst_n: in std_logic;                      --! Reset signal. Active low.
    en: in std_logic;                         --! Enable signal.
    clear: in std_logic;                      --! Clear signal.
    config_valid : in std_logic;                  --! Signal to validate the configuration.
    config_predictor: in config_123_predictor;            --! Configuration values of the predictor.
    s_signed: in std_logic_vector (DRANGE downto 0);        --! Current sample to be compressed, represented as a signed value.
    s_scaled: in std_logic_vector (W_SCALED-1 downto 0);      --! Scaled predicted sample.
    ld: in std_logic_vector (W_LD - 1 downto 0);          --! Local difference value.
    weight: in std_logic_vector (W_WEI-1 downto 0);         --! Weight value.
    ro: in std_logic_vector (W_RO - 1 downto 0);          --! Weight update scaling exponent.
    updated_weight: out std_logic_vector (W_WEI - 1 downto 0);    --! Updated weight value (registered).
    valid : out std_logic                     --! Validates updated_weight.
    );
    
end weight_update_shyloc;

architecture arch of weight_update_shyloc is 

  constant W_SHIFTED: integer := W_LD + MAX_RO;
  constant W_RESULT: integer  := W_SHIFTED + 1; --maximum(W_SHIFTED + 1, W_LD);
  constant W_PRED_ERR: integer := DRANGE + 4;
  --constant W_INIT_TABLE: integer := log2(Cz);
  constant one: std_logic_vector(W_WEI-1 downto 0) := (0 => '1', others => '0');
  
  signal w_min, w_max, two_powW: std_logic_vector(W_WEI-1 downto 0);
  
  signal clipin: std_logic_vector(W_RESULT-1 downto 0);
  signal clipout: std_logic_vector (W_WEI-1 downto 0);
  signal s1, s2, s3: std_logic_vector(W_SHIFTED-1 downto 0);
  signal abs_ro: std_logic_vector(ro'high downto 0);
  signal tmp, tmp_next: signed (W_SHIFTED -1 downto 0);
  signal weight_tmp: std_logic_vector (W_WEI-1 downto 0);
  signal sign_e: std_logic;
  signal pred_error: signed (W_PRED_ERR-1 downto 0);
  signal is_valid_d1, is_valid: std_logic;
  
begin

  valid <= is_valid;

  -- Entity clip (clip.vhd)
  clip: entity shyloc_123.clip(arch)
  generic map (
    W_BOUND => W_WEI, 
    W_CLIP => W_RESULT)
  port map (
    min => w_min, 
    max => w_max, 
    clipin => clipin, 
    clipout => clipout);
    
  -- Entity barrel_shifter (barrel_shifter.vhd)
  barrel_right: entity shyloc_utils.barrel_shifter(arch)
  generic map (W => W_SHIFTED, S_MODE => 4, STAGES => W_RO)
  port map (barrel_data_in => s1, amt => abs_ro, barrel_data_out => s2);
  
  barrel_left: entity shyloc_utils.barrel_shifter(arch)
  generic map (W => W_SHIFTED, S_MODE => 0, STAGES => W_RO)
  port map (barrel_data_in => s1, amt => abs_ro, barrel_data_out => s3);  

  abs_ro <= std_logic_vector(abs(signed(ro)));
  
  --w_max <= std_logic_vector(to_signed(WE_MAX, W_WEI));
  --w_min <= std_logic_vector(to_signed(WE_MIN, W_WEI));
  
  ------------------------------------------ constants ----------------------------------
  --one <= (0 => '1', others => '0');
  process (config_predictor.OMEGA)
  --  variable two_powW_var: std_logic_vector (two_powW'high downto 0);
  begin
    for i in two_powW'high downto 0 loop
      if i < to_integer(unsigned(config_predictor.OMEGA)+2) then
        two_powW(i) <= '1';
      else
        two_powW(i) <= '0';
      end if;
    end loop;
  end process;
  --two_powW <= std_logic_vector(unsigned(one) sll to_integer(unsigned(config_predictor.OMEGA)+2));
  
  --two_powW <= std_logic_vector(unsigned(one) sll to_integer(unsigned(config_predictor.OMEGA)+2));
  
  w_max <= two_powW; --std_logic_vector(unsigned(two_powW) - 1);
  w_min <= not(w_max);
  ------------------------------------------ constants ----------------------------------
  
  -- Compute prediction error and sign_e
  pred_error <= (resize(signed(s_signed), pred_error'length) sll 1) - resize(signed(s_scaled), pred_error'length);
  sign_e <= pred_error(pred_error'high);
  

  process(clk, rst_n)
  begin
    if (rst_n = '0') then
      updated_weight <= (others => '0');
      weight_tmp <= (others => '0');
      tmp <=  (others => '0');
      is_valid <= '0';
      is_valid_d1 <= '0';
    elsif (clk'event and clk='1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        updated_weight <= (others => '0');
        weight_tmp <= (others => '0');
        tmp <=  (others => '0');
        is_valid <= '0';
        is_valid_d1 <= '0';
      else
        is_valid_d1 <= en;
        is_valid <= is_valid_d1;
        
        if (en = '1') then -- and init = '0') then 

          weight_tmp <= weight; 
          tmp <= tmp_next;
        end if;
        --if (init_tmp = '0') then
          updated_weight <= clipout; 
        --else
        --  updated_weight <= std_logic_vector(init_weight_tmp);
        --end if;
      end if;
    end if;
  end process;

  -- Combinational logic
  process (sign_e, ro, ld, weight_tmp, s2, s3, tmp)
    variable inv_ro: unsigned (ro'high downto 0);
    variable v1: signed (ld'high downto 0);
    variable v3: signed (W_SHIFTED-1 downto 0);
    variable v4: signed (v3'length downto 0);
    variable v5: signed (v3'length downto 0);
    variable v6: signed (W_RESULT-1 downto 0);
  begin
    if (sign_e = '1') then -- Change the local differences sign according to sign_e
      v1 := signed(not(ld)) + 1;  
      s1 <= std_logic_vector(resize (v1, s1'length));
    else
      v1:= signed(ld);
      s1 <= std_logic_vector(resize (v1, s1'length));
    end if;
    
    if ro(ro'high) = '1' then
      v3 := signed(s3);  -- If ro is negative, shift left (multiply)
    else
      v3 := signed(s2);  -- If ro is positive arithmetic shift right (divide)
    end if;   
    
    tmp_next <= v3; -- Partial result is registered

    v4 := resize(tmp, v4'length) + 1; 
    v5 := v4(v4'high)&v4(v4'high downto 1);
    v6 := resize(v5, W_RESULT)  + resize(signed(weight_tmp), W_RESULT); 
    clipin <= std_logic_vector(v6);
  end process; 
end arch; --============================================================================