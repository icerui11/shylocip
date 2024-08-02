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
-- Design unit  : opcode_update
--
-- File name    : opcode_update.vhd
--
-- Purpose      : Operation code and coordinates generator
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
--============================================================================

--!@file #opcode_update.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  Operation code and coordinates generator
--!@details  This module gives the position of the current sample to be compressed in the spatial and spectral dimension. 
--! The spatial position is given by the signal t, where t=x+y*Nx, and the spectral position by coordinate z. 
--! The position is updated when the compression of a new sample starts, according to BSQ order. 
--!@details It outputs a code which indicates the relative position of a sample in the spatial dimension:
--!@details 00000 First sample of the image. z > 0 and y = 0 and x = 0
--!@details 10000 First sample of the image in the first band. z = 0 and y = 0 and x = 0
--!@details 00001 Sample is in the upper edge.
--!@details 10001 Sample is the last one of the first row.
--!@details 01010 Sample is in the left edge.
--!@details 00111 Sample is in the right edge.
--!@details 10111 Sample is the last one in the last row.
--!@details 11111 Sample is in the last row.
--!@details 01111 All other samples.

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

--! opcode_update entity Operation code and coordinates generator
--! This module gives the position of the current sample to be compressed in the spatial and spectral dimension. 
entity opcode_update is
  generic (RESET_TYPE     : integer := 1;     --! Asynchronous (0) or synchronous (1) reset
       Nx         : natural := 512;     --! Number of samples in the spatial dimension x.
       Ny         : natural := 512;   --! Number of samples in the spatial dimension y.
       Nz         : natural := 512;   --! Number of samples in the spatial dimension z.
       W_ADDR_IN_IMAGE  : natural := 16;    --! Bit width of the signal which stores the coordinates x and y.
       W_T: natural   := 32);         --! Bit width of signal t. 
  port(
    -- System Interface
    clk   : in std_logic;           --! Clock signal.
    rst_n : in std_logic;           --! Reset signal; active low.
    
    -- Configuration and Control Interface
    en        : in std_logic;       --! Enable signal.
    clear     : in std_logic;       --! Synchronous clear for all registers.
    config_image  : in config_123_image;    --! Configuration values selected by the user.
    
    -- Data Output Interface
    z     : out std_logic_vector (W_ADDR_IN_IMAGE - 1 downto 0);    --! Coordinate z. 
    t     : out std_logic_vector (W_T - 1 downto 0);          --! Coordinate t computed as t = x + y*Nx.
    opcode    : out std_logic_vector (4 downto 0)             --! Code indicating the relative position of a sample in the spatial dimension (registered).
  );
end opcode_update;

-----------------------------------------------------------------------------
--!@brief Architecture definition for bsq
-----------------------------------------------------------------------------
architecture bsq_arch of opcode_update is
  
  -- Signals to store next coordinates
  signal sig_x: unsigned (W_ADDR_IN_IMAGE - 1 downto 0);
  signal sig_y: unsigned (W_ADDR_IN_IMAGE - 1 downto 0);
  signal sig_z: unsigned (W_ADDR_IN_IMAGE - 1 downto 0);
  signal sig_t: unsigned (W_T - 1 downto 0);
  
begin

  ----------------------------------------
  -- Process to compute output coordinates
  ----------------------------------------
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      opcode <= (others => '0');
      sig_x <= (others => '0');
      sig_y <= (others => '0');
      sig_z <= (others => '0');
      sig_t <= (others => '0');
      t <= (others => '0');
      z <= (others => '0');
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        opcode <= (others => '0');
        sig_x <= (others => '0');
        sig_y <= (others => '0');
        sig_z <= (others => '0');
        sig_t <= (others => '0');
        t <= (others => '0');
        z <= (others => '0');
      else
        if (en = '1') then  
          if (sig_x = unsigned(config_image.Nx)-1) then
            sig_x <= (others => '0');
            if (sig_y = unsigned(config_image.Ny)-1) then
              sig_y <= (others => '0');
              sig_z <= sig_z + 1;
              sig_t <= (others => '0');
            else
              sig_y <= sig_y + 1;
              sig_t <= sig_t + 1;
            end if;
          else
            sig_x <= sig_x +1;
            sig_t <= sig_t + 1;
          end if;   
          -- generate opcode values   
          if (sig_y /= 0) then
            if (sig_x = 0) then
              if (sig_y = unsigned(config_image.Ny)-1) then
                -- sample is in the last row
                opcode <= "11010"; 
              else
                opcode <= "01010";
              end if;
            elsif (sig_x = unsigned(config_image.Nx)-1) then
              if (sig_y = unsigned(config_image.Ny)-1) then
                -- sample in the last row
                opcode <= "10111"; 
              else
                opcode <= "00111";
              end if;
            else
              if (sig_y = unsigned(config_image.Ny)-1) then
                -- last row
                opcode <= "11111"; 
              else
                opcode <= "01111";
              end if;
            end if;
          elsif (sig_x /= 0) then
            if (sig_x = unsigned(config_image.Nx)-1) then
              opcode <= "10001";
            else
              opcode <= "00001";
            end if;
          elsif (sig_z = 0) then
            opcode <= "10000";
          else
            opcode <= "00000";
          end if;
          z <= std_logic_vector(sig_z);
          t <= std_logic_vector(sig_t);
        end if;
      end if;
    end if;
  end process;

end bsq_arch;

-----------------------------------------------------------------------------
--!@brief Architecture definition for bip
-----------------------------------------------------------------------------
architecture bip_arch of opcode_update is
  
  -- Signals to store next coordinates
  signal sig_x: unsigned (W_ADDR_IN_IMAGE - 1 downto 0);
  signal sig_y: unsigned (W_ADDR_IN_IMAGE - 1 downto 0);
  signal sig_z: unsigned (W_ADDR_IN_IMAGE - 1 downto 0);
  signal sig_t: unsigned (W_T - 1 downto 0);
  
begin

  ----------------------------------------
  -- Process to compute output coordinates
  ----------------------------------------
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      opcode <= (others => '0');
      sig_x <= (others => '0');
      sig_y <= (others => '0');
      sig_z <= (others => '0');
      sig_t <= (others => '0');
      t <= (others => '0');
      z <= (others => '0');
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        opcode <= (others => '0');
        sig_x <= (others => '0');
        sig_y <= (others => '0');
        sig_z <= (others => '0');
        sig_t <= (others => '0');
        t <= (others => '0');
        z <= (others => '0');
      else
        if (en = '1') then
          -- iterate according to order
          if (sig_z = unsigned(config_image.Nz)-1) then
            sig_z <= (others => '0');
            sig_t <= sig_t + 1;
            sig_x <= sig_x + 1;
            if (sig_x = unsigned(config_image.Nx)-1) then
              sig_x <= (others => '0');
              sig_y <= sig_y + 1;
              if (sig_y = Ny-1) then 
                sig_t <= (others => '0');
                sig_y <= (others => '0');
              end if;
            end if;
          else
            sig_z <= sig_z + 1;
          end if;
          
          -- generate opcode values   
          if (sig_y /= 0) then
            if (sig_x = 0) then
              if (sig_y = unsigned(config_image.Ny)-1) then
                 -- sample is in the last row
                 opcode <= "11010";
              else
                opcode <= "01010";
              end if;
            elsif (sig_x = unsigned(config_image.Nx)-1) then
              if (sig_y = unsigned(config_image.Ny)-1) then
                -- sample in the last row
                opcode <= "10111"; 
              else
                opcode <= "00111";
              end if;
            else
              if (sig_y = unsigned(config_image.Ny)-1) then
                -- last row
                opcode <= "11111"; 
              else
                opcode <= "01111";
              end if;
            end if;
          elsif (sig_x /= 0) then
            if (sig_x = unsigned(config_image.Nx)-1) then
              opcode <= "10001";
            else
              opcode <= "00001";
            end if;
          elsif (sig_z = 0) then
            opcode <= "10000";
          else
            opcode <= "00000";
          end if;
          z <= std_logic_vector(sig_z);
          t <= std_logic_vector(sig_t);
        end if;
      end if;
    end if;
  end process;

end bip_arch;

-----------------------------------------------------------------------------
--!@brief Architecture definition for bil
-----------------------------------------------------------------------------
architecture bil_arch of opcode_update is
  
  -- Signals to store next coordinates
  signal sig_x: unsigned (W_ADDR_IN_IMAGE - 1 downto 0);
  signal sig_y: unsigned (W_ADDR_IN_IMAGE - 1 downto 0);
  signal sig_z: unsigned (W_ADDR_IN_IMAGE - 1 downto 0);
  signal sig_t: unsigned (W_T - 1 downto 0);
  
begin

  ----------------------------------------
  -- Process to compute output coordinates
  ----------------------------------------
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      opcode <= (others => '0');
      sig_x <= (others => '0');
      sig_y <= (others => '0');
      sig_z <= (others => '0');
      sig_t <= (others => '0');
      t <= (others => '0');
      z <= (others => '0');
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        opcode <= (others => '0');
        sig_x <= (others => '0');
        sig_y <= (others => '0');
        sig_z <= (others => '0');
        sig_t <= (others => '0');
        t <= (others => '0');
        z <= (others => '0');
      else
        if (en = '1') then
          -- iterate according to order
          if (sig_x = unsigned(config_image.Nx)-1) then
            sig_x <= (others => '0');
            sig_z <= sig_z + 1;
            if (sig_z = unsigned(config_image.Nz)-1) then
              sig_z <= (others => '0');
              sig_t <= sig_t+1;
              sig_y <= sig_y + 1;
              if (sig_y = unsigned(config_image.Ny)-1) then 
                sig_t <= (others => '0');
                sig_y <= (others => '0');
              end if;
            else
              sig_t <= sig_t - unsigned(config_image.Nx) + 1;
            end if;
          else
            sig_t <= sig_t + 1;
            sig_x <= sig_x + 1;
          end if;
          
          -- generate opcode values   
          if (sig_y /= 0) then
            if (sig_x = 0) then
              if (sig_y = unsigned(config_image.Ny)-1) then
                -- sample is in the last row
                opcode <= "11010"; 
              else
                opcode <= "01010";
              end if;
            elsif (sig_x = unsigned(config_image.Nx)-1) then
              if (sig_y = unsigned(config_image.Ny)-1) then
                -- sample in the last row
                opcode <= "10111"; 
              else
                opcode <= "00111";
              end if;
            else
              if (sig_y = unsigned(config_image.Ny)-1) then
                -- last row
                opcode <= "11111"; 
              else
                opcode <= "01111";
              end if;
            end if;
          elsif (sig_x /= 0) then
            if (sig_x = unsigned(config_image.Nx)-1) then
              opcode <= "10001";
            else
              opcode <= "00001";
            end if;
          elsif (sig_z = 0) then
            opcode <= "10000";
          else
            opcode <= "00000";
          end if;
          z <= std_logic_vector(sig_z);
          t <= std_logic_vector(sig_t);
        end if;
      end if;
    end if;
  end process;

end bil_arch;




