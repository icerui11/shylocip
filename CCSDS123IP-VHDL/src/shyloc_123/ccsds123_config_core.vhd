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
-- Design unit  : Package for configuration modules of the CCSDS 123
--
-- File name    : ccsds123_config_core.vhd
--
-- Purpose      : Instantiates the necessary modules to read the configuration from AHB
--          or assign it from generics; and generate the header.
--
-- Note         : 
--
-- Library      : shyloc_123
--
-- Author       :
--                Institute for Applied Microelectronics (IUMA)
--                University of Las Palmas de Gran Canaria
--                Campus Universitario de Tafira s/n
--          35017, Las Palmas de Gran Canaria
--                Canary Islands, Spain
--
-- Contact      : 
--                
-- Instantiates : ccsds123_ahbs, ccsds123_shyloc_interface, header123_gen
--============================================================================
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library shyloc_123; 
use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all;
use shyloc_123.config123_package.all;

library shyloc_utils;    
use shyloc_utils.shyloc_functions.all;
use shyloc_utils.amba.all;


--!@file #ccsds123_config_core.vhd#
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Instantiates the necessary modules to read the configuration from AHB (EN_RUNCFG = 1)
--| or assign it from generics (EN_RUNCFG = 0); and generate the header.



entity ccsds123_config_core is
  generic(
    EN_RUNCFG: integer := 1;        --! Enables or disables runtime configuration. 
    RESET_TYPE: integer := 1;       --! Reset flavour (0) asynchronous (1) synchronous.
    PREDICTION_TYPE: integer := 1;      --! Prediction architecture (0) BIP (1) BIP-MEM (2) BSQ (3) BIL (4) BIL-MEM
    HSINDEX : integer;            --! AHB slave index
    HSADDR: integer             --! AHB slave address
  );
  port (
    Clk: in std_logic;            --! Clock signal.
    Rst_n: in std_logic;          --! Reset signal. Active low.
    ahbsi : in ahb_slv_in_type;       --! AHB slave input signals
    ahbso: out ahb_slv_out_type;      --! AHB slave output signals
    amba_clk: in std_logic;         --! AHB clock
    amba_reset: in std_logic;       --! AHB reset
    en_interface: out std_logic;      --! Enable ccsds123_shyloc_interface module operation
    interface_awaiting_config: out std_logic; --! When high: waiting for configuration; When low: configuration received.
    interface_error: out std_logic;       --! Signals configuration error when high. 
    error_code: out std_logic_vector (3 downto 0);  --! Code to identify the source of the error. 
    dispatcher_ready: in std_logic;         --! Output dispatcher can accept header values.
    header : out std_logic_vector(W_BUFFER_GEN-1 downto 0); --! Header value packed; ready to be sent to the output of the compressor. 
    header_valid: out std_logic;        --! When high, validates the header values. 
    config_image : out config_123_image;    --! Image metadata configuration values to be broadcasted to the rest of the compressor. 
    config_predictor: out config_123_predictor; --! Prediction configuration values to be broadcasted to the rest of the compressor. 
    config_sample: out config_123_sample;   --! Sample-adaptive configuration values to be broadcasted to the rest of the compressor. 
    config_weight_tab: out weight_tab_type;   --! Table of custom weight vectors (functionality not included); signal left here for future developments.
    n_bits_header: out std_logic_vector(W_NBITS_HEAD_GEN-1 downto 0); --! Number of valid bits in the header values. 
    control_out_s: in ctrls;          --! Record with value of control signals, to be stored in the STATUS memory-mapped register. 
    config_valid: out std_logic;        --! When high, validate the configuration. Stays high while configuration is valid. 
    ahbm_status: in ahbm_123_status;      --! AHB master status record. 
    config_ahbm: out  config_123_ahbm;      --! Configuration values to be broadcasted to AHB master controller (when preset).
    clear: std_logic              --! Synchronous clear signal. 
  );
end ccsds123_config_core;
  
architecture arch of ccsds123_config_core is
  --signal  config_received: std_logic;
  
  -- Signals for amba slave instance
  signal ahb_clear, error_ahb, ahb_valid : std_logic := '0';
  signal control_out_ahb: ctrls;
  signal ahb_config: config_123_f;

  -- Signals for the clock adaptation instance
  signal clear_ahb_ack_s, error_s_out: std_logic := '0';  
  signal config_s: config_123_f;

  signal valid_s: std_logic := '0';
  signal config_valid_local: std_logic := '0';
  signal error_code_local: std_logic_vector(3 downto 0) := (others => '0');
  signal awaiting_config_local: std_logic := '0';
  signal valid_s_out: std_logic := '0';
  
  -- Configuration values
  signal config_image_int : config_123_image := (others => (others => '0'));
  signal config_predictor_int: config_123_predictor := (others => (others => '0'));
  signal config_sample_int: config_123_sample := (others => (others => '0'));
  signal config_weight_tab_int:  weight_tab_type := (others => (others => '0'));
  signal en_int: std_logic := '0';
begin

  config_valid <= config_valid_local;
  error_code <= error_code_local;
  valid_s_out <= valid_s; 
  interface_awaiting_config <= awaiting_config_local;
  
  config_image <= config_image_int;
  config_predictor <= config_predictor_int;
  config_sample <= config_sample_int;
  config_weight_tab <= config_weight_tab_int;
  
  en_interface <= en_int;
  
  --! When runtime configuration is enabled, we need the AHB slave interface module and the clock adaptation.
  gen_ahb_slave: if EN_RUNCFG = 1 generate
    --!@brief AHB slave interface
    ahbslave : entity shyloc_123.ccsds123_ahbs(rtl)
    generic map(
      hindex => HSINDEX,
      haddr => HSADDR, 
      RESET_TYPE => RESET_TYPE)
    port map(rst_n => amba_reset,
      clk => amba_clk,
      ahbsi => ahbsi,
      ahbso => ahbso,
      clear => ahb_clear,
      control_out_ahb => control_out_ahb,
      config => ahb_config,
      error => error_ahb,
      valid => ahb_valid);
      
    config_ahbm.config_valid <= ahb_valid;
    config_ahbm.P <= ahb_config.P(config_ahbm.P'high downto 0);
    config_ahbm.Nx <= ahb_config.Nx(config_ahbm.Nx 'high downto 0);
    config_ahbm.Nz <= ahb_config.Nz(config_ahbm.Nz'high downto 0);
    config_ahbm.Ny <= ahb_config.Ny(config_ahbm.Ny'high downto 0);
    config_ahbm.ExtMemAddress <= ahb_config.ExtMemAddress(config_ahbm.ExtMemAddress'high downto 0);

    --!@brief Clock adaptation module
    clk_adapt: entity shyloc_123.ccsds123_clk_adapt(registers)
      port map (
        rst => amba_reset,
        clk_ahb => amba_clk, 
        clk_s => Clk, 
        valid_ahb => ahb_valid,
        config_ahb => ahb_config,
        config_s => config_s, 
        control_out_s => control_out_s, 
        control_out_ahb => control_out_ahb,
        clear_s => clear, 
        clear_ahb_out => ahb_clear,
        clear_ahb_ack_s => clear_ahb_ack_s,
        error_ahb_in => error_ahb,  
        error_s_out => error_s_out,
        valid_s_out => valid_s);
    end generate gen_ahb_slave;
  
  --! When runtime configuration is disabled, we do not instantiate the AHB slave interface. Signals set to all zeros. 
  gen_no_ahb_slave: if EN_RUNCFG = 0 generate
    --valid_ahb <= '0';
    ahb_valid <= '0';
    --clear_s <= '0'; 
    ---clear_ahb_out <= '0';
    --clear_s <= '0';
    --clear_ahb_out <= '0';
    clear_ahb_ack_s <= '0';
    zero_config(ahb_config);
    zero_config(config_s);
    zero_config(control_out_ahb);
    error_ahb <= '0';
    error_s_out <= '0';
    valid_s <= '0';
    ahb_clear <= '0';
    config_ahbm.config_valid <= ahb_valid;
    config_ahbm.P <= ahb_config.P(config_ahbm.P'high downto 0);
    config_ahbm.Nx <= ahb_config.Nx(config_ahbm.Nx 'high downto 0);
    config_ahbm.Nz <= ahb_config.Nz(config_ahbm.Nz'high downto 0);
    config_ahbm.Ny <= ahb_config.Ny(config_ahbm.Ny'high downto 0);
    config_ahbm.ExtMemAddress <= ahb_config.ExtMemAddress(config_ahbm.ExtMemAddress'high downto 0);
  end generate gen_no_ahb_slave;
  
  -----------------------------------------------------------------------------------------
  -- This proces will take care of enabling the ccsds123_shyloc_interface
  -- Taking into account if runtime configuration is enabled (wait for values to be
  -- written through AHB slave interface; or when runtime configuration is disabled
  -- generate a 1 level in en_int when modules are ready. 
  -- en_int value is Kept high until clear or reset.
  -----------------------------------------------------------------------------------------
  
  process(clk, rst_n) 
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then 
      en_int <= '0';
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        en_int <= '0';
      else
        if (EN_RUNCFG = 1) then
          en_int <= valid_s;
        else
          -- Modified by AS: PREDICTION_TYPE = 4 (BIL-MEM) included
          if (PREDICTION_TYPE = 1 or PREDICTION_TYPE = 2 or PREDICTION_TYPE = 4) then
          -------------------------
            if (ahbm_status.ahb_idle = '1') then --make sure AMBA master is in IDLE before starting again
              en_int <= '1';
            end if;
          else
            en_int <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;
  
  --!@brief Interface module (validates configuration and puts it in records)
  interface_gen : entity shyloc_123.ccsds123_shyloc_interface(arch)
  port map (clk => Clk,
      rst_n => Rst_n,
      config_in => config_s,
      en => en_int,
      clear => clear,
      config_image => config_image_int,             
      config_predictor => config_predictor_int,         
      config_sample => config_sample_int,           
      config_weight_tab => config_weight_tab_int,       
      config_valid => config_valid_local,
      error => interface_error,
      error_code => error_code_local,
      awaiting_config => awaiting_config_local);
  
  --!@brief Generation of the header values
  header_gen : entity shyloc_123.header123_gen(arch)
  generic map (HEADER_ADDR => MAX_HEADER_SIZE,  
         W_BUFFER_GEN =>  W_BUFFER_GEN,
       PREDICTION_TYPE => PREDICTION_TYPE,
         W_NBITS_HEAD_GEN => W_NBITS_HEAD_GEN,
      RESET_TYPE      => RESET_TYPE,    
      MAX_HEADER_SIZE   => MAX_HEADER_SIZE, 
      Nz_GEN        => Nz_GEN,      
      Q_GEN       => Q_GEN,     
      W_MAX_HEADER_SIZE   => W_MAX_HEADER_SIZE,
      WEIGHT_INIT_GEN   => WEIGHT_INIT_GEN, 
      ENCODING_TYPE   => ENCODING_TYPE, 
      ACC_INIT_TYPE_GEN => ACC_INIT_TYPE_GEN
      )
  port map (Clk => Clk,
        Rst_N => Rst_n,
        clear => clear,
        config_image_in => config_image_int,
        config_predictor_in => config_predictor_int,
        config_sample_in => config_sample_int,
        config_weight_tab_in => config_weight_tab_int,
        config_received => config_valid_local,
        dispatcher_ready => dispatcher_ready,
        header_out => header,   
        header_out_valid => header_valid,
        n_bits => n_bits_header); 
end arch;