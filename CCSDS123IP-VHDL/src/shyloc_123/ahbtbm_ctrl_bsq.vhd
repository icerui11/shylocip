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
-- Design unit  : AHB master controller. 
--
-- File name    : ahbtbm_ctrl_bsq.vhd
--
-- Purpose      : Control for accesing an external memory through AHB.
--
-- Note         : 
--
-- Library      : 
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
--
--============================================================================

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library shyloc_utils;

library shyloc_123;
use shyloc_123.ccsds_ahb_types.all;
use shyloc_123.ahb_utils.all;
use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all; 

--!@file #ahbtbm_ctrl_bsq.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Control for accessing an external memory through AHB.
--!@details Shares values with IP cores using asynchronous FIFOs. Includes different architectures for BSQ and BIP. 
--!@details Calculates and and generates the addresses. 

entity ahbtbm_ctrl_bsq is
  generic (
    EDAC: integer := 0;
  W   : integer := 32;    --! Data bitwdith of the AHB bus. 
  Nx: integer := 3;         --! Number of columns in the hyperspectral cube. 
  Ny: integer := 3;       --! Number of lines in the hyperspectral cube. 
  Nz: integer := 4;       --! Number of bands in the hyperspectral cube. 
  NBP: integer := 3       --! Number of previous bands used for prediction. 
  );  
  port (
    rst_ahb   : in  std_ulogic;             --! AHB reset, active low. 
    clk_ahb   : in  std_ulogic;             --! AHB clock,. 
  
  rst_s: in std_logic;                --! IP core reset, active low. 
  clk_s: in std_logic;                --! IP core clock. 
  
  clear_s: in std_logic;                --! Clear signal, active high. Clocked with clk_s.
  ahbm_status: out ahbm_123_status;         --! AHB status signals. Clocked with clk_s.
  config_valid_s: in std_logic;           --! Config valid signal. Clocked with clk_s.
  
  config_image_s: in config_123_image;        --! Image configuration values. Clocked with clk_s.
  config_predictor_s: in config_123_predictor;    --! Prediction configuration values. Clocked with clk_s.
  
  config_ahbm: in config_123_ahbm;          --! AHB master configuration values.
  
  done: out std_logic;                --! Done flag, active high. Clocked with clk_s.
  
  data_out_in: in std_logic_vector (W-1 downto 0);  --! Data to be written in external memory. 
  rd_in: out std_logic;               --! Read enable for asynchronous FIFO. 
  empty_in: in std_logic;               --! Empty flag of asynchronous FIFO. 
  
  data_in_out : out std_logic_vector (W-1 downto 0);  --! Data read from external memory. 
  wr_out: out std_logic;                --! Write enable for asynchronous FIFO. 
  full_out: in std_logic;               --! Full flag of asynchronous FIFO.
  hfull_out: in std_logic;              --! Half Full flag of asynchronous FIFO.
  
    ctrli : out  ahbtbm_ctrl_in_type;         --! Control signals to communicate with AHB master module. 
    ctrlo : in ahbtbm_ctrl_out_type           --! Control signals to communicate with AHB master module. 
    );
end;  

--!@brief Architecture definition when the samples are compressed in BSQ order. 
architecture arch_shyloc_bsq of ahbtbm_ctrl_bsq is  
  -- control registers for AHB 
   signal ctrl, ctrl_reg  : ahbtb_ctrl_type;
   -- state type for FSMs
   type state_type is (idle, s0, s1, s2, s3, s4, s5, clear);
   signal state_reg, state_next: state_type;
   signal state_reg_ahbw, state_next_ahbw: state_type;
   
   -- Array type for data burst
   type array_type is array (0 to 7) of  std_logic_vector(31 downto 0);
   signal data_burst, data_burst_cmb: array_type;
   
   -- Number of uninterrupted read operations that can be performed
   signal n_reads, n_reads_cmb: unsigned(31 downto 0);
   signal n_reads_next_band_cmb, n_reads_next_band : unsigned(31 downto 0);
   -- Number of uninterrupted read operations that can be performed
   signal n_writes, n_writes_cmb: unsigned(31 downto 0);
   
    -- Counters for the number of samples read.
   signal samples_read, samples_read_cmb, samples_written, samples_written_cmb: unsigned(31 downto 0);
   -- Write address
   signal address_write, address_write_cmb   : std_logic_vector(31 downto 0);
    -- Read address
   signal address_read, address_read_cmb, address_read_init, address_read_init_cmb   : std_logic_vector(31 downto 0);
   
    -- Data to be written/ read
   signal data,  data_cmb        : std_logic_vector(31 downto 0);
   signal size, size_cmb         : std_logic_vector(1 downto 0);
   signal htrans, htrans_cmb     : std_logic_vector(1 downto 0);
   signal hburst, hburst_cmb     : std_logic;  
   signal debug, debug_cmb       : integer;
   -- if 0, next address stage takes place in the next cycle
   signal appidle, appidle_cmb   : boolean;
   
   --Trigger a write or read operation
   signal ahbwrite, ahbwrite_cmb, ahbread_cmb, ahbread : std_logic;
   --Counters
   signal counter, counter_reg, frame_counter_write_cmb, frame_counter_write_reg, z_counter, z_counter_cmb, beats, beats_reg, vector_counter, vector_counter_reg: unsigned(31 downto 0);
   signal frame_counter_read_cmb, frame_counter_read_reg, z_counter_read, z_counter_read_cmb: unsigned(31 downto 0);
   signal count_burst, count_burst_cmb, burst_size, burst_size_cmb: unsigned (31 downto 0);
   -- Read flag for FIFO
   signal rd_in_reg, rd_in_out, allow_read, allow_read_reg, allow_write: std_logic;
   
   -- Adapted clear to AHB clk. 
   signal clear_ahb: std_logic;
   -- Adapted config valid to AHB clk. 
   signal config_valid_adapted_ahb: std_logic;
    -- AHB status information
   signal ahb_status_s, ahb_status_ahb_cmb, ahb_status_ahb_reg: ahbm_123_status;
   -- Signals if the addresses need to be wrapped. 
   signal wrap_condition, wrap_condition_cmb: signed (6 downto 0);
  
  -- EDAC signals
   signal EDACDout:    std_logic_vector(0 to 63)     := (others => '0');        -- Output data word
   signal EDACPout:    std_logic_vector(0 to 7)      := (others => '0');        -- Output check bits
   signal EDACDin:    std_logic_vector(0 to 63)     := (others => '0');         -- Input data word
   signal EDACPin:    std_logic_vector(0 to 7)      := (others => '0');         -- Input check bits
   signal EDACCorr:    std_logic_vector(0 to 63)     := (others => '0');        -- Corrected data
   signal EDACsErr:    Std_ULogic := '0';                               -- Single error
   signal EDACdErr:    Std_ULogic := '0';                               -- Double error
   signal EDACuErr:    Std_ULogic := '0';                               -- Uncorrectable error
   
   -- signals for EDAC
   signal data_out_in_edac: std_logic_vector (W-1 downto 0);
   signal wr_out_edac: std_logic;
   
begin
  ----------------------------------------------------------------------------- 
  -- Output assignments
  ----------------------------------------------------------------------------- 
  ctrli <= ctrl.i;
  ctrl.o <= ctrlo;
  rd_in <= rd_in_out;

  gen_edac: if EDAC = 2 or EDAC = 3 generate
    ----------------------------------------------------------------------------- 
    --!@brief EDAC instantiation.
    ----------------------------------------------------------------------------- 
    edac_core_out: entity shyloc_utils.EDAC_RTL(RTL)
    generic map(EDACType => 5)  -- EDAC type selection
    port map(
        DataOut => EDACDout,
        CheckOut => EDACPout,
        DataIn => EDACDin, 
        CheckIn => EDACPin, 
        DataCorr => EDACCorr, 
        SingleErr => EDACsErr, 
        DoubleErr => EDACdErr,
        MultipleErr => EDACuErr);                   -- Uncorrectable error
    
    EDACDout(0 to 23) <= data_out_in(23 downto 0);
    data_out_in_edac(23 downto 0) <= data_out_in(23 downto 0);
    data_out_in_edac(27 downto 24) <= EDACPout(0 to 3);
    data_out_in_edac(31 downto 28) <= (others => '0');
    
    EDACDin(0 to 23) <= ctrl.o.hrdata(23 downto 0);
    data_in_out(31 downto 24) <= (others => '0');
    data_in_out(23 downto 0) <= EDACCorr(0 to 23);
    EDACPin(0 to 3) <= ctrl.o.hrdata(27 downto 24);
    EDACPin(0 to 3) <= (others => '0');
    -- generate edac error only if there were valid data read
    wr_out_edac <= ctrl.o.dvalid and ahb_status_ahb_reg.ahb_idle;
    wr_out <= wr_out_edac;
    ahb_status_ahb_cmb.edac_double_error <= EDACuErr when wr_out_edac = '1' else '0';
    ahb_status_ahb_cmb.edac_single_error <= EDACsErr;
  end generate gen_edac;
  
  ----------------------------------------------------------------------------- 
  --!@brief Set signals to zero when there is no EDAC
  ----------------------------------------------------------------------------- 
  
  gen_no_edac: if EDAC = 0 or EDAC = 1 generate
    --assign to zero to avoid floating warnings --
    EDACDout <= (others => '0');
    EDACPout <= (others => '0');
    EDACDin <= (others => '0');
    EDACPin <= (others => '0');
    EDACCorr <= (others => '0');
    EDACsErr <= '0';
    EDACdErr <= '0';
    EDACuErr <= '0';
    
    data_in_out <= ctrl.o.hrdata;
    --prevent writing from old requests when idle
    wr_out_edac <= ctrl.o.dvalid and ahb_status_ahb_reg.ahb_idle;
    ahb_status_ahb_cmb.edac_double_error <= '0';
    ahb_status_ahb_cmb.edac_single_error <= '0';
    data_out_in_edac <= data_out_in;
    wr_out <= wr_out_edac;
  end generate gen_no_edac;
  
  ahb_status_ahb_cmb.ahb_error <= ctrl.o.status.err;
  ahbm_status.ahb_idle <= not ahb_status_s.ahb_idle;
  ahbm_status.ahb_error <= ahb_status_s.ahb_error;
  ahbm_status.edac_double_error <= ahb_status_s.edac_double_error;
  
  --Check for AHB error
  --ahb_status_ahb_cmb.ahb_error <= '1' when ctrl.o.status.hresp = "01" else '0';
  
  -----------------------------------------------------------------------------
  --!@brief Toggle synchronizer for synchronous clear
  -----------------------------------------------------------------------------
  syn_clear: entity shyloc_utils.synchronizer(toggle)
  port map(
    rst => rst_s,
    clk_a => clk_s, 
    clk_b => clk_ahb,
    input_a => clear_s,
    output_b => clear_ahb
  );
  
  -----------------------------------------------------------------------------
  --!@brief Two FF synchronizer for AHB idle flag. 
  -----------------------------------------------------------------------------
  
  sync_ahbidle: entity shyloc_utils.synchronizer(two_ff)
  port map (
    rst => rst_s,
    clk_a => clk_ahb, 
    clk_b => clk_s,
    input_a => ahb_status_ahb_reg.ahb_idle,
    output_b => ahb_status_s.ahb_idle
  );
  
  -----------------------------------------------------------------------------
  --!@brief Two FF synchronizer
  -----------------------------------------------------------------------------
  
  sync_valid: entity shyloc_utils.synchronizer(two_ff)
  port map (
    rst => rst_s,
    clk_a => clk_s, 
    clk_b => clk_ahb,
    input_a => config_valid_s,
    output_b => config_valid_adapted_ahb
  );
  -----------------------------------------------------------------------------
  --!@brief Toggle for error
  -----------------------------------------------------------------------------
  
  sync_ahb_error: entity shyloc_utils.synchronizer(toggle)
  port map (
    rst => rst_s,
    clk_a => clk_ahb, 
    clk_b => clk_s,
    input_a => ahb_status_ahb_reg.ahb_error,
    output_b => ahb_status_s.ahb_error
  );
  
  -----------------------------------------------------------------------------
  --!@brief Two FF synchronizer for EDAC error
  -----------------------------------------------------------------------------
  sync_edac_error: entity shyloc_utils.synchronizer(two_ff)
  port map (
    rst => rst_s,
    clk_a => clk_ahb, 
    clk_b => clk_s,
    input_a => ahb_status_ahb_reg.edac_double_error,
    output_b => ahb_status_s.edac_double_error
  );
  
  -----------------------------------------------------------------------------
  --!@brief Two FF synchronizer for EDAC sigle error
  -----------------------------------------------------------------------------
  sync_edac_single_error: entity shyloc_utils.synchronizer(two_ff)
  port map (
    rst => rst_s,
    clk_a => clk_ahb, 
    clk_b => clk_s,
    input_a => ahb_status_ahb_reg.edac_single_error,
    output_b => ahb_status_s.edac_single_error
  );
  
  -----------------------------------------------------------------------------
  --! Registers
  -----------------------------------------------------------------------------
  
  reg: process(clk_ahb, rst_ahb)
  begin
    if rst_ahb = '0' and RESET_TYPE = 0 then
      state_reg <= idle;
      state_reg_ahbw <= idle;
      
      size <= (others => '0');
      htrans <= (others => '0');
      hburst <= '0';
      debug <= 0;
      appidle <= true;
      ahbwrite <= '0';
      ahbread <= '0';
      address_write <= (others => '0');
      address_read <= (others => '0');
      
      data <= (others => '0');
      data_burst <= (others => (others => '0'));
      count_burst <= (others => '0');
      burst_size <= (others => '0');
      rd_in_reg <= '0';
      counter_reg <= (others => '0');
      vector_counter_reg <= (others => '0');
      n_reads <= (others => '0');
      n_writes <= (others => '0');
      samples_read <=  (others => '0');
      samples_written <=  (others => '0');
      allow_read_reg <= '0';
      frame_counter_write_reg <=  (others => '0');
      z_counter <= (others => '0');
      z_counter_read <= (others => '0');
      frame_counter_read_reg <= (others => '0');
      address_read_init <= (others => '0');
      ahb_status_ahb_reg <= (others => '0');
      beats_reg <= (others => '0');
      n_reads_next_band <= (others => '0');
      wrap_condition <= (others => '0');
      ctrl_reg.i <= ctrli_idle;
      ctrl_reg.o <= ctrlo_nodrive;
    elsif clk_ahb'event and clk_ahb = '1' then
      if clear_ahb = '1' or  (rst_ahb = '0' and RESET_TYPE = 1) then
        if (clear_ahb = '1') then
          state_reg <= clear;
        else
          state_reg <= idle;
        end if;
        state_reg_ahbw <= idle;
        size <= (others => '0');
        htrans <= (others => '0');
        hburst <= '0';
        debug <= 0;
        appidle <= true;
        ahbwrite <= '0';
        ahbread <= '0';
        address_write <= (others => '0');
        address_read <= (others => '0');
        
        data <= (others => '0');
        data_burst <= (others => (others => '0'));
        count_burst <= (others => '0');
        burst_size <= (others => '0');
        rd_in_reg <= '0';
        counter_reg <= (others => '0');
        vector_counter_reg <= (others => '0');
        n_reads <= (others => '0');
        n_writes <= (others => '0');
        samples_read <=  (others => '0');
        samples_written <=  (others => '0');
        allow_read_reg <= '0';
        frame_counter_write_reg <=  (others => '0');
        z_counter <= (others => '0');
        z_counter_read <= (others => '0');
        frame_counter_read_reg <= (others => '0');
        address_read_init <= (others => '0');
        ahb_status_ahb_reg <= (others => '0');
        beats_reg <= (others => '0');
        n_reads_next_band <= (others => '0');
        wrap_condition <= (others => '0');
        ctrl_reg.i <= ctrli_idle;
        ctrl_reg.o <= ctrlo_nodrive;
      else
        state_reg <= state_next;
        state_reg_ahbw <= state_next_ahbw;
        data_burst <= data_burst_cmb; 
        size <= size_cmb;
        data <= data_cmb;
        htrans <= htrans_cmb;
        hburst <= hburst_cmb;
        debug <= debug_cmb;
        appidle <= appidle_cmb;
        ahbwrite <= ahbwrite_cmb;
        ahbread <= ahbread_cmb;
        address_write <= address_write_cmb;
        address_read <= address_read_cmb;
        count_burst <= count_burst_cmb;
        burst_size <= burst_size_cmb;
        ctrl_reg.i <= ctrl.i;
        rd_in_reg <= rd_in_out;
        counter_reg <= counter;
        vector_counter_reg <= vector_counter;
        n_reads <= n_reads_cmb;
        n_writes <= n_writes_cmb;
        samples_read <= samples_read_cmb;
        samples_written <=  samples_written_cmb;
        allow_read_reg <= allow_read;
        frame_counter_write_reg <=  frame_counter_write_cmb;
        z_counter <= z_counter_cmb;
        frame_counter_read_reg <= frame_counter_read_cmb;
        z_counter_read <= z_counter_read_cmb;
        address_read_init <= address_read_init_cmb;
        ahb_status_ahb_reg <= ahb_status_ahb_cmb;
        beats_reg <= beats;
        n_reads_next_band_cmb <= n_reads_next_band;
        wrap_condition <= wrap_condition_cmb;
        ctrl_reg.o <= ctrl.o;
      end if;
    end if; 
  end process;
  
  
  
  ----------------------------------------------------------------------------- 
  --! FSM to generate addresses and read/write orders
  ----------------------------------------------------------------------------- 
  
  comb: process (state_reg, rst_ahb, state_reg_ahbw, address_write, address_read, data, state_next_ahbw, rd_in_reg, data_out_in_edac, empty_in, counter_reg, 
      n_reads, n_writes, samples_read, frame_counter_write_reg, z_counter, frame_counter_read_reg, z_counter_read, 
      address_read_init, ahb_status_ahb_reg, config_valid_adapted_ahb, config_image_s, n_reads_next_band, config_predictor_s, hfull_out, wrap_condition,
      appidle, debug, hburst, htrans, allow_read_reg, size, beats_reg, data_burst, samples_written, vector_counter_reg, ctrl.o)
    variable data_burst_v: array_type;
    --variable read_offset, op1_nat, op2_nat: natural;
    variable read_offset, write_offset, op1, op2, op3: std_logic_vector(31 downto 0);
    variable next_read_addr: std_logic_vector (31 downto 0);
    variable n_reads_var: unsigned (31 downto 0);
    variable z_counter_read_var: unsigned(z_counter'high downto 0);
    variable P_conf: natural;
  begin
    read_offset := (others => '0');
    write_offset := (others => '0');
    state_next <= state_reg;
    address_write_cmb <= address_write;
    address_read_cmb <= address_read;
    data_cmb <= data;
    size_cmb <= size;
    htrans_cmb <= htrans;
    hburst_cmb <= hburst;
    debug_cmb <= debug;
    appidle_cmb <= appidle;
    ahbwrite_cmb <= '0';
    ahbread_cmb <= '0';
    data_burst_cmb <= data_burst;
    done <= '0';
    rd_in_out <= '0';
    counter <= counter_reg;
    vector_counter <= vector_counter_reg;
    n_reads_cmb <= n_reads;
    n_writes_cmb <= n_writes;
    samples_read_cmb <= samples_read;
    samples_written_cmb <= samples_written;
    allow_read <= '0';
    frame_counter_write_cmb <= frame_counter_write_reg;
    z_counter_cmb <= z_counter;
    frame_counter_read_cmb <= frame_counter_read_reg;
    z_counter_read_cmb <= z_counter_read;
    address_read_init_cmb <= address_read_init;
    ahb_status_ahb_cmb.ahb_idle <= ahb_status_ahb_reg.ahb_idle;
    beats <= beats_reg;
    z_counter_read_var := z_counter_read;
    n_reads_next_band_cmb <= n_reads_next_band;
    wrap_condition_cmb <= wrap_condition;
    P_conf := to_integer(unsigned(config_predictor_s.P));
    case (state_reg) is
      when clear => 
        if (config_valid_adapted_ahb = '0') then
          state_next <= idle;
        end if;
      when idle =>
        if (rst_ahb = '1' and config_valid_adapted_ahb = '1' and state_next_ahbw = s0) then
          state_next <= s1;
          counter <= (others => '0');
          -- In principle here I am sure I can capture the configuration
          --n_writes_cmb <= resize(unsigned(config_image_s.Nx)*unsigned(config_image_s.Ny), n_writes_cmb'length);
          n_writes_cmb <= resize(unsigned(config_image_s.xy_bsq), n_writes_cmb'length);
          samples_read_cmb <= (others => '0');
          address_write_cmb <= config_predictor_s.ExtMemAddress - 4;
          ahb_status_ahb_cmb.ahb_idle  <= '1';
        else
          ahb_status_ahb_cmb.ahb_idle  <= '0';
        end if;
      when s1 => 
        --master can accept new write request
        if (empty_in = '0' and state_next_ahbw = s0) then
          rd_in_out <= '1';
        end if;
        
        -- If there is nothing to write, we go and see if we find anything to read. 
        if (empty_in = '1' and unsigned(samples_written) > unsigned(samples_read)) then
          state_next <= s2;
          appidle_cmb <= true;
        end if;
        
        if (state_reg_ahbw = s0 and rd_in_reg = '1') then
          if (frame_counter_write_reg = unsigned(config_image_s.xy_bsq) -1) then
            frame_counter_write_cmb <= (others => '0');
            z_counter_cmb <= z_counter + 1; --probably we do not need this counter!
          else
            frame_counter_write_cmb <= frame_counter_write_reg + 1;
          end if;
          
          if (frame_counter_write_reg = 0) then -- reset at the beginning of frame
            -- must find a better way to compute this (using offsets or masks!)
            --write_offset := to_integer(unsigned(address_write)) - to_integer(unsigned(config_predictor_s.ExtMemAddress)) - (to_integer(unsigned(config_image_s.Nx)*unsigned(config_image_s.Ny))-1)*(P_conf+1)*4 - 4;
            --write_offset := to_integer(unsigned(address_write)) - to_integer(unsigned(config_predictor_s.ExtMemAddress)) - (to_integer(unsigned(config_image_s.xy_bsq))-1)*(P_conf+1)*4 - 4;
            op1 := address_write;
            op2 := config_predictor_s.ExtMemAddress;
            op3 := (config_image_s.xy_bsq - 1)*(P_conf+1);
            op3 := op3*4;
            op3 := op3 + 4;
            op2 := op2 + op3;
            if unsigned(op1) < unsigned(op2) then
              write_offset := P_conf*4;
            else
              write_offset := op1 - op2;
            end if;
            address_write_cmb <= config_predictor_s.ExtMemAddress + write_offset; --std_logic_vector(to_unsigned(write_offset, 32));
          else
            write_offset := (P_conf+1)*4;
            address_write_cmb <= address_write + write_offset; --std_logic_vector(to_unsigned(write_offset, 32));
          end if;
  
          data_cmb <= data_out_in_edac;
          --information i need for things to be written
          size_cmb <= "10";
          htrans_cmb <= "10";
          hburst_cmb <= '0';
          debug_cmb <= 2;
          
          --trigger the operation
          ahbwrite_cmb <= '1';      
          samples_written_cmb <= samples_written + 1;
          
          if (counter_reg < n_writes) then
            counter <= counter_reg + 1;
            --appidle control
            if (empty_in = '0') then --there will be more data in the next iteration
              appidle_cmb <= false; --appidle = false if there will be more data in the next cycle
            else
              appidle_cmb <= true;
            end if;
          else
            n_writes_cmb <= to_unsigned(0, n_reads_cmb'length);
            appidle_cmb <= true;
            counter <= (others => '0');
            state_next <= s2;
          end if;
        end if;
      -- let's read the data now
      when s2 => 
        --master can accept new read request
        -- we read and we make sure the FIFO is not full
        if (state_next_ahbw = s0 and hfull_out = '0') then --check if half full!
          allow_read <= '1';
        end if;
        
        if (hfull_out = '1' and vector_counter_reg = 0 and allow_read_reg /= '1') then
          state_next <= s1;
          appidle_cmb <= true;
        end if;
        
        if (state_reg_ahbw = s0 and allow_read_reg = '1') then
          size_cmb <= "10";
          htrans_cmb <= "10";
          -- in examples this is set to 1 but it does not make sense!
          hburst_cmb <= '0';
          debug_cmb <= 2;
          --trigger the operation
          ahbread_cmb <= '1';
          
          -- need a condition to know if i need to wrap up
          if vector_counter_reg = 0 then
            samples_read_cmb <= samples_read + 1; --count only once per vector
            --calculate initial read address
            if (frame_counter_read_reg = unsigned(config_image_s.xy_bsq) -1) then
              frame_counter_read_cmb <= (others => '0');
              --TBD: use z_counter to compute the number of iterations, i.e. n_reads, 
              -- so that it is independent from write
              z_counter_read_var := z_counter_read + 1;
              z_counter_read_cmb <= z_counter_read + 1;
            else
              frame_counter_read_cmb <= frame_counter_read_reg + 1;
            end if;
            --for the first sample in a band, reset read pointer
            if (frame_counter_read_reg = 0) then -- reset at the beginning of frame
              -- must find a better way to compute this (using offsets or masks!)
              op1:= address_read_init;
              op2 := config_predictor_s.ExtMemAddress;
              op3 := (config_image_s.xy_bsq - 1)*(P_conf+1);
              op3 := op3*4;
              op3 := op3 + 4;
              op2 := op2 + op3;
              --read_offset := to_integer(unsigned(address_read_init)) - to_integer(unsigned(config_predictor_s.ExtMemAddress)) - (to_integer(unsigned(config_image_s.xy_bsq))-1)*(P_conf+1)*4 - 4;
              if unsigned(op1) < unsigned(op2) then --condition to wrap read address
                --wrapping condition to read
                read_offset := (P_conf)*4;
              else
                read_offset := op1 - op2;
              end if;
              wrap_condition_cmb <= signed('0'&config_predictor_s.P) + 1 - signed('0'&read_offset(wrap_condition_cmb'high + 1 downto 2));
              address_read_init_cmb <= config_predictor_s.ExtMemAddress + read_offset;
              address_read_cmb <= config_predictor_s.ExtMemAddress + read_offset;
            else --if it's not the first sample in a band, move P elements forward
              read_offset := (P_conf+1)*4;
              address_read_cmb <= address_read_init + read_offset;
              address_read_init_cmb <= address_read_init + read_offset;
            end if;
          else
            --this needs to be made configurable
          --  if (address_read (3 downto 0) = "1100") then 
          --    address_read_cmb <= address_read(31 downto 4)&"0000"; --wrap read address
          --  else
          --    address_read_cmb <= address_read + x"00000004";
          --  end if;
            if to_integer(vector_counter_reg) = to_integer(wrap_condition) then
              op1:= P_conf*4;
              read_offset := address_read - op1;
              address_read_cmb <= read_offset;
              --assert address_read_cmb /= x"4000000C" report "address read is wrapped" severity failure;
            else
              address_read_cmb <= std_logic_vector(unsigned(address_read) + x"00000004");
            end if;
          end if;
          
          --Compute number of sequential reads.
          if (z_counter_read_var < unsigned(config_predictor_s.P)) then
            n_reads_var := z_counter_read_var; -- still unclear why I need one more
          else
            n_reads_var := unsigned(config_predictor_s.P) - to_unsigned(1, n_reads_cmb'length);
          end if;
          
          if (vector_counter_reg < n_reads) then -- i need to have room for n_reads in the output FIFO otherwise, stop and make an appidle!
            vector_counter <= vector_counter_reg + 1;
            if ctrl.o.update = '1' and hfull_out = '0' then
              appidle_cmb <= false;
            else
              appidle_cmb <= true;
            end if;
          else
            n_reads_cmb <= n_reads_var;
            vector_counter <= (others => '0');
            appidle_cmb <= true;
            state_next <= s1;
          end if;
        end if;
      --Burst not used for now, left here for future developments
      -- when s3 =>
      --  if (state_reg_ahbw = s0) then
      --    -- burst write 4 beats --not used now
      --    for i in 0 to 3 loop
      --      data_burst_v(i) := std_logic_vector(to_unsigned(i, data_burst_v(i)'length));
      --    end loop;
      --    data_burst_cmb <= data_burst_v;
      --    address_write_cmb <= x"40000000";
      --    size_cmb <= "10";
      --    htrans_cmb <= "10";
      --    hburst_cmb <= '1';
      --    debug_cmb <= 2;
      --    --number of beats
      --    beats <= to_unsigned(4,beats'length);
      --    ahbwrite_cmb <= '1';
      --    state_next <= s4;
      --  end if;
      --Burst not used for now, left here for future developments
      --when s4 => 
      --  if (state_reg_ahbw = s0) then
      --    -- burst read 4 beats --not used now
      --    for i in 0 to 3 loop
      --      data_burst_v(i) := std_logic_vector(to_unsigned(i, data_burst_v(i)'length));
      --    end loop;
      --    data_burst_cmb <= data_burst_v;
      --    address_read_cmb <= x"40000000";
      --    size_cmb <= "10";
      --    htrans_cmb <= "10";
      --    hburst_cmb <= '1';
      --    debug_cmb <= 2;
      --    --number of beats
      --    beats <= to_unsigned(4,beats'length);
      --    ahbread_cmb <= '1';
      --    state_next <= s5;
      --  end if;
      --when s5 =>
      --  done <= '1';
      when others => 
        state_next <= state_reg;
    end case;
  end process;
  
  
  comb_ahb: process (state_reg_ahbw, address_write_cmb, address_read_cmb, data_cmb, size_cmb, htrans_cmb, hburst_cmb, 
        debug_cmb, appidle_cmb, ahbwrite_cmb, rst_ahb, ctrl.o, ctrl_reg, ahbread_cmb, data_burst_cmb, 
        beats, count_burst, burst_size, data_burst)
  begin
    state_next_ahbw <= state_reg_ahbw;
    count_burst_cmb <= count_burst;
    burst_size_cmb <= burst_size;
    ctrl.i <= ctrl_reg.i;
    case (state_reg_ahbw) is
      when idle =>
        --ctrl.o <= ctrlo_nodrive;
        ctrl.i <= ctrli_idle;
        if (rst_ahb = '1') then
          state_next_ahbw <= s0;
        end if;
      when s0 =>
        --read
        if ahbread_cmb = '1' and ctrl.o.update = '1' then
          ctrl.i.ac.ctrl.use128 <= 0;
          ctrl.i.ac.ctrl.dbgl <= debug_cmb;
          ctrl.i.ac.hsize <= '0' & size_cmb;
          ctrl.i.ac.haddr <= address_read_cmb; 
          ctrl.i.ac.hdata <= data_cmb;
          ctrl.i.ac.htrans <= htrans_cmb; 
          ctrl.i.ac.hwrite <= '0'; 
          ctrl.i.ac.hburst <= "00" & hburst_cmb;
          ctrl.i.ac.hprot <= "1110";
          --Burst not used for now, left here for future developments
          --it is a burst
          --if (ctrl.i.ac.hburst /= "000") then
          --  ctrl.i.ac.hdata <= data_burst_cmb(0);
          --  ctrl.i.ac.htrans <= "10";
          --  count_burst_cmb <= to_unsigned(1, count_burst_cmb'length);
          --  state_next_ahbw <= s4;
          --  burst_size_cmb <= beats;
          --elsif (appidle_cmb = true) then
          if (appidle_cmb = true) then
            state_next_ahbw <= s2;
          end if;
        elsif ahbread_cmb = '1' and ctrl.o.update = '0' then
          state_next_ahbw <= s3;
        end if;
        
        --write
        if ahbwrite_cmb = '1' and ctrl.o.update = '1' then
          ctrl.i.ac.ctrl.use128 <= 0;
          ctrl.i.ac.ctrl.dbgl <= debug_cmb;
          ctrl.i.ac.hburst <= "000"; ctrl.i.ac.hsize <= '0' & size_cmb;
          ctrl.i.ac.haddr <= address_write_cmb; ctrl.i.ac.hdata <= data_cmb;
          ctrl.i.ac.htrans <= htrans_cmb; ctrl.i.ac.hwrite <= '1'; 
          ctrl.i.ac.hburst <= "00" & hburst_cmb;
          ctrl.i.ac.hprot <= "1110";
          --Burst not used for now, left here for future developments
          --it is a burst
          -- if (ctrl.i.ac.hburst /= "000") then
            -- ctrl.i.ac.hdata <= data_burst_cmb(0);
            -- ctrl.i.ac.htrans <= "10";
            -- count_burst_cmb <= to_unsigned(1, count_burst_cmb'length);
            -- state_next_ahbw <= s4;
            -- burst_size_cmb <= beats;
          -- elsif (appidle_cmb = true) then
          if (appidle_cmb = true) then
            state_next_ahbw <= s2;
          end if;
        elsif ahbwrite_cmb = '1' and ctrl.o.update = '0' then
          state_next_ahbw <= s1;
        end if;
      when s1 => 
        -- wait for ctrl.o.update = '1' to write 
        if (ctrl.o.update = '1') then
          ctrl.i.ac.ctrl.use128 <= 0;
          ctrl.i.ac.ctrl.dbgl <= debug_cmb;
          ctrl.i.ac.hburst <= "000"; ctrl.i.ac.hsize <= '0' & size_cmb;
          ctrl.i.ac.haddr <= address_write_cmb; ctrl.i.ac.hdata <= data_cmb;
          ctrl.i.ac.htrans <= htrans_cmb; ctrl.i.ac.hwrite <= '1'; 
          ctrl.i.ac.hburst <= "00" & hburst_cmb;
          ctrl.i.ac.hprot <= "1110";
          if (appidle_cmb = true) then
            state_next_ahbw <= s2;
          else
            state_next_ahbw <= s0;
          end if;
        end if;
      when s2 => 
        -- because of appidle, wait for ctrl.o.update = '1'
        if (ctrl.o.update = '1') then
          state_next_ahbw <= s0;
          ctrl.i <= ctrli_idle;         
        end if;
      when s3 =>
        -- wait for ctrl.o.update = '1' to read 
        if (ctrl.o.update = '1') then
          ctrl.i.ac.ctrl.use128 <= 0;
          ctrl.i.ac.ctrl.dbgl <= debug_cmb;
          ctrl.i.ac.hsize <= '0' & size_cmb;
          ctrl.i.ac.haddr <= address_read_cmb; 
          ctrl.i.ac.hdata <= data_cmb;
          ctrl.i.ac.htrans <= htrans_cmb; 
          ctrl.i.ac.hwrite <= '0'; 
          ctrl.i.ac.hburst <= "00" & hburst_cmb;
          ctrl.i.ac.hprot <= "1110";
          if (appidle_cmb = true) then
            state_next_ahbw <= s2;
          else
            state_next_ahbw <= s0;
          end if;
        end if;
      --Burst not used for now, left here for future developments
      -- when s4 =>
        -- if (ctrl.o.update = '1') then
          -- count_burst_cmb <= count_burst + 1;
          --count_burst + 1;
          -- ctrl.i <= ctrl_reg.i;
          -- ctrl.i.ac.htrans <= "11";
          -- ctrl.i.ac.haddr <= ctrl_reg.i.ac.haddr  + X"00000004"; 
          -- ctrl.i.ac.hdata <=  data_burst (to_integer(count_burst));
          -- if (count_burst = burst_size - 1) then
            -- state_next_ahbw <= s2;
          -- end if;
        -- else
          -- ctrl.i <= ctrl_reg.i;
        -- end if;  
      when others => 
        state_next_ahbw <= idle;
    end case;
  end process;
  
end arch_shyloc_bsq; --============================================================================  
