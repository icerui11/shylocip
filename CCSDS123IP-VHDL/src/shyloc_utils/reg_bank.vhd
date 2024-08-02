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
-- Design unit  : reg_bank wrapper module
--
-- File name    : reg_bank.vhd
--
-- Purpose      : Register bank wrapper to store intermediate data
--
-- Note         :
--
-- Library      : shyloc_utils
--
-- Author       : Lucana Santos
--
-- Instantiates : 
--============================================================================

--!@file #reg_bank.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  Register bank controlled by one clock signal + GENERIC to change technology

--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;

--! Use shyloc_utils
library shyloc_utils;

--! reg_bank entity. Register bank to store intermediate data
entity reg_bank is
  generic (RESET_TYPE: integer := 1;    --! Implement Asynchronous Reset (0) or Synchronous Reset (1)
       Cz: natural := 15;       --! Number of components of the vectors.
       W: natural := 16;        --! Bit width of the stored values.
       W_ADDRESS: natural := 32;    --! Bit width of the address signal.
       TECH: integer := 0);     --! Parameter used to change technology; (0) uses inferred memories.
       
           
  port (
    -- System Interface
    clk: in std_logic;                    --! Clock signal.
    rst_n: in std_logic;                  --! Reset signal. Active low. 
    -- Control and data Interface
    clear: in std_logic;                  --! Clear signal.
    data_in: in std_logic_vector (W - 1 downto 0);      --! Input data to be stored.
    data_out: out std_logic_vector (W -1 downto 0);     --! Output read data.
    read_addr: in std_logic_vector (W_ADDRESS-1 downto 0);  --! Read address.
    write_addr: in std_logic_vector (W_ADDRESS-1 downto 0); --! Write address.
    we: in std_logic;                   --! Write enable. Active high.
    re: in std_logic                    --! Read enable. Active high. 
    );
      
end reg_bank;

--! @brief Architecture of reg_bank 
architecture arch of reg_bank is
  type array_type is array (0 to Cz-1) of std_logic_vector (data_in'high downto 0);
  signal bank: array_type;
begin

  gen_inf_ram: if (TECH = 0) or (W_ADDRESS < 6) generate
    inf_ram: entity shyloc_utils.reg_bank_inf(arch)
      generic map(
        Cz => Cz,
        W =>  W,
        W_ADDRESS => W_ADDRESS,
        RESET_TYPE => RESET_TYPE)
      port map(
        clk       =>    clk,      
        rst_n   =>    rst_n,    
        clear   =>    clear,      
        data_in   =>    data_in,    
        data_out  =>    data_out,       
        read_addr =>    read_addr,            
        write_addr  =>    write_addr,     
        we      =>    we,     
        re      =>    re  );
  
  end generate gen_inf_ram;
  
        gen_tech_ram : if (TECH /= 0) and (W_ADDRESS >= 6) generate
          tech_ram : entity shyloc_utils.reg_bank_tech(struct)
            generic map(
              Cz         => Cz,
              W          => W,
              W_ADDRESS  => W_ADDRESS,
              RESET_TYPE => RESET_TYPE)
            port map(
              clk        => clk,
              rst_n      => rst_n,
              clear      => clear,
              data_in    => data_in,
              data_out   => data_out,
              read_addr  => read_addr,
              write_addr => write_addr,
              we         => we,
              re         => re);
        end generate gen_tech_ram;
  
end arch;




--============================================================================--
-- Design unit  : reg_bank_2clk module
--
-- File name    : reg_bank_2clk.vhd
--
-- Purpose      : Register bank to store intermediate data with different clocks for reading and writing
--
-- Note         :
--
-- Library      : shyloc_utils
--
-- Author       :
--                Institute for Applied Microelectronics (IUMA)
--                University of Las Palmas de Gran Canaria
--                Campus Universitario de Tafira s/n
--                35017, Las Palmas de Gran Canaria
--                Canary Islands, Spain
--
-- Contact      : lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--
-- Instantiates : 
--============================================================================

--!@file #reg_bank_2clk.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  Register bank to store intermediate data with different clocks for reading and writing

--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;

--! Use shyloc_utils
library shyloc_utils;

--! reg_bank_2clk entity. Register bank to store intermediate data
entity reg_bank_2clk is
  generic (Cz: natural := 15;       --! Number of components of the vectors.
       W: natural := 16;        --! Bit width of the stored values.
       W_ADDRESS: natural := 4;   --! Bit width of the address signal. 
       RESET_TYPE: integer := 0;    --! Implement Asynchronous Reset (0) or Synchronous Reset (1)
       TECH: integer := 0);     --! Parameter used to change technology; (0) uses inferred memories.
  port (
      clkw: in std_logic;                   --! Clock signal.
      rstw_n: in std_logic;                 --! Reset signal. Active low.
      data_in: in std_logic_vector (W - 1 downto 0);      --! Input data to be stored.
      write_addr: in std_logic_vector (W_ADDRESS-1 downto 0); --! Write address.
      we: in std_logic;                   --! Write enable. Active high
      clearw: in std_logic;                 --! Clear signal.
      
      clkr: in std_logic;                   --! Clock signal.
      rstr_n: in std_logic;                 --! Reset signal. Active low. 
      data_out: out std_logic_vector (W -1 downto 0);     --! Output read data.
      read_addr: in std_logic_vector (W_ADDRESS-1 downto 0);  --! Read address.
      clearr: in std_logic;                 --! Clear signal.
      re: in std_logic                    --! Read enable. Active low. 
      );
      
end reg_bank_2clk;

--! @brief Architecture of reg_bank_2clk considering reset signals
architecture arch of reg_bank_2clk is
begin
  gen_inf_ram_2clk: if (TECH = 0) or (W_ADDRESS < 6) generate
    inf_ram_2clk: entity shyloc_utils.reg_bank_2clk_inf(arch)
      generic map(
        Cz => Cz,
        W =>  W,
        W_ADDRESS => W_ADDRESS,
        RESET_TYPE => RESET_TYPE)
      port map(
        clkw    =>    clkw,     
        rstw_n    =>    rstw_n,   
        data_in   =>    data_in,      
        write_addr  =>    write_addr,   
        we      =>    we,       
        clearw    =>    clearw,           
        clkr    =>    clkr,     
        rstr_n    =>    rstr_n,     
        data_out  =>    data_out,   
        read_addr =>    read_addr,    
        clearr    =>    clearr,     
        re      =>    re  );
  
  end generate gen_inf_ram_2clk;
  
        gen_tech_ram_2clk : if (TECH /= 0) and (W_ADDRESS >= 6) generate
          tech_ram_2clk : entity shyloc_utils.reg_bank_2clk_tech(struct)
            generic map(
              Cz         => Cz,
              W          => W,
              W_ADDRESS  => W_ADDRESS,
              RESET_TYPE => RESET_TYPE)
            port map(
              clkw       => clkw,
              rstw_n     => rstw_n,
              data_in    => data_in,
              write_addr => write_addr,
              we         => we,
              clearw     => clearw,
              clkr       => clkr,
              rstr_n     => rstr_n,
              data_out   => data_out,
              read_addr  => read_addr,
              clearr     => clearr,
              re         => re);
        end generate gen_tech_ram_2clk;
  
end arch;
