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
-- Design unit  : AHB types package
--
-- File name    : ccsds_ahb_types.vhd
--
-- Purpose      : Contains types definitions for AHB master and slave interfaces.
--    
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
-- Instantiates : 
--============================================================================

library IEEE;
use IEEE.std_logic_1164.all;
library shyloc_123; 
use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all;    

--!@file #ccsds_ahb_types.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Contains types definitions for AHB master and slave interfaces.


package ccsds_ahb_types is

  ---------------------------------------------------------------------------
  --! AHB master control record.
  ---------------------------------------------------------------------------
  type ahbtbm_ctrl_type is record
    delay   : std_logic_vector(7 downto 0);
    dbgl    : integer;
    reset   : std_logic;
    use128  : integer;
  end record;
  
  ---------------------------------------------------------------------------
  --! AHB master access type record.
  ---------------------------------------------------------------------------
  type ahbtbm_access_type is record
    haddr     : std_logic_vector(31 downto 0);
    hdata     : std_logic_vector(31 downto 0);
    hdata128  : std_logic_vector(127 downto 0);
    htrans    : std_logic_vector(1 downto 0);
    hburst    : std_logic_vector(2 downto 0);
    hsize     : std_logic_vector(2 downto 0);
    hprot     : std_logic_vector(3 downto 0);
    hwrite    : std_logic;
    ctrl      : ahbtbm_ctrl_type;
  end record;
  
  ---------------------------------------------------------------------------
  --! AHB master status type record
  ---------------------------------------------------------------------------
  type ahbtbm_status_type is record
    err     : std_logic;
    ecount  : std_logic_vector(15 downto 0);
    eaddr   : std_logic_vector(31 downto 0);
    edatac  : std_logic_vector(31 downto 0);
    edatar  : std_logic_vector(31 downto 0);
    hresp   : std_logic_vector(1 downto 0);
  end record;
  
  ---------------------------------------------------------------------------
  --! AHB master access array type
  ---------------------------------------------------------------------------
  type ahbtbm_access_array_type is array (0 to 1) of ahbtbm_access_type;

  ---------------------------------------------------------------------------
  --! AHB master ctrl type
  ---------------------------------------------------------------------------
  type ahbtbm_ctrl_in_type is record
    ac  : ahbtbm_access_type;
  end record;
  
  ---------------------------------------------------------------------------
  --! AHB master ctrl out type
  ---------------------------------------------------------------------------
  type ahbtbm_ctrl_out_type is record
    rst       : std_logic;
    clk       : std_logic;
    update    : std_logic;
    dvalid    : std_logic;
    hrdata    : std_logic_vector(31 downto 0);
    hrdata128 : std_logic_vector(127 downto 0);
    status    : ahbtbm_status_type;
  end record;

  --------------------------------------------------------------------------
  --! AHB ctrl type
  ---------------------------------------------------------------------------
  type ahbtb_ctrl_type is record
    i : ahbtbm_ctrl_in_type;
    o : ahbtbm_ctrl_out_type;
  end record;
  
  --------------------------------------------------------------------------
  --! AHB register type
  ---------------------------------------------------------------------------
  type reg_type is record
      grant     : std_logic;
      grant2    : std_logic;
      retry     : std_logic_vector(1 downto 0);
      read      : std_logic; -- indicate 
      write     : std_logic; 
      dbgl      : integer;
      use128    : integer;
      hsize     : std_logic_vector(2 downto 0);
      ac        : ahbtbm_access_array_type;
      retryac   : ahbtbm_access_type;
      curac     : ahbtbm_access_type;
      haddr     : std_logic_vector(31 downto 0); -- addr current access
      hdata     : std_logic_vector(31 downto 0); -- data current access
      hdata128  : std_logic_vector(127 downto 0); -- data current access
      hwrite    : std_logic;                     -- write current access
      hrdata    : std_logic_vector(31 downto 0);
      hrdata128 : std_logic_vector(127 downto 0);
      status    : ahbtbm_status_type;
      dvalid    : std_logic;
      oldhtrans : std_logic_vector(1 downto 0);
      start   : std_ulogic;
      active  : std_ulogic;
  end record;

  --------------------------------------------------------------------------
  --! AHB idle constant
  ---------------------------------------------------------------------------
  constant ac_idle : ahbtbm_access_type :=
    (haddr => x"00000000", hdata => x"00000000", 
     hdata128 => x"00000000000000000000000000000000", 
     htrans => "00", hburst =>"000", hsize => "000", hprot => "0000", hwrite => '0', 
     ctrl => (delay => x"00", dbgl => 100, reset =>'0', use128 => 0));

  --------------------------------------------------------------------------
  --! AHB cltr idle constant
  ---------------------------------------------------------------------------    
  constant ctrli_idle : ahbtbm_ctrl_in_type :=(ac => ac_idle);
  
  --------------------------------------------------------------------------
  --! AHB cltr no drive constant
  ---------------------------------------------------------------------------    
  constant ctrlo_nodrive : ahbtbm_ctrl_out_type :=(rst => 'H', clk => 'H', 
    update => 'H', dvalid => 'H', hrdata => (others => 'H'), hrdata128 => (others => 'H'),
    status => (err => 'H', ecount => (others => 'H'), eaddr => (others => 'H'),
         edatac => (others => 'H'), edatar => (others => 'H'),
         hresp => (others => 'H')));
end package ccsds_ahb_types;
