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
-- Design unit  : bitpackv2 module
--
-- File name    : bitpackv2.vhd
--
-- Purpose      : Bit packing for codewords or residuals, and header.
--
-- Note         :
--
-- Library      : shyloc_utils
--
-- Author       : Lucana Santos
--
-- Instantiates : r_shift (barrel_shifter), l_shift (barrel_shifter)
--============================================================================

--!@file #bitpackv2.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  Bit packing for codewords or residuals, and header.
--!@details The codewords are packed in a bit-by-bit fashion. This module packs the input data in a buffer, 
--! which size can be selected by the user by setting the parameter. Once the buffer is full, it is copied to the 
--! output register and validated by a flag. The output data corresponds to the final compressed bit stream.  

--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;

--! Use shyloc_utils
library shyloc_utils;

--! bitpackv2 entity. Bit packing for codewords or residuals, and header.
entity bitpackv2 is
  generic (
       W_W_BUFFER_GEN : integer := 32;    --! Number of bits to represent the bit width of the output buffer.
       RESET_TYPE   : integer := 1;     --! Reset type (Synchronous or asynchronous).
       W_BUFFER   : natural := 32;      --! Bit width of the output buffer. It has to be always greater than the maximum possible bit width of the codewords (U_MAX + DRANGE).
       W_NBITS    : natural := 6        --! Bit width of the signal which represents the number of bits of each codeword.
       );
  port (
    
    -- System Interface
    clk   : in std_logic;                   --! Clock signal.
    rst_n : in std_logic;                   --! Reset signal. Active low.
    
    -- Configuration and Control Interface
    en          : in std_logic;                   --! Enable signal.
    clear       : in std_logic;                   --! It forces the module to its initial state.
    W_BUFFER_configured : in std_logic_vector(W_W_BUFFER_GEN-1 downto 0); --! Output word size.             
    config_valid    : in std_logic;                   --! Validates the input configuration.
    
    -- Data Interface
    n_bits    : in std_logic_vector (W_NBITS-1 downto 0);       --! Number of bits of the codeword.
    codeword  : in std_logic_vector (W_BUFFER-1 downto 0);      --! Codeword.
    flush   : in std_logic;                     --! Flag to force the module to flush the output buffer.
    buff_left : out std_logic_vector (W_BUFFER -1 downto 0);      --! Register to store flushed bits after a flush operation.
    bits_flush  : out std_logic_vector (W_W_BUFFER_GEN-1 downto 0);   --! Register to store the number of bits in the flush register.
    buff_out  : out std_logic_vector (W_BUFFER -1 downto 0);      --! Output buffer.
    buff_full : out std_logic);                   --! Flag to indicate that the buffer is full. 
end bitpackv2;

--! @brief Architecture of bitpackv2 
architecture arch of bitpackv2 is
  
  constant STAGES: natural := W_W_BUFFER_GEN; -- Max. number of stages of the barrel shifter
  signal amt_right, amt_left: std_logic_vector (STAGES-1 downto 0);
  signal codeword_in, codeword_tmp_right, codeword_in_conf, codeword_tmp_left : std_logic_vector (W_BUFFER -1 downto 0);
  signal bits_left, bits_left_next: unsigned (W_W_BUFFER_GEN-1 downto 0); -- Store the amount of bits left in buffer
  signal buff_tmp, buff_tmp_next, buff_out_tmp, buff_out_next: std_logic_vector (W_BUFFER -1 downto 0);
  signal buff_full_next : std_logic;
  signal mask : std_logic_vector(W_BUFFER -1 downto 0);

begin
  
  --------------------------------------
  --! Input and output signal assignments
  --------------------------------------
  codeword_in  <= std_logic_vector(resize (unsigned(codeword), W_BUFFER));
  buff_out <= buff_out_tmp;
  
  codeword_in_conf <= mask and codeword_in;
  
  ------------------------------------------------
  --!@brief  barrel_shifter to perform right shift
  ------------------------------------------------
  r_shift: entity shyloc_utils.barrel_shifter(arch)
    generic map (W => W_BUFFER,
          S_MODE => 1, --right shift
          STAGES => STAGES) 
    port map (
      barrel_data_in => codeword_in_conf,
      amt => amt_right,
      barrel_data_out => codeword_tmp_right);
      
  -----------------------------------------------
  --!@brief  barrel_shifter to perform left shift
  -----------------------------------------------
  l_shift: entity shyloc_utils.barrel_shifter(arch)
  generic map (W => W_BUFFER,
        S_MODE => 0, --left shift
        STAGES => STAGES) 
  port map (
    barrel_data_in => codeword_in_conf,
    amt => amt_left,
    barrel_data_out => codeword_tmp_left); -- Map to a variable with the size of the buffer (truncate or extend)
  
  
  ------------------------------------------------------------------------------------------------------------------------
  --! Process to update the remaining bits for the output word (aong with the full flag), and to set the mask to write it
  ------------------------------------------------------------------------------------------------------------------------
  process (clk, rst_n)
    variable W_BUFFER_conf  : integer:= 0;
    variable ini      : std_logic := '1';
  begin 
    if (rst_n = '0' and RESET_TYPE = 0) then 
      W_BUFFER_conf := 0;
      ini := '1';
      bits_left <= to_unsigned(W_BUFFER, bits_left'length);
      buff_tmp <= (others => '0');
      buff_out_tmp <= (others => '0');
      buff_full <= '0';
      buff_left <= (others => '0');
      bits_flush <= (others => '0');
      mask <= (others => '1');
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        W_BUFFER_conf := 0;
        ini := '1';
        bits_left <= to_unsigned(W_BUFFER, bits_left'length);
        buff_tmp <= (others => '0');
        buff_out_tmp <= (others => '0');
        buff_full <= '0';
        buff_left <= (others => '0');
        bits_flush <= (others => '0');
        mask <= (others => '1');
      else
        if (ini = '1' and config_valid = '1') then
          W_BUFFER_conf := to_integer(unsigned(W_BUFFER_configured));
          for j in 0 to W_BUFFER-1 loop
            if (j < W_BUFFER_conf) then
              mask(j) <= '1';
            else
              mask(j) <= '0';
            end if;
          end loop; 
          bits_left <= to_unsigned(W_BUFFER_conf, bits_left'length);
          ini := '0';
        end if;
        if (en = '1') then
          buff_full <= buff_full_next;
          buff_out_tmp <= buff_out_next;
          if (flush = '1') then
            buff_tmp <= (others => '0');
            bits_left <= to_unsigned(W_BUFFER_conf, bits_left'length);
            bits_flush <= std_logic_vector(resize(bits_left_next, bits_flush'length));
            buff_left <= buff_tmp_next;
          else
            buff_tmp <= buff_tmp_next;
            bits_left <= bits_left_next;
          end if;
        elsif (flush = '1') then
          if (bits_left /= to_unsigned(W_BUFFER_conf, bits_left'length)) then
            buff_out_tmp <= buff_tmp; 
            buff_full <= '1';
            buff_tmp <= (others => '0');
            bits_left <= to_unsigned(W_BUFFER_conf, bits_left'length);
          else
            buff_full <= '0';
          end if;
        else
          buff_full <= '0';
        end if;
      end if;
    end if;
  end process;
  
  
  ----------------------------------------------------------------------------------------------------------------------
  --! Process to compute the remaining bits for the next partial write in the output word, and perform the partial write
  ----------------------------------------------------------------------------------------------------------------------
  process (bits_left, n_bits, buff_tmp, buff_out_tmp, codeword_tmp_right, codeword_tmp_left, en, W_BUFFER_configured, mask) 
    variable n_bits_var: unsigned (bits_left'high downto 0);
    variable buff_tmp_var: std_logic_vector (W_BUFFER -1 downto 0);
    variable sh_left: unsigned(bits_left'high downto 0);
    variable sh_right: unsigned(bits_left'high downto 0);
    variable W_BUFFER_conf : integer:= 0;
  begin
    
    if (bits_left'length > n_bits'length) then
      n_bits_var := resize(unsigned(n_bits), bits_left'length);
    else
      n_bits_var := unsigned(n_bits(bits_left'high downto 0));
    end if;
    
    sh_right := resize(n_bits_var - bits_left, sh_right'length);
    amt_right <= std_logic_vector(sh_right);
    W_BUFFER_conf := to_integer(unsigned(W_BUFFER_configured));
    -- There are bits enough in the output word
    if (n_bits_var < bits_left) then 
      sh_left := resize(bits_left - n_bits_var, sh_left'length);
      amt_left <= std_logic_vector(sh_left);
      buff_tmp_var := (codeword_tmp_left xor buff_tmp) and mask;
      buff_full_next <= '0';
      buff_tmp_next <= buff_tmp_var;
      buff_out_next <= buff_out_tmp; 
      if (en = '1') then 
        bits_left_next <= bits_left - n_bits_var; 
      else
        bits_left_next <= bits_left;
      end if;
    -- There are not bits enough in the output word (real partial write indeed)
    else  
      sh_left := resize(bits_left + W_BUFFER_conf - n_bits_var,sh_left'length);
      amt_left <= std_logic_vector(sh_left);    
      buff_tmp_var := codeword_tmp_right xor buff_tmp; 
      buff_full_next <= '1';
      buff_out_next <= buff_tmp_var;
      buff_tmp_next <= codeword_tmp_left and mask;
      if (en = '1') then
        bits_left_next <= W_BUFFER_conf - n_bits_var + bits_left;
      else
        bits_left_next <= bits_left;      
      end if;
    end if;
  end process;

end arch;
