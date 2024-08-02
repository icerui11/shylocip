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
-- Design unit  : N-bits FlipFlop
--
-- File name    : ff.vhd
--
-- Purpose      : FlipFlop 
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
-- Instantiates : 
--============================================================================

library ieee;
use ieee.std_logic_1164.all;   

--!@file #ff.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email  lsfalcon@iuma.ulpgc.es
--!@brief  N-bits FlipFlop

entity ff is
  generic (N: integer := 1;       --! Bitwidth of the data to be registered
      RESET_TYPE : integer := 0);   --! Reset type: (0) asynchronous reset (1) synchronous reset.
  port (
    rst_n: in std_logic;            --! Reset (active low)
    clk: in std_logic;              --! Clock
    din: in std_logic_vector(N-1 downto 0);   --! Input data
    dout: out std_logic_vector(N-1 downto 0)  --! Output data
  );
end ff;

architecture arch of ff is
begin
  process(clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      dout <= (others => '0');
    elsif clk'event and clk = '1' then
      if (rst_n = '0' and RESET_TYPE= 1) then
        dout <= (others => '0');
      else
        dout <= din;
      end if;
    end if; 
  end process;
end arch; --============================================================================

--============================================================================--
-- Design unit  : 1-bit FlipFlop
--
-- File name    : ff1bit.vhd
--
-- Purpose      : 1-bit FlipFlop with synchronous clear
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
-- Instantiates : 
--============================================================================

library ieee;
use ieee.std_logic_1164.all;

--!@file #ff1bit.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email  lsfalcon@iuma.ulpgc.es
--!@brief  1-bit FlipFlop with synchronous clear

entity ff1bit is
  generic (RESET_TYPE : integer := 0);  --! Reset type: (0) asynchronous reset (1) synchronous reset.
  port (
    rst_n: in std_logic;        --! Reset (active low)
    clear: in std_logic;        --! Synchronus clear
    clk: in std_logic;          --! Clock
    din: in std_logic;          --! Input data
    dout: out std_logic         --! Output data
  );
end ff1bit;

architecture arch of ff1bit is
begin
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      dout <= '0';
    elsif clk'event and clk = '1' then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        dout <= '0';
      else
        dout <= din;
      end if;
    end if; 
  end process;
end arch; --============================================================================

--============================================================================--
-- Design unit  : Register with shift for N-bit data
--
-- File name    : shift_ff.vhd
--
-- Purpose      : Stores N-bit data and shifts every clock cycle 
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
-- Instantiates : 
--============================================================================

library ieee;
use ieee.std_logic_1164.all; 

--!@file #shift_ff.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email  lsfalcon@iuma.ulpgc.es
--!@brief  Stores N-bit data and shifts every clock cycle for N_STAGES.

entity shift_ff is
  generic (N: integer := 1;       --! Bit width of the data to be registered
       N_STAGES: integer := 3;    --! Number of shift stages
       RESET_TYPE: integer := 0);   --! Reset type: (0) asynchronous reset (1) synchronous reset.
  port (
    rst_n: in std_logic;            --! Reset (active low)
    clk: in std_logic;                          --! Synchronus clear
    clear: in std_logic;                        --! Clock
    din: in std_logic_vector(N-1 downto 0);     --! N-bits input data
    dout: out std_logic_vector(N-1 downto 0)    --! N-bits output data
  );
end shift_ff;

architecture arch of shift_ff is
  type array_type is array (0 to N_STAGES-1) of std_logic_vector(N-1 downto 0);
  signal ff: array_type;
begin
  dout <= ff(N_STAGES-1);
  
  process(clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      --dout <= (others => '0');
      ff <= (others => (others => '0'));
    elsif clk'event and clk = '1' then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        ff <= (others => (others => '0'));
      else
        ff(0) <= din;
        -- N_STAGES registers, the data moves every clock cycle.
        for i in 1 to N_STAGES-1 loop 
          ff(i) <= ff(i-1);
        end loop;
      end if;
    end if; 
  end process;
end arch; --============================================================================--

library ieee;
use ieee.std_logic_1164.all; 

--!@file #shift_ff1bit.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email  lsfalcon@iuma.ulpgc.es
--!@brief  Stores 1-bit data and shifts every clock cycle for N_STAGES.

entity shift_ff1bit is
  generic (N_STAGES: integer := 3;    --! Number of shift stages
       RESET_TYPE: integer := 0);   --! Reset type: (0) asynchronous reset (1) synchronous reset.
  port (
    rst_n: in std_logic;            --! Reset (active low)
    clk: in std_logic;                          --! Synchronus clear
    clear: in std_logic;                        --! Clock
    din: in std_logic;                --! 1-bit input data
    dout: out std_logic               --! 1-bit output data
  );
end shift_ff1bit;

architecture arch of shift_ff1bit is
  type array_type is array (0 to N_STAGES-1) of std_logic;
  signal ff: array_type;
begin
  dout <= ff(N_STAGES-1);
  
  process(clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      --dout <= (others => '0');
      ff <= (others => '0');
    elsif clk'event and clk = '1' then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        ff <= (others => '0');
      else
        ff(0) <= din;
        -- N_STAGES registers, the data moves every clock cycle.
        for i in 1 to N_STAGES-1 loop 
          ff(i) <= ff(i-1);
        end loop;
      end if;
    end if; 
  end process;
end arch; --============================================================================--

--============================================================================--
-- Design unit  : Register with shift for N-bit data with enable
--
-- File name    : shift_ff_en.vhd
--
-- Purpose      : Stores N-bit data and shifts every clock cycle  if 
--          enable is activated.
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
-- Instantiates : 
--============================================================================

library ieee;
use ieee.std_logic_1164.all;

--!@file #shift_ff_en.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email  lsfalcon@iuma.ulpgc.es
--!@brief  Stores N-bit data and shifts every clock cycle for N_STAGES. It shifts
--! if enable is activated.

entity shift_ff_en is
  generic (N: integer := 1;         --! Bit width of the data to be registered
       N_STAGES: integer := 3;            --! Number of shift stages
       RESET_TYPE: integer := 0);         --! Reset type: (0) asynchronous reset (1) synchronous reset.
  port (
    rst_n: in std_logic;            --! Reset (active low)
    clk: in std_logic;                        --! Clock
    en: in std_logic;                         --! Enable
    clear: in std_logic;                      --! Synchronous clear
    din: in std_logic_vector(N-1 downto 0);   --! N-bits input data
    dout: out std_logic_vector(N-1 downto 0)  --! N-bits output data
  );
end shift_ff_en;

architecture arch of shift_ff_en is
  type array_type is array (0 to N_STAGES-1) of std_logic_vector(N-1 downto 0);
  signal ff: array_type;
begin
  dout <= ff(N_STAGES-1);
  
  process(clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      --dout <= (others => '0');
      ff <= (others => (others => '0'));
    elsif clk'event and clk = '1' then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        ff <= (others => (others => '0'));
      else
        if en = '1' then
          ff(0) <= din;
        end if;
        for i in 1 to N_STAGES-1 loop
          ff(i) <= ff(i-1);
        end loop;
      end if; 
    end if; 
  end process;
end arch; --============================================================================

--============================================================================--
-- Design unit  : N-bits FlipFlop with enable
--
-- File name    : ff_en.vhd
--
-- Purpose      : FlipFlop 
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
-- Instantiates : 
--============================================================================

library ieee;
use ieee.std_logic_1164.all;   

--!@file #ff.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos and Antonio Sanchez
--!@email  lsfalcon@iuma.ulpgc.es, ajsanchez@iuma.ulpgc.es
--!@brief  N-bits FlipFlop with enable

entity ff_en is
  generic (N: integer := 1;        --! Bitwidth of the data to be registered
      RESET_TYPE : integer := 0);    --! Reset type: (0) asynchronous reset (1) synchronous reset.
  port (
    rst_n: in std_logic;            --! Reset (active low)
    clk: in std_logic;              --! Clock
    en: in std_logic;                         --! Enable
    clear: in std_logic;                      --! Synchronous clear
    din: in std_logic_vector(N-1 downto 0);    --! Input data
    dout: out std_logic_vector(N-1 downto 0)  --! Output data
  );
end ff_en;

architecture arch of ff_en is
begin
  process(clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      dout <= (others => '0');
    elsif clk'event and clk = '1' then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        dout <= (others => '0');
      else
        if en = '1' then
          dout <= din;
        end if;
      end if;
    end if;  
  end process;
end arch; --============================================================================