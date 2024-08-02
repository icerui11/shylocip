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

library IEEE;
use IEEE.std_logic_1164.all;
library grlib;
use grlib.amba.all;
use grlib.stdlib.all;

library shyloc_utils;
use shyloc_utils.amba.all;

library shyloc_123;
use shyloc_123.ccsds_ahb_types.all;

package ccsds_ahb_debug_func is
-- pragma translate_off
impure function ptime return string;
procedure print_access (ahbmi: in shyloc_utils.amba.ahb_mst_in_type; r, rin: in reg_type);
-- pragma translate_on
end package ccsds_ahb_debug_func;

package body ccsds_ahb_debug_func is
  -- pragma translate_off
  impure function ptime return string is
    variable s  : string(1 to 20);
    variable length : integer := tost(NOW / 1 ns)'length; 
  begin
    s(1 to length + 9) :="Time: " & tost(NOW / 1 ns) & "ns ";
    return s(1 to length + 9);
  end function ptime;
  
  
  procedure print_access (ahbmi: in shyloc_utils.amba.ahb_mst_in_type; r, rin: in reg_type) is 
  
  begin
    if r.read = '1' and ahbmi.hready = '1' then --and r.oldhtrans /= HTRANS_IDLE then
      if ahbmi.hresp = shyloc_utils.amba.HRESP_OKAY then
      if rin.status.err = '0' then
        if r.dbgl >= 2 then
        if r.use128 = 0 then print(ptime & "Read[" & tost(r.haddr) & "]: " & tost(ahbmi.hrdata(31 downto 0)));
        else 
          if r.hsize = "100" then print(ptime & "Read[" & tost(r.haddr) & "]: " & tost(ahbmi.hrdata)); 
          else print(ptime & "Read[" & tost(r.haddr) & "]: " & tost(ahbreaddword(ahbmi.hrdata))); end if;
        end if;
        end if;
      else
        if r.dbgl >= 1 then
        if r.use128 = 0 then print(ptime & "Read[" & tost(r.haddr) & "]: " & tost(ahbmi.hrdata(31 downto 0)) 
                       & " != " & tost(r.hdata));
        else 
          if r.hsize = "100" then print(ptime & "Read[" & tost(r.haddr) & "]: " & tost(ahbmi.hrdata) 
                        & " != " & tost(r.hdata128)); 
          else print(ptime & "Read[" & tost(r.haddr) & "]: " & tost(ahbreaddword(ahbmi.hrdata)) 
               & " != " & tost(r.hdata128(63 downto 0))); 
          end if;
        end if;
        end if;
      end if;
      elsif ahbmi.hresp = shyloc_utils.amba.HRESP_RETRY then
        if r.dbgl >= 3 then
        print(ptime & "Read[" & tost(r.haddr) & "]: [RETRY]");
        end if;
      elsif ahbmi.hresp = shyloc_utils.amba.HRESP_SPLIT then
        if r.dbgl >= 3 then
        print(ptime & "Read[" & tost(r.haddr) & "]: [SPLIT]");
        end if;
      elsif ahbmi.hresp = shyloc_utils.amba.HRESP_ERROR then
        if r.dbgl >= 1 then
        print(ptime & "Read[" & tost(r.haddr) & "]: [ERROR]");
        end if;
      end if;
    end if;
    if r.hwrite = '1' and ahbmi.hready = '1' and r.oldhtrans /= shyloc_utils.amba.HTRANS_IDLE then
      if ahbmi.hresp = shyloc_utils.amba.HRESP_OKAY then
      if r.dbgl >= 2 then
        if r.use128 = 0 then print(ptime & "Write[" & tost(r.haddr) & "]: " & tost(r.hdata));
        else 
        if r.hsize = "100" then print(ptime & "Write[" & tost(r.haddr) & "]: " & tost(r.hdata128)); 
        else print(ptime & "Write[" & tost(r.haddr) & "]: " & tost(r.hdata128(63 downto 0))); end if;
        end if;
      end if;
      elsif ahbmi.hresp = shyloc_utils.amba.HRESP_RETRY then
      if r.dbgl >= 3 then
        if r.use128 = 0 then print(ptime & "Write[" & tost(r.haddr) & "]: " & tost(r.hdata) & " [RETRY]");
        else 
        if r.hsize = "100" then print(ptime & "Write[" & tost(r.haddr) & "]: " & tost(r.hdata128) & " [RETRY]"); 
        else print(ptime & "Write[" & tost(r.haddr) & "]: " & tost(r.hdata128(63 downto 0)) & " [RETRY]"); end if; 
        end if;
      end if;
      elsif ahbmi.hresp = shyloc_utils.amba.HRESP_SPLIT then
      if r.dbgl >= 3 then
        print(ptime & "Write[" & tost(r.haddr) & "]: " & tost(r.hdata) 
          & " [SPLIT]");
      end if;
      elsif ahbmi.hresp = shyloc_utils.amba.HRESP_SPLIT then
      if r.dbgl >= 3 then
        print(ptime & "Write[" & tost(r.haddr) & "]: " & tost(r.hdata) 
          & " [SPLIT]");
      end if;
      elsif ahbmi.hresp = shyloc_utils.amba.HRESP_ERROR then
      if r.dbgl >= 1 then
        if r.use128 = 0 then print(ptime & "Write[" & tost(r.haddr) & "]: " & tost(r.hdata) & " [ERROR]");
        else 
        if r.hsize = "100" then print(ptime & "Write[" & tost(r.haddr) & "]: " & tost(r.hdata128) & " [ERROR]"); 
        else print(ptime & "Write[" & tost(r.haddr) & "]: " & tost(r.hdata128(63 downto 0)) & " [ERROR]"); end if; 
        end if;
      end if;
      end if;
    end if;
  end print_access;

--pragma translate_on
end package body;