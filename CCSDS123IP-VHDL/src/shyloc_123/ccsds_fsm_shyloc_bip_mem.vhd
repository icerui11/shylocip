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
-- Design unit  : CCSDS123 FSM for BIP-mem predictor
--
-- File name    : ccsds_fsm_shyloc_bip_mem.vhd
--
-- Purpose      : Generates read/write flags for neighbouring and current FIFOs
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
-- Instantiates: 
--============================================================================
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>-

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
library shyloc_123; use shyloc_123.ccsds123_parameters.all; use shyloc_123.ccsds123_constants.all;    
use shyloc_123.fifo_ctrl.all; 


--!@file #ccsds_fsm_shyloc_bip_mem.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Generates read/write flags for neighbouring and current FIFOs. Waits for availability of data
--! from AHB master.
--! Ensure synchronization of control signals and activation of the localsum module. 

entity ccsds_fsm_shyloc_bip_mem is
  generic (DRANGE: integer := 16;       --! Dynamic range of the input samples
       --W_ADDR_BANK: integer := 2;     --! Bit width of the address signal in the register banks.
       W_ADDR_IN_IMAGE: integer := 16;  --! Bit width of the image coordinates (x, y, z)
       W_BUFFER: integer := 64;     --! Bit width of the output buffer.
       RESET_TYPE: integer := 1     --! Reset flavour (0) asynchronous (1) synchronous
      );
  port (
    clk: in std_logic;                        --! Clock signal.
    rst_n: in std_logic;                      --! Reset signal. Active low.
    
    --Input sample FIFO
    r_update_curr: out std_logic;                 --! Read enable in the CURR FIFO. Active high.
    
    -- Neighbour FIFOs
    w_update_top: out std_logic;                  --! Write enable in the TOP FIFO. Active high.
    r_update_top: out std_logic;                  --! Read enable in the TOP FIFO. Active high. 
    
    w_update_top_left: out std_logic;               --! Write enable in the TOP LEFT FIFO. Active high. 
    r_update_top_left: out std_logic;               --! Read enable in the TOP LEFT FIFO. Active high.
    
    w_update_top_right_ahbo: out std_logic;             --! Write enable in the TOP RIGHT FIFO. Active high. . 
    r_update_top_right_ahbi: out std_logic;             --! Read enable in the TOP RIGHT FIFO. Active high.
    
    w_update_left: out std_logic;                   --! Write enable in the LEFT FIFO.  Active high.
    r_update_left: out std_logic;                 --! Read enable in the LEFT FIFO. Active high.
  
    en_opcode: out std_logic;                   --! Enable opcode
    opcode: in std_logic_vector (4 downto 0);           --! Opcode value (output of OPCODE module)
    z_opcode: in std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);   --! z coordinate output from OPCODE (from comp module)
    t_opcode: in std_logic_vector (W_T-1 downto 0);         --! t coordinate output from OPCODE (from comp module)
    t_ls: out std_logic_vector (W_T-1 downto 0);          --! t coordinate input to localsum
    
    en_localsum: out std_logic;                   --! Enable signal for local sum module. Active high.
    opcode_localsum: out std_logic_vector (4 downto 0);       --! Opcode value input for localsum module
    z_ls: out std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);    --! z coordinate input to localsum
    
    s_out: in std_logic_vector (DRANGE-1 downto 0);           --! Current sample to be compressed, output from current FIFO s(x, y, z)
    s_in_left: out std_logic_vector (DRANGE-1 downto 0);      --! Current sample to be compressed, input for LEFT FIFO s(x, y, z)
    s_in_top_right: out std_logic_vector (DRANGE-1 downto 0);   --! Sample to be stored in TOP RIGHT FIFO. Sent to comp (AHB FIFO)
    
    en_localdiff: out std_logic;                  --! Enable localdiff computation. 
    s_in_localdiff: out std_logic_vector(DRANGE-1 downto 0);    --! Current sample - Input of localdiff module
    
    en_localdiff_shift: out std_logic;                --! Enables localdiff shift
    config_valid: in std_logic;                   --! Validates the configuration. 
    z_configured : in std_logic_vector (W_Nz_GEN-1 downto 0);   --! Number of bands configured by the user
    eop: out std_logic;                       --! EOP to signal that we are starting the processing of the last sample
    clear : in std_logic;                     --! Clear flag to reset all registers. Synchronous.
    fsm_invalid_state:  out std_logic;                --! Signals that any of the FSMs has entered an invalid state.
    --Current FIFO
    empty_curr: in std_logic;                   --! CURR FIFO flag empty.               
    aempty_curr: in std_logic;                    --! CURR FIFO flag almost empty.
    clear_curr: out std_logic;                    --! Clear current FIFO.
    full_top_right_ahbo: in std_logic;                --! TOP LEFT FIFO flag full. 
    empty_top_right_ahbi: in std_logic;               --! TOP LEFT FIFO flag empty.
    full_top_right_ahbi: in std_logic               --! TOP LEFT FIFO flag full.  
    );
end ccsds_fsm_shyloc_bip_mem;


architecture arch_bip_mem of ccsds_fsm_shyloc_bip_mem is
  -- in principle this architecture is the same as BIP the other, but it will consider the possibility of using AHB mem interface.
  -- we will use two FIFOs to interface with AMBA that will also serve as clk-adapt modules
  -- for now we'll make it simple, one read+one write per sample.
  -- later we can consider multiplexing the data to achieve better memory performance.
  -- FIFO_TO_AHB and FIFO_FROM_AHB will store the I/O data to and from memory
  
  -- Enable opcode
  signal en_opcode_cmb, opcode_valid, en_opcode_d1: std_logic;
  -- Read update from FIFO current and neighbouring
  signal r_update_curr_cmb, r_update_top_cmb, r_update_top_left_cmb, r_update_left_cmb, r_update_top_right_cmb_ahbi: std_logic;
  -- Write update from FIFO current and neighbouring
  signal w_update_top_cmb, w_update_left_cmb, w_update_top_right_cmb_ahbo, w_update_top_left_cmb: std_logic;
  -- Intermediate storage of opcode values for synchronization
  signal opcode_write, opcode_write_cmb, opcode_localsum_reg, opcode_localsum_cmb, opcode_read, opcode_read_cmb: std_logic_vector (4 downto 0);
  --signal neighbours_state_cmb, neighbours_state_reg: std_logic;
  signal s_in_top_right_reg, s_in_top_right_cmb, s_in_localsum, s_in_localsum_cmb, s_in_localsum_reg, s_in_left_cmb, s_in_left_reg: std_logic_vector (s_in_left'high downto 0);
  signal en_localsum_cmb, en_localsum_reg: std_logic;
  signal en_localdiff_reg, en_localdiff_shift_reg: std_logic;

  type state_type is (idle, s0, s1, finished_clear, finished);
  signal state_reg, state_next:  state_type;
  
  type state_type2 is (idle, s0, s1, s2, s3, s4, wait_cycles);
  signal state_reg2, state_next2: state_type2;
  
  --Enables writing the neighbours in FIFOs when available
  signal en_write_nei, en_write_nei_cmb: std_logic;
  -- Flag to stop enabling opcode (because we are finished)
  signal stop_opcode, pending_opcode, pending_opcode_cmb: std_logic;
  -- z value at different moments to ensure synchronization (pipeline registers)
  signal z_write_cmb, z_write, z_ls_reg, z_ls_cmb: std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);
  -- t value at different moments to ensure synchronization (pipeline registers)
  signal t_write_cmb, t_write, t_ls_reg, t_ls_cmb: std_logic_vector (W_T-1 downto 0);
  -- Signals to finish computing opcides, and reset FIFO pointers
  signal finished_opcode, finished_opcode_cmb, clear_curr_reg, clear_curr_cmb, eop_cmb: std_logic;
  -- Insert wait cycles when the number of bands is lower than the latency of the prediction
  signal n_wait_cycles_cmb, n_wait_cycles, cycles_counter, cycles_counter_cmb, cycles_counter_band, cycles_counter_band_cmb: unsigned(W_CYCLE_COUNT-1 downto 0);
  -- To generate invalid state error
  signal fsm_invalid_state_cmb, fsm_invalid_state_cmb2, fsm_invalid_state_reg: std_logic;
  
begin
  ----------------------------------------------------------------------------- 
  -- Output assignments
  -----------------------------------------------------------------------------
  en_opcode <= opcode_valid;
  
  opcode_localsum <= opcode_localsum_reg;
  s_in_left <= s_in_left_reg;
  s_in_localsum <= s_in_localsum_reg;
  en_localsum <= en_localsum_reg;
  en_localdiff <= en_localdiff_reg;
  en_localdiff_shift <= en_localdiff_shift_reg;
  z_ls <= z_ls_reg;
  t_ls <= t_ls_reg;
  clear_curr <= clear_curr_reg;
  fsm_invalid_state <= fsm_invalid_state_reg;
  
  --NOTE: Not registered!! Sent a read from FIFO
  s_in_top_right <= s_in_top_right_cmb;
  
  --These flags are not registerd, so that we can use full and empty flags.
  r_update_top_right_ahbi <= r_update_top_right_cmb_ahbi;
  w_update_top_right_ahbo <= w_update_top_right_cmb_ahbo;

  ----------------------------------------------------------------------------- 
  -- Registers
  -----------------------------------------------------------------------------
  process(clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      state_reg <= idle;
      state_reg2 <= idle;
      r_update_curr <= '0';
      r_update_top <= '0'; 
      r_update_top_left <= '0';
      r_update_left <= '0';
      w_update_top <= '0';
      w_update_left <= '0';
      w_update_top_left <= '0';
      opcode_write <= (others => '0');
      s_in_top_right_reg <= (others => '0');
      en_localsum_reg  <= '0';
      opcode_valid <= '0';
      en_write_nei <= '0';
      opcode_localsum_reg <= (others => '0');
      s_in_left_reg <= (others => '0');
      s_in_localsum_reg <= (others => '0');
      pending_opcode <= '0';
      opcode_read <= (others => '0');
      z_write <= (others => '0');
      z_ls_reg <= (others => '0');
      t_write <= (others => '0');
      t_ls_reg <= (others => '0');
      finished_opcode <= '0';
      clear_curr_reg <= '0';
      eop <= '0';   
      n_wait_cycles <= (others => '0');
      cycles_counter <= (others => '0');
      fsm_invalid_state_reg <= '0';
    elsif clk'event and clk = '1' then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        state_reg <= idle;
        state_reg2 <= idle;
        r_update_curr <= '0';
        r_update_top <= '0'; 
        r_update_top_left <= '0';
        r_update_left <= '0';
        w_update_top <= '0';
        w_update_left <= '0';
        w_update_top_left <= '0';
        opcode_write <= (others => '0');
        s_in_top_right_reg <= (others => '0');
        en_localsum_reg  <= '0';
        opcode_valid <= '0';
        en_write_nei <= '0';
        opcode_localsum_reg <= (others => '0');
        s_in_left_reg <= (others => '0');
        s_in_localsum_reg <= (others => '0');
        pending_opcode <= '0';
        opcode_read <= (others => '0');
        z_write <= (others => '0');
        t_write <= (others => '0');
        z_ls_reg <= (others => '0');
        t_ls_reg <= (others => '0');    
        finished_opcode <= '0';
        clear_curr_reg <= '0';
        eop <= '0';
        n_wait_cycles <= (others => '0');
        cycles_counter <= (others => '0');
        fsm_invalid_state_reg <= '0';
      else
        opcode_valid <= en_opcode_cmb;
        r_update_curr <= r_update_curr_cmb;
        r_update_top <= r_update_top_cmb; 
        r_update_top_left <= r_update_top_left_cmb;
        r_update_left <= r_update_left_cmb;
        w_update_top <= w_update_top_cmb;
        w_update_left <= w_update_left_cmb;
        w_update_top_left <= w_update_top_left_cmb;
        s_in_top_right_reg <= s_in_top_right_cmb;
        s_in_localsum_reg <= s_in_localsum_cmb;
        state_reg <= state_next;
        state_reg2 <= state_next2;
        opcode_write <= opcode_write_cmb;
        en_localsum_reg  <= en_localsum_cmb;
        en_write_nei  <= en_write_nei_cmb;
        opcode_localsum_reg <= opcode_localsum_cmb;
        s_in_left_reg <= s_in_left_cmb;
        pending_opcode <= pending_opcode_cmb;
        opcode_read <= opcode_read_cmb;
        z_write <= z_write_cmb;
        z_ls_reg <= z_ls_cmb;
        t_write <= t_write_cmb;
        t_ls_reg <= t_ls_cmb; 
        finished_opcode <= finished_opcode_cmb;
        clear_curr_reg <=clear_curr_cmb;
        eop <= eop_cmb;
        n_wait_cycles <= n_wait_cycles_cmb;
        cycles_counter <= cycles_counter_cmb;
        fsm_invalid_state_reg <= fsm_invalid_state_cmb or fsm_invalid_state_cmb2;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------------------- 
  -- FSM for input FIFO ctrl and opcode enable: we enable opcode when there is a 
  -- valid sample read from the input FIFO. 
  ----------------------------------------------------------------------------- 
  fsm_opcode: process(rst_n, state_reg, empty_curr, aempty_curr, stop_opcode, finished_opcode_cmb, 
  clear_curr_reg, config_valid, z_configured, n_wait_cycles)
  begin
    r_update_curr_cmb <= '0';
    en_opcode_cmb <= '0';
    state_next <= state_reg;  
    clear_curr_cmb <= clear_curr_reg;
    eop_cmb <= '0';
    n_wait_cycles_cmb <= n_wait_cycles; 
    fsm_invalid_state_cmb <= '0';
    case state_reg is
    
      when idle =>
          if (rst_n = '1' and config_valid = '1' and finished_opcode_cmb = '0') then
            state_next <= s0;
            if Cz = 0 then --no feedback loop when Cz = 0
              n_wait_cycles_cmb <= (others => '0');
            elsif (unsigned(z_configured)-1 < CYCLES_MAC_WEIGHT) then
              n_wait_cycles_cmb <= to_unsigned(CYCLES_MAC_WEIGHT, n_wait_cycles_cmb'length) - resize(unsigned(z_configured),  n_wait_cycles'length);
            --  n_wait_cycles_cmb <= (others => '0');
            else
              n_wait_cycles_cmb <= (others => '0');
            end if;
          end if;
        when s0 =>
          if (empty_curr = '0' and finished_opcode_cmb = '0' and stop_opcode = '0') then
            en_opcode_cmb <= '1';
            r_update_curr_cmb <= '1';
            state_next <= s1;
          end if;
          if finished_opcode_cmb = '1' then
            en_opcode_cmb <= '0';
            r_update_curr_cmb <= '0';
            clear_curr_cmb <= '1';
            state_next <= finished_clear;
          end if;
        when s1 =>
          if (not (empty_curr = '1' or aempty_curr = '1') and finished_opcode_cmb = '0' and stop_opcode = '0') then
            en_opcode_cmb <= '1';
            r_update_curr_cmb <= '1';
            state_next <= s1;
          else
            state_next <= s0;
          end if;
          if finished_opcode_cmb = '1' then
            en_opcode_cmb <= '0';
            r_update_curr_cmb <= '0';
            clear_curr_cmb <= '1';
            state_next <= finished_clear;
          end if;
        when finished_clear =>
          clear_curr_cmb <= '1';
          eop_cmb <= '1';
          state_next <= finished;
        when finished =>
          clear_curr_cmb <= '0';
          state_next <= idle;
        when others =>
          state_next <= idle; 
          fsm_invalid_state_cmb <= '1';         
    end case;
  end process;  

  ----------------------------------------------------------------------------- 
  -- Generation of finished flag to stop opcode generation
  -----------------------------------------------------------------------------
  process (opcode, z_opcode, z_configured, finished_opcode)
  begin
    if finished_opcode = '0' then
      if (opcode = "10111" and unsigned(z_opcode) = unsigned(z_configured)-1) then
        finished_opcode_cmb <= '1';
      else
        finished_opcode_cmb <= '0';
      end if;
    else
      finished_opcode_cmb <= finished_opcode;
    end if;
  end process;

  ----------------------------------------------------------------------------- 
  -- FSM to decide when to read/write from FIFOs - reads and writes from AHB
  -- FIFOs
  -----------------------------------------------------------------------------
  
  fsm_neighbours: process(state_reg2, rst_n, opcode, opcode_write, opcode_valid, s_out, s_in_top_right_reg, empty_top_right_ahbi, full_top_right_ahbo,
  pending_opcode, opcode_read, z_opcode, z_configured, z_write, finished_opcode, cycles_counter, n_wait_cycles, t_write, t_opcode)
    variable write_samples: std_logic_vector (2 downto 0);
    variable read_samples : std_logic_vector (4 downto 0);
    variable op_required: integer :=0; --0: none --1: write --2 : read -- 3: both
  begin
    r_update_top_right_cmb_ahbi <= '0';
    r_update_top_cmb  <= '0';
    r_update_top_left_cmb  <= '0';
    r_update_left_cmb <= '0';
    w_update_top_right_cmb_ahbo <= '0';
    read_samples := ctrl_fifo_read(opcode);
    opcode_write_cmb <= opcode_write;
    state_next2 <= state_reg2;
    en_write_nei_cmb <= '0';
    s_in_top_right_cmb <= s_in_top_right_reg;
    stop_opcode <= '0';
    pending_opcode_cmb <= pending_opcode;
    z_write_cmb <= z_write;
    t_write_cmb <= t_write;
    cycles_counter_cmb <= cycles_counter;
    fsm_invalid_state_cmb2 <= '0';
    opcode_read_cmb <= opcode_read;
    case state_reg2 is
      when idle =>
        if (rst_n = '1' and opcode_valid = '1') then
          state_next2 <= s1;
        end if;
      when s1 =>
        if (opcode_valid = '0') then
          state_next2 <= idle;
          pending_opcode_cmb <= '0';
        else
          pending_opcode_cmb <= '1';
        end if;
        
        --Data to write in top right FIFO and write enable
        s_in_top_right_cmb <= s_out;
        opcode_write_cmb <= opcode;
        z_write_cmb <= z_opcode;
        t_write_cmb <= t_opcode;
        opcode_read_cmb <= opcode;
        
        if (unsigned(z_opcode) = unsigned(z_configured)-1 and n_wait_cycles > 0) then
          stop_opcode <= '1';
          cycles_counter_cmb <= n_wait_cycles;
          state_next2 <= wait_cycles;
        end if;
        
        if (opcode /= "11111" and opcode /= "10111" and opcode /= "11010" and read_samples(1) = '1') then
          op_required := 3; --read and write
        elsif (opcode /= "11111" and opcode /= "10111" and opcode /= "11010"  and read_samples(1) = '0') then
          op_required := 2; -- only write
        elsif (read_samples(1) = '1') then
          op_required := 1; -- only read
        else
          op_required := 0; --none (from top_right)
        end if;
        
        if (op_required = 3) then
          if (empty_top_right_ahbi = '1') then 
            state_next2 <= s2;
            stop_opcode <= '1';
          else
            if full_top_right_ahbo = '1' then
              state_next2 <= s2;
              stop_opcode <= '1';
            else
              --enable next stage of neighbours
              en_write_nei_cmb <= '1' and not finished_opcode;
              --write the top_right sample
              w_update_top_right_cmb_ahbo <= '1'; --not registered
              --read the top sample
              read_samples := ctrl_fifo_read(opcode);
              r_update_top_right_cmb_ahbi <= read_samples(1); --not registered
              --these are registered
              r_update_top_cmb  <= read_samples(2);
              r_update_top_left_cmb  <= read_samples(3);
              r_update_left_cmb <= read_samples(4);
            end if;
            
          end if;
        elsif (op_required = 2) then -- only write - no read needed from top, I can read from the rest and continue
          -- I don't need to read from the top, so I can read from neighbours if needed
          en_write_nei_cmb <= '1' and not finished_opcode;
          -- although I don't need to read the top I might need to read from the others...
          
          r_update_top_right_cmb_ahbi <= read_samples(1); --this is zero
          r_update_top_cmb  <= read_samples(2);
          r_update_top_left_cmb  <= read_samples(3);
          r_update_left_cmb <= read_samples(4);
          
          if (full_top_right_ahbo = '1') then
            -- the write FIFO is full, I cannot write the sample. Stop bringing new samples until we sort this out
            state_next2 <= s3;
            stop_opcode <= '1';
          else
            -- the write FIFO is not full, I can happily continue
            w_update_top_right_cmb_ahbo <= '1';
            --stop_opcode <= '0';
          end if;
          
        elsif (op_required = 1) then -- only read - I cannot activate reads from neighbours
          -- I need to read the top sample...
          if (empty_top_right_ahbi = '1') then
            -- If the read FIFO is empty, I cannot read from it... so I'd better wait
            state_next2 <= s4;
            stop_opcode <= '1';
          else
            -- The FIFO is not empty, I can continue reading the necessary top_right sample and neighbours
            --stop_opcode <= '0';
            en_write_nei_cmb <= '1' and not finished_opcode;
            r_update_top_right_cmb_ahbi <= read_samples(1);
            r_update_top_cmb  <= read_samples(2);
            r_update_top_left_cmb  <= read_samples(3);
            r_update_left_cmb <= read_samples(4);
          end if;
        else --if (op_required = 0) then --no operation required from top_right! but from others maybe...
          en_write_nei_cmb <= '1' and not finished_opcode;
          --stop_opcode <= '0';
          r_update_top_right_cmb_ahbi <= read_samples(1);
          r_update_top_cmb  <= read_samples(2);
          r_update_top_left_cmb  <= read_samples(3);
          r_update_left_cmb <= read_samples(4);
        end if;

      when s2 =>
        -- If I am here, it is because I needed to read and write but I could not do it       
        if (empty_top_right_ahbi = '1' or full_top_right_ahbo = '1') then
          --wait for the situation to be sorted out
            if (opcode_valid = '1') then
              pending_opcode_cmb <= '1';
            end if;
            stop_opcode <= '1';
        else
          --situation is sorted out, I can proceed to read the samples.
          --Maybe I should check here if there is a pending opcode to process(?)
          en_write_nei_cmb <= '1' and not finished_opcode;
          w_update_top_right_cmb_ahbo <= '1';
          read_samples := ctrl_fifo_read(opcode_read); 
          r_update_top_right_cmb_ahbi <= read_samples(1);
          r_update_top_cmb  <= read_samples(2);
          r_update_top_left_cmb  <= read_samples(3);
          r_update_left_cmb <= read_samples(4);
          
          if (opcode_valid = '1' or pending_opcode = '1') then
            --check if we need to insert wait cycles before returning to s1
            if (unsigned(z_write) = unsigned(z_configured)-1 and n_wait_cycles > 0) then
              stop_opcode <= '1';
              cycles_counter_cmb <= n_wait_cycles;
              state_next2 <= wait_cycles;
              pending_opcode_cmb <= '1';
            else
              state_next2 <= s1;
              pending_opcode_cmb <= '0';
            end if;
          else
            state_next2 <= idle;
          end if;
        end if;
      when s3 =>
        -- If I am here, it is because I wanted to write a sample but I could not
        if (full_top_right_ahbo = '0') then
          w_update_top_right_cmb_ahbo <= '1';
          if (opcode_valid = '1' or pending_opcode = '1') then
            if (unsigned(z_write) = unsigned(z_configured)-1 and n_wait_cycles > 0) then
              stop_opcode <= '1';
              cycles_counter_cmb <= n_wait_cycles;
              state_next2 <= wait_cycles;
              pending_opcode_cmb <= '1';
            else
              state_next2 <= s1;
              pending_opcode_cmb <= '0';
            end if;
          else
            state_next2 <= idle;
          end if;
          --stop_opcode <= '0';
        else
          if (opcode_valid = '1') then
            pending_opcode_cmb <= '1';
          end if;
          stop_opcode <= '1';
        end if;
      when s4 =>
        -- If I am here, it is because I wanted to read a sample but I could not
        if (empty_top_right_ahbi = '0') then
          if (opcode_valid = '1' or pending_opcode = '1') then
            if (unsigned(z_write) = unsigned(z_configured)-1 and n_wait_cycles > 0) then
              stop_opcode <= '1';
              cycles_counter_cmb <= n_wait_cycles;
              state_next2 <= wait_cycles;
              pending_opcode_cmb <= '1';
            else
              state_next2 <= s1;
              pending_opcode_cmb <= '0';
            end if;
          else
            state_next2 <= idle;
          end if;
          en_write_nei_cmb <= '1' and not finished_opcode;
          read_samples := ctrl_fifo_read(opcode_read);
          r_update_top_right_cmb_ahbi <= read_samples(1);
          r_update_top_cmb  <= read_samples(2);
          r_update_top_left_cmb  <= read_samples(3);
          r_update_left_cmb <= read_samples(4);
        else
          if (opcode_valid = '1') then
            pending_opcode_cmb <= '1';
          end if;
          stop_opcode <= '1';
        end if;
      when wait_cycles => 
        if (opcode_valid = '1') then
          pending_opcode_cmb <= '1';
        end if;
        if (cycles_counter > 0) then
          cycles_counter_cmb <= cycles_counter -1;
          stop_opcode <= '1';
        else
          if pending_opcode = '1' or opcode_valid = '1' then
            state_next2 <= s1;
            pending_opcode_cmb <= '0';
          else
            state_next2 <= idle;
          end if;
        end if;
      when others =>
        state_next2 <= idle;
        fsm_invalid_state_cmb2 <= '1';
    end case;
  end process;
  
  -----------------------------------------------------------------------------
  -- process to write in input samples and enable localsum
  -- also put correct data in FIFO s_in_left
  -----------------------------------------------------------------------------
  process(en_write_nei, opcode_write, s_in_top_right_reg, s_in_left_reg, opcode_localsum_reg, 
  s_in_localsum_reg, z_write, t_write, z_ls_reg, t_ls_reg)
    variable write_samples: std_logic_vector (2 downto 0);
    variable read_samples : std_logic_vector (4 downto 0);
  begin
    w_update_top_cmb <= '0';
    w_update_left_cmb <= '0';
    w_update_top_left_cmb <= '0';
    en_localsum_cmb <= '0';
    write_samples:= ctrl_fifo_write(opcode_write);
    opcode_localsum_cmb <= opcode_localsum_reg;
    s_in_left_cmb <= s_in_left_reg;
    s_in_localsum_cmb <= s_in_localsum_reg;
    z_ls_cmb <= z_ls_reg;
    t_ls_cmb <= t_ls_reg;
    if (en_write_nei = '1') then
      -- write samples from FIFOS
      s_in_left_cmb <= s_in_top_right_reg;
    
      w_update_top_cmb <= write_samples(0);
      w_update_left_cmb <= write_samples(1);
      w_update_top_left_cmb <= write_samples(2);
      
      -- enable localsum with correct (synchronized) localsum intpus
      en_localsum_cmb <= '1';
      opcode_localsum_cmb <= opcode_write;
      s_in_localsum_cmb <= s_in_top_right_reg;
      z_ls_cmb <= z_write;
      t_ls_cmb <= t_write;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  --process for localdiff activation
  -----------------------------------------------------------------------------
  process(clk,rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      en_localdiff_reg <= '0';
      s_in_localdiff <=  (others => '0');
      en_localdiff_shift_reg <= '0';
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        en_localdiff_reg <= '0';
        s_in_localdiff <=  (others => '0');
        en_localdiff_shift_reg <= '0';
      else
        if (en_localsum_reg = '1') then
          s_in_localdiff <= s_in_localsum_reg;
        end if;
        en_localdiff_reg <= en_localsum_reg;
        en_localdiff_shift_reg <= en_localdiff_reg;
      end if;
    end if;
  end process;
end arch_bip_mem;