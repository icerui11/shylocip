--============================================================================--
-- Design unit  : EDAC entity and architecture instantiating the various EDACs
--
-- File name    : edac-rtl.vhd
--
-- Purpose      : Allows quick synthesis check of EDAC procedures.
--
-- Note         : Leftmost bit no. 0 is the most significant.
--
-- Library      : EDAC_Lib {recommended}
--
-- Author       : Sandi Habinc
--                European Space Agency (ESA)
--                P.O. Box 299
--                NL-2200 AG Noordwijk ZH
--                The Netherlands
--
-- Contact      : mailto:micro.electronics@estec.esa.int
--                http://www.estec.esa.int/microelectronics
--
--============================================================================
-- 
--  Copyright European Space Agency
--  
--  This code is given under the terms of the
--  ESA Licence (Agreement) on Synthesisable HDL Models,
--  which you have signed prior to receiving the code.
--   
--  Any feedback (bugs, improvements etc.) shall be reported to ESA
--  at E-Mail IpCoreRequest@esa.int
--  
--  No technical support is available from ESA for this IP core,
--  however, any news on the IP will be posted on the web page:
--  http://www.estec.esa.int/microelectronics/core/corepage.html
-- 
--------------------------------------------------------------------------------
-- Version  Author   Date        Changes
-- 0.4      ESA       1 Dec 00   New model
-- 0.7      ESA (RW) 15 Jan 2015 Added EDAC57
--------------------------------------------------------------------------------
library IEEE;
use IEEE.Std_Logic_1164.all;

library Work;
use Work.EDAC.all;

entity EDAC_RTL is
   generic(
      EDACType:           Natural range 0 to 11 := 11);  -- EDAC type selection
   port(
      DataOut:       in   Word64;                        -- Output data bits
      CheckOut:      out  Word8;                         -- Output check bits
      DataIn:        in   Word64;                        -- Input data bits
      CheckIn:       in   Word8;                         -- Input check bits
      DataCorr:      out  Word64;                        -- Corrected data bits
      SingleErr:     out  Std_ULogic;                    -- Single error
      DoubleErr:     out  Std_ULogic;                    -- Double error
      MultipleErr:   out  Std_ULogic);                   -- Uncorrectable error
end EDAC_RTL;

--============================================================================--

architecture RTL of EDAC_RTL is
begin
   -----------------------------------------------------------------------------
   -- Select EDAC type
   -----------------------------------------------------------------------------
   EDAC0: if EDACType=0 generate
      EDAC4Hamming(
         DataOut     => DataOut(0 to 3),
         CheckOut    => CheckOut(0 to 3),
         DataIn      => DataIn(0 to 3),
         CheckIn     => CheckIn(0 to 3),
         DataCorr    => DataCorr(0 to 3),
         SingleErr   => SingleErr,
         DoubleErr   => DoubleErr,
         MultipleErr => MultipleErr);
         DataCorr(4 to 63) <= (others => '-');
         CheckOut(4 to 7)  <= (others => '-');
   end generate;

   EDAC1: if EDACType=1 generate
      EDAC8Hamming(
         DataOut     => DataOut(0 to 7),
         CheckOut    => CheckOut,
         DataIn      => DataIn(0 to 7),
         CheckIn     => CheckIn,
         DataCorr    => DataCorr(0 to 7),
         SingleErr   => SingleErr,
         DoubleErr   => DoubleErr,
         MultipleErr => MultipleErr);
         DataCorr(8 to 63) <= (others => '-');
   end generate;

   EDAC2: if EDACType=2 generate
      EDAC8Cyclic(
         DataOut     => DataOut(0 to 7),
         CheckOut    => CheckOut,
         DataIn      => DataIn(0 to 7),
         CheckIn     => CheckIn,
         DataCorr    => DataCorr(0 to 7),
         SingleErr   => SingleErr,
         DoubleErr   => DoubleErr,
         MultipleErr => MultipleErr);
         DataCorr(8 to 63) <= (others => '-');
   end generate;

   EDAC3: if EDACType=3 generate
      EDAC16Hamming(
         DataOut     => DataOut(0 to 15),
         CheckOut    => CheckOut,
         DataIn      => DataIn(0 to 15),
         CheckIn     => CheckIn,
         DataCorr    => DataCorr(0 to 15),
         SingleErr   => SingleErr,
         DoubleErr   => DoubleErr,
         MultipleErr => MultipleErr);
         DataCorr(16 to 63) <= (others => '-');
   end generate;

   EDAC4: if EDACType=4 generate
      EDAC16Strong(
         DataOut     => DataOut(0 to 15),
         CheckOut    => CheckOut,
         DataIn      => DataIn(0 to 15),
         CheckIn     => CheckIn,
         DataCorr    => DataCorr(0 to 15),
         SingleErr   => SingleErr,
         DoubleErr   => DoubleErr,
         MultipleErr => MultipleErr);
         DataCorr(16 to 63) <= (others => '-');
   end generate;

   EDAC5: if EDACType=5 generate
      EDAC24Hamming(
         DataOut     => DataOut(0 to 23),
         CheckOut    => CheckOut,
         DataIn      => DataIn(0 to 23),
         CheckIn     => CheckIn,
         DataCorr    => DataCorr(0 to 23),
         SingleErr   => SingleErr,
         DoubleErr   => DoubleErr,
         MultipleErr => MultipleErr);
         DataCorr(24 to 63) <= (others => '-');
   end generate;

   EDAC6: if EDACType=6 generate
      EDAC32Hamming(
         DataOut     => DataOut(0 to 31),
         CheckOut    => CheckOut,
         DataIn      => DataIn(0 to 31),
         CheckIn     => CheckIn,
         DataCorr    => DataCorr(0 to 31),
         SingleErr   => SingleErr,
         DoubleErr   => DoubleErr,
         MultipleErr => MultipleErr);
         DataCorr(32 to 63) <= (others => '-');
   end generate;

   EDAC7: if EDACType=7 generate
      EDAC32Strong(
         DataOut     => DataOut(0 to 31),
         CheckOut    => CheckOut,
         DataIn      => DataIn(0 to 31),
         CheckIn     => CheckIn,
         DataCorr    => DataCorr(0 to 31),
         SingleErr   => SingleErr,
         DoubleErr   => DoubleErr,
         MultipleErr => MultipleErr);
         DataCorr(32 to 63) <= (others => '-');
   end generate;

   EDAC8: if EDACType=8 generate
      EDAC40Hamming(
         DataOut     => DataOut(0 to 39),
         CheckOut    => CheckOut,
         DataIn      => DataIn(0 to 39),
         CheckIn     => CheckIn,
         DataCorr    => DataCorr(0 to 39),
         SingleErr   => SingleErr,
         DoubleErr   => DoubleErr,
         MultipleErr => MultipleErr);
         DataCorr(40 to 63) <= (others => '-');
   end generate;

   EDAC9: if EDACType=9 generate
      EDAC48Hamming(
         DataOut     => DataOut(0 to 47),
         CheckOut    => CheckOut,
         DataIn      => DataIn(0 to 47),
         CheckIn     => CheckIn,
         DataCorr    => DataCorr(0 to 47),
         SingleErr   => SingleErr,
         DoubleErr   => DoubleErr,
         MultipleErr => MultipleErr);
         DataCorr(48 to 63) <= (others => '-');
   end generate;

   EDAC10: if EDACType=10 generate
      EDAC64Hamming(
         DataOut     => DataOut(0 to 63),
         CheckOut    => CheckOut,
         DataIn      => DataIn(0 to 63),
         CheckIn     => CheckIn,
         DataCorr    => DataCorr(0 to 63),
         SingleErr   => SingleErr,
         DoubleErr   => DoubleErr,
         MultipleErr => MultipleErr);
   end generate;
   EDAC57i: if EDACType=11 generate
      EDAC57(
         DataOut     => DataOut(0 to 56),
         CheckOut    => CheckOut(0 to 5),
         DataIn      => DataIn(0 to 56),
         CheckIn     => CheckIn(0 to 5),
         DataCorr    => DataCorr(0 to 56),
         SingleErr   => SingleErr);
		 DataCorr(57 to 63) <= (others => '-');
         CheckOut(6 to 7)  <= (others => '-');
   end generate;
end RTL; --===================================================================--
