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
-- Design unit  : CCSDS123 predictor
--
-- File name    : predictor_shyloc.vhd
--
-- Purpose      : Top module of the predictor. Instantiates and bind
--          the components and FSMs for each prediction order. 
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
-- Instantiates:  .bip architecture: ccsds_fsm_shyloc_bip, ccsds_comp_shyloc_bip
--          .bip_mem architecture: ccsds_fsm_shyloc_bip_mem, ccsds_comp_shyloc_bip_mem
--          .bsq architecture: ccsds_fsm_shyloc_bsq, ccsds_comp_shyloc_bsq
--          .bil architecture: ccsds_fsm_shyloc_bil, ccsds_comp_shyloc_bil
--============================================================================
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
library shyloc_123; use shyloc_123.ccsds123_parameters.all; use shyloc_123.ccsds123_constants.all;     


library shyloc_utils;
use shyloc_utils.amba.all;

--!@file #predictor_shyloc.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Top module of the predictor. Instantiates and bind the components and FSMs for each prediction order.

entity predictor_shyloc is
  generic (D_GEN: integer := D_GEN;       --! Dynamic range of the input samples
   --W_ADDR_BANK: integer := 2;           --! Bit width of the address signal in the register banks.
   W_ADDR_IN_IMAGE: integer := 16;        --! Bit width of the image coordinates (x, y, z)
   W_BUFFER_GEN: integer := W_BUFFER_GEN;     --! Bit width of the output buffer.
   RESET_TYPE: integer              --! Reset flavour (0) asynchronous (1) synchronous
  );
  port(
    clk: in std_logic;                --! Clock.
    rst_n: in std_logic;              --! Reset (active low).
    clk_ahb: in std_logic;              --! AHB clock
    rst_ahb: in std_logic;              --! AHB reset
    
    sign: in std_logic;               --! Signedness of the input samples (0) unsigned (1) signed.
    s: in std_logic_vector (D_GEN-1 downto 0);    --! Input samples
    s_valid: in std_logic;              --! Validates input samples
    
    config_valid: in std_logic;           --! Signals that the configuraton is valid. Kept during the entire compression.
    config_image : in config_123_image;       --! Image metadata configuration values.
    config_predictor: in config_123_predictor;    --! Predictor configuration values.
    
    config_ahbm: in config_123_ahbm;        --! Configuration values to be sent to AHB master
    ahbm_status: out ahbm_123_status;       --! Status of the AHB master
    ahbmi: in ahb_mst_in_type;            --! AHB master input
    ahbmo: out ahb_mst_out_type;          --! AHB master output
    
    ready_pred: out std_logic;            --! Predictor is ready to receive samples when high. Otherwise it is not. 
    finished_pred: out std_logic;         --! Predictor has finished the processing of all samples. No more samples will be issued after.
    eop_pred: out std_logic;            --! Predictor has started the compression of the last sample.
    fifo_full_pred: out std_logic;          --! If '1', there was an attempt to write in a full input FIFO.
    fsm_invalid_state: out std_logic;       --! If '1', a states machine went into an invalid state.
    pred_edac_double_error: out std_logic;      --! Internal EDAC double error. 
    clear : in std_logic;             --! Asynchronous clear for all registers.
    
    mapped : out std_logic_vector (D_GEN-1 downto 0); --! Mapped prediction residual.
    mapped_valid: out std_logic;            --! Validates input residual when '1'.
  
    ls_out: out std_logic_vector (D_GEN+2 downto 0);  --! Local sum output for debugging.
    ld_out: out std_logic_vector (D_GEN+3 downto 0)   --! Local diff output for debugging. 
  );
end predictor_shyloc;

----------------------------------------------------------------------------- 
--! BIP ARCHIRTECTURE
-----------------------------------------------------------------------------
architecture arch of predictor_shyloc is

    -- FIFO for current sample (input)
    signal w_update_curr: std_logic;            
    signal r_update_curr: std_logic;
    signal empty_curr: std_logic;                   
    signal aempty_curr: std_logic;                
    signal full_curr: std_logic;                
    signal afull_curr:  std_logic;      
    
    -- FIFOs for neighbours
    signal w_update_top: std_logic;             
    signal r_update_top: std_logic;             
    
    signal w_update_top_left: std_logic;          
    signal r_update_top_left: std_logic;          
    
    signal w_update_top_right: std_logic;           
    signal r_update_top_right: std_logic;         
    
    signal w_update_left: std_logic;            
    signal r_update_left:  std_logic;           
    
    
    signal en_opcode:  std_logic;             
    signal opcode: std_logic_vector (4 downto 0);
    
    signal z_opcode: std_logic_vector (W_ADDR_IN_IMAGE -1 downto 0);
    signal z_configured: std_logic_vector (W_Nz_GEN-1 downto 0);
    signal en_localsum:  std_logic;
    signal opcode_localsum: std_logic_vector (4 downto 0);
    signal en_localdiff: std_logic;
    signal s_in_localdiff: std_logic_vector (D_GEN-1 downto 0); 
    signal en_localdiff_shift: std_logic;
    signal s_out: std_logic_vector (D_GEN-1 downto 0);        
    signal s_in_left: std_logic_vector (D_GEN-1 downto 0);
    signal s_in_top_right: std_logic_vector (D_GEN-1 downto 0);

    signal finished: std_logic; 
    signal eop: std_logic;
    signal clear_curr: std_logic;

begin

  --Predictor is ready when the input FIFO is not full and the configuration is valid
  ready_pred <= not full_curr and not afull_curr and config_valid;
  -- Output assignment for finished signal
  finished_pred <= finished;
  -- Configured number of bands in the image.
  z_configured <= config_image.Nz;
  -- Output assignment for end of package.
  eop_pred <= eop;
  
  ----------------------------------------------------------------------------- 
  --! FSM for control in BIP architecture
  -----------------------------------------------------------------------------
  fsm: entity shyloc_123.ccsds_fsm_shyloc_bip(arch_bip)
    generic map(
        DRANGE  => D_GEN,
        --W_ADDR_BANK => W_ADDR_BANK, 
        W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE, 
        W_BUFFER => W_BUFFER_GEN,
        RESET_TYPE => RESET_TYPE
        )
        
    port map(
      clk => clk,
      rst_n => rst_n,
      eop => eop, 
      w_update_curr=> w_update_curr,              
      r_update_curr=> r_update_curr,              
      w_update_top=> w_update_top,                
      r_update_top=> r_update_top,                
      w_update_top_left=> w_update_top_left,          
      r_update_top_left=> r_update_top_left,          
      w_update_top_right=> w_update_top_right ,         
      r_update_top_right=> r_update_top_right,          
      w_update_left=> w_update_left,            
      r_update_left=> r_update_left,            
      en_opcode=> en_opcode ,             
      opcode => opcode,
      z_opcode => z_opcode,
      en_localsum=>  en_localsum,
      opcode_localsum => opcode_localsum,
      config_valid => config_valid,
      z_configured => z_configured,   
      clear => clear,      
      en_localdiff => en_localdiff,
      s_in_localdiff => s_in_localdiff,
      en_localdiff_shift => en_localdiff_shift, 
      s_out => s_out,
      s_in_left => s_in_left,
      s_in_top_right => s_in_top_right,      
      empty_curr=> empty_curr,                    
      aempty_curr=> aempty_curr,      
      fsm_invalid_state =>    fsm_invalid_state,
      clear_curr => clear_curr  
    );
  
  ----------------------------------------------------------------------------- 
  --! Components instantiation in BIP architecture
  -----------------------------------------------------------------------------
  comp: entity shyloc_123.ccsds_comp_shyloc_bip(arch_bip)
    generic map(
      DRANGE  => D_GEN,
      --W_ADDR_BANK => W_ADDR_BANK, 
      W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE, 
      W_BUFFER => W_BUFFER_GEN,
      RESET_TYPE => RESET_TYPE
    )
    port map(
    clk => clk,
    rst_n => rst_n,
    s => s,
    sign => sign,
    w_update_curr=> s_valid,              
    r_update_curr=> r_update_curr,              
    w_update_top=> w_update_top,                
    r_update_top=> r_update_top,                
    w_update_top_left=> w_update_top_left,          
    r_update_top_left=> r_update_top_left,          
    w_update_top_right=> w_update_top_right ,         
    r_update_top_right=> r_update_top_right,          
    w_update_left=> w_update_left,            
    r_update_left=> r_update_left,            
    en_opcode=> en_opcode ,             
    opcode => opcode,
    z_opcode => z_opcode,
    en_localsum=>  en_localsum,
    en_localdiff => en_localdiff,
    s_in_localdiff => s_in_localdiff,
    en_localdiff_shift => en_localdiff_shift, 
    opcode_localsum => opcode_localsum,
    ls_out => ls_out,
    ld_out => ld_out,
    s_out => s_out,
    s_in_left => s_in_left,
    s_in_top_right => s_in_top_right,
    finished => finished,
    config_valid => config_valid,
    config_image  => config_image,
    config_predictor => config_predictor,
    clear => clear,
    empty_curr=> empty_curr,                    
    aempty_curr=> aempty_curr,                
    full_curr=> full_curr,                
    afull_curr=>  afull_curr, 
    clear_curr => clear_curr,   
    fifo_full_pred => fifo_full_pred,
    pred_edac_double_error => pred_edac_double_error,
    mapped => mapped, 
    mapped_valid => mapped_valid
    );
end arch;

----------------------------------------------------------------------------- 
--! BIP-MEM ARCHIRTECTURE
-----------------------------------------------------------------------------
architecture arch_bip_mem of predictor_shyloc is

  -- FIFO for current sample (input)
  signal r_update_curr: std_logic;
  signal empty_curr: std_logic;                   
  signal aempty_curr: std_logic;                
  signal full_curr: std_logic;                
  signal afull_curr:  std_logic;  
    
  -- FIFOs for neighbours
  signal w_update_top: std_logic;             
  signal r_update_top: std_logic;             
  
  signal w_update_top_left: std_logic;          
  signal r_update_top_left: std_logic;          
  
  signal w_update_top_right_ahbo: std_logic;            
  signal r_update_top_right_ahbo: std_logic;    
  
  signal w_update_top_right_ahbi: std_logic;            
  signal r_update_top_right_ahbi: std_logic;      
  
  signal w_update_left: std_logic;            
  signal r_update_left:  std_logic;           

  signal en_opcode:  std_logic;             
  signal opcode: std_logic_vector (4 downto 0);
  signal z_opcode: std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);
  signal t_opcode: std_logic_vector (W_T-1 downto 0);
  
  --localsum
  signal en_localsum:  std_logic;
  signal opcode_localsum: std_logic_vector (4 downto 0);
  signal z_ls: std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);
  signal t_ls: std_logic_vector (W_T-1 downto 0);
  
  --localdiff
  signal en_localdiff: std_logic;
  signal s_in_localdiff: std_logic_vector (D_GEN-1 downto 0);   
  
  signal s_out: std_logic_vector (D_GEN-1 downto 0);        
  signal s_in_left: std_logic_vector (D_GEN-1 downto 0);      
  signal s_in_top_right: std_logic_vector (D_GEN-1 downto 0);   
  
  --localdiff shift
  signal en_localdiff_shift: std_logic;
  
  -- AHB synchronization FIFOs              
  signal full_top_right_ahbo:   std_logic;              
  signal afull_top_right_ahbo: std_logic; 

  signal empty_top_right_ahbi: std_logic;                       
  signal full_top_right_ahbi:   std_logic;
  
  signal finished: std_logic;
  
  signal z_configured: std_logic_vector (W_Nz_GEN-1 downto 0);
  signal eop: std_logic;
  signal clear_curr: std_logic;   

begin
  --Predictor is ready when the input FIFO is not full and the configuration is valid
  ready_pred <= not full_curr and not afull_curr and config_valid;
  -- Output assignment for finished signal
  finished_pred <= finished;
  -- Configured number of bands in the image.
  z_configured <= config_image.Nz;
  -- Output assignment for end of package.
  eop_pred <= eop;
  
  ----------------------------------------------------------------------------- 
  --! FSM for control in BIP-MEM arhictecture
  -----------------------------------------------------------------------------
  fsm: entity shyloc_123.ccsds_fsm_shyloc_bip_mem(arch_bip_mem)
    generic map(
        DRANGE  => D_GEN,
        --W_ADDR_BANK => W_ADDR_BANK, 
        W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE, 
        W_BUFFER => W_BUFFER_GEN,
        RESET_TYPE => RESET_TYPE
        )
    port map(
      clk => clk,
      rst_n => rst_n,           
      r_update_curr=> r_update_curr,              
      w_update_top=> w_update_top,                
      r_update_top=> r_update_top,                
      w_update_top_left=> w_update_top_left,          
      r_update_top_left=> r_update_top_left,  
      w_update_top_right_ahbo=> w_update_top_right_ahbo ,                 
      r_update_top_right_ahbi=> r_update_top_right_ahbi,
      w_update_left=> w_update_left,            
      r_update_left=> r_update_left,            
      en_opcode=> en_opcode ,             
      opcode => opcode,
      z_opcode => z_opcode,
      t_opcode => t_opcode, 
      t_ls => t_ls, 
      en_localsum=>  en_localsum,
      opcode_localsum => opcode_localsum,
      z_ls => z_ls,
      en_localdiff => en_localdiff,
      s_in_localdiff => s_in_localdiff,
      en_localdiff_shift => en_localdiff_shift, 
      s_out => s_out,
      s_in_left => s_in_left,
      s_in_top_right => s_in_top_right, 
      config_valid => config_valid,
      empty_curr=> empty_curr,                    
      aempty_curr=> aempty_curr,                
      fsm_invalid_state => fsm_invalid_state,
      clear_curr => clear_curr, 
      clear => clear,
      z_configured => z_configured,     
      eop => eop, 
      full_top_right_ahbo =>  full_top_right_ahbo,              
      empty_top_right_ahbi=> empty_top_right_ahbi,                          
      full_top_right_ahbi=>   full_top_right_ahbi
    );

  ----------------------------------------------------------------------------- 
  --! Components instantiation in BIP-MEM architecture
  -----------------------------------------------------------------------------
  comp: entity shyloc_123.ccsds_comp_shyloc_bip_mem(arch_bip_mem)
    generic map(
      DRANGE  => D_GEN,
      --W_ADDR_BANK => W_ADDR_BANK, 
      W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE, 
      HMINDEX_123 => HMINDEX_123,
      W_BUFFER => W_BUFFER_GEN,
      RESET_TYPE => RESET_TYPE
    )
    port map(
    clk => clk,
    rst_n => rst_n,
    s => s,
    sign => sign,
    w_update_curr=> s_valid,              
    r_update_curr=> r_update_curr,              
    w_update_top=> w_update_top,                
    r_update_top=> r_update_top,                
    w_update_top_left=> w_update_top_left,          
    r_update_top_left=> r_update_top_left,          
    w_update_top_right_ahbo=> w_update_top_right_ahbo,          
    r_update_top_right_ahbi=> r_update_top_right_ahbi, 
    w_update_left=> w_update_left,            
    r_update_left=> r_update_left,            
    en_opcode=> en_opcode ,             
    opcode => opcode, 
    en_localsum=>  en_localsum,
    z_ls => z_ls,
    t_opcode => t_opcode, 
    t_ls => t_ls, 
    en_localdiff => en_localdiff,
    s_in_localdiff => s_in_localdiff,
    en_localdiff_shift => en_localdiff_shift, 
    opcode_localsum => opcode_localsum,
    ls_out => ls_out,
    ld_out => ld_out,
    s_out => s_out,
    s_in_left => s_in_left,
    s_in_top_right => s_in_top_right,
    config_valid => config_valid,
    z_opcode => z_opcode,
    config_image  => config_image,
    config_predictor => config_predictor,
    clear => clear,
    clear_curr => clear_curr, 
    finished => finished, 
    empty_curr=> empty_curr,                    
    aempty_curr=> aempty_curr,                
    full_curr=> full_curr,                
    afull_curr=>  afull_curr,
    full_top_right_ahbo=>   full_top_right_ahbo,              
    empty_top_right_ahbi=> empty_top_right_ahbi,          
    full_top_right_ahbi=>   full_top_right_ahbi,
    clk_ahb => clk_ahb,
    rst_ahb => rst_ahb, 
    ahbmi => ahbmi, 
    ahbmo => ahbmo,
    config_ahbm => config_ahbm, 
    ahbm_status => ahbm_status, 
    fifo_full_pred => fifo_full_pred,
    pred_edac_double_error => pred_edac_double_error,
    mapped => mapped, 
    mapped_valid => mapped_valid
     
    );
end arch_bip_mem;

----------------------------------------------------------------------------- 
--! BSQ ARCHIRTECTURE
-----------------------------------------------------------------------------
architecture arch_bsq of predictor_shyloc is

    -- FIFO for current sample (input)        
    signal r_update_curr: std_logic;
    signal empty_curr: std_logic;                   
    signal aempty_curr: std_logic;                
    signal full_curr: std_logic;                
    signal afull_curr:  std_logic;        
    
    -- FIFOs for neighbours
    signal w_update_top_right: std_logic;           
    signal r_update_top_right: std_logic;         

    --Opcode
    signal en_opcode:  std_logic;             
    signal opcode: std_logic_vector (4 downto 0);
    
    --localsum
    signal en_localsum:  std_logic;
    signal opcode_localsum: std_logic_vector (4 downto 0);
    
    --localdiff
    signal en_localdiff: std_logic;
    signal s_in_localdiff: std_logic_vector (D_GEN-1 downto 0);   
    
    signal s_out: std_logic_vector (D_GEN-1 downto 0);        
    signal s_in_left: std_logic_vector (D_GEN-1 downto 0);        
    signal s_in_top_right: std_logic_vector (D_GEN-1 downto 0);   
    
    --localdiff shift
    signal en_localdiff_shift: std_logic;
    
    signal z: std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);
    signal full_ld_ahbo: std_logic;
    signal empty_ld_ahbi: std_logic;
    signal w_update_ld_ahbo: std_logic;
    signal r_update_ld_ahbi: std_logic;
    
    -- Record FIFO
    signal w_update_record: std_logic;
    signal r_update_record: std_logic;
    signal hfull_record: std_logic;
    
    signal r_update_ld : std_logic;
    signal r_update_wei : std_logic;
    signal en_weight_dir_fsm : std_logic; 
    signal en_predictor : std_logic; 
    signal clear_mac : std_logic;
    signal empty_record, aempty_record, full_record: std_logic;
    signal en_weight_central_fsm: std_logic;
    signal address_central: std_logic_vector (W_COUNT_PRED - 1 downto 0);
    signal opcode_weight_out, opcode_weight_fsm: std_logic_vector (4 downto 0);
    signal r_update_wei_dir: std_logic;
    signal opcode_predictor_out: std_logic_vector(4 downto 0);
    signal finished: std_logic;
    
    signal z_configured: std_logic_vector (W_Nz_GEN-1 downto 0);
    signal eop: std_logic;
    signal clear_curr: std_logic;
    signal z_opcode: std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);
    signal z_predictor_out: std_logic_vector(W_ADDR_IN_IMAGE-1 downto 0);
    signal PREDICTION_configured: std_logic_vector (0 downto 0);
        
begin

  --Predictor is ready when the input FIFO is not full and the configuration is valid
  ready_pred <= not full_curr and not afull_curr and config_valid;
  -- Output assignment for finished signal
  finished_pred <= finished;
  -- Configured number of bands in the image.
  z_configured <= config_image.Nz;
  -- Output assignment for end of package.
  eop_pred <= eop;
  
  

  ----------------------------------------------------------------------------- 
  --! FSM for control in BSQ architecture
  -----------------------------------------------------------------------------
  fsm: entity shyloc_123.ccsds_fsm_shyloc_bsq(arch_bsq)
    generic map(
      DRANGE  => D_GEN,
      --W_ADDR_BANK => W_ADDR_BANK, 
      W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE, 
      W_BUFFER => W_BUFFER_GEN,
      RESET_TYPE => RESET_TYPE
      ) 
    port map(
      clk => clk,
      rst_n => rst_n,             
      r_update_curr=> r_update_curr,                    
      w_update_top_right=> w_update_top_right ,         
      r_update_top_right=> r_update_top_right,
      en_opcode=> en_opcode ,             
      opcode => opcode,
      z => z, 
      z_predictor_out => z_predictor_out,
      en_localsum=>  en_localsum,
      opcode_localsum => opcode_localsum,
      opcode_predictor_out => opcode_predictor_out,
      en_localdiff => en_localdiff,
      s_in_localdiff => s_in_localdiff,
      en_localdiff_shift => en_localdiff_shift, 
      s_out => s_out,
      s_in_left => s_in_left,
      s_in_top_right => s_in_top_right, 
      config_valid => config_valid, 
      z_opcode => z_opcode,
      clear_curr => clear_curr, 
      clear => clear,
      z_configured => z_configured, 
      P_configured => config_predictor.P,
      PREDICTION_configured => config_predictor.PREDICTION,
      eop => eop, 
      fsm_invalid_state =>    fsm_invalid_state,
      config_predictor => config_predictor,
      empty_curr=> empty_curr,                    
      aempty_curr=> aempty_curr,                   
      full_ld_ahbo => full_ld_ahbo,
      empty_ld_ahbi => empty_ld_ahbi, 
      w_update_ld_ahbo => w_update_ld_ahbo, 
      r_update_ld_ahbi => r_update_ld_ahbi, 
      w_update_record => w_update_record,
      r_update_record => r_update_record,
      hfull_record => hfull_record,
      empty_record =>empty_record,
      aempty_record => aempty_record,
      r_update_ld => r_update_ld, 
      r_update_wei => r_update_wei,
      en_weight_dir_fsm => en_weight_dir_fsm, 
      en_predictor => en_predictor, 
      clear_mac => clear_mac, 
      en_weight_central_fsm => en_weight_central_fsm, 
      address_central => address_central, 
      opcode_weight_out => opcode_weight_out, 
      opcode_weight_fsm => opcode_weight_fsm, 
      r_update_wei_dir => r_update_wei_dir
    );
    
  ----------------------------------------------------------------------------- 
  --! Components instantiation in BSQ architecture
  -----------------------------------------------------------------------------
  comp: entity shyloc_123.ccsds_comp_shyloc_bsq(arch_bsq)
    generic map(
      DRANGE  => D_GEN,
      --W_ADDR_BANK => W_ADDR_BANK, 
      W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE, 
      HMINDEX_123 => HMINDEX_123,
      W_BUFFER => W_BUFFER_GEN,
      RESET_TYPE => RESET_TYPE
    )
    port map(
      clk => clk,
      rst_n => rst_n,
      s => s,
      sign => sign,
      w_update_curr=> s_valid,              
      r_update_curr=> r_update_curr,          
      w_update_top_right=> w_update_top_right,          
      r_update_top_right=> r_update_top_right,          
      en_opcode=> en_opcode ,             
      opcode => opcode,
      z => z, 
      z_predictor_out => z_predictor_out,
      en_localsum=>  en_localsum,
      en_localdiff => en_localdiff,
      s_in_localdiff => s_in_localdiff,
      en_localdiff_shift => en_localdiff_shift, 
      opcode_localsum => opcode_localsum,
      opcode_predictor_out => opcode_predictor_out,
      ls_out => ls_out,
      ld_out => ld_out,
      s_out => s_out,
      s_in_left => s_in_left,
      s_in_top_right => s_in_top_right,
      config_valid => config_valid, 
      finished => finished,
      z_opcode => z_opcode,
      config_image  => config_image,
      config_predictor => config_predictor,
      clear => clear,
      clear_curr => clear_curr, 
      empty_curr=> empty_curr,                    
      aempty_curr=> aempty_curr,                
      full_curr=> full_curr,                
      afull_curr=>  afull_curr,               
      full_ld_ahbo => full_ld_ahbo,
      empty_ld_ahbi => empty_ld_ahbi, 
      w_update_ld_ahbo => w_update_ld_ahbo, 
      r_update_ld_ahbi => r_update_ld_ahbi,
      clk_ahb => clk_ahb,
      rst_ahb => rst_ahb, 
      ahbmi => ahbmi, 
      ahbmo => ahbmo, 
      config_ahbm => config_ahbm, 
      ahbm_status => ahbm_status,
      w_update_record => w_update_record,
      r_update_record => r_update_record,
      hfull_record => hfull_record, 
      empty_record =>empty_record,
      aempty_record =>aempty_record,
      r_update_ld => r_update_ld, 
      r_update_wei => r_update_wei,
      en_weight_dir_fsm => en_weight_dir_fsm, 
      en_predictor => en_predictor, 
      clear_mac => clear_mac, 
      en_weight_central_fsm => en_weight_central_fsm, 
      address_central => address_central, 
      opcode_weight_out => opcode_weight_out, 
      opcode_weight_fsm => opcode_weight_fsm, 
      r_update_wei_dir => r_update_wei_dir,
      fifo_full_pred => fifo_full_pred,
      pred_edac_double_error => pred_edac_double_error,
      mapped => mapped, 
      mapped_valid => mapped_valid
    );
end arch_bsq;

----------------------------------------------------------------------------- 
--! BIL ARCHIRTECTURE
-----------------------------------------------------------------------------
architecture arch_bil of predictor_shyloc is

    -- FIFO for current sample (input)
    signal w_update_curr: std_logic;            
    signal r_update_curr: std_logic;
    signal empty_curr: std_logic;                   
    signal aempty_curr: std_logic;                
    signal full_curr: std_logic;                
    signal afull_curr:  std_logic;      
    
    -- Neighbour FIFOs
    signal w_update_top: std_logic;             
    signal r_update_top: std_logic;             
    
    signal w_update_top_left: std_logic;          
    signal r_update_top_left: std_logic;          
    
    signal w_update_top_right: std_logic;           
    signal r_update_top_right: std_logic;         
    
    signal w_update_left: std_logic;            
    signal r_update_left:  std_logic;   
    
    --opcode
    signal en_opcode:  std_logic;             
    signal opcode: std_logic_vector (4 downto 0);
    signal z_opcode: std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);
    
    --localsum
    signal en_localsum:  std_logic;
    signal opcode_localsum: std_logic_vector (4 downto 0);
    
    --localdiff
    signal en_localdiff: std_logic;
    signal s_in_localdiff: std_logic_vector (D_GEN-1 downto 0);   
    
    signal s_out: std_logic_vector (D_GEN-1 downto 0);        
    signal s_in_left: std_logic_vector (D_GEN-1 downto 0);
    signal s_in_top_right: std_logic_vector (D_GEN-1 downto 0);   
    
    --localdiff shift
    signal en_localdiff_shift: std_logic;
    
    signal z: std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);
    signal hfull_record: std_logic;
    signal finished: std_logic;
    signal z_configured: std_logic_vector (W_Nz_GEN-1 downto 0);
    signal eop: std_logic;
    signal clear_curr: std_logic;
begin
  --Predictor is ready when the input FIFO is not full and the configuration is valid
  ready_pred <= not full_curr and not afull_curr and config_valid;
  -- Output assignment for finished signal
  finished_pred <= finished;
  -- Configured number of bands in the image.
  z_configured <= config_image.Nz;
  -- Output assignment for end of package.
  eop_pred <= eop;
  
  ----------------------------------------------------------------------------- 
  --! FSM for control in BIL arhictecture
  -----------------------------------------------------------------------------

  fsm: entity shyloc_123.ccsds_fsm_shyloc_bil(arch_bil)
    generic map(
        DRANGE  => D_GEN,
        --W_ADDR_BANK => W_ADDR_BANK, 
        W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE, 
        W_BUFFER => W_BUFFER_GEN,
        RESET_TYPE => RESET_TYPE
      )
        
    port map(
      clk => clk,
      rst_n => rst_n,
      w_update_curr=> w_update_curr,              
      r_update_curr=> r_update_curr,                    
      w_update_top_right=> w_update_top_right ,         
      r_update_top_right=> r_update_top_right,                    
      en_opcode=> en_opcode ,             
      opcode => opcode,
      z => z,
      en_localsum=>  en_localsum,
      opcode_localsum => opcode_localsum,
      en_localdiff => en_localdiff,
      s_in_localdiff => s_in_localdiff,
      en_localdiff_shift => en_localdiff_shift, 
      s_out => s_out,
      s_in_left => s_in_left,
      s_in_top_right => s_in_top_right, 
      config_valid => config_valid, 
      z_opcode => z_opcode,
      clear_curr => clear_curr, 
      clear => clear,
      z_configured => z_configured,     
      eop => eop,
      empty_curr=> empty_curr,                    
      aempty_curr=> aempty_curr,                
      full_curr=> full_curr,                
      afull_curr=>  afull_curr,
      fsm_invalid_state=> fsm_invalid_state,     
      hfull_record => hfull_record
    );
    
  ----------------------------------------------------------------------------- 
  --! Components instantiation in BIL architecture
  -----------------------------------------------------------------------------
  comp: entity shyloc_123.ccsds_comp_shyloc_bil(arch_bil)
    generic map(
        DRANGE  => D_GEN,
        --W_ADDR_BANK => W_ADDR_BANK, 
        W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE, 
        W_BUFFER => W_BUFFER_GEN,
        RESET_TYPE => RESET_TYPE
    )
    port map(
      clk => clk,
      rst_n => rst_n,
      s => s,
      sign => sign,
      w_update_curr=> s_valid,              
      r_update_curr=> r_update_curr,          
      w_update_top_right=> w_update_top_right ,         
      r_update_top_right=> r_update_top_right,          
      en_opcode=> en_opcode ,             
      opcode => opcode,
      z => z,
      en_localsum=>  en_localsum,
      en_localdiff => en_localdiff,
      s_in_localdiff => s_in_localdiff,
      en_localdiff_shift => en_localdiff_shift, 
      opcode_localsum => opcode_localsum,
      ls_out => ls_out,
      ld_out => ld_out,
      s_out => s_out,
      s_in_left => s_in_left,
      s_in_top_right => s_in_top_right,
      config_valid => config_valid,
      finished => finished, 
      z_opcode => z_opcode,
      config_image  => config_image,
      config_predictor => config_predictor,
      clear => clear,
      clear_curr => clear_curr, 
      empty_curr=> empty_curr,                    
      aempty_curr=> aempty_curr,                
      full_curr=> full_curr,                
      afull_curr=>  afull_curr,               
      hfull_record => hfull_record,
      fifo_full_pred => fifo_full_pred,
      pred_edac_double_error => pred_edac_double_error,
      mapped => mapped, 
      mapped_valid => mapped_valid
    );
end arch_bil;

-----------------------------------------------------------------------------  
--! Modified by AS: New BIL-MEM ARCHIRTECTURE
-----------------------------------------------------------------------------
architecture arch_bil_mem of predictor_shyloc is

    -- FIFO for current sample (input)
    signal w_update_curr: std_logic;
    signal r_update_curr: std_logic;
    signal empty_curr: std_logic;
    signal aempty_curr: std_logic;
    signal full_curr: std_logic;
    signal afull_curr:  std_logic;

    signal w_update_top_right_ahbo: std_logic;
    signal r_update_top_right_ahbi: std_logic;
    
    --opcode
    signal en_opcode:  std_logic;                
    signal opcode: std_logic_vector (4 downto 0);      
    signal z_opcode: std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);    
    signal t_opcode: std_logic_vector (W_T-1 downto 0);    
    
    --localsum
    signal en_localsum:  std_logic;                
    signal opcode_localsum: std_logic_vector (4 downto 0);    
    signal z_ls: std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);    
    signal t_ls: std_logic_vector (W_T-1 downto 0);    
    
    --localdiff
    signal en_localdiff: std_logic;        
    signal s_in_localdiff: std_logic_vector (D_GEN-1 downto 0);    
    
    signal s_out: std_logic_vector (D_GEN-1 downto 0);  
    signal s_in_left: std_logic_vector (D_GEN-1 downto 0);  
    signal s_in_top_right: std_logic_vector (D_GEN-1 downto 0);    
    
    --localdiff shift
    signal en_localdiff_shift: std_logic;        
    
    signal hfull_record: std_logic;    
    signal finished: std_logic;      
    signal z_configured: std_logic_vector (W_Nz_GEN-1 downto 0);  
    signal eop: std_logic;        
    signal clear_curr: std_logic;    
    
    -- AHB synchronization FIFOs      
    signal full_top_right_ahbo:   std_logic;    

    signal empty_top_right_ahbi: std_logic;    
    signal aempty_top_right_ahbi: std_logic;
    signal full_top_right_ahbi:   std_logic;      

begin

  --Predictor is ready when the input FIFO is not full and the configuration is valid
  ready_pred <= not full_curr and not afull_curr and config_valid;
  -- Output assignment for finished signal
  finished_pred <= finished;
  -- Configured number of bands in the image.
  z_configured <= config_image.Nz;
  -- Output assignment for end of package.
  eop_pred <= eop;
  
  -----------------------------------------------------------------------------  
  --! FSM for control in BIL-MEM arhictecture
  -----------------------------------------------------------------------------

  fsm: entity shyloc_123.ccsds_fsm_shyloc_bil_mem(arch_bil_mem)
    generic map(
        DRANGE  => D_GEN,
        --W_ADDR_BANK => W_ADDR_BANK, 
        W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE, 
        W_BUFFER =>  W_BUFFER_GEN,
        RESET_TYPE => RESET_TYPE
      )
        
    port map(
      clk => clk,      
      rst_n => rst_n,      
      w_update_curr => w_update_curr,   
      r_update_curr => r_update_curr,    
      w_update_top_right_ahbo => w_update_top_right_ahbo,  
      r_update_top_right_ahbi => r_update_top_right_ahbi,
      en_opcode=> en_opcode,        
      opcode => opcode,  
      z_opcode => z_opcode,    
      t_opcode => t_opcode,   
      z_ls => z_ls,      
      t_ls => t_ls,       
      en_localsum => en_localsum,      
      opcode_localsum => opcode_localsum,    
      en_localdiff => en_localdiff,  
      s_in_localdiff => s_in_localdiff,      
      en_localdiff_shift => en_localdiff_shift,     
      s_out => s_out,        
      s_in_left => s_in_left,  
      s_in_top_right => s_in_top_right,   
      config_valid => config_valid,   
      clear_curr => clear_curr,   
      clear => clear,    
      z_configured => z_configured,   
      eop => eop,    
      empty_curr => empty_curr,    
      aempty_curr => aempty_curr,    
      full_curr => full_curr,    
      afull_curr => afull_curr,  
      fsm_invalid_state => fsm_invalid_state,     
      hfull_record => hfull_record,  
      full_top_right_ahbo => full_top_right_ahbo,      
      empty_top_right_ahbi => empty_top_right_ahbi,  
      aempty_top_right_ahbi => aempty_top_right_ahbi,    -- Modified by AS: new port for TOP_RIGHT_FROM_AHB_FIFO almost empty signal      
      full_top_right_ahbi => full_top_right_ahbi  
    );
    
  -----------------------------------------------------------------------------  
  --! Components instantiation in BIL-MEM architecture
  -----------------------------------------------------------------------------
  comp: entity shyloc_123.ccsds_comp_shyloc_bil_mem(arch_bil_mem)
    generic map(
        DRANGE  => D_GEN,
        --W_ADDR_BANK => W_ADDR_BANK, 
        W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE,
        HMINDEX_123 => HMINDEX_123,  
        W_BUFFER =>  W_BUFFER_GEN,
        RESET_TYPE => RESET_TYPE
    )
    port map(
      clk => clk,    
      rst_n => rst_n,  
      s => s,      
      sign => sign,    
      w_update_curr => s_valid,     
      r_update_curr => r_update_curr,  
      w_update_top_right_ahbo => w_update_top_right_ahbo,  
      r_update_top_right_ahbi => r_update_top_right_ahbi,  
      en_opcode => en_opcode,  
      opcode => opcode,    
      z_ls => z_ls,  
      t_ls => t_ls,     
      z_opcode => z_opcode,    
      t_opcode => t_opcode,   
      en_localsum => en_localsum,    
      opcode_localsum => opcode_localsum,    
      en_localdiff => en_localdiff,  
      s_in_localdiff => s_in_localdiff,  
      en_localdiff_shift => en_localdiff_shift,   
      ls_out => ls_out,  
      ld_out => ld_out,  
      s_out => s_out,    
      s_in_left => s_in_left,    
      s_in_top_right => s_in_top_right,  
      config_valid => config_valid,  
      finished => finished,     
      config_image  => config_image,    
      config_predictor => config_predictor,  
      clear => clear,      
      clear_curr => clear_curr,   
      empty_curr => empty_curr,  
      aempty_curr => aempty_curr,  
      full_curr => full_curr,    
      afull_curr =>  afull_curr,    
      hfull_record => hfull_record,  
      full_top_right_ahbo => full_top_right_ahbo,    
      empty_top_right_ahbi => empty_top_right_ahbi,
      aempty_top_right_ahbi => aempty_top_right_ahbi,    -- Modified by AS: new port for TOP_RIGHT_FROM_AHB_FIFO almost empty signal      
      full_top_right_ahbi => full_top_right_ahbi,  
      clk_ahb => clk_ahb,    
      rst_ahb => rst_ahb,   
      ahbmi => ahbmi,     
      ahbmo => ahbmo,    
      config_ahbm => config_ahbm,   
      ahbm_status => ahbm_status,    
      fifo_full_pred => fifo_full_pred,    
      pred_edac_double_error => pred_edac_double_error,  
      mapped => mapped,     
      mapped_valid => mapped_valid  
    );
    
end arch_bil_mem;