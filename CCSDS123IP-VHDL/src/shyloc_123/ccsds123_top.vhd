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
-- Design unit  : CCSDS123 top module
--
-- File name    : ccsds123_top.vhd
--
-- Purpose      : Top module binds configuration + prediction + sample-adaptive encoder 
--                              + dispatcher module
--
-- Note         : 
--
-- Library      : 
--
-- Author       :
--                Institute for Applied Microelectronics (IUMA)
--                University of Las Palmas de Gran Canaria
--                Campus Universitario de Tafira s/n
--                                35017, Las Palmas de Gran Canaria
--                Canary Islands, Spain
--
-- Contact      : 
--                
-- Instantiates: 
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

library shyloc_utils;
use shyloc_utils.amba.all;

--!@file #ccsds123_top.vhd#
-- File history:
--      v1.0: 16/03/2015: Preliminary black box. 
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Top module connecting all sub-modules in the CCSDS123 IP core.
--!Includes configuration + prediction + sample-adaptive entropy coder + dispatcher module. 
--!Takes care of the generation of control output signals. 

entity ccsds123_top is
  generic (
    EN_RUNCFG       : integer := EN_RUNCFG;  --! Enables (1) or disables (0) runtime configuration.
    RESET_TYPE      : integer := RESET_TYPE;  --! Reset flavour asynchronous (0) synchronous (1)
    EDAC            : integer := EDAC;  --! Edac implementation (0) No EDAC (1) Only internal memories (2) Only external memories (3) both.
       PREDICTION_TYPE: integer := PREDICTION_TYPE;  --! Selects the prediction architecture to be implemented (0) BIP (1) BIP-MEM (2) BSQ (3) BIL (4) BIL-MEM.
    ENCODING_TYPE   : integer := ENCODING_TYPE;  --! (0) no sample-adaptive module instantitaed (1)  instantiate sample adaptive module

    HSINDEX_123      : integer := HSINDEX_123;     --! AHB slave index
    HSCONFIGADDR_123 : integer := HSCONFIGADDR_123;  --! ADDR field of the AHB Slave.
    HSADDRMASK_123   : integer := HSADDRMASK_123;  --! MASK field of the AHB Slave.

    HMINDEX_123   : integer := HMINDEX_123;  --! AHB master index.
    HMAXBURST_123 : integer := HMAXBURST_123;  --! AHB master burst beat limit (0 means unlimited) -- not used

    ExtMemAddress_GEN : integer := ExtMemAddress_GEN;  --! External memory address (used when EN_RUNCFG = 0)

    Nx_GEN             : integer := Nx_GEN;  --! Maximum number of samples in a line the IP core is implemented for. 
    Ny_GEN             : integer := Ny_GEN;  --! Maximum number of samples in a column the IP core is implemented for. 
    Nz_GEN             : integer := Nz_GEN;  --! Maximum number of bands the IP core is implemented for. 
    D_GEN              : integer := D_GEN;  --! Maximum input sample bitwidth IP core is implemented for. 
    IS_SIGNED_GEN      : integer := IS_SIGNED_GEN;  --! Singedness of input samples (used when EN_RUNCFG = 0).
    DISABLE_HEADER_GEN : integer := DISABLE_HEADER_GEN;  --! Disables header in the compressed image(used when EN_RUNCFG = 0).
    ENDIANESS_GEN      : integer := ENDIANESS_GEN;  --! Endianess of the input image (used when EN_RUNCFG = 0).

    P_MAX          : integer := P_MAX;  --! Maximum number of P the IP core is implemented for. 
    PREDICTION_GEN : integer := PREDICTION_GEN;  --! (0) Full prediction (1) Reduced prediction.
    LOCAL_SUM_GEN  : integer := LOCAL_SUM_GEN;  --! (0) Neighbour oriented (1) Column oriented.
    OMEGA_GEN      : integer := OMEGA_GEN;  --! Weight component resolution.
    R_GEN          : integer := R_GEN;  --! Register size

    VMAX_GEN        : integer := VMAX_GEN;   --! Factor for weight update.
    VMIN_GEN        : integer := VMIN_GEN;   --! Factor for weight update.
    T_INC_GEN       : integer := T_INC_GEN;  --! Weight update factor change interval
    WEIGHT_INIT_GEN : integer := WEIGHT_INIT_GEN;  --! Weight initialization mode.

    ENCODER_SELECTION_GEN : integer := ENCODER_SELECTION_GEN;  --! Selects between sample-adaptive(1) or block-adaptive (2) or no encoding (3) (used when EN_RUNCFG = 0)
    INIT_COUNT_E_GEN      : integer := INIT_COUNT_E_GEN;  --! Initial count exponent.
    ACC_INIT_TYPE_GEN     : integer := ACC_INIT_TYPE_GEN;  --! Accumulator initialization type.
    ACC_INIT_CONST_GEN    : integer := ACC_INIT_CONST_GEN;  --! Accumulator initialization constant.
    RESC_COUNT_SIZE_GEN   : integer := RESC_COUNT_SIZE_GEN;  --! Rescaling counter size.
    U_MAX_GEN             : integer := U_MAX_GEN;  --! Unary length limit.
    W_BUFFER_GEN          : integer := W_BUFFER_GEN;

    Q_GEN : integer := Q_GEN
    );
  port (
    -- System interface
    Clk_S : in std_logic;               --! IP core clock signal
    Rst_N : in std_logic;               --! IP core reset signal. Active low. 

    Clk_AHB : in std_logic;             --! AHB clock signal
    Rst_AHB : in std_logic;             --! AHB reset.

    --Input data interface
    DataIn          : in std_logic_vector (D_GEN-1 downto 0);  --! Uncompressed samples
    DataIn_NewValid : in std_logic;     --! Flag to validate input data 

    --Data output interface
    DataOut          : out std_logic_vector (W_BUFFER_GEN-1 downto 0);  --! Input data for uncompressed samples
    DataOut_NewValid : out std_logic;   --! Flag to validate input data
    IsHeaderOut      : out std_logic;  --! The data in DataOut corresponds to the header when the core is shyloc_123 working as a pre-processor.
    NbitsOut         : out std_logic_vector (5 downto 0);  --! Number of valid bits in the DataOut signal (needed when IsHeaderOut = 1).

    -- Control interface
    AwaitingConfig : out std_logic;  --! The IP core is waiting to receive the configuration through the AHB Slave interface.
    Ready          : out std_logic;  --! If asserted (high) the IP core has been configured and is able to receive new samples for compression. If de-asserted (low) the IP is not ready to receive new samples
    FIFO_Full      : out std_logic;  --! Signals that the input FIFO is full. Possible loss of data. 
    EOP            : out std_logic;  --! Compression of last sample has started.
    Finished       : out std_logic;  --! The IP has finished compressing all samples.
    ForceStop      : in  std_logic;     --! Force the stop of the compression.
    error          : out std_logic;  --! There has been an error during the compression.

    -- AHB 123 Slave interface
    AHBSlave123_In  : in  AHB_Slv_In_Type;   --! AHB slave input signals
    AHBSlave123_Out : out AHB_Slv_Out_Type;  --! AHB slave input signals

    -- AHB 123 Master interface
    AHBMaster123_In  : in  AHB_Mst_In_Type;   --! AHB slave input signals
    AHBMaster123_Out : out AHB_Mst_Out_Type;  --! AHB slave input signals

    -- External encoder signals. To be considered only when an external encoder is present, i.e. when ENCODER_SELECTION = 2. 
    ForceStop_Ext      : out std_logic;  --! Force the external IP core to stop
    AwaitingConfig_Ext : in  std_logic;  --! The external encoder IP core is waiting to receive the configuration.
    Ready_Ext          : in  std_logic;  --! Configuration has been received and the external encoder IP is ready to receive new samples.
    FIFO_Full_Ext      : in  std_logic;  --! The input FIFO of the external encoder IP is full.
    EOP_Ext            : in  std_logic;  --! Compression of last sample has started by the external encoder IP.
    Finished_Ext       : in  std_logic;  --! The external encoder IP has finished compressing all samples.
    Error_Ext          : in  std_logic  --! There has been an error during the compression in the external encoder IP.
    );

end ccsds123_top;

architecture arch of ccsds123_top is

  signal HeaderData   : std_logic_vector (W_BUFFER_GEN-1 downto 0);
  signal IsHeaderFlag : std_logic;
  signal NBitsHeader  : std_logic_vector(W_NBITS_HEAD_GEN-1 downto 0);

  signal Pre_DataOut       : std_logic_vector (D_GEN-1 downto 0);
  signal Pre_DataOut_Valid : std_logic;

  signal Sample_DataIn       : std_logic_vector (D_GEN-1 downto 0);
  signal Sample_DataIn_Valid : std_logic;

  signal SampleCompressed       : std_logic_vector (W_BUFFER_GEN-1 downto 0);
  signal SampleCompressed_Valid : std_logic;

  signal ready_pred                                : std_logic;
  signal config_valid                              : std_logic;
  signal sample_ready, sample_finished, sample_eop : std_logic;
  signal sign                                      : std_logic;
  signal control_out_s                             : ctrls;
  signal clear                                     : std_logic;

  signal AwaitingConfigOut : std_logic;
  signal ReadyOut          : std_logic;
  signal ErrorOut          : std_logic;
  signal ErrorCodeOut      : std_logic_vector(3 downto 0);
  signal FinishedOut       : std_logic;
  signal FIFOFullOut       : std_logic;
  signal EOPOut            : std_logic;

  signal pred_finished : std_logic;

  --Configuration records
  signal config_image      : config_123_image;
  signal config_predictor  : config_123_predictor;
  signal config_sample     : config_123_sample;
  signal config_weight_tab : weight_tab_type;

  signal dispatcher_ready    : std_logic;
  signal dispatcher_finished : std_logic;

  signal interface_awaiting_config : std_logic;
  signal interface_error           : std_logic;
  signal pred_eop                  : std_logic;

  --this signal will go to 0 after all the configuration values have been received.
  signal allow_rx, allow_rx_reg                                   : std_logic;
  --to count the amount of samples we have received
  signal counter_requested_samples, counter_requested_samples_cmb : unsigned (W_SAMPLE_COUNTER-1 downto 0);
  --signal clear: std_logic;
  signal config_ahbm                                              : config_123_ahbm;
  signal ahbm_status                                              : ahbm_123_status;

  signal clear_f      : std_logic;
  signal Awaiting_int : std_logic;
  signal error_f      : std_logic;
  signal DataInBE     : std_logic_vector (D_GEN-1 downto 0);
  signal DataInBE_SE  : std_logic_vector (D_GEN-1 downto 0);

  signal fifo_full_pred                                                                                                                 : std_logic;
  signal error_core_cmb, error_core_reg, fsm_invalid_state, fsm_insvalid_state_sample, fsm_insvalid_state_pred, fsm_insvalid_state_disp : std_logic;
  signal error_code_core_cmb, error_code_core_reg, error_code_interface                                                                 : std_logic_vector(3 downto 0);
  signal finished_cmb, finished_reg                                                                                                     : std_logic;

  -- state register for control signals
  type   state_type is (idle, check_errors, wait_for_config, compressing, stopped);
  signal state_next, state_reg     : state_type;
  signal ForceStop_reg, error_flag : std_logic;
  signal en_interface              : std_logic;

  -- Local reset
  signal rst_n_sync   : std_logic;
  signal rst_ahb_sync : std_logic;

  -- Internal edac
  signal top_edac_double_error    : std_logic;
  signal pred_edac_double_error   : std_logic;
  signal sample_edac_double_error : std_logic;
  signal disp_edac_double_error   : std_logic;

  signal NbitsOut_Ext : std_logic_vector (W_NBITS_HEAD_GEN-1 downto 0);
  
begin

  -----------------------------------------------------------------------------
  --! Reset synchronization
  -----------------------------------------------------------------------------
  
  sync_ahb_reset : entity shyloc_utils.reset_sync(two_ff)
    port map (
      clk       => clk_ahb,
      reset_in  => Rst_AHB,
      reset_out => rst_ahb_sync);

  sync_s_reset : entity shyloc_utils.reset_sync(two_ff)
    port map (
      clk       => clk_s,
      reset_in  => Rst_N,
      reset_out => rst_n_sync);

  sign  <= config_image.IS_SIGNED(0);
  clear <= clear_f or ForceStop or error_f;

  -----------------------------------------------------------------------------
  --! Output assignments
  -----------------------------------------------------------------------------
  --allow_rx makes use lower ready when we have received all the necessary samples
  Ready          <= ReadyOut and allow_rx and not (error_core_cmb);
  Finished       <= finished_cmb or ErrorOut;
  error          <= ErrorOut;
  AwaitingConfig <= AwaitingConfigOut and not error_flag;
  ErrorCodeOut   <= error_code_interface when (AwaitingConfigOut = '1' and ErrorOut = '1') else error_code_core_reg;
  EOP            <= EOPOut;
  FIFO_Full      <= FIFOFullOut;
  ForceStop_Ext  <= ForceStop;
  NbitsOut       <= NbitsOut_Ext (5 downto 0);


  -----------------------------------------------------------------------------
  --! Count the received samples, to lower ready when all have been received
  -----------------------------------------------------------------------------
  comb_allow_rx : process (config_image, counter_requested_samples, DataIn_NewValid, allow_rx_reg)
    variable counter_requested_samples_var : unsigned (W_SAMPLE_COUNTER-1 downto 0);
  begin
    counter_requested_samples_cmb <= counter_requested_samples;
    allow_rx                      <= allow_rx_reg;
    if (DataIn_NewValid = '1') then
      if (counter_requested_samples = unsigned(config_image.number_of_samples) -1) then
        allow_rx                      <= '0';
        counter_requested_samples_cmb <= counter_requested_samples;
      else
        counter_requested_samples_cmb <= counter_requested_samples + 1;
        allow_rx                      <= '1';
      end if;
    end if;
  end process;

  reg_ready_ctr : process (Clk_S, rst_n_sync)
    variable counter_requested_samples_var : unsigned (W_SAMPLE_COUNTER-1 downto 0);
  begin
    if (rst_n_sync = '0' and RESET_TYPE = 0) then
      counter_requested_samples <= (others => '0');
      allow_rx_reg              <= '1';
    elsif (Clk_S'event and Clk_S = '1') then
      if (rst_n_sync = '0' and RESET_TYPE = 1) then
        counter_requested_samples <= (others => '0');
        allow_rx_reg              <= '1';
      else
        if (config_valid = '0' or ForceStop = '1') then
          counter_requested_samples <= (others => '0');
          allow_rx_reg              <= '1';
        else
          counter_requested_samples <= counter_requested_samples_cmb;
          allow_rx_reg              <= allow_rx;
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  --! Generation of invalid fsm error signal
  -----------------------------------------------------------------------------
  fsm_invalid_state_sample : if ENCODER_SELECTION_GEN = 1 generate
    fsm_invalid_state <= fsm_insvalid_state_sample or fsm_insvalid_state_pred or fsm_insvalid_state_disp;
  end generate fsm_invalid_state_sample;

  fsm_invalid_state_no_sample : if ENCODER_SELECTION_GEN /= 1 generate
    fsm_invalid_state <= fsm_insvalid_state_pred or fsm_insvalid_state_disp;
  end generate fsm_invalid_state_no_sample;

  -----------------------------------------------------------------------------
  --! Generation of internal EDAC error signal
  -----------------------------------------------------------------------------
  internal_edac_sample : if ENCODER_SELECTION_GEN = 1 generate
    top_edac_double_error <= pred_edac_double_error or sample_edac_double_error or disp_edac_double_error;
  end generate internal_edac_sample;

  internal_edac_no_sample : if ENCODER_SELECTION_GEN /= 1 generate
    top_edac_double_error <= pred_edac_double_error or disp_edac_double_error;
  end generate internal_edac_no_sample;

  -----------------------------------------------------------------------------
  --! Generation of control signals output depending of the configuration 
  --! with/without encoding; sample/block; and the architecture. 
  -----------------------------------------------------------------------------
  comb_output_mux : process (config_image.ENCODER_SELECTION, dispatcher_finished, dispatcher_ready, interface_awaiting_config,
                            interface_error, sample_ready, ready_pred, AwaitingConfig_Ext, Error_Ext, sample_eop, pred_eop, ahbm_status, fifo_full_pred,
                            Finished_Ext, error_core_cmb, FIFO_Full_Ext, Ready_Ext)
  begin
    --Default values just as if the IP is working as predictor only
    AwaitingConfigOut <= interface_awaiting_config;
    ReadyOut          <= not(interface_awaiting_config) and ready_pred and dispatcher_ready;
    ErrorOut          <= interface_error;
    EOPOut            <= pred_eop;
    FinishedOut       <= dispatcher_finished;
    Awaiting_int      <= interface_awaiting_config;
    FIFOFullOut       <= fifo_full_pred;

    if (unsigned(config_image.ENCODER_SELECTION) = 0) then  --just preprocessor
      if (PREDICTION_TYPE = 0 or PREDICTION_TYPE = 3) then
        AwaitingConfigOut <= interface_awaiting_config;
      else
        AwaitingConfigOut <= interface_awaiting_config and ahbm_status.ahb_idle;  --ensure ahb master can receive configuration before going to 1;
      end if;
      ErrorOut    <= interface_error or error_core_cmb;
      ReadyOut    <= not(interface_awaiting_config) and ready_pred and dispatcher_ready;
      EOPOut      <= pred_eop;
      FinishedOut <= dispatcher_finished;
      FIFOFullOut <= fifo_full_pred;
    elsif (unsigned(config_image.ENCODER_SELECTION) = 2) then  --block_adaptive
      if (PREDICTION_TYPE = 0 or PREDICTION_TYPE = 3) then
                                        --both have to be '0'
        AwaitingConfigOut <= (interface_awaiting_config or AwaitingConfig_Ext);
      else
                                        --When there is AHB master, wait for it
        AwaitingConfigOut <= (interface_awaiting_config or AwaitingConfig_Ext) and ahbm_status.ahb_idle;
      end if;
      ErrorOut <= interface_error or Error_Ext or error_core_cmb;
      ReadyOut <= not(interface_awaiting_config) and ready_pred and dispatcher_ready and Ready_Ext;

      FinishedOut <= dispatcher_finished and Finished_Ext;
      FIFOFullOut <= fifo_full_pred or FIFO_Full_Ext;
    elsif (ENCODING_TYPE = 1 and unsigned(config_image.ENCODER_SELECTION) = 1) then
      --sample adaptive selected
      if (PREDICTION_TYPE = 0 or PREDICTION_TYPE = 3) then
        AwaitingConfigOut <= interface_awaiting_config;
      else
                                        --When there is AHB master, wait for it
        AwaitingConfigOut <= interface_awaiting_config and ahbm_status.ahb_idle;
      end if;
      ErrorOut    <= interface_error or error_core_cmb;
      FIFOFullOut <= fifo_full_pred;
      ReadyOut    <= not(interface_awaiting_config) and ready_pred and sample_ready and dispatcher_ready;
      EOPOut      <= sample_eop;
      FinishedOut <= dispatcher_finished;
    end if;
  end process;

  -----------------------------------------------------------------------------
  --! FSM: Control to register and manage error codes other than interface errors
  -----------------------------------------------------------------------------
  
  error_ctrl_fsm : process (ahbm_status.edac_double_error, ahbm_status.ahb_error,
                           fsm_invalid_state, error_core_reg, state_reg, rst_n_sync, AwaitingConfigOut,
                           FinishedOut, ForceStop_reg, finished_reg, interface_error, en_interface,
                           ErrorOut, error_code_core_reg, top_edac_double_error)
    variable error_core_var : std_logic;
    variable finished_var   : std_logic;
    variable first_error    : std_logic := '1';
  begin
    finished_cmb        <= finished_reg;
    error_core_cmb      <= error_core_reg;
    state_next          <= state_reg;
    error_code_core_cmb <= error_code_core_reg;
    error_f             <= '0';
    clear_f             <= '0';
    error_flag          <= '0';
    case (state_reg) is
      when idle =>
        -- Stay in idle until the configuration interface module is enabled
        if (rst_n_sync = '1' and en_interface = '1') then
          state_next <= check_errors;
        end if;
      when check_errors =>
        -- Check if there are error
        finished_cmb   <= '0';
        error_core_cmb <= '0';
        if interface_error = '0' then
          if AwaitingConfigOut = '0' and ErrorOut = '0' then
          -- If there are no errors and the configuration has been received, compress
            state_next <= compressing;
          else
          --Otherwise wait for config
            state_next <= wait_for_config;
          end if;
        else
        --If there were errors, signal them and clear the sub-modules
          error_f    <= '1';
          clear_f    <= '1';
          error_flag <= '1';
          state_next <= stopped;
        end if;
        if ErrorOut = '1' then
        --If while waiting for the configuration there are errors from other sources
          state_next <= stopped;
          error_f    <= '1';
          clear_f    <= '1';
          error_flag <= '1';
        end if;
      when wait_for_config =>
        if AwaitingConfigOut = '0' and ErrorOut = '0' then
          state_next <= compressing;
        elsif ErrorOut = '1' then
          state_next <= stopped;
          error_flag <= '1';
          error_f    <= '1';
          clear_f    <= '1';
        end if;
      when compressing =>
        --AHB no memory interface, src of errors only fsm_invalid_state or internal EDAC
        error_core_var := fsm_invalid_state;
        if error_core_var = '1' then
                                          --INVALID FSM ERROR
          error_code_core_cmb <= "0101";
        end if;
        error_core_var := error_core_var or top_edac_double_error;
        if error_core_var = '1' then
                                          --INTERNAL EDAC ERROR
          error_code_core_cmb <= "0111";  --EDAC ERROR   
        end if;
        -- Modified by AS: PREDICTION_TYPE = 4 (BIL-MEM) included
        if (PREDICTION_TYPE = 1 or PREDICTION_TYPE = 2 or  PREDICTION_TYPE = 4) then
        ----------------------------
                                          --aditionally, errors coming from AHB interface
          error_core_var := error_core_var or ahbm_status.ahb_error;
          if error_core_var = '1' then
                                          --AHB ERROR
            error_code_core_cmb <= "0110";
          end if;
          --Only EDAC errors from internal memories considered. External memories always accessed by AHB.
          --if (EDAC = 2 or EDAC = 3) then 
          --      --aditionally, errors coming from EDAC interface
          --      error_core_var := error_core_var or ahbm_status.edac_double_error;
                                          --      if error_core_var = '1' then
                                          --              error_code_core_cmb <= "0111"; --EDAC ERROR
                                          --      end if;
                                          --end if;
        end if;
        error_core_cmb <= error_core_var;
        finished_var   := FinishedOut or ForceStop_reg;
        finished_cmb   <= (FinishedOut or ForceStop_reg);
        -- Decision about next state
        if (error_core_var = '1' or finished_var = '1') then
          state_next <= stopped;
          error_f    <= '1';
          clear_f    <= '1';
        end if;
      when stopped =>
        if AwaitingConfigOut = '1' then
                                          --I am assuming there will be always 1 clk of awaiting_config = 1 between compressions
          state_next <= idle;
        end if;
      when others =>
        state_next <= idle;
    end case;
  end process;

  -----------------------------------------------------------------------------
  --! Registers
  -----------------------------------------------------------------------------
  error_ctrl_reg : process (Clk_S, rst_n_sync)
  begin
    if (rst_n_sync = '0' and RESET_TYPE = 0) then
      finished_reg        <= '0';
      state_reg           <= idle;
      error_core_reg      <= '0';
      error_code_core_reg <= (others => '0');
      ForceStop_reg       <= '0';
    elsif (Clk_S'event and Clk_S = '1') then
      if (rst_n_sync = '0' and RESET_TYPE = 1) then
        finished_reg        <= '0';
        state_reg           <= idle;
        error_core_reg      <= '0';
        error_code_core_reg <= (others => '0');
        ForceStop_reg       <= '0';
      else
        finished_reg        <= finished_cmb;
        state_reg           <= state_next;
        error_core_reg      <= error_core_cmb;
        error_code_core_reg <= error_code_core_cmb;
        ForceStop_reg       <= ForceStop;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------------------- 
  --! Status signal to be sent to AHB slave (written in memory-mapped register)
  ----------------------------------------------------------------------------- 

  control_out_s.AwaitingConfig <= AwaitingConfigOut;
  control_out_s.Ready          <= ReadyOut;
  control_out_s.error          <= ErrorOut;
  control_out_s.ErrorCode      <= ErrorCodeOut;
  control_out_s.EOP            <= EOPOut;
  control_out_s.FIFO_Full      <= FIFOFullOut;
  control_out_s.Finished       <= finished_cmb or ErrorOut;

  ----------------------------------------------------------------------------- 
  --! Configuration and header generation
  ----------------------------------------------------------------------------- 
  config_core : entity shyloc_123.ccsds123_config_core(arch)
    generic map (
      EN_RUNCFG       => EN_RUNCFG,
      PREDICTION_TYPE => PREDICTION_TYPE,
      RESET_TYPE      => RESET_TYPE,
      HSINDEX         => HSINDEX_123,
      HSADDR          => HSCONFIGADDR_123
      )
    port map(
      Clk                       => Clk_S,
      Rst_n                     => rst_n_sync,
      amba_clk                  => clk_ahb,
      amba_reset                => Rst_AHB_sync,
                                        -- Amba Interface
      ahbsi                     => AHBSlave123_In,
      ahbso                     => AHBSlave123_Out,
      en_interface              => en_interface,
      interface_awaiting_config => interface_awaiting_config,
      interface_error           => interface_error,
      error_code                => error_code_interface,
      dispatcher_ready          => dispatcher_ready,
      header                    => HeaderData,
      header_valid              => IsHeaderFlag,
      n_bits_header             => NBitsHeader,
      control_out_s             => control_out_s,
      config_image              => config_image,
      config_predictor          => config_predictor,
      config_sample             => config_sample,
      config_weight_tab         => config_weight_tab,
      config_valid              => config_valid,
      config_ahbm               => config_ahbm,
      ahbm_status               => ahbm_status,
      clear                     => clear
      );

  ----------------------------------------------------------------------------- 
  --! Preparation of input samples (sign extension, endianess swap)
  -----------------------------------------------------------------------------
  --Endianess 0 means little endian
  gen_endianess_swap : if D_GEN > 8 generate
    DataInBE <= DataIn(D_GEN-9 downto 0)&Datain(D_GEN-1 downto D_GEN-8) when (config_valid = '1' and config_image.ENDIANESS = "0" and config_image.BYPASS = "0") and unsigned(config_image.D) > 8 else DataIn;
  end generate gen_endianess_swap;

  gen_endianess_noswap : if D_GEN <= 8 generate
    DataInBE <= DataIn;
  end generate gen_endianess_noswap;

  --SIGN EXTENSION IS NECESSARY FOR SIGNED IMAGES WHEN D_conf < D_GEN
  process (config_image, DataInBE)
  begin
    if config_image.IS_SIGNED = "1" then
      for i in D_GEN-1 downto 0 loop
        if i > unsigned(config_image.D)-1 then
          DataInBE_SE(i) <= DataInBE (to_integer(unsigned(config_image.D))-1);
        else
          DataInBE_SE(i) <= DataInBE(i);
        end if;
      end loop;
    else
      DataInBE_SE <= DataInBE;
    end if;
  end process;

  ----------------------------------------------------------------------------- 
  -- Prediction
  ----------------------------------------------------------------------------- 

  gen_pred_bip : if PREDICTION_TYPE = 0 generate
    -----------------------------------------------------------------------------       
    --! BIP architecture for prediction
    -----------------------------------------------------------------------------
    PREDICTOR_BIP : entity shyloc_123.predictor_shyloc(arch)
      generic map (D_GEN           => D_GEN,
                                        --W_ADDR_BANK => W_ADDR, 
                   W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE,
                   W_BUFFER_GEN    => W_BUFFER_GEN,
                   RESET_TYPE      => RESET_TYPE
                   )
      port map (
        Clk                    => Clk_s,
        Rst_N                  => rst_n_sync,
        clk_ahb                => clk_ahb,
        rst_ahb                => rst_ahb_sync,
        sign                   => sign,
        s                      => DataInBE_SE,
        s_valid                => DataIn_NewValid,
        ready_pred             => ready_pred,
        finished_pred          => pred_finished,
        eop_pred               => pred_eop,
        mapped                 => Pre_DataOut,
        mapped_valid           => Pre_DataOut_Valid,
        config_valid           => config_valid,
        config_image           => config_image,
        config_predictor       => config_predictor,
        clear                  => clear,
        fsm_invalid_state      => fsm_insvalid_state_pred,
        config_ahbm            => config_ahbm,
        fifo_full_pred         => fifo_full_pred,
        pred_edac_double_error => pred_edac_double_error,
        ahbm_status            => ahbm_status,
        ahbmi                  => AHBMaster123_In,
        ahbmo                  => AHBMaster123_Out
        );
  end generate gen_pred_bip;

  gen_pred_bip_mem : if PREDICTION_TYPE = 1 generate
    -----------------------------------------------------------------------------       
    --! BIP-MEM architecture  for prediction
    -----------------------------------------------------------------------------
    PREDICTOR_BIP_MEM : entity shyloc_123.predictor_shyloc(arch_bip_mem)
      generic map (D_GEN           => D_GEN,
                                        --W_ADDR_BANK => W_ADDR, 
                   W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE,
                   W_BUFFER_GEN    => W_BUFFER_GEN,
                   RESET_TYPE      => RESET_TYPE
                   )
      port map (
        Clk                    => Clk_s,
        Rst_N                  => rst_n_sync,
        clk_ahb                => clk_ahb,
        rst_ahb                => rst_ahb_sync,
        sign                   => sign,
        s                      => DataInBE_SE,
        s_valid                => DataIn_NewValid,
        ready_pred             => ready_pred,
        finished_pred          => pred_finished,
        eop_pred               => pred_eop,
        mapped                 => Pre_DataOut,
        mapped_valid           => Pre_DataOut_Valid,
        config_valid           => config_valid,
        config_image           => config_image,
        config_predictor       => config_predictor,
        clear                  => clear,
        fsm_invalid_state      => fsm_insvalid_state_pred,
        config_ahbm            => config_ahbm,
        ahbm_status            => ahbm_status,
        fifo_full_pred         => fifo_full_pred,
        pred_edac_double_error => pred_edac_double_error,
        ahbmi                  => AHBMaster123_In,
        ahbmo                  => AHBMaster123_Out
        );
  end generate gen_pred_bip_mem;


  gen_pred_bsq : if PREDICTION_TYPE = 2 generate
    -----------------------------------------------------------------------------       
    --! BSQ architecture for prediction
    -----------------------------------------------------------------------------
    PREDICTOR_BSQ : entity shyloc_123.predictor_shyloc(arch_bsq)
      generic map (D_GEN           => D_GEN,
                                        --W_ADDR_BANK => W_ADDR, 
                   W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE,
                   W_BUFFER_GEN    => W_BUFFER_GEN,
                   RESET_TYPE      => RESET_TYPE
                   )
      port map (
        Clk                    => Clk_s,
        Rst_N                  => rst_n_sync,
        clk_ahb                => clk_ahb,
        rst_ahb                => rst_ahb_sync,
        sign                   => sign,
        s                      => DataInBE_SE,
        s_valid                => DataIn_NewValid,
        ready_pred             => ready_pred,
        finished_pred          => pred_finished,
        eop_pred               => pred_eop,
        mapped                 => Pre_DataOut,
        mapped_valid           => Pre_DataOut_Valid,
        config_valid           => config_valid,
        config_image           => config_image,
        config_predictor       => config_predictor,
        clear                  => clear,
        fsm_invalid_state      => fsm_insvalid_state_pred,
        config_ahbm            => config_ahbm,
        ahbm_status            => ahbm_status,
        fifo_full_pred         => fifo_full_pred,
        pred_edac_double_error => pred_edac_double_error,
        ahbmi                  => AHBMaster123_In,
        ahbmo                  => AHBMaster123_Out
        );
  end generate gen_pred_bsq;

  gen_pred_bil : if PREDICTION_TYPE = 3 generate
    -----------------------------------------------------------------------------       
    --! BIL architecture for prediction
    -----------------------------------------------------------------------------
    PREDICTOR_BIL : entity shyloc_123.predictor_shyloc(arch_bil)
      generic map (D_GEN           => D_GEN,
                                        --W_ADDR_BANK => W_ADDR, 
                   W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE,
                   W_BUFFER_GEN    => W_BUFFER_GEN,
                   RESET_TYPE      => RESET_TYPE
                   )
      port map (
        Clk                    => Clk_s,
        Rst_N                  => rst_n_sync,
        clk_ahb                => clk_ahb,
        rst_ahb                => rst_ahb_sync,
        sign                   => sign,
        s                      => DataInBE_SE,
        s_valid                => DataIn_NewValid,
        ready_pred             => ready_pred,
        finished_pred          => pred_finished,
        eop_pred               => pred_eop,
        mapped                 => Pre_DataOut,
        mapped_valid           => Pre_DataOut_Valid,
        config_valid           => config_valid,
        config_image           => config_image,
        config_predictor       => config_predictor,
        clear                  => clear,
        fsm_invalid_state      => fsm_insvalid_state_pred,
        config_ahbm            => config_ahbm,
        ahbm_status            => ahbm_status,
        fifo_full_pred         => fifo_full_pred,
        pred_edac_double_error => pred_edac_double_error,
        ahbmi                  => AHBMaster123_In,
        ahbmo                  => AHBMaster123_Out
        );
  end generate gen_pred_bil;

  -- Modified by AS: predictor instantiation for the new bil-mem architecture
  gen_pred_bil_mem: if PREDICTION_TYPE = 4 generate
    -----------------------------------------------------------------------------  
    --! BIL-MEM architecture for prediction
    -----------------------------------------------------------------------------
    PREDICTOR_BIL_MEM: entity shyloc_123.predictor_shyloc(arch_bil_mem) 
        generic map (D_GEN => D_GEN, 
              --W_ADDR_BANK => W_ADDR, 
              W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE, 
              W_BUFFER_GEN => W_BUFFER_GEN,
              RESET_TYPE =>  RESET_TYPE
              )
        port map (
          Clk         =>   Clk_s,
          Rst_N        =>   rst_n_sync,
          clk_ahb       =>   clk_ahb,
          rst_ahb       =>   rst_ahb_sync,
          sign         => sign, 
          s => DataInBE_SE, 
          s_valid => DataIn_NewValid,
          ready_pred => ready_pred,
          finished_pred => pred_finished, 
          eop_pred => pred_eop,
          mapped        =>   Pre_DataOut,  
          mapped_valid    =>  Pre_DataOut_Valid,
          config_valid      =>  config_valid, 
          config_image => config_image, 
          config_predictor => config_predictor,
          clear => clear, 
          fsm_invalid_state => fsm_insvalid_state_pred,
          config_ahbm => config_ahbm,
          ahbm_status => ahbm_status, 
          fifo_full_pred => fifo_full_pred,
          pred_edac_double_error => pred_edac_double_error,
          ahbmi        =>   AHBMaster123_In,    
          ahbmo        =>   AHBMaster123_Out    
        );
  end generate gen_pred_bil_mem;
  --------------------------
  
  ----------------------------------------------------------------------------- 
  --! Sample-adaptive encoder
  ----------------------------------------------------------------------------- 
  gen_sample : if ENCODING_TYPE = 1 generate
    Sample_DataIn       <= Pre_DataOut;
    Sample_DataIn_Valid <= Pre_DataOut_Valid;
    sample_adaptive : entity shyloc_123.sample_top(arch)
      generic map(
        DRANGE          => D_GEN,
        PREDICTION_TYPE => PREDICTION_TYPE,
        W_BUFFER        => W_BUFFER_GEN)                
      port map(
        clk                      => clk_S,
        rst_n                    => rst_n_sync,
        config_valid             => config_valid,
        config_image             => config_image,
        config_sample            => config_sample,
        data_in                  => Sample_DataIn,
        data_in_valid            => Sample_DataIn_Valid,
        header                   => HeaderData,
        is_header_in             => IsHeaderFlag,
        n_bits_header_in         => NBitsHeader,
        sample_ready             => sample_ready,
        stop                     => sample_finished,
        clear                    => clear,
        fsm_invalid_state        => fsm_insvalid_state_sample,
        sample_edac_double_error => sample_edac_double_error,
        eop                      => sample_eop,
        buff_full                => SampleCompressed_Valid,
        buff_out                 => SampleCompressed
        );
  end generate;


  ----------------------------------------------------------------------------- 
  --! Output dispatcher
  -----------------------------------------------------------------------------

  dispatcher : entity shyloc_123.ccsds123_dispatcher(arch)
    generic map (D_GEN            => D_GEN,
                 W_BUFFER_GEN     => W_BUFFER_GEN,
                 W_NBITS_HEAD_GEN => W_NBITS_HEAD_GEN,
                 ENCODING_TYPE    => ENCODING_TYPE,
                 RESET_TYPE       => RESET_TYPE, TECH => TECH)
    port map (
      clk   => Clk_S,
      rst_n => rst_n_sync,
      clear => clear,

      config_image => config_image,
      config_valid => config_valid,

      header        => HeaderData,
      header_valid  => IsHeaderFlag,
      n_bits_header => NBitsHeader,

      sample_compressed => SampleCompressed,
      sample_valid      => SampleCompressed_Valid,
      sample_finished   => sample_finished,

      mapped        => Pre_DataOut,
      mapped_valid  => Pre_DataOut_Valid,
      pred_finished => pred_finished,

      dispatcher_ready       => dispatcher_ready,
      dispatcher_finished    => dispatcher_finished,
      fsm_invalid_state      => fsm_insvalid_state_disp,
      disp_edac_double_error => disp_edac_double_error,
      ready_ext              => Ready_Ext,
      DataOut                => DataOut,
      DataOut_Valid          => DataOut_NewValid,
      IsHeaderOut            => IsHeaderOut,
      NbitsOut               => NbitsOut_Ext);

end arch;
