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
-- Design unit  : Predictor module
--
-- File name    : predictor2stagesv2.vhd
--
-- Purpose      : Calculates the prediction (CCSDS 123.0-B-1; Section 4.7).
--
-- Note         : 
--
-- Library      : shyloc_123
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
-- Instantiates : clip
--============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library shyloc_123; use shyloc_123.ccsds123_parameters.all; use shyloc_123.ccsds123_constants.all;    

--!@file #predictor2stagesv2.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Calculates the prediction (CCSDS 123.0-B-1; Section 4.7).
--!@details The prediction is performed in two clock cycles. The input dz comes from the multiply and accumulator
--! module. 


entity predictor2stagesv2 is
  generic (
       RESET_TYPE: integer := 1;
       OMEGA: integer := 14;        --! Weight component resolution
       W_S_SIGNED: integer := 17;     --! Dynamic range of the input samples (signed).
       R: integer := 64;          --! Register size. 
       W_DZ: integer := 39;       --! Bit width of the result of the multiply and accumulate stage. 
       NBP: integer := 3;         --! Number of bands for prediction. 
       W_SCALED : integer := 66;      --! Bit width of the scaled predictor (R+2)
       W_SMAX: integer := 17;       --! Bit width of parameters smax, smin, smid (DRANGE + 1)
       W_ADDR_IN_IMAGE: integer := 15;  --! Width in bit of the address to the samples in the image.
       W_LS: integer := 19);        --! Bit width of the local differences.
  port (
     clk: in std_logic;                     --! Clock signal.
     rst_n: in std_logic;                   --! Reset signal. Active low.
     opcode: in std_logic_vector (4 downto 0);          --! Code indicating the relative position of a sample in the spatial dimension.
     en: in std_logic;                      --! Enable signal.
     clear : in std_logic;                    --! Synchronous clear signal. 
     config_predictor: in config_123_predictor;         --! Predictor configuration values.
     config_image: in config_123_image;             --! Image metadata configuration values.
     z: in std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);   --! Coordinate z.
     s: in std_logic_vector (W_S_SIGNED-1 downto 0);      --! Sample to be compressed
     smax_var: in std_logic_vector(1 downto 0);         --! Variable part (first 2 most significant bits) of smax.
     smin_var: in std_logic_vector(1 downto 0);         --! Variable part (first 2 most significant bits) of smin. 
     smid_var: in std_logic_vector(1 downto 0);         --! Variable part (first 2 most significant bits) of smid.
     dz: in std_logic_vector(W_DZ -1  downto 0);        --! Result of the multiplication and accumulation stage.
     ls: in std_logic_vector (W_LS-1 downto 0);         --! Result of the local sum stage.
     s_mapped : out std_logic_vector (W_S_SIGNED-1 downto 0); --! Sample to be compressed to be sent to mapped 
     valid: out std_logic;                    --! Valid flag
     s_scaled : out std_logic_vector (W_SCALED-1 downto 0);   --! Scaled predicted sample.
     smin: out std_logic_vector(W_SMAX-1 downto 0);       --! Smin value, computed.
     smax: out std_logic_vector(W_SMAX-1 downto 0)        --! Smax value, computed. 
     );   
end predictor2stagesv2;

---------------------------------------------------------------------------
--!@brief Architecture definition
---------------------------------------------------------------------------
architecture arch of predictor2stagesv2 is
  
  constant W_CLIP : integer := W_SCALED;
  constant W_BOUND: integer := W_SMAX+1;
  
  signal smid, smid_cmb: std_logic_vector (W_SMAX-1 downto 0);
  signal smax_next, smin_next: std_logic_vector (1 downto 0); 
  signal clip_max, clip_min: std_logic_vector(W_BOUND-1 downto 0);  
  signal s_pred_out_clip : std_logic_vector (W_BOUND-1 downto 0);
  signal s_pred_no_clip, s_pred_no_clip_next : std_logic_vector (W_SCALED-1 downto 0);
  signal smax_const, smin_const, smid_const: std_logic_vector (W_SMAX-3 downto 0);
  signal two_powD, two_powD_1, smax_clip, smin_clip: std_logic_vector (W_SMAX -1 downto 0);
  signal s_z_prev: std_logic_vector (W_S_SIGNED-1 downto 0); 
  signal valid_reg : std_logic;
  signal s_mapped_reg: std_logic_vector (W_S_SIGNED-1 downto 0); 
  constant one: std_logic_vector(W_SMAX-1 downto 0) := (0 => '1', others => '0');
  signal v3_reg, v3_cmb: signed (R-1 downto 0);
  signal opcode_reg: std_logic_vector (4 downto 0);
  signal s_z_prev_reg: std_logic_vector (W_S_SIGNED-1 downto 0);
  
begin
  ---------------------------------------------------------------------------
  -- Computation of smax, smin and smid
  ---------------------------------------------------------------------------
  smax_const (smax_const'high downto 0)   <= (others => '1');
  smid_const (smid_const'high downto 0)   <= (others => '0');
  smin_const (smin_const'high downto 0)   <= (others => '0');
  
  smax_next <= smax_var; 
  smin_next <= smin_var; 
  
  --Useful values to compute smin, smax
  two_powD <= std_logic_vector(unsigned(one) sll to_integer(unsigned(config_image.D)));
  two_powD_1 <= std_logic_vector(signed(two_powD) - 1);
  
  smid_cmb <= (others => '0') when unsigned(config_image.IS_SIGNED) = 1 else '0'&two_powD(two_powD'high downto 1);  
  smax_clip <= two_powD_1 when unsigned(config_image.IS_SIGNED) = 0 else '0'&two_powD_1(two_powD_1'high downto 1);
  smin_clip <= (others => '0') when unsigned(config_image.IS_SIGNED) = 0 else not(smax_clip);
  
  ---------------------------------------------------------------------------
  --!@Clip module (clip.vhd)
  ---------------------------------------------------------------------------
  uut: entity shyloc_123.clip(arch)
  generic map (
    W_BOUND => W_BOUND, 
    W_CLIP => W_CLIP)
  port map (
    min => clip_min, 
    max => clip_max, 
    clipin => s_pred_no_clip_next, 
    clipout => s_pred_out_clip);
   
  clip_max <= smax_clip &'1'; 
  clip_min <= smin_clip &'0';

  ---------------------------------------------------------------------------
  -- Registers
  ---------------------------------------------------------------------------
  process (rst_n, clk)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      s_scaled  <= (others => '0');
      s_pred_no_clip <= (others => '0');
      s_z_prev <= (others => '0');
      s_mapped_reg <= (others => '0');
      s_mapped <= (others => '0');
      valid <= '0';
      valid_reg <= '0';
      smin <= (others => '0');
      smax <= (others => '0');
      smid <= (others => '0');
      s_z_prev_reg <= (others => '0');
      opcode_reg <= (others => '0');
      v3_reg <= (others => '0');
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        s_scaled  <= (others => '0');
        s_pred_no_clip <= (others => '0');
        s_z_prev <= (others => '0');
        s_mapped_reg <= (others => '0');
        s_mapped <= (others => '0');
        valid <= '0';
        valid_reg <= '0';
        smin <= (others => '0');
        smax <= (others => '0');
        smid <= (others => '0');
        s_z_prev_reg <= (others => '0');
        opcode_reg <= (others => '0');
        v3_reg <= (others => '0');
      else  
        smin <= smin_clip;
        smax <= smax_clip;
        smid <= smid_cmb;
        s_z_prev_reg <= s_z_prev;
        v3_reg <= v3_cmb;
        if (en = '1') then
          opcode_reg <= opcode;
          s_pred_no_clip <= s_pred_no_clip_next;
          valid_reg <= '1';
          s_mapped_reg <= s;
          if opcode(3 downto 0) = "0000" or unsigned(config_predictor.P) = 0 then
            s_z_prev <= s;
          end if;
        else
          valid_reg <= '0';
        end if;
        
        s_mapped <= s_mapped_reg;
        valid <= valid_reg;
        
        if (opcode_reg(3 downto 0) /= "0000") then
          s_scaled <= std_logic_vector(resize(signed(s_pred_out_clip), s_scaled'length));
        elsif (opcode_reg = "10000" or unsigned(config_predictor.P) = 0) then
          s_scaled <= s_pred_no_clip_next;
        else
          s_scaled <= s_pred_no_clip_next;
        end if;
      end if;
    end if; 
  end process;


  ---------------------------------------------------------------------------
  -- Combinatorial logic
  ---------------------------------------------------------------------------
  process (ls, dz, smid, s_z_prev_reg, opcode_reg, config_predictor, v3_reg, en)
    variable v0: signed (ls'high + 1 downto 0);
    variable v1: signed (v0'high + OMEGA downto 0);
    variable v2: signed (dz'high + 1 downto 0);
    variable v3, v4 : signed (R-1 downto 0);
    variable v5 : signed (v3'high + 2 downto 0);
    variable omega_index: integer := 0;
    variable mask_R: signed (R-1 downto 0) := (others => '1');
    variable reg_conf: integer := 0;
  begin

    v0 := resize (signed(ls), v0'length) - (resize (signed (smid), v0'length) sll 2);
    --TBC: barrel shifter
    v1 := resize(v0, v1'length)  sll to_integer(unsigned(config_predictor.OMEGA));
    v2 := resize(signed(dz), v2'length) + resize(v1, v2'length);
    
    reg_conf := to_integer(unsigned(config_predictor.R));

    if (v2'length > R) then
      v3 := v2(v3'high downto 0);
    else
      v3 := resize (v2, v3'length);
    end if;
    
    if (reg_conf > 0) then
      mask_R := (others => v3(reg_conf-1));
      for i in 0 to v3'high loop
        if i < reg_conf then
          v3(i) := v3(i);
        else
          v3(i) := mask_R(i);
        end if;
      end loop;
    end if;
    
    if (en = '1') then
      v3_cmb <= v3;
    else
      v3_cmb <= v3_reg;
    end if;
    
    v4 := shift_right(v3_reg, to_integer(unsigned(config_predictor.OMEGA)+1)); -- but it has to be arithmetic shift
    v5 := resize(v4, v5'length) + 1 + (resize (signed(smid), v5'length) sll 1);
    
    -- Output selection based on registered opcode
    if (opcode_reg(3 downto 0) /= "0000") then
      s_pred_no_clip_next <= std_logic_vector(v5);
    elsif (opcode_reg = "10000" or unsigned(config_predictor.P) = 0) then
      s_pred_no_clip_next(smid'high+1 downto 0) <= smid(smid'high downto 0)&'0';
      s_pred_no_clip_next(s_pred_no_clip_next'high downto smid'high+2) <= (others => '0');
    else
      s_pred_no_clip_next(s_z_prev'high+1 downto 0) <= s_z_prev_reg(s_z_prev'high downto 0)&'0';
      s_pred_no_clip_next(s_pred_no_clip_next'high downto s_z_prev'high+2) <= (others => s_z_prev_reg(s_z_prev'high));
    end if;
  end process;

end arch;