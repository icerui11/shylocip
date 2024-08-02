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
---------------------------------- VHDL Code ----------------------------------
-- package      = N/A
-- 
-- File         = ccsds123_top_wrapper.vhd
-- 
-- Purpose      = Wrapper of the CCSDS123 IP Core which is used
--                during Post Synthesis/PAR simulations.
-- 
-- Library      = work
-- 
-- Dependencies = shyloc_123, shyloc_utils
-- 
-- Author       = V. Vlagkoulis
--
-- Copyright    = TELETEL 2017
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

library shyloc_123; 
use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all;    

library shyloc_utils;
use shyloc_utils.amba.all;


entity ccsds123_top_wrapper is
  port
    (
    -- System interface
    Clk_S                    : in  Std_Logic;    --! IP core clock signal
    Rst_N                    : in  Std_Logic;    --! IP core reset signal. Active low. 
    
    Clk_AHB                  : in  Std_Logic;    --! AHB clock signal
    Rst_AHB                  : in  Std_Logic;    --! AHB reset.
    
    -- Input data interface
    DataIn                   : in  Std_Logic_Vector (D_GEN-1 downto 0);        --! Uncompressed samples
    DataIn_NewValid          : in  Std_Logic;    --! Flag to validate input data  
      
    -- Data output interface
    DataOut                  : out Std_Logic_Vector (W_BUFFER_GEN-1 downto 0); --! Input data for uncompressed samples
    DataOut_NewValid         : out Std_Logic;    --! Flag to validate input data
    IsHeaderOut              : out Std_Logic;    --! The data in DataOut corresponds to the header when the core is shyloc_123 working as a pre-processor.
    NbitsOut                 : out Std_Logic_Vector (5 downto 0);    --! Number of valid bits in the DataOut signal (needed when IsHeaderOut = 1).
      
    -- Control interface
    AwaitingConfig           : out Std_Logic;    --! The IP core is waiting to receive the configuration through the AHB Slave interface.
    Ready                    : out Std_Logic;    --! If asserted (high) the IP core has been configured and is able to receive new samples for compression.
    FIFO_Full                : out std_logic;    --! Signals that the input FIFO is full. Possible loss of data. 
    EOP                      : out Std_Logic;    --! Compression of last sample has started.
    Finished                 : out Std_Logic;    --! The IP has finished compressing all samples.
    ForceStop                : in  std_logic;    --! Force the stop of the compression.
    Error                    : out Std_Logic;    --! There has been an error during the compression.
  
    -- AHB 123 Slave interface
    AHBSlave123_In_HSEL      : in Std_ULogic;                          -- slave select
    AHBSlave123_In_HADDR     : in Std_Logic_Vector(HAMAX-1 downto 0);  -- address bus (byte)
    AHBSlave123_In_HWRITE    : in Std_ULogic;                          -- read/write
    AHBSlave123_In_HTRANS    : in Std_Logic_Vector(1 downto 0);        -- transfer type
    AHBSlave123_In_HSIZE     : in Std_Logic_Vector(2 downto 0);        -- transfer size
    AHBSlave123_In_HBURST    : in Std_Logic_Vector(2 downto 0);        -- burst type
    AHBSlave123_In_HWDATA    : in Std_Logic_Vector(HDMAX-1 downto 0);  -- write data bus
    AHBSlave123_In_HPROT     : in Std_Logic_Vector(3 downto 0);        -- protection control
    AHBSlave123_In_HREADY    : in Std_ULogic;                          -- transfer done
    AHBSlave123_In_HMASTER   : in Std_Logic_Vector(3 downto 0);        -- current master
    AHBSlave123_In_HMASTLOCK : in Std_ULogic;                          -- locked access

    AHBSlave123_Out_HREADY   : out Std_ULogic;                         -- transfer done
    AHBSlave123_Out_HRESP    : out Std_Logic_Vector(1 downto 0);       -- response type
    AHBSlave123_Out_HRDATA   : out Std_Logic_Vector(HDMAX-1 downto 0); -- read data bus
    AHBSlave123_Out_HSPLIT   : out Std_Logic_Vector(15 downto 0);      -- split completion

    -- AHB 123 Master interface
    AHBMaster123_In_HGRANT   : in Std_ULogic;                          -- bus grant
    AHBMaster123_In_HREADY   : in Std_ULogic;                          -- transfer done
    AHBMaster123_In_HRESP    : in Std_Logic_Vector(1 downto 0);        -- response type
    AHBMaster123_In_HRDATA   : in Std_Logic_Vector(HDMAX-1 downto 0);  -- read data bus

    AHBMaster123_Out_HBUSREQ : out Std_ULogic;                         -- bus request
    AHBMaster123_Out_HLOCK   : out Std_ULogic;                         -- lock request
    AHBMaster123_Out_HTRANS  : out Std_Logic_Vector(1 downto 0);       -- transfer type
    AHBMaster123_Out_HADDR   : out Std_Logic_Vector(HAMAX-1 downto 0); -- address bus (byte)
    AHBMaster123_Out_HWRITE  : out Std_ULogic;                         -- read/write
    AHBMaster123_Out_HSIZE   : out Std_Logic_Vector(2 downto 0);       -- transfer size
    AHBMaster123_Out_HBURST  : out Std_Logic_Vector(2 downto 0);       -- burst type
    AHBMaster123_Out_HPROT   : out Std_Logic_Vector(3 downto 0);       -- protection control
    AHBMaster123_Out_HWDATA  : out Std_Logic_Vector(HDMAX-1 downto 0); -- write data bus

    -- External encoder signals. To be considered only when an external encoder is present, i.e. when ENCODER_SELECTION = 2. 
    ForceStop_Ext            : out Std_Logic;    --! Force the external IP core to stop
    AwaitingConfig_Ext       : in  Std_Logic;    --! The external encoder IP core is waiting to receive the configuration.
    Ready_Ext                : in  Std_Logic;    --! Configuration has been received and the external encoder IP is ready to receive new samples.
    FIFO_Full_Ext            : in  Std_Logic;    --! The input FIFO of the external encoder IP is full.
    EOP_Ext                  : in  Std_Logic;    --! Compression of last sample has started by the external encoder IP.
    Finished_Ext             : in  Std_Logic;    --! The external encoder IP has finished compressing all samples.
    Error_Ext                : in  Std_Logic     --! There has been an error during the compression in the external encoder IP.
    );
end ccsds123_top_wrapper;

architecture beh of ccsds123_top_wrapper is

component ccsds123_top
  generic 
    (
    EN_RUNCFG: integer  := EN_RUNCFG;    --! Enables (1) or disables (0) runtime configuration.
    RESET_TYPE : integer := RESET_TYPE;  --! Reset flavour asynchronous (0) synchronous (1)
    EDAC: integer  :=  EDAC;        --! Edac implementation (0) No EDAC (1) Only internal memories (2) Only external memories (3) both.
    PREDICTION_TYPE: integer := PREDICTION_TYPE;  --! Selects the prediction architecture to be implemented (0) BIP (1) BIP-MEM (2) BSQ (3) BIL.
    ENCODING_TYPE: integer  := ENCODING_TYPE;    --! (0) no sample-adaptive module instantitaed (1)  instantiate sample adaptive module
       
    HSINDEX_123: integer := HSINDEX_123;      --! AHB slave index
    HSCONFIGADDR_123: integer := HSCONFIGADDR_123;  --! ADDR field of the AHB Slave.
    HSADDRMASK_123: integer := HSADDRMASK_123;    --! MASK field of the AHB Slave.
       
    HMINDEX_123: integer := HMINDEX_123;      --! AHB master index.
    HMAXBURST_123: integer := HMAXBURST_123;    --! AHB master burst beat limit (0 means unlimited) -- not used

    ExtMemAddress_GEN: integer := ExtMemAddress_GEN; --! External memory address (used when EN_RUNCFG = 0)

    Nx_GEN: integer := Nx_GEN;    --! Maximum number of samples in a line the IP core is implemented for. 
    Ny_GEN: integer := Ny_GEN;    --! Maximum number of samples in a column the IP core is implemented for. 
    Nz_GEN: integer := Nz_GEN;    --! Maximum number of bands the IP core is implemented for. 
    D_GEN: integer := D_GEN;    --! Maximum input sample bitwidth IP core is implemented for. 
    IS_SIGNED_GEN: integer := IS_SIGNED_GEN;  --! Singedness of input samples (used when EN_RUNCFG = 0).
    DISABLE_HEADER_GEN: integer := DISABLE_HEADER_GEN;  --! Disables header in the compressed image(used when EN_RUNCFG = 0).
    ENDIANESS_GEN: integer := ENDIANESS_GEN;    --! Endianess of the input image (used when EN_RUNCFG = 0).
        
    P_MAX: integer := P_MAX;    --! Maximum number of P the IP core is implemented for. 
    PREDICTION_GEN: integer := PREDICTION_GEN;  --! (0) Full prediction (1) Reduced prediction.
    LOCAL_SUM_GEN: integer := LOCAL_SUM_GEN;  --! (0) Neighbour oriented (1) Column oriented.
    OMEGA_GEN: integer := OMEGA_GEN;      --! Weight component resolution.
    R_GEN: integer := R_GEN;          --! Register size
       
    VMAX_GEN: integer := VMAX_GEN;      --! Factor for weight update.
    VMIN_GEN: integer := VMIN_GEN;      --! Factor for weight update.
    T_INC_GEN: integer := T_INC_GEN;    --! Weight update factor change interval
    WEIGHT_INIT_GEN: integer := WEIGHT_INIT_GEN;  --! Weight initialization mode.
       
    ENCODER_SELECTION_GEN: integer := ENCODER_SELECTION_GEN;  --! Selects between sample-adaptive(1) or block-adaptive (2) or no encoding (3) (used when EN_RUNCFG = 0)
    INIT_COUNT_E_GEN: integer := INIT_COUNT_E_GEN;        --! Initial count exponent.
    ACC_INIT_TYPE_GEN: integer := ACC_INIT_TYPE_GEN;      --! Accumulator initialization type.
    ACC_INIT_CONST_GEN: integer := ACC_INIT_CONST_GEN;      --! Accumulator initialization constant.
    RESC_COUNT_SIZE_GEN: integer := RESC_COUNT_SIZE_GEN;    --! Rescaling counter size.
    U_MAX_GEN: integer := U_MAX_GEN;              --! Unary length limit.
    W_BUFFER_GEN: integer := W_BUFFER_GEN;
       
    Q_GEN: integer := Q_GEN
    );
  port 
    (
    -- System interface
    Clk_S: in Std_Logic;       --! IP core clock signal
    Rst_N: in Std_Logic;       --! IP core reset signal. Active low. 
    
    Clk_AHB: in Std_Logic;       --! AHB clock signal
    Rst_AHB: in Std_Logic;       --! AHB reset.
    
    -- Input data interface
    DataIn: in Std_Logic_Vector (D_GEN-1 downto 0);   --! Uncompressed samples
    DataIn_NewValid: in Std_Logic;             --! Flag to validate input data  
      
    -- Data output interface
    DataOut: out Std_Logic_Vector (W_BUFFER_GEN-1 downto 0);     --! Input data for uncompressed samples
    DataOut_NewValid: out Std_Logic;                 --! Flag to validate input data
    IsHeaderOut: out Std_Logic;                   --! The data in DataOut corresponds to the header when the core is shyloc_123 working as a pre-processor.
    NbitsOut: out Std_Logic_Vector (5 downto 0);   --! Number of valid bits in the DataOut signal (needed when IsHeaderOut = 1).
      
    -- Control interface
    AwaitingConfig: out Std_Logic;     --! The IP core is waiting to receive the configuration through the AHB Slave interface.
    Ready: out Std_Logic;       --! If asserted (high) the IP core has been configured and is able to receive new samples for compression. If de-asserted (low) the IP is not ready to receive new samples
    FIFO_Full: out std_logic;    --! Signals that the input FIFO is full. Possible loss of data. 
    EOP: out Std_Logic;       --! Compression of last sample has started.
    Finished: out Std_Logic;     --! The IP has finished compressing all samples.
    ForceStop: in std_logic;    --! Force the stop of the compression.
    Error: out Std_Logic;       --! There has been an error during the compression.
  
    -- AHB 123 Slave interface
    AHBSlave123_In: in AHB_Slv_In_Type;     --! AHB slave input signals
    AHBSlave123_Out: out AHB_Slv_Out_Type;     --! AHB slave input signals
    
    -- AHB 123 Master interface
    AHBMaster123_In: in AHB_Mst_In_Type;     --! AHB slave input signals
    AHBMaster123_Out: out AHB_Mst_Out_Type;   --! AHB slave input signals

    -- External encoder signals. To be considered only when an external encoder is present, i.e. when ENCODER_SELECTION = 2. 
    ForceStop_Ext: out Std_Logic;     --! Force the external IP core to stop
    AwaitingConfig_Ext: in Std_Logic;   --! The external encoder IP core is waiting to receive the configuration.
    Ready_Ext: in Std_Logic;       --! Configuration has been received and the external encoder IP is ready to receive new samples.
    FIFO_Full_Ext: in Std_Logic;     --! The input FIFO of the external encoder IP is full.
    EOP_Ext: in Std_Logic;         --! Compression of last sample has started by the external encoder IP.
    Finished_Ext: in Std_Logic;     --! The external encoder IP has finished compressing all samples.
    Error_Ext: in Std_Logic       --! There has been an error during the compression in the external encoder IP.
    );
end component;
  
  
-- AHB 123 Slave interface
signal AHBSlave123_In   : AHB_Slv_In_Type;      --! AHB slave input signals
signal AHBSlave123_Out  : AHB_Slv_Out_Type;     --! AHB slave input signals
    
-- AHB 123 Master interface
signal AHBMaster123_In  : AHB_Mst_In_Type;     --! AHB slave input signals
signal AHBMaster123_Out : AHB_Mst_Out_Type;    --! AHB slave input signals


begin

-- AHB 123 Slave interface
AHBSlave123_In.HSEL     <= AHBSlave123_In_HSEL;
AHBSlave123_In.HADDR    <= AHBSlave123_In_HADDR;
AHBSlave123_In.HWRITE   <= AHBSlave123_In_HWRITE;
AHBSlave123_In.HTRANS   <= AHBSlave123_In_HTRANS;
AHBSlave123_In.HSIZE    <= AHBSlave123_In_HSIZE;
AHBSlave123_In.HBURST   <= AHBSlave123_In_HBURST;
AHBSlave123_In.HWDATA   <= AHBSlave123_In_HWDATA;
AHBSlave123_In.HPROT    <= AHBSlave123_In_HPROT;
AHBSlave123_In.HREADY   <= AHBSlave123_In_HREADY;
AHBSlave123_In.HMASTER  <= AHBSlave123_In_HMASTER;
AHBSlave123_In.HMASTLOCK<= AHBSlave123_In_HMASTLOCK;

AHBSlave123_Out_HREADY  <= AHBSlave123_Out.HREADY;
AHBSlave123_Out_HRESP   <= AHBSlave123_Out.HRESP;
AHBSlave123_Out_HRDATA  <= AHBSlave123_Out.HRDATA;
AHBSlave123_Out_HSPLIT  <= AHBSlave123_Out.HSPLIT;

-- AHB 123 Master interface
AHBMaster123_In.HGRANT  <= AHBMaster123_In_HGRANT;
AHBMaster123_In.HREADY  <= AHBMaster123_In_HREADY;
AHBMaster123_In.HRESP   <= AHBMaster123_In_HRESP;
AHBMaster123_In.HRDATA  <= AHBMaster123_In_HRDATA;

AHBMaster123_Out_HBUSREQ<= AHBMaster123_Out.HBUSREQ;
AHBMaster123_Out_HLOCK  <= AHBMaster123_Out.HLOCK;
AHBMaster123_Out_HTRANS <= AHBMaster123_Out.HTRANS;
AHBMaster123_Out_HADDR  <= AHBMaster123_Out.HADDR;
AHBMaster123_Out_HWRITE <= AHBMaster123_Out.HWRITE;
AHBMaster123_Out_HSIZE  <= AHBMaster123_Out.HSIZE;
AHBMaster123_Out_HBURST <= AHBMaster123_Out.HBURST;
AHBMaster123_Out_HPROT  <= AHBMaster123_Out.HPROT;
AHBMaster123_Out_HWDATA <= AHBMaster123_Out.HWDATA;


ccsds123: ccsds123_top
  port map
    (
    clk_s => clk_s, 
    rst_n => rst_n, 
    clk_ahb => clk_ahb, 
    rst_ahb => rst_ahb, 
    DataIn => DataIn, 
    DataIn_NewValid => DataIn_NewValid, 
    AwaitingConfig => AwaitingConfig, 
    Ready => Ready, 
    FIFO_Full => FIFO_Full, 
    EOP => EOP, 
    Finished => Finished, 
    ForceStop => ForceStop,
    Error => Error,
    AHBSlave123_In => AHBSlave123_In, 
    AHBSlave123_Out => AHBSlave123_Out,   
    AHBMaster123_In => AHBMaster123_In, 
    AHBMaster123_Out => AHBMaster123_Out,
    DataOut => DataOut,
    DataOut_NewValid => DataOut_NewValid, 
    IsHeaderOut => IsHeaderOut, 
    NbitsOut => NbitsOut, 
    ForceStop_Ext => ForceStop_Ext,
    AwaitingConfig_Ext => AwaitingConfig_Ext,
    Ready_Ext => Ready_Ext, 
    FIFO_Full_Ext => FIFO_Full_Ext, 
    EOP_Ext => EOP_Ext, 
    Finished_Ext => Finished_Ext, 
    Error_Ext => Error_Ext
    );


end beh;
