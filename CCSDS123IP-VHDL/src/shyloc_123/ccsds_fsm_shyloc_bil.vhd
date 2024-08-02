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
-- Design unit  : CCSDS123 FSM for BIL predictor
--
-- File name    : ccsds_fsm_shyloc_bil.vhd
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


--!@file #ccsds_fsm_shyloc_bil.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Takes care of the control


entity ccsds_fsm_shyloc_bil is
  generic (DRANGE: integer := 16;       --! Dynamic range of the input samples
      -- W_ADDR_BANK: integer := 2;     --! Bit width of the address signal in the register banks.
       W_ADDR_IN_IMAGE: integer := 16;  --! Bit width of the image coordinates (x, y, z)
       W_BUFFER: integer := 64;     --! Bit width of the output buffer.
       RESET_TYPE: integer := 1     --! Reset flavour (0) asynchronous reset (1) synchronous reset.
      );
  port (
    clk: in std_logic;                        --! Clock signal.
    rst_n: in std_logic;                      --! Reset signal. Active low.
    
    --Input sample FIFO
    w_update_curr: out std_logic;                   --! Write enable in the CURR FIFO.  Active high.
    r_update_curr: out std_logic;                 --! Read enable in the CURR FIFO. Active high.
    w_update_top_right: out std_logic;                --! Write enable in the TOP RIGHT FIFO. Active high. 
    r_update_top_right: out std_logic;                --! Read enable in the TOP RIGHT FIFO. Active high.
    en_opcode: out std_logic;                   --! Enable opcode
    opcode: in std_logic_vector (4 downto 0);           --! Opcode value (output of OPCODE module)
    z: in std_logic_vector(W_ADDR_IN_IMAGE -1 downto 0);      --! z coordinate.
    en_localsum: out std_logic;                   --! Enable signal for local sum module. Active high.
    opcode_localsum: out std_logic_vector (4 downto 0);       --! Opcode value input for localsum module
    s_out: in std_logic_vector (DRANGE-1 downto 0);           --! Current sample to be compressed, output from current FIFO s(x, y, z)
    s_in_left: out std_logic_vector (DRANGE-1 downto 0);      --! Current sample to be compressed, input for TOP FIFO s(x, y, z)
    s_in_top_right: out std_logic_vector (DRANGE-1 downto 0);   --! Sample to be written in TOP RIGHT FIFO.
    en_localdiff: out std_logic;                  --! Localdiff enable
    s_in_localdiff: out std_logic_vector(DRANGE-1 downto 0);    --! Sample input to the local differences module
    en_localdiff_shift: out std_logic;                --! Enables localdiff shift.
    config_valid: in std_logic;                   --! Validates the configuration during the compression
    eop: out std_logic;                       --! End of package flag.
    z_opcode: in std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);   --! z value as calculated by the opcode module
    z_configured: in std_logic_Vector(W_Nz_GEN-1 downto 0);     --! Number of samples in a band set by the user
    clear_curr: out std_logic;                    --! Asynchronous clear of FIFO pointers.
    clear: in std_logic;                      --! Synchronous clear to reset all registers.
    fsm_invalid_state:  out std_logic;                --! Signals that the IP has entered an invalid state.
    --Current FIFO    
    empty_curr: in std_logic;                   --! CURR FIFO flag empty.               
    aempty_curr: in std_logic;                    --! CURR FIFO flag almost empty.
    full_curr: in std_logic;                    --! CURR FIFO flag full. 
    afull_curr: in std_logic;                   --! CURR FIFO flag almost full.
    hfull_record: in std_logic                    --! Hfull flag of the record FIFO.
    );
end ccsds_fsm_shyloc_bil;

architecture arch_bil of ccsds_fsm_shyloc_bil is
  signal en_opcode_cmb, opcode_valid, en_opcode_d1: std_logic;
  signal r_update_curr_cmb, r_update_top_cmb, r_update_top_left_cmb, r_update_left_cmb, r_update_top_right_cmb: std_logic;
  signal w_update_top_cmb, w_update_left_cmb, w_update_top_right_cmb, w_update_top_left_cmb: std_logic;
  signal opcode_write, opcode_write_cmb, opcode_localsum_reg, opcode_localsum_cmb: std_logic_vector (4 downto 0);
  signal neighbours_state_cmb, neighbours_state_reg: std_logic;
  signal s_in_top_right_reg, s_in_top_right_cmb, s_in_localsum, s_in_localsum_cmb, s_in_localsum_reg, s_in_left_cmb, s_in_left_reg: std_logic_vector (s_in_left'high downto 0);
  signal en_localsum_cmb, en_localsum_reg: std_logic;
  signal en_localdiff_reg, en_localdiff_shift_reg: std_logic;
  
  -- state register
  type state_type is (idle, s0, s1, finished, finished_clear);
  
  signal state_reg, state_next: state_type;
  type state_type2 is (idle, s0, s1);
  signal  state_reg2, state_next2: state_type2;
  --type state_type4 is (idle, s0, s1, s2, s3, s4, finished, finished_clear);
  --signal state_reg4, state_next4: state_type4;
  signal en_write_nei, en_write_nei_cmb: std_logic;
    
  signal finished_opcode, finished_opcode_cmb, clear_curr_reg, clear_curr_cmb, eop_cmb: std_logic;  
  signal fsm_invalid_state_cmb, fsm_invalid_state_cmb2, fsm_invalid_state_reg: std_logic;
  
begin

  ----------------------------------------------------------------------------- 
  -- Output assignments
  -----------------------------------------------------------------------------
  
  en_opcode <= opcode_valid;
  s_in_top_right <= s_in_top_right_reg;
  opcode_localsum <= opcode_localsum_reg;
  s_in_left <= s_in_left_reg;
  s_in_localsum <= s_in_localsum_reg;
  en_localsum <= en_localsum_reg;
  en_localdiff <= en_localdiff_reg;
  en_localdiff_shift <= en_localdiff_shift_reg;
  fsm_invalid_state <= fsm_invalid_state_reg;
  -- Driven to zero because they are not really used.
  w_update_curr <= '0';
  clear_curr <= '0';
  ----------------------------------------------------------------------------- 
  --  Registers
  -----------------------------------------------------------------------------
  
  process(clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      state_reg <= idle;
      r_update_curr <= '0';
      r_update_top_right <= '0';
      w_update_top_right <= '0';
      opcode_write <= (others => '0');
      s_in_top_right_reg <= (others => '0');
      state_reg2 <= idle;
      en_localsum_reg  <= '0';
      opcode_valid <= '0';
      en_write_nei <= '0';
      opcode_localsum_reg <= (others => '0');
      s_in_left_reg <= (others => '0');
      s_in_localsum_reg <= (others => '0');   
      finished_opcode <= '0';
      clear_curr_reg <='0';
      eop <= '0';
      fsm_invalid_state_reg <= '0';
    elsif clk'event and clk = '1' then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        state_reg <= idle;
        r_update_curr <= '0';
        r_update_top_right <= '0';
        w_update_top_right <= '0';
        opcode_write <= (others => '0');
        s_in_top_right_reg <= (others => '0');
        state_reg2 <= idle;
        en_localsum_reg  <= '0';
        opcode_valid <= '0';
        en_write_nei <= '0';
        opcode_localsum_reg <= (others => '0');
        s_in_left_reg <= (others => '0');
        s_in_localsum_reg <= (others => '0'); 
        finished_opcode <= '0';
        clear_curr_reg <='0';
        eop <= '0';
        fsm_invalid_state_reg <= '0'; 
      else
        opcode_valid <= en_opcode_cmb;
        r_update_curr <= r_update_curr_cmb;
        r_update_top_right <= r_update_top_right_cmb;
        w_update_top_right <= w_update_top_right_cmb;
        s_in_top_right_reg <= s_in_top_right_cmb;
        s_in_localsum_reg <= s_in_localsum_cmb;
        state_reg <= state_next;
        state_reg2 <= state_next2;
        opcode_write <= opcode_write_cmb;
        en_localsum_reg  <= en_localsum_cmb;
        en_write_nei  <= en_write_nei_cmb;
        opcode_localsum_reg <= opcode_localsum_cmb;
        s_in_left_reg <= s_in_left_cmb; 
        finished_opcode <= finished_opcode_cmb;
        clear_curr_reg <=clear_curr_cmb;
        eop <= eop_cmb;
        fsm_invalid_state_reg <= fsm_invalid_state_cmb or fsm_invalid_state_cmb2;
      end if;
    end if;
  end process;
  
  ----------------------------------------------------------------------------- 
  -- FSM for input FIFO ctrl and opcode enable: we enable opcode when there is a 
  -- valid sample read from the input FIFO. Considers that the record FIFO
  -- is not half full in order to stop processing.
  -----------------------------------------------------------------------------
  fsm_opcode: process(rst_n, state_reg, empty_curr, aempty_curr, finished_opcode_cmb, clear_curr_reg, config_valid, hfull_record)   
  begin
    r_update_curr_cmb <= '0';
    en_opcode_cmb <= '0';
    state_next <= state_reg;  
    clear_curr_cmb <= clear_curr_reg;
    eop_cmb <= '0'; 
    fsm_invalid_state_cmb <= '0';
    case state_reg is
      when idle =>
        if (rst_n = '1' and config_valid = '1' and finished_opcode_cmb = '0') then
          state_next <= s0;
        end if;
      when s0 =>
        if (empty_curr = '0' and finished_opcode_cmb = '0' and hfull_record = '0') then
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
        if (not (empty_curr = '1' or aempty_curr = '1') and finished_opcode_cmb = '0' 
        and hfull_record = '0') then
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
  -- FSM to decide when to read/write from neighbors
  -----------------------------------------------------------------------------
  
  fsm_neighbours: process(state_reg2, rst_n, opcode, opcode_write, opcode_valid, s_out, s_in_top_right_reg, z, finished_opcode, z_configured)
    variable write_samples: std_logic_vector (2 downto 0);
    variable read_samples : std_logic_vector (4 downto 0);
  begin
    --r_update_curr_cmb <= '0';
    r_update_top_right_cmb <= '0';
    r_update_top_cmb  <= '0';
    r_update_top_left_cmb  <= '0';
    r_update_left_cmb <= '0';
    w_update_top_right_cmb <= '0';
    read_samples := ctrl_fifo_read(opcode);
    opcode_write_cmb <= opcode_write;
    state_next2 <= state_reg2;
    en_write_nei_cmb <= '0';
    s_in_top_right_cmb <= s_in_top_right_reg;
    fsm_invalid_state_cmb2 <= '0';
    case state_reg2 is
      when idle =>
        if (rst_n = '1' and opcode_valid = '1') then
          state_next2 <= s1;
        end if;
      when s1 =>
        if (opcode_valid = '0') then
          state_next2 <= idle;
        end if;
        --Data to write in top right FIFO and write enable
        s_in_top_right_cmb <= s_out;
        if (opcode /= "11111" and opcode /= "10111" and opcode /= "11010") then --sample is not in the last row
          w_update_top_right_cmb <= '1';
        else
          w_update_top_right_cmb <= '0';
        end if;
        -- Enable writing in neigbouring FIFOs
        en_write_nei_cmb <= '1' and not finished_opcode;
        -- Opcode value to be considered when writing in neighbouring FIFOs
        opcode_write_cmb <= opcode;
        
        if opcode = "10001" and unsigned(z) < unsigned(z_configured) -1 then
          r_update_top_right_cmb <= '0';
        elsif opcode = "10001" and unsigned(z) = unsigned(z_configured) -1 then
          r_update_top_right_cmb <= '1';
        elsif opcode = "10111" and unsigned(z) < unsigned(z_configured)-1 then
          r_update_top_right_cmb  <= '1';
        else
          r_update_top_right_cmb <= read_samples(1);
        end if;
        
        r_update_top_cmb  <= read_samples(2);
        r_update_top_left_cmb  <= read_samples(3);
        r_update_left_cmb <= read_samples(4);
      when others =>
        state_next2 <= idle;
        fsm_invalid_state_cmb2 <= '1';
    end case;
  end process;
  
  -----------------------------------------------------------------------------
  -- process to write in input samples and enable localsum
  -- also put correct data in FIFO s_in_left
  -----------------------------------------------------------------------------
  process(en_write_nei, opcode_write, s_in_top_right_reg, s_in_left_reg, opcode_localsum_reg, s_in_localsum_reg)
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
    if (en_write_nei = '1') then
      -- write samples from FIFOS
      s_in_left_cmb <= s_in_top_right_reg;
    
      w_update_top_cmb <= write_samples(0);
      w_update_left_cmb <= write_samples(1);
      w_update_top_left_cmb <= write_samples(2);
      
      -- enable localsum with correct localsum data
      en_localsum_cmb <= '1';
      opcode_localsum_cmb <= opcode_write;
      s_in_localsum_cmb <= s_in_top_right_reg;
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

end arch_bil;