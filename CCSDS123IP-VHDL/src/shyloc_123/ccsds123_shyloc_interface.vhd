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
-- Design unit  : Interface module; reads and validates configuration. 
--
-- File name    : ccsds123_shyloc_interface.vhd
--
-- Purpose      : Read and validate configuration values. 
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

library shyloc_123; 
use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all;
use shyloc_123.config123_package.all;

library shyloc_utils;    
use shyloc_utils.shyloc_functions.all;


--!@file #ccsds123_shyloc_interface.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief This module performs the choice between the generic values and 
--! the values received by AMBA for the compression parameters.
--! The module also performs validation of the configuration values according to the possible values, 
--! and generates an error flag and an error code if necessary.
--! If runtime configuration is disabled. Configuration values are read from constants in ccsds123_parameters.vhd

entity ccsds123_shyloc_interface is
  port (
    clk: in std_logic;                --! Clock signal.
    rst_n: in std_logic;              --! Reset signal. Active low.
    config_in: in config_123_f;           --! Configuration captured by AMBA.
    en: in std_logic;               --! Synchronous clear.
    clear: in std_logic;              --! Compression has been forced to stop. Go back to idle state.                       
    config_image: out config_123_image;       --! Image metadata configuration values selected.
    config_predictor: out config_123_predictor;   --! Predictor configuration values selected.
    config_sample: out config_123_sample;     --! Sample-adaptive configuration values selected.
    config_WEIGHT_TAB: out weight_tab_type;     --! Custom weight table values (functionality not implemented yet).
    config_valid : out std_logic;         --! Configuration selected is valid. 
    error: out std_logic;             --! Indicates an error on the configuration selected.
    error_code: out std_logic_vector(3 downto 0); --! Indicates the error.
    awaiting_config: out std_logic          --! Indicates interface is waiting for configuration.
  );
end ccsds123_shyloc_interface;
  

architecture arch of ccsds123_shyloc_interface is

  signal config_image_reg, config_image_cmb: config_123_image;    
  signal config_predictor_reg, config_predictor_cmb: config_123_predictor;    
  signal config_sample_reg, config_sample_cmb: config_123_sample;   
  signal config_reg_WEIGHT_TAB, config_cmb_WEIGHT_TAB: weight_tab_type;   
  signal config_valid_reg, config_valid_cmb, error_reg, error_cmb, awaiting_config_reg, awaiting_config_cmb: std_logic := '0';
  signal error_code_reg, error_code_cmb: std_logic_vector(3 downto 0) := (others => '0');
  signal first_config_reg, first_config_cmb: std_logic;
    
begin
  -----------------------------------------------------------------------
  --! Output assignments
  -----------------------------------------------------------------------
  
  config_image <= config_image_reg;
  config_predictor <= config_predictor_reg;
  config_sample <= config_sample_reg;
  config_WEIGHT_TAB <= config_reg_WEIGHT_TAB;
  error <= error_reg;
  error_code <= error_code_reg;
  awaiting_config <= awaiting_config_reg;
  
  -----------------------------------------------------------------------
  --! Generation of valid level when runtime configuration is enabled.
  -----------------------------------------------------------------------
  gen_config_valid_run: if EN_RUNCFG = 1 generate
    config_valid <= (config_valid_reg and not en);
  end generate gen_config_valid_run;
  
  -----------------------------------------------------------------------
  --! Generation of valid level when runtime configuration is disabled.
  -----------------------------------------------------------------------
  gen_config_valid_no_run: if EN_RUNCFG = 0 generate
    config_valid <= config_valid_reg;
  end generate gen_config_valid_no_run;
  
  -----------------------------------------------------------------------
  --! Outputs registration
  -----------------------------------------------------------------------
  regs: process (clk, rst_n) 
    begin
      if (rst_n = '0' and RESET_TYPE = 0) then
        config_image_reg <= (others => (others => '0'));
        config_predictor_reg <= (others => (others => '0'));
        config_sample_reg <= (others => (others => '0'));
        config_reg_WEIGHT_TAB <= (others => (others => '0'));
      
        config_valid_reg <= '0';      
        error_reg <= '0';           
        error_code_reg <= (others => '0'); 
        awaiting_config_reg <= '1';
        first_config_reg <= '0';
      
      elsif (clk'event and clk = '1') then
        if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
          config_image_reg <= (others => (others => '0'));
          config_predictor_reg <= (others => (others => '0'));
          config_sample_reg <= (others => (others => '0'));
          config_reg_WEIGHT_TAB <= (others => (others => '0'));
          config_valid_reg <= '0';      
          awaiting_config_reg <= '1';
          if (clear = '1') then 
            first_config_reg <= first_config_cmb;
            error_reg <= error_cmb;           
            error_code_reg <= error_code_cmb; 
          else
            first_config_reg <= '0';
            -- Modified by AS: error and error_code not properly initialized when synchronous reset is configured
            error_reg <= '0';            
            error_code_reg <= (others => '0'); 
            ----------------------------------
          end if;
        else 
          config_image_reg <= config_image_cmb;
          config_predictor_reg <=  config_predictor_cmb;
          config_sample_reg <= config_sample_cmb;
          config_reg_WEIGHT_TAB <= config_cmb_WEIGHT_TAB;
          config_valid_reg <= config_valid_cmb;
          error_reg <= error_cmb;
          error_code_reg <= error_code_cmb;
          awaiting_config_reg <= awaiting_config_cmb;
        end if;
      end if;
    end process;
    
  -----------------------------------------------------------------------
  --! Combinational logic - assings configuration, checks if it is correct
  -----------------------------------------------------------------------
  comb_interfae: process (config_in, config_image_reg, config_predictor_reg, config_sample_reg, config_reg_WEIGHT_TAB, en, error_reg, error_code_reg, config_valid_reg, awaiting_config_reg)

    variable config_image_check: config_123_image_f;
    variable config_image_var: config_123_image;      
    variable config_predictor_check: config_123_predictor_f;      
    variable config_sample_check: config_123_sample_f;          
  begin
    config_image_cmb <= config_image_reg;
    config_predictor_cmb <= config_predictor_reg;
    config_sample_cmb <= config_sample_reg;
    config_cmb_WEIGHT_TAB <= config_reg_WEIGHT_TAB;
    config_valid_cmb <= config_valid_reg;
    error_cmb <= error_reg;
    error_code_cmb <= error_code_reg;
    awaiting_config_cmb <= awaiting_config_reg;
    first_config_cmb <= '0';
    config_image_check := configure_image;
    config_sample_check:= configure_sample;
    config_predictor_check := configure_predictor;
    config_image_var := config_image_cmb;
    if (EN_RUNCFG = 0) then
      --configure from generics
      config_image_cmb <= configure_image;
      config_image_var := configure_image;
      config_image_check := configure_image;
    
      config_predictor_cmb <= configure_predictor;
      config_predictor_check := configure_predictor;
      
      config_sample_cmb <= configure_sample;
      config_sample_check:= configure_sample;
      
      --Functionality for weight vector not included yet, lines left commented.
      --if WEIGHT_INIT_GEN = 1 then
      --  if (unsigned(config_predictor_check.WEIGHT_INIT) = 1) then
      --    for i in 0 to Cz-1 loop
      --      config_cmb_WEIGHT_TAB(i)(WEIGHT_TAB_GEN(i)'high downto 0) <= WEIGHT_TAB_GEN(i)(config_cmb_WEIGHT_TAB(i)'high downto 0);
      --    end loop;
      --  end if;
      --end if;
    else
      if (en = '1') then
        --Configure from input
        config_image_cmb <= configure_image(config_in);
        config_image_var := configure_image(config_in);
        config_image_check := configure_image(config_in);
        
        config_predictor_cmb <= configure_predictor (config_in);
        config_predictor_check := configure_predictor (config_in);
        
        config_sample_cmb <= configure_sample (config_in);
        config_sample_check := configure_sample (config_in);
        --Functionality for weight vector not included yet, lines left commented.
      --  if (unsigned(config_predictor_check.WEIGHT_INIT) = 1) then
      --    for i in 0 to Cz-1 loop
      --      config_cmb_WEIGHT_TAB(i)(config_cmb_WEIGHT_TAB(i)'high downto 0) <= config_in.WEIGHT_TAB(i)(config_cmb_WEIGHT_TAB(i)'high downto 0);
      --    end loop;
      --  end if;
      end if;
    end if;
    
    -- Modified by AS: PREDICTION_TYPE = 4 (BIL-MEM) included. BIL-MEM makes use of xz_bip as it is required for the control of the external memory communications
    if PREDICTION_TYPE = 0 or PREDICTION_TYPE = 1 or PREDICTION_TYPE = 4 then
    ----------------------
      config_image_var.xz_bip  := std_logic_vector(unsigned(config_image_var.Nx)*unsigned(config_image_var.Nz));
      config_image_cmb.xz_bip <= config_image_var.xz_bip;
      config_image_cmb.number_of_samples <= std_logic_vector(unsigned(config_image_var.xz_bip)*unsigned(config_image_var.Ny));
    elsif PREDICTION_TYPE = 2 or PREDICTION_TYPE = 3 then
      config_image_var.xy_bsq :=  std_logic_vector(unsigned(config_image_var.Ny)*unsigned(config_image_var.Nx));
      config_image_cmb.xy_bsq <= config_image_var.xy_bsq;
      config_image_cmb.number_of_samples <= std_logic_vector(unsigned(config_image_var.xy_bsq)*unsigned(config_image_var.Nz));
    end if;
    
    --check for errors
    
    if (en = '1') then
      first_config_cmb <= '1'; 
      config_valid_cmb <= '0';
      -- checking errors in configuration
      if (unsigned(config_image_check.Nx) = 0 or unsigned(config_image_check.Ny) = 0 or unsigned(config_image_check.Nz) = 0) then
        error_cmb <= '1';
        error_code_cmb <= "0001";
        awaiting_config_cmb <= '1';
        -- pragma translate_off
        assert false report "Nx, Ny or Nz = 0" severity warning;
        -- pragma translate_on
      elsif (unsigned(config_image_check.Nx) < 1 or unsigned(config_image_check.Nx) > Nx_GEN or unsigned(config_image_check.Nx) > 65535) then
        error_cmb <= '1';
        error_code_cmb <= "0010";
        awaiting_config_cmb <= '1';
        -- pragma translate_off
        assert false report "Nx > than corresponding generic" severity warning;
        -- pragma translate_on
            elsif (unsigned(config_image_check.Ny) < 1 or unsigned(config_image_check.Ny) > Ny_GEN or unsigned(config_image_check.Ny) > 65535) then
        error_cmb <= '1';
        error_code_cmb <= "0010";
        awaiting_config_cmb <= '1';
        -- pragma translate_off
        assert false report "Ny > than corresponding generic" severity warning;
        -- pragma translate_on
      elsif (unsigned(config_image_check.Nz) < 1 or unsigned(config_image_check.Nz) > Nz_GEN or unsigned(config_image_check.Nz) > 65535) then
        error_cmb <= '1';
        error_code_cmb <= "0010";
        awaiting_config_cmb <= '1';
        -- pragma translate_off
        assert false report "Nz > than corresponding generic" severity warning;
        -- pragma translate_on
      elsif (unsigned(config_image_check.D) > D_GEN or unsigned(config_image_check.D)  < 2 or unsigned(config_image_check.D)  > 16) then
        error_cmb <= '1';
        error_code_cmb <= "0010";
        awaiting_config_cmb <= '1';
        -- pragma translate_off
        assert false report "D > than corresponding generic" severity warning;
        -- pragma translate_on
      elsif (unsigned(config_predictor_check.P) < 0 or unsigned(config_predictor_check.P) > P_MAX or unsigned(config_predictor_check.P) > 15) then
        error_cmb <= '1';
        error_code_cmb <= "0010";
        awaiting_config_cmb <= '1';
        -- pragma translate_off
        assert false report "P > than corresponding generic" severity warning;
        -- pragma translate_on
      elsif (unsigned(config_predictor_check.OMEGA) < 4 or unsigned(config_predictor_check.OMEGA) > OMEGA_GEN or unsigned(config_predictor_check.OMEGA) > 19) then
        error_cmb <= '1';
        error_code_cmb <= "0010";
        awaiting_config_cmb <= '1';
        -- pragma translate_off
        assert false report "OMEGA > than corresponding generic" severity warning;
        -- pragma translate_on
      elsif (unsigned(config_predictor_check.R) < maximum(32, to_integer((unsigned(config_image_check.D) + unsigned(config_predictor_check.OMEGA)+2))) or unsigned(config_predictor_check.R) > R_GEN or unsigned(config_predictor_check.R) > 64) then
        error_cmb <= '1';
        error_code_cmb <= "0010";
        awaiting_config_cmb <= '1';
        -- pragma translate_off
        assert false report "R > than corresponding generic" severity warning;
        -- pragma translate_on
      elsif (signed(config_predictor_check.VMIN) < -6 or signed(config_predictor_check.VMIN) < to_signed(VMIN_GEN, config_predictor_check.VMIN'length) or signed(config_predictor_check.VMIN) > signed(config_predictor_check.VMAX)) then
        error_cmb <= '1';
        error_code_cmb <= "0010";
        awaiting_config_cmb <= '1';
        -- pragma translate_off
        assert false report "VMIN < than corresponding generic" severity warning;
        -- pragma translate_on
      elsif (signed(config_predictor_check.VMAX) < signed(config_predictor_check.VMAX) or signed(config_predictor_check.VMIN) > VMAX_GEN or signed(config_predictor_check.VMAX) > 9) then
        error_cmb <= '1';
        error_code_cmb <= "0010";
        awaiting_config_cmb <= '1';
        -- pragma translate_off
        assert false report "VMAX > than corresponding generic" severity warning;
        -- pragma translate_on
      elsif (unsigned(config_predictor_check.TINC) < 4 or unsigned(config_predictor_check.TINC) > T_INC_GEN or unsigned(config_predictor_check.TINC) > 11) then
        error_cmb <= '1';
        error_code_cmb <= "0010";
        awaiting_config_cmb <= '1';
        -- pragma translate_off
        assert false report "TINC > than corresponding generic" severity warning;
        -- pragma translate_on
      elsif (unsigned(config_image_check.ENCODER_SELECTION) = 1 and (unsigned(config_image_check.W_BUFFER) < (unsigned(config_image_check.D) + unsigned(config_sample_check.U_MAX)) or unsigned(config_image_check.W_BUFFER) > W_BUFFER_GEN)) then --this only affects sample_adaptive
        error_cmb <= '1';
        error_code_cmb <= "0011";
        awaiting_config_cmb <= '1';
        -- pragma translate_off
        assert false report "W_BUFFER > than corresponding generic" severity warning;
        -- pragma translate_on
      elsif (W_BUFFER_GEN < (D_GEN + U_MAX_GEN) or W_BUFFER_GEN > 64) then
        error_cmb <= '1';
        error_code_cmb <= "0100";
        awaiting_config_cmb <= '1';
        -- pragma translate_off
        assert false report "incorrect W_BUFFER > than corresponding generic" severity warning;
        -- pragma translate_on
      elsif (unsigned(config_predictor_check.WEIGHT_INIT) = 1 and (unsigned(config_predictor_check.Q) < 0 or unsigned(config_predictor_check.Q) > (unsigned(config_predictor_check.OMEGA) + 3))) then
          error_cmb <= '1';
          error_code_cmb <= "0010";
          awaiting_config_cmb <= '1';
          -- pragma translate_off
          assert false report "Q > than corresponding generic" severity warning;
          -- pragma translate_on
      -- See if there are errors for sample-adaptive only if sample-adaptive is selected
      elsif (unsigned(config_image_check.ENCODER_SELECTION) = 1 and (unsigned(config_sample_check.INIT_COUNT_E) < 1 or unsigned(config_sample_check.INIT_COUNT_E) > INIT_COUNT_E_GEN or unsigned(config_sample_check.INIT_COUNT_E) > 8)) then
        error_cmb <= '1';
        error_code_cmb <= "0010";
        awaiting_config_cmb <= '1';
        -- pragma translate_off
        assert false report "INIT_COUNT_E > than corresponding generic" severity warning;
        -- pragma translate_on
      elsif (unsigned(config_image_check.ENCODER_SELECTION) = 1 and (unsigned(config_sample_check.ACC_INIT_CONST) < 0 or unsigned(config_sample_check.ACC_INIT_CONST) > ACC_INIT_CONST_GEN or unsigned(config_sample_check.INIT_COUNT_E) > (unsigned(config_image_check.D) - 2))) then
        error_cmb <= '1';
        error_code_cmb <= "0010";
        awaiting_config_cmb <= '1';
        -- pragma translate_off
        assert false report "ACC_INIT_CONST > than corresponding generic" severity warning;
        -- pragma translate_on
      elsif (unsigned(config_image_check.ENCODER_SELECTION) = 1 and (unsigned(config_sample_check.RESC_COUNT_SIZE) < (maximum(4, to_integer(unsigned(config_sample_check.INIT_COUNT_E) + 1))) or unsigned(config_sample_check.RESC_COUNT_SIZE) > RESC_COUNT_SIZE_GEN or unsigned(config_sample_check.RESC_COUNT_SIZE) > 9)) then
        error_cmb <= '1';
        error_code_cmb <= "0010";
        awaiting_config_cmb <= '1';
        -- pragma translate_off
        assert false report "RESC_COUNT_SIZE > than corresponding generic" severity warning;
        -- pragma translate_on
      elsif (unsigned(config_image_check.ENCODER_SELECTION) = 1 and (unsigned(config_sample_check.U_MAX) < 8 or unsigned(config_sample_check.U_MAX) > U_MAX_GEN or unsigned(config_sample_check.U_MAX) > 32)) then
        error_cmb <= '1';
        error_code_cmb <= "0010";
        awaiting_config_cmb <= '1';
        -- pragma translate_off
        assert false report "U_MAX > than corresponding generic" severity warning;
        -- pragma translate_on
      else
        error_cmb <= '0';
        error_code_cmb <= "0000";
        awaiting_config_cmb <= '0';
        config_valid_cmb <= '1';
      end if;   
    end if;
  end process;

  
end arch;