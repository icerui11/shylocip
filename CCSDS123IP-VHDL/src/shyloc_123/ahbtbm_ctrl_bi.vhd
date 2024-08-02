--============================================================================--
-- Design unit  : AHB master controller for bip and bil architectures. 
--
-- File name    : ahbtbm_ctrl_bi.vhd
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
--!@details Shares values with IP cores using asynchronous FIFOs. Includes different architectures for BSQ and BIP/BIL. 
--!@details Calculates and and generates the addresses. 

entity ahbtbm_ctrl_bi is
  generic (
  W    : integer := 32;    --! Data bitwdith of the AHB bus. 
  Nx: integer := Nx_GEN;          --! Number of columns in the hyperspectral cube. 
  Ny: integer := Ny_GEN;        --! Number of lines in the hyperspectral cube. 
  Nz: integer := Nz_GEN;        --! Number of bands in the hyperspectral cube. 
  NBP: integer := P_MAX        --! Number of previous bands used for prediction. 
  );   
  port (
    rst_ahb   : in  std_ulogic;              --! AHB reset, active low. 
    clk_ahb   : in  std_ulogic;              --! AHB clock. 
  
  rst_s: in std_logic;                --! IP core reset, active low. 
  clk_s: in std_logic;                --!  IP core clock. 
  
  clear_s: in std_logic;                --! Clear signal, active high. Clocked with clk_s.
  ahbm_status: out ahbm_123_status;          --! AHB status signals. Clocked with clk_s.
  config_valid_s: in std_logic;            --! Config valid signal. Clocked with clk_s.
  
  config_image_s: in config_123_image;        --! Image configuration values. Clocked with clk_s.
  config_predictor_s: in config_123_predictor;    --! Prediction configuration values. Clocked with clk_s.
  
  config_ahbm: in config_123_ahbm;          --! AHB master configuration values.
  
  done: out std_logic;                 --! Done flag, active high. Clocked with clk_s.
  
  data_out_in: in std_logic_vector (W-1 downto 0);  --! Data to be written in external memory. 
  rd_in: out std_logic;                --! Read enable for asynchronous FIFO. 
  empty_in: in std_logic;                --! Empty flag of asynchronous FIFO. 
  
  data_in_out : out std_logic_vector (W-1 downto 0);  --! Data read from external memory. 
  wr_out: out std_logic;                --! Write enable for asynchronous FIFO. 
  full_out: in std_logic;                --! Full flag of asynchronous FIFO.
  hfull_out: in std_logic;              --! Half Full flag of asynchronous FIFO.
  
    ctrli : out  ahbtbm_ctrl_in_type;          --! Control signals to communicate with AHB master module. 
    ctrlo : in ahbtbm_ctrl_out_type            --! Control signals to communicate with AHB master module. 
    );
end;  

-----------------------------------------------------------------------------
--!@brief Architecture definition when the samples are compressed in BIL order.
-----------------------------------------------------------------------------
  
architecture arch_shyloc of ahbtbm_ctrl_bi is
  -- control registers for AHB 
  signal ctrl, ctrl_reg  : ahbtb_ctrl_type;
  -- state type for FSMs
  type state_type is (idle, s0, s1, s2, s3, s4, s5, clear);
  signal state_reg, state_next: state_type;
  signal state_reg_ahbw, state_next_ahbw: state_type;
  
  -- Number of uninterrupted read operations that can be performed. Modified by AS: signals resized from 32 to 8 bits
  signal n_reads, n_reads_cmb: unsigned(7 downto 0);
  
  -- Number of uninterrupted write operations that can be performed. Modified by AS: Signal width depending on compile-time parameters (instead of 32 fixed size)
  signal n_writes, n_writes_cmb: unsigned((W_Nx_GEN + W_Nz_GEN - 1) downto 0);
  -- Modified by AS: new signal to compute the initial number of writes, depending on target architecture. (new) Signal width depending on compile-time parameters (instead of 32 fixed size)
  signal n_init_writes: unsigned((W_Nx_GEN + W_Nz_GEN) - 1 downto 0);
  ---------------------
  -- Counters for the number of samples read. Modified by AS: Signal width depending on compile-time parameters (instead of 32 fixed size). Counters for the number of samples written removed
  signal samples_read, samples_read_cmb: unsigned((W_Nx_GEN + W_Ny_GEN + W_Nz_GEN - 1) downto 0);
  -- Modified by AS: new signals to improve timing
  signal remaining_reads, remaining_reads_cmb, remaining_writes, remaining_writes_cmb: unsigned((W_Nx_GEN + W_Ny_GEN + W_Nz_GEN - 1) downto 0);    -- Total number of samples pending to read/write (reverse sample counters)
  signal WR_gap, WR_gap_cmb: unsigned((W_Nx_GEN + W_Nz_GEN) - 1 downto 0);    -- Gap between the number of written and read samples
  ---------------------
  -- Write address
    signal address_write, address_write_cmb   : std_logic_vector(31 downto 0);
  -- Read address
  signal address_read, address_read_cmb   : std_logic_vector(31 downto 0);
  -- Data to be written/ read
    signal data,  data_cmb        : std_logic_vector(31 downto 0);
    signal size, size_cmb         : std_logic_vector(1 downto 0);
    signal htrans, htrans_cmb     : std_logic_vector(1 downto 0);
    signal hburst, hburst_cmb     : std_logic;
    signal debug, debug_cmb       : integer;
  -- if 0, next address stage takes place in the next cycle
    signal appidle, appidle_cmb   : boolean;
  -- Modified by AS: new signal to know if the written/read value has been consumed
  signal data_valid, data_valid_cmb  : std_logic;
  -------------------------------
  
  --Trigger a write or read operation
  signal ahbwrite, ahbwrite_cmb, ahbread_cmb, ahbread : std_logic;
  --Counters
  -- Modified by AS: Counter width depending on compile-time parameters (instead of 32 fixed size)
  -- Modified by AS: new reverse counters in exchange of counter and counter_reg
  signal rev_counter, rev_counter_reg: unsigned((W_Nx_GEN + W_Nz_GEN - 1) downto 0);
  -- Modified by AS: beats, count_burst and burst_size widths reduced from 32 to 5 bits
  signal count_burst, count_burst_cmb, burst_size, burst_size_cmb, beats, beats_reg: unsigned (4 downto 0);
  ------------------
  
  -- Read flag for FIFO - allow reading from FIFO
  signal rd_in_reg, rd_in_out, allow_read, allow_read_reg: std_logic;
     
    -- Adapted clear to AHB clk. 
  signal clear_ahb: std_logic;
  -- Adapted config valid to AHB clk. 
  signal config_valid_adapted_ahb: std_logic;
  -- AHB status information
  signal ahb_status_s, ahb_status_ahb_cmb, ahb_status_ahb_reg: ahbm_123_status;

  -- EDAC signals 
   signal EDACDout:    std_logic_vector(0 to 63)     := (others => '0');        -- Output data word
   signal EDACPout:    std_logic_vector(0 to 7)      := (others => '0');        -- Output check bits
   signal EDACDin:    std_logic_vector(0 to 63)     := (others => '0');         -- Input data word
   signal EDACPin:    std_logic_vector(0 to 7)      := (others => '0');         -- Input check bits
   signal EDACCorr:    std_logic_vector(0 to 63)     := (others => '0');        -- Corrected data
   signal EDACsErr:    Std_ULogic := '0';                                -- Single error
   signal EDACdErr:    Std_ULogic := '0';                               -- Double error
   signal EDACuErr:    Std_ULogic := '0';                                -- Uncorrectable error
      
   -- signals for EDAC
   signal data_out_in_edac: std_logic_vector (W-1 downto 0);
   signal wr_out_edac: std_logic;
   signal interleave, interleave_cmb: std_logic;
begin
  -----------------------------------------------------------------------------  
  -- Output assignments
  -----------------------------------------------------------------------------
  ctrli <= ctrl.i;
  ctrl.o <= ctrlo;
  rd_in <= rd_in_out;
  
  gen_edac: if EDAC = 2 or EDAC = 3 generate
  
    edac_core_out: entity shyloc_utils.EDAC_RTL(RTL)
    -----------------------------------------------------------------------------
    --!@brief EDAC instantiation.
    -----------------------------------------------------------------------------
    generic map(EDACType => 5)  -- EDAC type selection, corrects 1 error, detects 2 on 24 bits. 
    port map(
        DataOut => EDACDout,
        CheckOut => EDACPout,
        DataIn => EDACDin, 
        CheckIn => EDACPin, 
        DataCorr => EDACCorr, 
        SingleErr => EDACsErr, 
        DoubleErr => EDACdErr,
        MultipleErr => EDACuErr);
    
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
    wr_out_edac <= ctrl.o.dvalid and ahb_status_ahb_reg.ahb_idle and not clear_ahb;
    wr_out <= wr_out_edac;
    ahb_status_ahb_cmb.edac_double_error <= EDACuErr when wr_out_edac = '1' else '0';
    ahb_status_ahb_cmb.edac_single_error <= EDACsErr;
  end generate gen_edac;
  
  -----------------------------------------------------------------------------
  --!@brief Values set to zero when EDAC is not instantiated. 
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
    wr_out_edac <= ctrl.o.dvalid and ahb_status_ahb_reg.ahb_idle and not clear_ahb;
    ahb_status_ahb_cmb.edac_double_error <= '0';
    ahb_status_ahb_cmb.edac_single_error <= '0';
    data_out_in_edac <= data_out_in;
    wr_out <= wr_out_edac;
  end generate gen_no_edac;
  
  --check for ahb error
  --ahb_status_ahb_cmb.ahb_error <= '1' when ctrl.o.status.hresp = "01" else '0';
  
  --check for ahb error (NOTE THAT THIS IS DONE DIFFERENTLY FOR BSQ - WHICH ONE IS THE GOOD ONE?)
  ahb_status_ahb_cmb.ahb_error <= ctrl.o.status.err;
  ahbm_status.ahb_idle <= not ahb_status_s.ahb_idle;
  ahbm_status.ahb_error <= ahb_status_s.ahb_error;
  ahbm_status.edac_double_error <= ahb_status_s.edac_double_error;
  
  -----------------------------------------------------------------------------
  --!@brief Toggle synchronizer for clear signal
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
  --!@brief Two FF synchronizer for ahb_idle
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
  --!@brief Toggle synchronizer for AHB error
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
      count_burst <= (others => '0');
      burst_size <= (others => '0');
      rd_in_reg <= '0';
      n_reads <= (others => '0');
      n_writes <= (others => '0');
      samples_read <=  (others => '0');
      allow_read_reg <= '0';
      ahb_status_ahb_reg <= (others => '0');
      beats_reg <= (others => '0');
      ctrl_reg.i <= ctrli_idle;
      ctrl_reg.o <= ctrlo_nodrive;
      interleave <= '0';
      -- Modified by AS: reset of new signals --
      data_valid <= '0';
      remaining_reads <= (others => '0');
      remaining_writes <= (others => '0');
      WR_gap <= (others => '0');
      rev_counter_reg <= (others => '0');
      --------------------------------------
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
        count_burst <= (others => '0');
        burst_size <= (others => '0');
        rd_in_reg <= '0';
        n_reads <= (others => '0');
        n_writes <= (others => '0');
        samples_read <=  (others => '0');
        allow_read_reg <= '0';
        ahb_status_ahb_reg <= (others => '0');
        beats_reg <= (others => '0');
        ctrl_reg.i <= ctrli_idle;
        ctrl_reg.o <= ctrlo_nodrive;
        interleave <= '0';
        -- Modified by AS: reset of new signals --
        data_valid <= '0';
        remaining_reads <= (others => '0');
        remaining_writes <= (others => '0');
        WR_gap <= (others => '0');
        rev_counter_reg <= (others => '0');
        --------------------------------------
      else
        state_reg <= state_next;
        state_reg_ahbw <= state_next_ahbw;
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
        -- modified by AS: rd_in_reg and allow_read_reg updated just when ctrlo.update = 1 --
        if (ctrl.o.update = '1') then
          rd_in_reg <= rd_in_out;
          allow_read_reg <= allow_read;
        end if;
        ------------------------------------------------------------
        n_reads <= n_reads_cmb;
        n_writes <= n_writes_cmb;
        samples_read <= samples_read_cmb;
        ahb_status_ahb_reg <= ahb_status_ahb_cmb;
        beats_reg <= beats;
        ctrl_reg.o <= ctrl.o;
        interleave <= interleave_cmb;
        -- Modified by AS: register new signals --
        data_valid <= data_valid_cmb;
        remaining_reads <= remaining_reads_cmb;
        remaining_writes <= remaining_writes_cmb;
        WR_gap <= WR_gap_cmb;
        rev_counter_reg <= rev_counter;
        --------------------------------------
      end if;
    end if;  
  end process;
  
  -- Modified by AS: compute the initial number of writes depending on the target architecture
  n_init_w_bip: if (PREDICTION_TYPE /= 4) generate
    n_init_writes <= resize(unsigned(config_image_s.xz_bip) - unsigned(config_image_s.Nx) - unsigned(config_image_s.Nz-x"00000001"), n_writes_cmb'length);
  end generate n_init_w_bip;
  n_init_w_bil: if (PREDICTION_TYPE = 4) generate
    n_init_writes <= resize(unsigned(config_image_s.xz_bip) - unsigned(config_image_s.Nx) - to_unsigned(1, config_image_s.xz_bip'length), n_writes_cmb'length);
  end generate n_init_w_bil;
  --------------------
  
  -----------------------------------------------------------------------------  
  --! FSM to generate addresses and read/write orders
  -----------------------------------------------------------------------------  

  -- Modified by AS: signals count_burst_cmb and ctrl.o.update included in the sensitivity list. Data_burst removed from the sensitivity list --
  -- (new): signals remaining_reads, remaining_writes, WR_gap, data_valid, rev_counter_reg and n_init_writes included in the sensitivity list. Signals counter_reg, samples_written removed from the sensitivity list
  comb: process (state_reg, rst_ahb, state_reg_ahbw, state_next_ahbw, address_write, address_read, data, rd_in_reg, data_out_in_edac, empty_in, count_burst_cmb,
      n_reads, n_writes, samples_read, ahb_status_ahb_reg, config_valid_adapted_ahb, config_image_s, config_predictor_s, hfull_out, allow_read_reg, 
      size, htrans, hburst, debug, appidle, beats_reg, interleave, ctrl.o.update, remaining_reads, remaining_writes, WR_gap, data_valid, rev_counter_reg, n_init_writes)
    variable beats_v: unsigned(4 downto 0);      -- Modified by AS: beats_v resized from 32 to 5 bits
    variable data_valid_v: std_logic;        -- Modified by AS: New variable for data_valid
  begin    
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
    done <= '0';
    rd_in_out <= '0';
    n_reads_cmb <= n_reads;
    n_writes_cmb <= n_writes;
    samples_read_cmb <= samples_read;
    allow_read <= '0';
    ahb_status_ahb_cmb.ahb_idle <= ahb_status_ahb_reg.ahb_idle;
    beats <= beats_reg;
    interleave_cmb <= interleave;
    -- Modified by AS: new signals default assignment --
    data_valid_v := data_valid;
    remaining_reads_cmb <= remaining_reads;
    remaining_writes_cmb <= remaining_writes;
    WR_gap_cmb <= WR_gap;
    rev_counter <= rev_counter_reg;
    --------------------------------------
    
    case (state_reg) is
      when clear => 
        if config_valid_adapted_ahb = '0' then
          state_next <= idle;
        end if;
      when idle =>
        if (rst_ahb = '1' and config_valid_adapted_ahb = '1' and state_reg_ahbw = s0) then
          state_next <= s1;
          --note: I'm ahead Nz-1 samples... at the end, when I calculate how many samples in a row I need to read. Take this into consideration
          -- Modified by AS: initial number of writes specific for each architecture, (new): reverse counter initialized
          n_writes_cmb <= n_init_writes;
          rev_counter <= n_init_writes;
          -------------------------------
          samples_read_cmb <= (others => '0');
          address_write_cmb <= config_predictor_s.ExtMemAddress - x"00000004";
          ahb_status_ahb_cmb.ahb_idle  <= '1';
          -- Modified by AS: Initialization of reverse sample counters and read/write gap
          remaining_reads_cmb <= resize(unsigned(config_image_s.number_of_samples) - unsigned(config_image_s.xz_bip), remaining_reads'length);
          remaining_writes_cmb <= resize(unsigned(config_image_s.number_of_samples) - unsigned(config_image_s.xz_bip), remaining_writes'length);
          WR_gap_cmb <= (others => '0');
          -------------------------------
        else
          ahb_status_ahb_cmb.ahb_idle  <= '0';
        end if;
      when s1 =>  -- write request
        -- Modified by AS: compute the number of beats (burst length) of the next write operation
        -- Modified by AS (new): if-else tree modified to adapt to the new size of beats_v. To_unsigned used instead of to_integer and use of reverse counters to simplify math operations
        if interleave = '0' then
          if (to_unsigned(HMAXBURST_123, rev_counter'length) < rev_counter_reg) then
            beats_v := to_unsigned(HMAXBURST_123, beats_v'length);
          else
            beats_v := resize(rev_counter_reg, beats_v'length);
          end if;
        else
          if (to_unsigned(HMAXBURST_123, remaining_writes'length) < remaining_writes) then
            beats_v := to_unsigned(HMAXBURST_123, beats_v'length);
          else
            beats_v := resize(remaining_writes, beats_v'length);
          end if;
        end if;
        beats <= beats_v;
        -----------------------------
        --master can accept new write request
        -- Modified by AS: valid address phase and data were not correctly signaled. it is necessary to correctly manage the burst transaction --
        -- Modified by AS (new) : check for ctrlo.updated included --
        if (empty_in = '0' and ctrl.o.update = '1' and (state_next_ahbw = s0 or state_next_ahbw = s4)) then
          data_valid_v := '1';
        -----------------------------
          rd_in_out <= '1';
        end if;
        -- we cannot write, but we might be able to read
        -- Modified by AS: condition modified to preserve a gap between the number of reads and writes. No changes while ctrl.o.update = '0'. (new): Math operation simplified with the WR gap (could the rest of terms be equal to n_init_writes???)
        if empty_in /= '0' and interleave = '1' and ctrl.o.update = '1' and (WR_gap > unsigned(config_image_s.xz_bip) - unsigned(config_image_s.Nx) + to_unsigned(1, config_image_s.xz_bip'length)) then
        ------------------------
          state_next <= s2;
          appidle_cmb <= true;
        end if;
        if (state_reg_ahbw = s0 and rd_in_reg = '1' and ctrl.o.update = '1') then  -- Modified by AS: No changes while ctrl.o.update = '0'
          data_valid_v := '0';
          --condition to wrap read address (can be changed to a power of two)
          if unsigned(address_write) = unsigned(config_predictor_s.ExtMemAddress) + unsigned(config_image_s.xz_bip)*4 then
            address_write_cmb <= config_predictor_s.ExtMemAddress;
          else
            address_write_cmb <= address_write + x"00000004";
          end if;
          data_cmb <= data_out_in_edac;
          --information i need for things to be written
          size_cmb <= "10";
          htrans_cmb <= "10";
          hburst_cmb <= '0';
          -- Modified by AS: initiating burst operation if there are enough data pending --
          if unsigned(beats_v) > 1 then
            hburst_cmb <= '1';
            state_next <= s3;
          end if;
          -----------------------------
          debug_cmb <= 2;
          
          --trigger the operation
          ahbwrite_cmb <= '1';
          -- Modified by AS: new counters updated --
          remaining_writes_cmb <= remaining_writes - 1;
          WR_gap_cmb <= WR_gap + 1;
          -- Modified by AS: condition updated (new): condition reversed and simplified with reverse counter --
          if (rev_counter_reg <= to_unsigned(1, rev_counter'length)) then
            interleave_cmb <= '1';
            -- Modified by AS: the number of consecutive read/write operations when there is interleaving now depends on HMAXBURST_123 (instead of being fixed to 8) --
            -- Modified by AS (new): Math operations replaced with reverse counters. Reverse counter updating.
            if (to_unsigned(HMAXBURST_123, WR_gap'length) > WR_gap) then  -- condition to avoid reading samples which have not been yet processed
              n_reads_cmb <= resize(WR_gap, n_reads_cmb'length);
              rev_counter <= resize(WR_gap, rev_counter'length);
            else
              n_reads_cmb <= to_unsigned(HMAXBURST_123, n_reads_cmb'length);
              rev_counter <= to_unsigned(HMAXBURST_123, rev_counter'length);
            end if;
            if (to_unsigned(HMAXBURST_123, remaining_writes'length) > remaining_writes) then
              n_writes_cmb <= resize(remaining_writes, n_writes_cmb'length);
            else
              n_writes_cmb <= to_unsigned(HMAXBURST_123, n_writes_cmb'length);
            end if;
            -----------------------------
            appidle_cmb <= true;
            state_next <= s2;
          else
          -------------------------------------
            rev_counter <= rev_counter_reg - 1;    -- Modified by AS: reverse counter updated
            if (empty_in = '0') then
              appidle_cmb <= false; --appidle = true if there will be more data in the next cycle
            else
              appidle_cmb <= true;
            end if;
          end if;
        end if;
      -- let's read the data now
      when s2 =>  -- read request
        -- Modified by AS: compute the number of beats (burst length) of the next read operation
        -- Modified by AS (new): if clause modified to adapt to the new size of beats_v. (new): Math operation and comparison replaced with reverse counter
        if (resize(n_reads, remaining_reads'length) < remaining_reads) then
          beats_v := resize(n_reads, beats_v'length);
        else
          beats_v := resize(remaining_reads, beats_v'length);
        end if;
        beats <= beats_v;
        -----------------------------
        -- master can accept new read request
        -- we read and we make sure the FIFO is not half full
        -- Modified by AS: valid address phase and data were not correctly signaled. it is necessary to correctly manage the burst transaction --
        if ((state_next_ahbw = s0 or state_next_ahbw = s4) and hfull_out = '0') then
          data_valid_v := '1';
        -----------------------------
          allow_read <= '1';
        end if;
        if hfull_out /= '0' and interleave = '1' and ctrl.o.update = '1' then    -- Modified by AS: No changes while ctrl.o.update = '0'
          state_next <= s1;
        end if;
        if (state_reg_ahbw = s0 and allow_read_reg = '1' and ctrl.o.update = '1') then  -- Modified by AS: No changes while ctrl.o.update = '0'
          data_valid_v := '0';
          --information i need to read things
          --condition to wrap read address (can be changed to a power of two)
          if (samples_read = 0 or unsigned(address_read) = unsigned(config_predictor_s.ExtMemAddress) + unsigned(config_image_s.xz_bip)*4) then --High complexity here
            address_read_cmb <= config_predictor_s.ExtMemAddress;
          else
            address_read_cmb <= address_read + x"00000004";
          end if;
          size_cmb <= "10";
          htrans_cmb <= "10";
          -- in examples this is set to 1 but it does not make sense!
          hburst_cmb <= '0';
          -- Modified by AS: initiating burst operation if there are enough data pending --
          if unsigned(beats_v) > 1 then
            hburst_cmb <= '1';
            state_next <= s4;
          end if;
          -----------------------------
          debug_cmb <= 2;
          --trigger the operation
          ahbread_cmb <= '1';
          samples_read_cmb <= samples_read + 1;
          -- Modified by AS: new counters updated --
          remaining_reads_cmb <= remaining_reads - 1;
          WR_gap_cmb <= WR_gap - 1;
          -- Modified by AS: condition updated. (new): Comparison simplified using WR gap and reverse counter
          if (rev_counter_reg <= to_unsigned(1, rev_counter'length)) or (WR_gap <= to_unsigned(1, WR_gap'length)) then    -- i need to have room for n_reads in the output FIFO otherwise, stop and make an appidle!
            --counter <= (others => '0');
            appidle_cmb <= true;
            -- Modified by AS: end of data stream was not correctly computed. (new): Math operation replaced by reverse counters
            if (remaining_writes > to_unsigned(0, remaining_writes'length)) then
            ----------------------------------
              state_next <= s1;
              rev_counter <= resize(n_writes, rev_counter'length);  -- Modified by AS: reverse counter updated
            -- Modified by AS: Comparison simplified with WR gap
            elsif (WR_gap = to_unsigned(1, WR_gap'length))  then
              state_next <= s5;  --finish
            else
              interleave_cmb <= '0';
              --compute how many samples we still need to read
              -- Modified by AS: WR_gap (old rem_reads) is capped at HMAXBURST_123 for a proper operation of burst transactions
              if (to_unsigned(HMAXBURST_123, WR_gap'length) < WR_gap) then
                n_reads_cmb <= to_unsigned(HMAXBURST_123, n_reads_cmb'length);
                rev_counter <= to_unsigned(HMAXBURST_123, rev_counter'length);    -- Modified by AS: reverse counter updated
              else
                n_reads_cmb <= resize(WR_gap, n_reads_cmb'length);
                rev_counter <= resize(WR_gap, rev_counter'length);          -- Modified by AS: reverse counter updated
              end if;
              -----------------------------------
              --state_next <= s2;
            end if;
          else
          ------------------------------------
            if (hfull_out = '1') then
              appidle_cmb <= true;
              allow_read <= '0';
            else
              --counter <= counter_reg + 1;
              rev_counter <= rev_counter_reg - 1;    -- Modified by AS: reverse counter updated
              appidle_cmb <= false;
            end if;
          end if;
        end if;
      -- Modified by AS: burst operation --
      when s3 =>  -- write burst
        hburst_cmb <= '1';
        size_cmb <= "10";
        data_cmb <= data_out_in_edac;
        debug_cmb <= 2;
        if ctrl.o.update = '1' then
          htrans_cmb <= "11";
          if rd_in_reg = '1' then
            data_valid_v := '0';
            -- Modified by AS: new counters updated --
            remaining_writes_cmb <= remaining_writes - 1;
            WR_gap_cmb <= WR_gap + 1;
            --condition to wrap read address (can be changed to a power of two)
            if unsigned(address_write) = unsigned(config_predictor_s.ExtMemAddress) + unsigned(config_image_s.xz_bip)*4 then
              address_write_cmb <= config_predictor_s.ExtMemAddress;
            else
              address_write_cmb <= address_write + x"00000004";
            end if;
            rev_counter <= rev_counter_reg - 1;    -- Modified by AS: reverse counter updated
          end if;
          if (empty_in = '0' and data_valid_v = '0' and (count_burst_cmb /= 0) and (state_reg_ahbw = s4)) then
            rd_in_out <= '1';
            ahbwrite_cmb <= '1';
            appidle_cmb <= false;  --appidle = true if there will be more data in the next cycle
            data_valid_v := '1';
          elsif (data_valid_v = '0') then
            appidle_cmb <= true;
          end if;
          if (state_reg_ahbw = s0) then
            -- Modified by AS: condition reversed and simplified with reverse counter
            if (rev_counter_reg <= to_unsigned(1, rev_counter'length)) then
              interleave_cmb <= '1';
              -- Compute the correct number of elements for the subsequent read and write bursts.  Modified by AS: Math operations replaced with new counters
              if (to_unsigned(HMAXBURST_123, WR_gap'length) > WR_gap) then
                n_reads_cmb <= resize(WR_gap, n_reads_cmb'length);
                rev_counter <= resize(WR_gap, rev_counter'length);    -- Modified by AS: reverse counter updated
              else
                n_reads_cmb <= to_unsigned(HMAXBURST_123, n_reads_cmb'length);
                rev_counter <= to_unsigned(HMAXBURST_123, rev_counter'length);    -- Modified by AS: reverse counter updated
              end if;
              if (to_unsigned(HMAXBURST_123, remaining_writes'length) > remaining_writes) then
                n_writes_cmb <= resize(remaining_writes, n_writes_cmb'length);
              else
                n_writes_cmb <= to_unsigned(HMAXBURST_123, n_writes_cmb'length);
              end if;
              appidle_cmb <= true;
              state_next <= s2;
            else
              state_next <= s1;
            end if;
            --------------------
          end if;
        end if;
      when s4 =>  -- read burst
        hburst_cmb <= '1';
        size_cmb <= "10";
        data_cmb <= data_out_in_edac;
        debug_cmb <= 5;
        if ctrl.o.update = '1' then
          htrans_cmb <= "11";
          if allow_read_reg = '1' then
            data_valid_v := '0';
            samples_read_cmb <= samples_read + 1;
            -- Modified by AS: new counters updated --
            remaining_reads_cmb <= remaining_reads - 1;
            WR_gap_cmb <= WR_gap - 1;
            --condition to wrap read address (can be changed to a power of two)
            if (samples_read = 0 or unsigned(address_read) = unsigned(config_predictor_s.ExtMemAddress) + unsigned(config_image_s.xz_bip)*4) then --High complexity here
              address_read_cmb <= config_predictor_s.ExtMemAddress;
            else
              address_read_cmb <= address_read + x"00000004";
            end if;
            rev_counter <= rev_counter_reg - 1;    -- Modified by AS: reverse counter updated
          end if;
          if (hfull_out = '0' and data_valid_v = '0' and (count_burst_cmb /= 0) and (state_reg_ahbw = s4)) then -- and (counter_reg < n_reads - 1) 
            allow_read <= '1';
            ahbread_cmb <= '1';
            appidle_cmb <= false;  --appidle = true if there will be more data in the next cycle
            data_valid_v := '1';
          elsif (data_valid_v = '0') then
            appidle_cmb <= true;
          end if;
          if (state_reg_ahbw = s0) or (state_reg_ahbw = s2) then    -- Modified by AS: this condition also holds for state_reg_ahbw = s2
            -- Modified by AS: condition reversed and simplified with reverse counter          
            if (rev_counter_reg <= to_unsigned(1, rev_counter'length)) then
              appidle_cmb <= true;
              -- Modified by AS: Math operations and comparisons simplified with new counters
              if (remaining_writes /= to_unsigned(0, remaining_writes'length)) then
                state_next <= s1;
                rev_counter <= resize(n_writes, rev_counter'length);      -- Modified by AS: reverse counter updated
              elsif (WR_gap = to_unsigned(0, WR_gap'length)) then
                state_next <= s5;  --finish
              else
                interleave_cmb <= '0';
                --compute how many samples we still need to read
                -- Modified by AS: rem_reads replaced with WR_gap
                if (to_unsigned(HMAXBURST_123, WR_gap'length) < WR_gap) then
                  n_reads_cmb <= to_unsigned(HMAXBURST_123, n_reads_cmb'length);
                  rev_counter <= to_unsigned(HMAXBURST_123, rev_counter'length);    -- Modified by AS: reverse counter updated
                  
                else
                  n_reads_cmb <= resize(WR_gap, n_reads'length);
                  rev_counter <= resize(WR_gap, rev_counter'length);
                end if;
                state_next <= s2;
              end if;
            else
              state_next <= s2;
            end if;
            ---------------------
          end if;
        end if;
      when s5 =>
        done <= '1';
      when others => 
        state_next <= state_reg;
    end case;
    -- Modified by AS: assignment from variable to signal --
    data_valid_cmb <= data_valid_v;
    --------------------
  end process;
  
  -----------------------------------------------------------------------------  
  --! FSM to generate signals for AHB
  -----------------------------------------------------------------------------
  -- Modified by AS: signal appidle included in the sensitivity list. Data_burst removed from the sensitivity list --
  comb_ahb: process (state_reg_ahbw, address_write_cmb, address_read_cmb, data_cmb, size_cmb, appidle_cmb, appidle, htrans_cmb, hburst_cmb, debug_cmb, ahbwrite_cmb, rst_ahb, ctrl.o.update, ctrl_reg.i, ctrl.i, ahbread_cmb, beats, count_burst, burst_size)
  -------------------------------------
  begin  
    state_next_ahbw <= state_reg_ahbw;
    count_burst_cmb <= count_burst;
    burst_size_cmb <= burst_size;
    ctrl.i <= ctrl_reg.i;
    --ctrl.o <= ctrl_reg.o;
    case (state_reg_ahbw) is
      when idle =>
        --ctrl.o <= ctrlo_nodrive;
        ctrl.i <= ctrli_idle;
        if (rst_ahb = '1') then
          state_next_ahbw <= s0;
        end if;
      when s0 =>      -- Modified by AS: if/else clauses reorganized
        --write
        if ahbwrite_cmb = '1' and ctrl.o.update = '1' then
          ctrl.i.ac.ctrl.use128 <= 0;
          ctrl.i.ac.ctrl.dbgl <= debug_cmb;
          ctrl.i.ac.hsize <= '0' & size_cmb;
          ctrl.i.ac.haddr <= address_write_cmb; ctrl.i.ac.hdata <= data_cmb;
          ctrl.i.ac.hprot <= "1110"; ctrl.i.ac.hwrite <= '1'; 
          -- Modified by AS: ctrl.i.ac.hburst assignment moved inside the if/else clause
          if hburst_cmb = '0' then
            ctrl.i.ac.htrans <= htrans_cmb;
            ctrl.i.ac.hburst <= "000";
            if (appidle_cmb = true) then
              state_next_ahbw <= s2;
            end if;
          -- Modified by AS: hburst signal value depending on the hburst_cmb flag and number of beats --
          else          --if hburst_cmb = '1' then
            ctrl.i.ac.htrans <= "10";
            count_burst_cmb <= to_unsigned(1, count_burst_cmb'length);
            state_next_ahbw <= s4;
            burst_size_cmb <= beats_reg;        -- Modified by AS: assignment from beats_reg instead of beats
            case to_integer(beats) is
              when 4 =>    ctrl.i.ac.hburst <= "011";
              when 8 =>    ctrl.i.ac.hburst <= "101";
              when 16 =>    ctrl.i.ac.hburst <= "111";
              when others =>  ctrl.i.ac.hburst <= "001";
            end case;
          end if;
          ------------------------------------------------
        --read
        elsif ahbread_cmb = '1' and ctrl.o.update = '1' then
          ctrl.i.ac.ctrl.use128 <= 0;
          ctrl.i.ac.ctrl.dbgl <= debug_cmb;
          ctrl.i.ac.hsize <= '0' & size_cmb;
          ctrl.i.ac.haddr <= address_read_cmb; 
          ctrl.i.ac.hdata <= data_cmb;
          ctrl.i.ac.hwrite <= '0';
          ctrl.i.ac.hprot <= "1110";
          -- Modified by AS: ctrl.i.ac.hburst assignment moved inside the if/else clause
          if hburst_cmb = '0' then
            ctrl.i.ac.htrans <= htrans_cmb;
            ctrl.i.ac.hburst <= "000";
            if (appidle_cmb = true) then
              state_next_ahbw <= s2;
            end if;
          -- Modified by AS: hburst signal value depending on the hburst_cmb flag and number of beats --
          else          --if hburst_cmb = '1' then
            ctrl.i.ac.htrans <= "10";
            count_burst_cmb <= to_unsigned(1, count_burst_cmb'length);
            state_next_ahbw <= s4;
            burst_size_cmb <= beats_reg;        -- Modified by AS: assignment from beats_reg instead of beats
            case to_integer(beats) is
              when 4 =>    ctrl.i.ac.hburst <= "011";
              when 8 =>    ctrl.i.ac.hburst <= "101";
              when 16 =>    ctrl.i.ac.hburst <= "111";
              when others =>  ctrl.i.ac.hburst <= "001";
            end case;
          end if;
          ------------------------------------------------
        elsif ahbwrite_cmb = '1' and ctrl.o.update = '0' then
          state_next_ahbw <= s1;
        elsif ahbread_cmb = '1' and ctrl.o.update = '0' then
          state_next_ahbw <= s3;
        end if;
      when s1 =>               -- Modified by AS: if/else clauses reorganized
        -- wait for ctrl.o.update = '1' to write 
        if (ctrl.o.update = '1') then
          ctrl.i.ac.ctrl.use128 <= 0;
          ctrl.i.ac.ctrl.dbgl <= debug_cmb;
          ctrl.i.ac.hsize <= '0' & size_cmb;
          ctrl.i.ac.haddr <= address_write_cmb; ctrl.i.ac.hdata <= data_cmb;
          ctrl.i.ac.hprot <= "1110"; ctrl.i.ac.hwrite <= '1'; 
          -- Modified by AS: ctrl.i.ac.hburst assignment moved inside the if/else clause
          if hburst_cmb = '0' then
            ctrl.i.ac.htrans <= htrans_cmb;
            ctrl.i.ac.hburst <= "000";
            if (appidle_cmb = true) then
              state_next_ahbw <= s2;
            else
              state_next_ahbw <= s0;
            end if;
          -- Modified by AS: hburst signal value depending on the hburst_cmb flag and number of beats --
          else          -- if hburst_cmb = '1' then
            ctrl.i.ac.htrans <= "10";
            count_burst_cmb <= to_unsigned(1, count_burst_cmb'length);
            if (appidle_cmb = true) then
              state_next_ahbw <= s2;
            else
              state_next_ahbw <= s4;
            end if;
            burst_size_cmb <= beats_reg;        -- Modified by AS: assignment from beats_reg instead of beats
            case to_integer(beats) is
              when 4 =>    ctrl.i.ac.hburst <= "011";
              when 8 =>    ctrl.i.ac.hburst <= "101";
              when 16 =>    ctrl.i.ac.hburst <= "111";
              when others =>  ctrl.i.ac.hburst <= "001";
            end case;
          end if;
          ------------------------------------------------
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
          ctrl.i.ac.hwrite <= '0'; 
          ctrl.i.ac.hprot <= "1110";
          -- Modified by AS: ctrl.i.ac.hburst assignment moved inside the if/else clause
          if hburst_cmb = '0' then
            ctrl.i.ac.hburst <= "000";
            ctrl.i.ac.htrans <= htrans_cmb; 
            if (appidle_cmb = true) then
              state_next_ahbw <= s2;
            else
              state_next_ahbw <= s0;
            end if;
          -- Modified by AS: hburst signal value depending on the hburst_cmb flag and number of beats --
          else          -- if hburst_cmb = '1' then
            ctrl.i.ac.htrans <= "10";
            count_burst_cmb <= to_unsigned(1, count_burst_cmb'length);
            if (appidle_cmb = true) then
              state_next_ahbw <= s2;
            else
              state_next_ahbw <= s4;
            end if;
            burst_size_cmb <= beats_reg;        -- Modified by AS: assignment from beats_reg instead of beats
            case to_integer(beats) is
              when 4 =>    ctrl.i.ac.hburst <= "011";
              when 8 =>    ctrl.i.ac.hburst <= "101";
              when 16 =>    ctrl.i.ac.hburst <= "111";
              when others =>  ctrl.i.ac.hburst <= "001";
            end case;
          end if;
          ------------------------------------------------
        end if;
      -- Modified by AS: Burst transanction enabled --
      when s4 => 
        if (ctrl.o.update = '1') then
          -- ctrl.i <= ctrl_reg.i;    -- Modified by AS: cassignment not necessary
          if (appidle = false) then
            if (count_burst = burst_size - 1) then
              count_burst_cmb <= to_unsigned(0, count_burst_cmb'length);
              state_next_ahbw <= s2;
            else
              count_burst_cmb <= count_burst + 1;
            end if;
            ctrl.i.ac.htrans <= "11";  -- Sequential transfer
            if (ctrl_reg.i.ac.hwrite = '1') then
              ctrl.i.ac.haddr <= address_write_cmb;
            else
              ctrl.i.ac.haddr <= address_read_cmb;
            end if;
          else
            ctrl.i.ac.htrans <= "01";  -- Busy
            ctrl.i.ac.haddr <= ctrl_reg.i.ac.haddr; 
          end if;
          ctrl.i.ac.hdata <= data_cmb;               --data_burst (to_integer(count_burst));
        end if;
      ------------------------------------------------
      when others => 
        state_next_ahbw <= idle;
    end case;
  end process;
  
end arch_shyloc;  --============================================================================  
