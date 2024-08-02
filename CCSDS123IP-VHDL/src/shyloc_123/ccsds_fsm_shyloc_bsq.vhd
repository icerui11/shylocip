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
-- Design unit  : CCSDS123 FSM for BSQ predictor
--
-- File name    : ccsds_fsm_shyloc_bsq_mem.vhd
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


--!@file #ccsds_fsm_shyloc_bsq.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Takes care of the control in BSQ architecture


entity ccsds_fsm_shyloc_bsq is
  generic (DRANGE: integer := 16;       --! Dynamic range of the input samples
       --W_ADDR_BANK: integer := 2;     --! Bit width of the address signal in the register banks.
       W_ADDR_IN_IMAGE: integer := 16;  --! Bit width of the image coordinates (x, y, z)
       W_BUFFER: integer := 64;     --! Bit width of the output buffer.
       RESET_TYPE: integer := 1     --! Reset flavour (0) asynchronous (1) synchronous
      );
  port (
    clk: in std_logic;                        --! Clock signal.
    rst_n: in std_logic;                      --! Reset signal. Active low.

    r_update_curr: out std_logic;                 --! Read enable in the CURR FIFO. Active high.
    
    w_update_top_right: out std_logic;                --! Write enable in the TOP RIGHT FIFO. Active high. 
    r_update_top_right: out std_logic;                --! Read enable in the TOP RIGHT FIFO. Active high.
  
    en_opcode: out std_logic;                   --! Enable opcode
    opcode: in std_logic_vector (4 downto 0);           --! Opcode value (output of OPCODE module)
    z: in std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);      --! z coordinate
    z_predictor_out: in std_logic_vector(W_ADDR_IN_IMAGE-1 downto 0); --! z coordinate
    en_localsum: out std_logic;                   --! Enable signal for local sum module. Active high.
    opcode_localsum: out std_logic_vector (4 downto 0);       --! Opcode value input for localsum module
    s_out: in std_logic_vector (DRANGE-1 downto 0);           --! Current sample to be compressed, output from current FIFO s(x, y, z)
    s_in_left: out std_logic_vector (DRANGE-1 downto 0);      --! Current sample to be compressed, input for TOP FIFO s(x, y, z)
    s_in_top_right: out std_logic_vector (DRANGE-1 downto 0);   --! Sample to be stored in TOP RIGHT FIFO. Comes from FSM.
    
    en_localdiff: out std_logic;                  --! Enable localdiff computation. 
    s_in_localdiff: out std_logic_vector(DRANGE-1 downto 0);    --! Current sample - Input of localdiff module
    
    en_localdiff_shift: out std_logic;                --! Activates the shift of the localdiff vector.
    opcode_predictor_out: in std_logic_vector (4 downto 0);     --! Opcode output from predictor.
    config_valid: in std_logic;
    eop: out std_logic;                       --! End of package flag.
    z_opcode: in std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);   --! z coordinate output from OPCODE
    z_configured: in std_logic_Vector(W_Nz_GEN-1 downto 0);     --! Number of bands configured by the user
    P_configured: in std_logic_vector(3 downto 0);          --! P configured by the user
    PREDICTION_configured: in std_logic_vector(0 downto 0);     --! Predition type configured by the user (0) full (1) reduced.
    clear_curr: out std_logic;                    --! Clear current FIFO
    clear: in std_logic;                      --! Synchronous clear for all registers.
    fsm_invalid_state:  out std_logic;                --! Invalid FSM signal
    config_predictor: in config_123_predictor;            --! Predictor configuration values
    empty_curr: in std_logic;                   --! CURR FIFO flag empty.               
    aempty_curr: in std_logic;                    --! CURR FIFO flag almost empty.
    full_ld_ahbo: in std_logic;                   --! Full flag from AHBO FIFO. 
    empty_ld_ahbi: in std_logic;                  --! Empty flag from AHBI FIFO.
    w_update_ld_ahbo: out std_logic;                --! Write update in AHBO FIFO
    r_update_ld_ahbi: out std_logic;                --! Read update in AHBI FIFO
    w_update_record: out std_logic;                 --! Write update for record FIFO
    r_update_record: out std_logic;                 --! Read update for record FIFO
    hfull_record: in std_logic;                   --! Flag signals that record FIFO is hfull
    empty_record: in std_logic;                   --! Flag signals that record FIFO is empty.
    aempty_record: in std_logic;                  --! Flag signals that record FIFO is almost empty.
    r_update_ld: out std_logic;                   --! Read a central local difference value (for dot product)
    r_update_wei: out std_logic;                  --! Read a weight value (for dot product)
    en_weight_dir_fsm: out std_logic;               --! Enable computation of directional weights
    en_predictor: out std_logic;                  --! Enable predictor
    clear_mac: out std_logic;                   --! Clear MAC.
    
    en_weight_central_fsm: out std_logic;             --! Enable computation of central weights
    address_central: out std_logic_vector (W_COUNT_PRED - 1 downto 0);    --! Address to read default weight initialization values
    opcode_weight_out: in std_logic_vector (4 downto 0);      --! Opcode used by weight update
    opcode_weight_fsm: out std_logic_vector (4 downto 0);     --! Opcode sent to weight update
    r_update_wei_dir: out std_logic                 --! Read update for directional weights
    
    );
end ccsds_fsm_shyloc_bsq;

architecture arch_bsq of ccsds_fsm_shyloc_bsq is
  signal en_opcode_cmb, opcode_valid: std_logic;
  signal r_update_curr_cmb, r_update_top_cmb, r_update_top_left_cmb, r_update_left_cmb, r_update_top_right_cmb: std_logic;
  signal w_update_top_cmb, w_update_left_cmb, w_update_top_right_cmb, w_update_top_left_cmb: std_logic;
  signal opcode_write, opcode_write_cmb, opcode_localsum_reg, opcode_localsum_cmb: std_logic_vector (4 downto 0);
  signal opcode_weight_reg, opcode_weight_fsm_out: std_logic_vector (4 downto 0);
  signal s_in_top_right_reg, s_in_top_right_cmb, s_in_localsum, s_in_localsum_cmb, s_in_localsum_reg, s_in_left_cmb, s_in_left_reg: std_logic_vector (s_in_left'high downto 0);
  signal en_localsum_cmb, en_localsum_reg: std_logic;
  signal en_localdiff_reg, en_localdiff_shift_reg: std_logic;
  
  -- state register
  type state_type is (idle, s0, s1, finished, finished_clear);
  signal state_reg, state_next: state_type;
  type state_type2 is (idle, s1);
  signal state_reg2, state_next2: state_type2;
  type state_type3 is (idle, s1);
  signal state_reg3, state_next3: state_type3;
  type state_type4 is (idle, s1, s2, s3, s4, s5, s6, s7, s8, finished);
  signal state_reg4, state_next4: state_type4;
  
  signal en_write_nei, en_write_nei_cmb: std_logic;
  -- to control when a new ld value can be retrieved
  signal r_update_record_reg, r_update_record_tmp: std_logic;
  
  signal pred_counter, pred_counter_next, pred_bound, pred_bound_update_cmb, pred_bound_update, pred_bound_update_r_ld_cmb, pred_bound_update_r_ld: unsigned (W_COUNT_PRED-1 downto 0);
        
  signal finished_opcode, finished_opcode_cmb, clear_curr_reg, clear_curr_cmb, eop_cmb: std_logic;
  signal fsm_invalid_state_cmb, fsm_invalid_state_cmb2, fsm_invalid_state_cmb3, fsm_invalid_state_cmb4 , fsm_invalid_state_reg: std_logic;
  
  --Counter to ensure we have finished computing the directional mac before we proceed with the next sample
  signal directional_mac_counter, directional_mac_counter_cmb : unsigned (2 downto 0);
  signal central_mac_counter, central_mac_counter_cmb : unsigned (2 downto 0);
  -- Number of cycles between last weight update operation and prediction.
  constant N_CYCLES_UPDATE_PRED : integer := 5;
  
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
  r_update_record <= r_update_record_tmp;
  opcode_weight_fsm <= opcode_weight_fsm_out;
  clear_curr <= clear_curr_reg;
  clear_mac <= '0';
  fsm_invalid_state <= fsm_invalid_state_reg;

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
        fsm_invalid_state_reg <= fsm_invalid_state_cmb or fsm_invalid_state_cmb2 or fsm_invalid_state_cmb3 or fsm_invalid_state_cmb4;
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
      end if;
    end if;
  end process;
  
  --------------------------------------------------------------------------------------------
  -- This block is the same as in BIP. Since the opcode changes according to the correct order
  -- this shall not vary. Later we can reduce the number of registers, 
  -- since we won't likely have one compressed sample per cycle, we will not need to
  -- propagate values through the modules 
  -------------------------------------------------------------------------------------------
  ----------------------------------------------------------------------------- 
  -- FSM for input FIFO ctrl and opcode enable: we enable opcode when there is a 
  -- valid sample read from the input FIFO. Considers that the record FIFO
  -- is not half full in order to stop processing.
  -----------------------------------------------------------------------------
  fsm_opcode: process(state_reg, empty_curr, aempty_curr, finished_opcode_cmb, clear_curr_reg, config_valid, hfull_record, rst_n)   
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
  fsm_neighbours: process(rst_n, opcode, opcode_write, opcode_valid, s_out, s_in_top_right_reg, finished_opcode, state_reg2)
    variable write_samples: std_logic_vector (2 downto 0);
    variable read_samples : std_logic_vector (4 downto 0);
  begin
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
        if finished_opcode = '0' then
          --Data to write in top right FIFO and write enable
          s_in_top_right_cmb <= s_out;
          if (opcode /= "11111" and opcode /= "10111" and opcode /= "11010") then --sample is not in the last row
            w_update_top_right_cmb <= '1';
          else
            w_update_top_right_cmb <= '0';
          end if;
          -- Enable writing in neigbouring FIFOs
          en_write_nei_cmb <= '1';
          -- Opcode value to be considered when writing in neighbouring FIFOs
          opcode_write_cmb <= opcode;
          r_update_top_right_cmb <= read_samples(1);
          r_update_top_cmb  <= read_samples(2);
          r_update_top_left_cmb  <= read_samples(3);
          r_update_left_cmb <= read_samples(4);
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
  -- Process for localdiff activation
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
        w_update_record <= en_localdiff_reg; -- write new localdiff values -- guaranteed not full because we do not retrieve new opcode if fifo is half-full
      end if;
    end if;
  end process;
  
  -- Until here, I have used registerd outputs, but from here they are not
  -- as we are evaluating the full and empty flags of the AHB FIFOs.

  -----------------------------------------------------------------------------
  -- Compute number of iterations depending on z and the configured P
  -----------------------------------------------------------------------------
  process (z_predictor_out, P_configured)
  begin
    if (unsigned(z_predictor_out) < unsigned(P_configured)) then
      pred_bound <= unsigned(z_predictor_out(W_COUNT_PRED-1 downto 0));
    else
      pred_bound <= resize(unsigned(P_configured), pred_bound'length);
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Registers for FSM3
  -----------------------------------------------------------------------------
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      state_reg3 <= idle;
      r_update_record_reg <= '0';
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        state_reg3 <= idle;
        r_update_record_reg <= '0';
      else
        state_reg3 <= state_next3;
        r_update_record_reg <= r_update_record_tmp;
      end if;
    end if;   
  end process;
  
  -----------------------------------------------------------------------------
  --  FSM3 Controls when to write in AHBO FIFO
  -----------------------------------------------------------------------------
  fsm_write_ahb: process (r_update_record_reg, state_reg3, full_ld_ahbo, P_configured)
  begin
    state_next3 <= state_reg3;
    w_update_ld_ahbo <= '0';
    fsm_invalid_state_cmb3 <= '0';
    case (state_reg3) is
      when idle => 
        if (unsigned(P_configured) > 0) then --do not write anything if P = 0
          -- There is valid data and the FIFO is not full
          w_update_ld_ahbo <= r_update_record_reg and not full_ld_ahbo;
          if (r_update_record_reg = '1' and full_ld_ahbo = '1') then
            state_next3 <= s1;
          end if;
        end if;
      when s1 =>
        -- wait for !full
        w_update_ld_ahbo <= not full_ld_ahbo;
        if (full_ld_ahbo = '0') then
          state_next3 <= idle;
        end if;
      when others => 
        state_next3 <= idle;
        fsm_invalid_state_cmb3 <= '1';
    end case;
  end process;
  
  -----------------------------------------------------------------------------
  -- Registers for FSM4
  -----------------------------------------------------------------------------
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      state_reg4 <= idle;
      pred_counter <= (others => '0'); 
      opcode_weight_reg <= (others => '0');
      pred_bound_update <= (others => '0');
      pred_bound_update_r_ld <= (others => '0');
      directional_mac_counter <= (others => '0');
      central_mac_counter <= (others => '0');
    elsif clk'event and clk = '1' then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        state_reg4 <= idle;
        pred_counter <= (others => '0'); 
        opcode_weight_reg <= (others => '0');
        pred_bound_update <= (others => '0');
        pred_bound_update_r_ld <= (others => '0');
        directional_mac_counter <= (others => '0');
        central_mac_counter <= (others => '0');
      else
        state_reg4 <= state_next4;
        pred_counter <= pred_counter_next;
        opcode_weight_reg <= opcode_weight_fsm_out;
        pred_bound_update <= pred_bound_update_cmb;
        pred_bound_update_r_ld <= pred_bound_update_r_ld_cmb;
        directional_mac_counter <= directional_mac_counter_cmb;
        central_mac_counter <= central_mac_counter_cmb;
      end if;
    end if;
  end process;
  
  -------------------------------------------------------------------------
  --This can be optimized to take less cycles, depending on pred_bound
  --When P = 0 and FULL prediction, it is obvious that we have to wait
  --for the directional differences to be computed
  --but in other cases, when we wait for AMBA, we do not need to wait there.
  ---------------------------------------------------------------------------
  
  -----------------------------------------------------------------------------
  -- FSM4 reads values from record fifo
  -- Waits until central ld are written and read
  -- Iterates according to pred_bound to read ld and weight pairs for MAC
  -----------------------------------------------------------------------------
  fsm_pred: process (state_reg4, empty_record, state_next3, pred_counter, opcode_weight_out, opcode_weight_reg, empty_ld_ahbi, opcode_predictor_out, pred_bound, pred_bound_update, P_configured, z_predictor_out, pred_bound_update_r_ld, z_configured, z, directional_mac_counter, central_mac_counter, prediction_configured)
  begin
    state_next4 <= state_reg4;
    r_update_record_tmp <= '0';
    en_predictor <= '0';
    pred_counter_next <= pred_counter;
    en_weight_dir_fsm <= '0';
    en_weight_central_fsm <= '0';
    address_central <= (others => '0');
    r_update_ld_ahbi <= '0';
    opcode_weight_fsm_out <= opcode_weight_reg;
    r_update_ld <= '0';
    r_update_wei <= '0';
    r_update_wei_dir <= '0';
    pred_bound_update_cmb <= pred_bound_update;
    pred_bound_update_r_ld_cmb <= pred_bound_update_r_ld;
    fsm_invalid_state_cmb4 <= '0';
    directional_mac_counter_cmb <= directional_mac_counter;
    central_mac_counter_cmb <= central_mac_counter;
    case (state_reg4) is
      when idle => 
        if (empty_record = '0' and state_next3 = idle) then 
          r_update_record_tmp <= '1';
          state_next4 <= s3;
        end if;
      when s3 =>
        if (empty_record = '0') then
          --for first sample - no need to check if things are available (not used)
          en_predictor <= '1'; 
          -- Read values from record
          r_update_record_tmp <= '1';
          state_next4 <= s5;
          -- Store opcode
          opcode_weight_fsm_out <= opcode_weight_out;
        end if;
      when s1 =>
        if (empty_record = '0' and state_next3 = idle) then 
            en_predictor <= '1'; 
            --read a new localdiff vector for MAC - not needed for first sample
            r_update_record_tmp <= '1'; 
            -- read localdiff value for weight update
            r_update_ld <= '1'; 
            r_update_wei <= '1';
            --and directional weights
            r_update_wei_dir <= '1'; 
            state_next4 <= s5;
            opcode_weight_fsm_out <= opcode_weight_out;
            --store previous  z value for weight update iterations!
            --store previous pred_bound value; used for update only
            pred_bound_update_cmb <= pred_bound;
            pred_bound_update_r_ld_cmb <= pred_bound_update;
        elsif opcode_predictor_out = "10111" and unsigned (z) = unsigned(z_configured)-1 then 
          --if last sample, just one more predictor (no read from record)
          en_predictor <= '1'; 
          state_next4 <= finished;
        end if;
      when s5 =>
          if ((pred_bound > 0 or unsigned (z_predictor_out) > 0) and (unsigned(P_configured) > 0)) then
            if (empty_ld_ahbi = '0') then 
              --I spend too much time here: be careful to prefetch memory data here!
              --this is for next, so pred_bound based on z_predictor is fine
              r_update_ld_ahbi <= '1'; 
              state_next4 <= s2;
            end if;
          else
            -- insert one idle cycle between enabling predictor and updating the weights
            state_next4 <= s2; 
          end if;
      when s2 => 
          if (pred_counter = 0 ) then
            --just once, will give 3 directional weights
            -- directional weights only for full prediction
            en_weight_dir_fsm <= '1'; 
            --reset to initial value, 3 is the number of cycles it takes to obtain the mac from this moment
            directional_mac_counter_cmb <= to_unsigned(4, directional_mac_counter_cmb'length);
          else
            if directional_mac_counter > 0 then
              directional_mac_counter_cmb <= directional_mac_counter - 1;
            end if;
            opcode_weight_fsm_out <= opcode_weight_reg;
          end if;
          
          if (pred_counter < pred_bound) then
            --this refers to update, so there is a situation in which I need a pred_bound based on
            --previous z_predictor
            if pred_counter < pred_bound_update then            
              en_weight_central_fsm <= '1';
            else  
              en_weight_central_fsm <= '0';
            end if;
            
            if (pred_counter < pred_bound - 1) then
              if pred_counter < pred_bound_update_r_ld - 1 then
                r_update_wei <= '1';
              else
                r_update_wei <= '0';
              end if;
              if pred_counter < pred_bound_update - 1 then
                --another pair ld, weights available in the next clk
                r_update_ld <= '1'; 
              else
                r_update_ld <= '0'; 
              end if;
            end if;
            --for weight initialization
            address_central <= std_logic_vector(pred_counter); 
            pred_counter_next <= pred_counter + 1;
            
            if (pred_counter < pred_bound - 1) then
              if empty_ld_ahbi = '0' then
                r_update_ld_ahbi <= '1';
              else
                state_next4 <= s6; 
              end if;
            end if;
          else
            pred_counter_next <= (others => '0');
            central_mac_counter_cmb <= to_unsigned(1, central_mac_counter'length);
            state_next4 <= s4;
          end if;
      when s6 => 
        if empty_ld_ahbi = '0' then
          r_update_ld_ahbi <= '1';
          state_next4 <= s2;
        end if;
      when s4 => 
        --stay in this state until computation of directional MAC has been completed
        if directional_mac_counter = 0 or PREDICTION_configured = "1" then
          --check if we have finished with the central also
          if central_mac_counter = 0 or pred_bound_update = 0 or PREDICTION_configured = "1" then
            state_next4 <= s7;
          else
            central_mac_counter_cmb <= central_mac_counter - 1;
          end if;
        else
          directional_mac_counter_cmb <= directional_mac_counter - 1;
          central_mac_counter_cmb <= central_mac_counter - 1;         
        end if;
      when s7 => --need one more cycle for the MAC
        state_next4 <= s1;
      when finished =>
      when others => 
        state_next4 <= idle;
        fsm_invalid_state_cmb4 <= '1';
    end case;
  end process;
end arch_bsq;