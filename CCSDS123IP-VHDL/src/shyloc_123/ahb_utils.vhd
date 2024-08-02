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
-- Design unit  : AHB utilities
--
-- File name    : ahb_utils.vhd
--
-- Purpose      : Some utilities needed by the AHB modules. 
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


--!@file #ahb_utils.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Some utilities needed by the AHB modules. 

package ahb_utils is
  ---------------------------------------------------------------------------
  --! Notx operator.
  ---------------------------------------------------------------------------
  function notx(d : std_logic_vector) return boolean;
  
  ---------------------------------------------------------------------------
  --! "-" overloaded
  ---------------------------------------------------------------------------
  function "-" (a, b : std_logic_vector) return std_logic_vector;
  
  ---------------------------------------------------------------------------
  --! "+" overloaded
  ---------------------------------------------------------------------------
  function "+" (a, b : std_logic_vector) return std_logic_vector;
  
  ---------------------------------------------------------------------------
  --! "+" overloaded
  ---------------------------------------------------------------------------
  function "+" (a : std_logic_vector; b: integer) return std_logic_vector;
  
  ---------------------------------------------------------------------------
  --! std logic vector of 32 zeros. 
  ---------------------------------------------------------------------------
  constant zero32 : std_logic_vector(31 downto 0) := (others => '0');
  
  ---------------------------------------------------------------------------
  --! "-" overloaded
  ---------------------------------------------------------------------------
  function "-" (d : std_logic_vector; i : integer) return std_logic_vector;
  
  ---------------------------------------------------------------------------
  --! "*" overloaded
  ---------------------------------------------------------------------------
  function "*" (d : std_logic_vector; i : integer) return std_logic_vector;
  
  ---------------------------------------------------------------------------
  --! "*" overloaded
  ---------------------------------------------------------------------------
  function "*" (d : integer; i : integer) return std_logic_vector;
  
end ahb_utils;

package body ahb_utils is

  ---------------------------------------------------------------------------
  --! Notx operator.
  ---------------------------------------------------------------------------
  function notx(d : std_logic_vector) return boolean is
    variable res : boolean;
  begin
    res := true;
  -- pragma translate_off
    res := not is_x(d);
  -- pragma translate_on
    return (res);
  end;

  ---------------------------------------------------------------------------
  --! "+" overloaded
  ---------------------------------------------------------------------------
  function "+" (a, b : std_logic_vector) return std_logic_vector is
    variable x : std_logic_vector(a'length-1 downto 0);
    variable y : std_logic_vector(b'length-1 downto 0);
    begin
    -- pragma translate_off
      if notx(a&b) then
    -- pragma translate_on
      return(std_logic_vector(unsigned(a) + unsigned(b)));
    -- pragma translate_off
      else
       x := (others =>'X'); y := (others =>'X');
       if (x'length > y'length) then return(x); else return(y); end if;
      end if;
    -- pragma translate_on
  end;
  
  ---------------------------------------------------------------------------
  --! "+" overloaded
  ---------------------------------------------------------------------------
  function "+" (a: std_logic_vector; b: integer) return std_logic_vector is
    variable x : std_logic_vector(a'length-1 downto 0);
    begin
    -- pragma translate_off
      if notx(a) then
    -- pragma translate_on
      return(std_logic_vector(unsigned(a) + b));
    -- pragma translate_off
      else
       x := (others =>'X'); return(x); 
      end if;
    -- pragma translate_on
  end;
  
  
  ---------------------------------------------------------------------------
  --! "-" overloaded
  ---------------------------------------------------------------------------
  function "-" (a, b : std_logic_vector) return std_logic_vector is
    variable x : std_logic_vector(a'length-1 downto 0);
    variable y : std_logic_vector(b'length-1 downto 0);
  begin
    -- pragma translate_off
      if notx(a&b) then
    -- pragma translate_on
      return(std_logic_vector(unsigned(a) - unsigned(b)));
    -- pragma translate_off
      else
       x := (others =>'X'); y := (others =>'X');
       if (x'length > y'length) then return(x); else return(y); end if; 
      end if;
    -- pragma translate_on
  end;
  
  ---------------------------------------------------------------------------
  --! "-" overloaded
  ---------------------------------------------------------------------------
  function "-" (d : std_logic_vector; i : integer) return std_logic_vector is
    variable x : std_logic_vector(d'length-1 downto 0);
  begin
    -- pragma translate_off
      if notx(d) then
    -- pragma translate_on
      return(std_logic_vector(unsigned(d) - i));
    -- pragma translate_off
      else x := (others =>'X'); return(x); 
      end if;
    -- pragma translate_on
  end;
  
  ---------------------------------------------------------------------------
  --! "*" overloaded
  ---------------------------------------------------------------------------
  function "*" (d : std_logic_vector; i : integer) return std_logic_vector is
    variable result: std_logic_vector(31 downto 0);
    variable intermediate: unsigned(32+5 - 1 downto 0);
  begin
    -- pragma translate_off
    assert d'length <= 32 report "ahb_utils: * operator std_logic_vector length up to 32 bits only" severity failure;
    assert i <= 16 report "ahb_utils: * operator integer max accepted value is 16" severity failure;
    -- pragma translate_on
    intermediate := resize(unsigned(d), 32)*to_unsigned(i, 5);
    -- pragma translate_off
    assert intermediate(intermediate'high downto 32) = to_unsigned(0, intermediate'length) report "ahb_utils: vector truncated" severity failure;
    -- pragma translate_on
    result := std_logic_vector(intermediate (31 downto 0));
    return result;
  end;
  
  ---------------------------------------------------------------------------
  --! "*" overloaded
  ---------------------------------------------------------------------------
  function "*" (d : integer; i : integer) return std_logic_vector is
    variable result: std_logic_vector(31 downto 0);
  begin
    result := std_logic_vector(to_unsigned(d*i, result'length));
    return result;
  end;
end package body;