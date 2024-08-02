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
-- Design unit  : sample fsm module
--
-- File name    : sample_fsm.vhd
--
-- Purpose      : Finite state machine controlling the behaviour of the compressor
--
-- Note         :
--
-- Library      : shyloc_123
--
-- Author       :
--                Institute for Applied Microelectronics (IUMA)
--                University of Las Palmas de Gran Canaria
--                Campus Universitario de Tafira s/n
--                35017, Las Palmas de Gran Canaria
--                Canary Islands, Spain
--
-- Contact      : lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--
-- Instantiates : 
--============================================================================

--!@file #sample_fsm.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief Finite state machine controlling the behaviour of the compressor

--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;


--! Use shyloc_123 library
library shyloc_123; 
--! Use generic shyloc123 parameters
use shyloc_123.ccsds123_parameters.all; 
--! Use constant shyloc123 constants
use shyloc_123.ccsds123_constants.all;  


entity sample_fsm is
  generic (
    DRANGE      : integer := 16;    --! Dynamic range of the input samples.
    W_ADDR_BANK   : integer := 2;     --! Bit width of the address signal in the register banks.  
    W_ADDR_IN_IMAGE : integer := 16);   --! Bit width of the image coordinates (x, y, z).
    
  port (
  
    -- System Interface
    clk   : in std_logic;       --! Clock signal.                   
    rst_n : in std_logic;       --! Reset signal. Active low.
    
    -- Configuration and control Interface
    config_image    : in config_123_image;    --! Image relative configuration.
    config_valid    : in std_logic;       --! Configuration validation
    clear       : in std_logic;       --! Clear signal to force every module to its initial state.
    eop         : out std_logic;      --! End of processing flag.
    stop        : out std_logic;      --! Stop encoding flag.
    clear_curr      : out std_logic;      --! Clear flag.
    fsm_invalid_state : out std_logic;      --! Invalid state flag.
    
    -- Data Interface
    t_opcode    : in std_logic_vector (W_ADDR_IN_IMAGE*2-1 downto 0);   --! t coordinate.
    z_opcode    : in std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);     --! z coordinate.
    opcode      : in std_logic_vector (4 downto 0);             --! Code indicating the relative position of a sample in the spatial. 
    en_opcode   : out std_logic;                      --! Opcode enable signal.
    en_update   : out std_logic;                      --! Count update enable signal.
    en_create   : out std_logic;                      --! Codeword creation enable signal.
    en_bitpack    : out std_logic;                      --! Bitpack enable signal.
    flush     : out std_logic;                      --! Flag to perform a flush at the end of the compressed file.  
    
    -- Samples FIFO Interface
    empty_curr    : in std_logic;         --! Samples FIFo is empty.
    aempty_curr   : in std_logic;         --! Samples FIFo is almost empty.
    r_update_curr : out std_logic         --! Read request from the samples FIFO.
    );
end sample_fsm;
  
--!@brief Architecture of sample_fsm
architecture arch of sample_fsm is
  
  type state_type is (idle, s0, s1, s2, s3, s4, finished);
  signal state_reg, state_next: state_type;
  
  -- Internal registers
  signal z: std_logic_vector (W_ADDR_IN_IMAGE -1 downto 0);
  
  -- Modules control
  signal  en_opcode_reg : std_logic;
  signal  en_opcode_out : std_logic;
  signal  en_update_reg : std_logic;
  signal  en_create_reg, en_create_reg2 : std_logic;
  signal  clear_curr_reg  : std_logic;
  signal  clear_curr_cmb  : std_logic;
  signal  flush_reg   : std_logic;
  signal  en_bitpack_reg  : std_logic;

  signal last         : std_logic;
  signal last_bitpack, last_bitpack_reg, last_bitpack_reg2 : std_logic;
  signal en_opcode_cmb    : std_logic;
  signal r_update_curr_cmb  : std_logic;
  
  signal flag_stop    : std_logic;
  signal stop_opcode_cmb  : std_logic;
  signal stop_reg     : std_logic;
  signal eop_reg      : std_logic;
  signal eop_cmb      : std_logic;
  
  signal fsm_invalid_state_cmb  : std_logic;
  signal fsm_invalid_state_reg  : std_logic;
  
begin
  
  ---------------------
  -- Output assignments
  ---------------------
  eop <= eop_reg;
  fsm_invalid_state <= fsm_invalid_state_reg;
  stop <= stop_reg;
  en_opcode <= en_opcode_out;
  en_update <= en_update_reg;
  en_create <= en_create_reg;
  en_bitpack <= en_bitpack_reg;
  clear_curr <= clear_curr_reg;
  flush <= flush_reg;
  
  
  en_opcode_out <= en_opcode_reg and not (stop_opcode_cmb);
  
  ---------------------
  -- Input registration
  ---------------------
  z <= z_opcode;
  
  ---------------------------------------------------------
  -- Stop control (one cycle after flushing the bit packer)
  ---------------------------------------------------------
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      stop_reg <= '0';
    elsif clk'event and clk = '1' then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then  
        stop_reg <= '0';
      else
        stop_reg <= flag_stop;
      end if;
    end if;
  end process;
  
  ------------------------------------------
  -- Controls the input FIFO ctrl and opcode
  ------------------------------------------
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      state_reg <= idle;
      en_opcode_reg <= '0';
      r_update_curr <= '0';
      clear_curr_reg <= '0';
      eop_reg <= '0';
      fsm_invalid_state_reg <= '0';
    elsif clk'event and clk = '1' then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        state_reg <= idle;
        en_opcode_reg <= '0';
        r_update_curr <= '0';
        clear_curr_reg <= '0';
        eop_reg <= '0';
        fsm_invalid_state_reg <= '0';
      else
        fsm_invalid_state_reg <= fsm_invalid_state_cmb;
        state_reg <= state_next;
        en_opcode_reg <= en_opcode_cmb;
        r_update_curr <= r_update_curr_cmb;
        clear_curr_reg <= clear_curr_cmb;
        eop_reg <= eop_cmb;
      end if;
    end if;   
  end process;
  
  ------------------------------------------
  -- Controls the input FIFO ctrl and opcode
  ------------------------------------------
  process(rst_n, empty_curr, aempty_curr, state_reg, stop_opcode_cmb, stop_reg, config_valid, clear_curr_reg)
  begin
    r_update_curr_cmb <= '0';
    en_opcode_cmb <= '0';
    state_next <= state_reg;
    clear_curr_cmb <= clear_curr_reg;
    eop_cmb <= '0';
    fsm_invalid_state_cmb <= '0';
    case state_reg is
      when idle =>
        if (rst_n = '1' and config_valid = '1' and stop_opcode_cmb = '0') then
          state_next <= s0;
        end if;
      when s0 =>
        if (rst_n = '1' and empty_curr = '0' and stop_opcode_cmb = '0') then
          en_opcode_cmb <= '1';
          r_update_curr_cmb <= '1';
          state_next <= s1;
        end if;
        if (stop_opcode_cmb = '1') then
          state_next <= finished;
          clear_curr_cmb <= '1';
          en_opcode_cmb <= '0';
          r_update_curr_cmb <= '0';
          eop_cmb <= '1';
        end if;
      when s1 =>
        if (not (empty_curr = '1' or aempty_curr = '1') and stop_opcode_cmb = '0') then
          en_opcode_cmb <= '1';
          r_update_curr_cmb <= '1';
          state_next <= s1;
        -- Modified by AS: if clauses rearranged to increase code coverage
        elsif (stop_opcode_cmb = '1') then
          state_next <= finished;
          clear_curr_cmb <= '1';
          en_opcode_cmb <= '0';
          r_update_curr_cmb <= '0';
          eop_cmb <= '1';
        ------------------------------------
        else
          state_next <= s0;
        end if;
        -- if (stop_opcode_cmb = '1') then
          -- state_next <= finished;
          -- clear_curr_cmb <= '1';
          -- en_opcode_cmb <= '0';
          -- r_update_curr_cmb <= '0';
          -- eop_cmb <= '1';
        -- end if;
      --no more opcodes to generate, no more data to read
      when finished =>  
        if (stop_reg = '1') then
          state_next <= idle;
          clear_curr_cmb <= '0';
        end if;
      when others =>
        state_next <= idle;
        fsm_invalid_state_cmb <= '1';
    end case;
  end process;
  
  ------------------------------------------
  -- Controls stop flag of the opcode
  ------------------------------------------
  process (opcode, z, config_image)
  begin
    if (opcode = "10111" and unsigned(z) = unsigned(config_image.Nz)-1) then
      stop_opcode_cmb <= '1';
    else
      stop_opcode_cmb <= '0';
    end if;
  end process;
  
  ------------------------------------------------------------------------------------------
  -- Controls Count update module, Codeword creation module, flush flag and bitpack module
  ------------------------------------------------------------------------------------------
  process (clk, rst_n) is
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      en_update_reg <= '0';
      en_create_reg <= '0';
      flag_stop <= '0';
      flush_reg <= '0';
      last_bitpack <= '0';
      last <= '0';
      en_bitpack_reg <= '0';
      en_create_reg2 <= '0';
      last_bitpack_reg <= '0';
      last_bitpack_reg2 <= '0';
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        en_update_reg <= '0';
        en_create_reg <= '0';
        flag_stop <= '0';
        flush_reg <= '0';
        last_bitpack <= '0';
        last <= '0';
        en_bitpack_reg <= '0';
        en_create_reg2 <= '0';
        last_bitpack_reg <= '0';
        last_bitpack_reg2 <= '0';
      else
        en_update_reg <= en_opcode_out;
        en_create_reg <= en_opcode_out;
        en_create_reg2 <= en_create_reg;
        last_bitpack_reg <= last_bitpack;
        last_bitpack_reg2 <= last_bitpack_reg;
        if (en_update_reg = '1') then
          if (opcode = "10111" and unsigned(z) = unsigned(config_image.Nz)-1) then
            last_bitpack <= '1';
            last <= '1';
          end if;
        end if;
        en_bitpack_reg <= en_create_reg2;
        -- trigger the bitback one last time to flush the buffer
        if (last_bitpack_reg2 = '1' and flag_stop = '0') then
          -- no enable, but only flush - it is how the bitpacker shyloc_123s
          en_bitpack_reg <= '0';
          flush_reg <= '1';
        end if;
        if (flush_reg = '1') then
          flag_stop <= '1';
          flush_reg <= '0';
          en_bitpack_reg <= '0';
        end if;
      end if;
    end if;
  end process;
end arch;