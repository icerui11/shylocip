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
-- Design unit  : shyloc_functions package
--
-- File name    : shyloc_functions.vhd
--
-- Purpose      : Providing generic functions to the compressor
--
-- Note         :
--
-- Library      : shyloc_utils
--
-- Author       : Lucana Santos, Ana Gomez
--
-- Contact      : lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--============================================================================

--!@file #shyloc_functions.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  Providing generic functions to the compressor

--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;

--! Use shyloc_functions package
package shyloc_functions is
  
  -------------------------------
  --! Calculates binary logarithm
  -------------------------------
  function log2_exact( i : integer) return integer;
  ---------------------------------------------
  --! Calculates binary logarithm with shifters
  ---------------------------------------------
  function log2( i : integer) return integer;
  ------------------------------------
  --! Calculates binary logarithm with ranges
  ------------------------------------
  function log2_simp( i : integer) return integer;
  ---------------------------------------------
  --! Calculates binary logarithm rounding down
  ---------------------------------------------
  function log2_floor( i : integer) return integer;
  ---------------
  --! Rounding up
  ---------------
  function ceil(A: integer; B: integer) return integer;
  -----------------------------------------------------------------------------------
  --! Estimates the number of k possibles options (according to D and CODESET values)
  -----------------------------------------------------------------------------------
  function get_n_k_options (D: integer; CODESET: integer) return integer;
  -----------------------------------------------
  --! Calculates the maximum between two integers
  -----------------------------------------------
  function maximum(a : integer; b: integer) return integer;
  ---------------------------------------------------------------------------------------------------------------
  --! Estimates the number of necessary bits to propagate the selected option (according to D and CODESET values)
  ---------------------------------------------------------------------------------------------------------------
  function get_n_bits_option(D: integer; CODESET: integer) return integer;
  ------------------------------------
  --! 
  ------------------------------------
  function get_k_bits_option(W_BUFFER: integer; CODESET: integer; W_K_GEN: integer) return integer;
  -------------------------------------------------------------------------------------------------
  --! Calculates the number of bits to shift to match variables involving W_BUFFER_GEN and W_BUFFER
  -------------------------------------------------------------------------------------------------
  function get_amt_shift(param: integer; param_conf: integer) return integer;
  ------------------------------------------------------------------------------
  --! Creates a valid signal to use the full_prediction parameter in computation
  ------------------------------------------------------------------------------
  function getfull( i : integer) return integer;
  ------------------------------------
  --! Calculates the absolute value
  ------------------------------------
  function absolute( a : integer ) return integer;
  ------------------------------------
  --! Returns the integer quotient of a division
  ------------------------------------
  function modulo (a: integer; b: integer) return integer;
  ------------------------------------
  --! Calculates indexes
  ------------------------------------
  function indexes (A: integer) return integer;
  -----------------------------------------
  --! Calculates the number of fs_sequences
  -----------------------------------------
  function n_fs_calc (segment_gen: unsigned; w_opt_gen: unsigned; j: unsigned;  w_buffer: integer) return integer;
  
  -----------------------------------------
  --! Calculates the number of fs_sequences
  -----------------------------------------
  
	function get_gamma_val (J_gen: integer; D_gen: integer) return integer;
	
	-----------------------------------------
	--! Defines the correct value of gamma
	-----------------------------------------
	
  
end shyloc_functions;

package body shyloc_functions is
  
  function log2_exact( i : integer) return integer is
    variable j  : integer := 0;
  begin
    for j in 1 to 32 loop
      if (2**j > i) then 
        return (j-1);
      end if;
    end loop;
    return 32;
  end function;
  
  function log2( i : integer) return integer is
    variable j  : integer := 0;
    variable k : unsigned (31 downto 0):= unsigned(to_signed(i, 32));
    variable exp : unsigned (31 downto 0):= (31 downto 1 => '0', 0 => '1');
    begin
      j := 0;
      k := unsigned(to_signed(i, 32));
      exp := (31 downto 1 => '0', 0 => '1');
      for h in 0 to 31 loop
        if (exp > k) then
          exit;
        end if;
        exp := exp sll 1;
        j := j + 1;
      end loop;
    return j;
  end function; 
  
  function log2_simp( i : integer) return integer is
    variable j  : integer := 0;
    begin
      if (i <= 8) then
        j := 3;
      elsif (i <= 16) then
        j := 4;
      elsif (i <= 32) then
        j := 5;
      else
        j := 6;
      end if;
    return j;
  end function; 

  function log2_floor( i : integer) return integer is
    variable j  : integer := 0;
  begin
    j := 0;
    while (2**j < i) loop
      j := j + 1;
    end loop; 
    return j;
  end function;

  function ceil (A: integer; B: integer) return integer is
    variable q: integer := 0;
    variable r: integer := 0;
  begin
    q := A/B;
    r := A-q*B;
    if (r > 0) then
      q := q+1;
    end if; 
    return q;
  end function;
  
  function get_n_k_options (D: integer; CODESET: integer) return integer is
    variable n_k_options: integer := 0;
  begin
  
    if (D <= 4) and (CODESET = 1) then
      if (D < 3) then
        n_k_options := 0;
      else
        n_k_options := 1;
      end if;
    elsif (D < 5) then
      n_k_options := 4;
    elsif (D < 9) then
      n_k_options := 5;
    elsif (D < 14) then
      n_k_options := D ;
    elsif (D < 17) then
      n_k_options := 13 ;
		-- Modified by AS & YB
		elsif (D < 30) then
			n_k_options := D ;
    else
      n_k_options := 29;
    end if;   
    
    return n_k_options;
  
  end function;
  function maximum(a : integer; b: integer) return integer is
  begin
    if (b > a) then return b;
    else return a;
    end if;
  end function;
  
  function get_n_bits_option(D: integer; CODESET: integer) return integer is
    variable n_bits_option : integer := 0;
  begin
    if (D <= 4) and (CODESET = 1) then
      if(D < 3) then
        n_bits_option := 2;
      else
        n_bits_option := 3;
      end if;
    elsif (D < 9) then
      n_bits_option := 4;
    elsif (D < 17) then
      n_bits_option := 5;
    else
      n_bits_option := 6;
    end if;
    return n_bits_option;
  end function;
  
  function get_k_bits_option(W_BUFFER: integer; CODESET: integer; W_K_GEN: integer) return integer is
    variable k_bits_option : integer := 0;
  begin
    if (2**(W_K_GEN) <= W_BUFFER) then
      k_bits_option := W_K_GEN+1;
    else
      k_bits_option := W_K_GEN;
    end if;
    return k_bits_option;
  end function;
  
  function get_amt_shift(param: integer; param_conf: integer)  return integer is
    variable amt_shift : integer := 0;
    variable diff : integer := 0;
  begin
    diff := param - param_conf;
    if (diff = 8) then
      amt_shift := 8;
    elsif (diff = 16) then
      amt_shift := 16;
    elsif (diff = 24) then
      amt_shift := 24;
    elsif (diff = 32) then
      amt_shift := 32;
    elsif (diff = 40) then
      amt_shift := 40;
    elsif (diff = 48) then
      amt_shift := 48;
    elsif (diff = 56) then
      amt_shift := 56;
    elsif (diff = 64) then
      amt_shift := 64;
    else
      amt_shift := 0;
    end if;
    return amt_shift;
  end function;
  
  function getfull( i : integer) return integer is
  begin
    if (i = 1) then 
      return 0;
    else 
      return 1;
    end if;
  end function;

  function absolute( a : integer ) return integer is
  begin
    if (a < 0) then 
      return (-1)*a;
    else 
      return a;
    end if;
  end function;
  
  function modulo (a: integer; b: integer) return integer is
    variable result: integer := 0;
  begin
    result :=  a - b*(a/b);
    return result;
  end function;
  
  function indexes (a: integer) return integer is
    variable result: integer := 0;
  begin
    if a < 0 then
      result := 0;
    else
      for i in 0 to a loop
        result :=  result + 2**i;
      end loop;
    end if;
    return result;
  end function;
  
  function n_fs_calc (segment_gen: unsigned; w_opt_gen: unsigned; j: unsigned; w_buffer: integer) return integer is 
    variable div : integer := 0;
    variable result : integer := 0;
  begin
    div := 8;
    case w_buffer is
      when 8 =>
        div := 8;
      when 16 =>
        div := 16;
      when 24 =>
        div := 24;
      when 32 => 
        div := 32;
      when 40 => 
        div := 40;
      when 48 => 
        div := 48;
      when 56 => 
        div := 56;
      when 64 =>
        div := 64;
      when others =>
        div := 8;
    end case;
    if (to_integer(segment_gen) + to_integer(w_opt_gen) > 3*to_integer(j)) then
      result := to_integer((unsigned(to_signed(to_integer((segment_gen + w_opt_gen)/div), (segment_gen'length + w_opt_gen'length)))) + 1);
    else 
      result := to_integer((unsigned(to_signed((3*to_integer(j)/div), (j'length)))) + 1);
    end if;
    return result;
  end function;
  
	function get_gamma_val (J_gen: integer; D_gen: integer) return integer is
		variable n_gamma_val: integer := 0;
 	begin
 	
		if ((J_gen*D_gen) < 1024) then
			n_gamma_val := 5;
		
		else
			n_gamma_val := 6;
		end if;		
		
		return n_gamma_val;
	
	end function;
	
end package body;
