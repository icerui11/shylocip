--============================================================================--
-- Design unit  : EDAC (package declarations)
--
-- File name    : edac.vhd
--
-- Purpose      : Error Detection and Correction encoders/decoders for various
--                word lengths. All codecs have separate parity calcualation for
--                check bit generation and error detection/correction. All
--                codes have a single correctable error indicator and (except the
--                63,57) a double correctable error indicator, and a multiple
--                uncorrectable error indicator. Only one of the codecs supports DEC.
--
--                Hamming EDAC codec, with SEC-DED     capability over 4 bit
--                Hamming EDAC codec, with SEC-DED     capability over 8 bit
--                Cyclic  EDAC codec, with DEC-EED     capability over 8 bit
--                Hamming EDAC codec, with SEC-DED     capability over 16 bit
--                Hamming EDAC codec, with SEC-DED-SBD capability over 16 bit
--                Hamming EDAC codec, with SEC-DED     capability over 24 bit
--                Hamming EDAC codec, with SEC-DED     capability over 32 bit
--                Hamming EDAC codec, with SEC-DED-SBD capability over 32 bit
--                Hamming EDAC codec, with SEC-DED     capability over 40 bit
--                Hamming EDAC codec, with SEC-DED     capability over 48 bit
--                Hamming EDAC codec, with SEC-DED     capability over 64 bit
--                Hamming EDAC codec, with SEC         capability over 57 bit
--
-- Note         : Leftmost bit, number 0, is the most significant.
--
--                DEC   Double Error Correction
--                DED   Double Error Detection
--                EED   Extended Error Detection
--                SBD   Single Bank-error Detection
--                SEC   Single Error Correction
--
-- Library      : EDAC_Lib {recommended}
--
-- Authors      : Sandi Habinc
--                European Space Agency (ESA)
--                P.O. Box 299
--                NL-2200 AG Noordwijk ZH
--                The Netherlands
--
--                M. S. Hodgart,  H. A. B. Tiggeler,
--                Surrey Satellite Technology Limited (SSTL)
--                Centre for Satellite Engineering Research
--                University of Surrey
--                Guildford
--                Surrey, United Kingdom
--                GU2 5XH
--
--                Mr Sandi Alexander Habinc
--                Gaisler Research
--                Stora Nygatan 13, SE-411 08 Göteborg, Sweden
--                sandi@gaisler.com, www.gaisler.com
--
-- Contact      : mailto: micro.electronics@estec.esa.int
--                http://www.estec.esa.int/microelectronics
--
-- Reference    : W. W. Petersen and E. J. Weldon, Error-correcting Codes,
--                MIT Press, Second Edition, 1972, pp 256-261
--
-- Reference    : T.A. Gulliver and V.K. Bhargava, A Systematic (16,8) Code for
--                Correcting Double Errors and Detecting Triple-Adjacent Errors,
--                IEEE Trans. Computers, Vol. 42, No. 1, pp. 109-112, 1993
--
-- Reference    : M. S. Hodgart,  H. A. B. Tiggeler, A (16,8) Error Correcting
--                Code (t=2) for Critical Memory Applications, Proceedings of
--                DASIA 2000 - DAta Systems In Aerospace, 2000
--
--                The cyclic 8 bit EDAC codec has been developed by SSTL, with
--                explicit permission given to ESA for its VHDL source code
--                distribution.
--
-- Reference    : R. Johansson, Two Error-Detecting and Correcting Circuits for
--                Space Applications, Proceedings of the 26:th Annual
--                International Symposium on Fault-Tolerant Computing, 1996
--                {used for the EDAC16Strong and EDAC32Strong codecs} 
--      
--
-- Reference    : Jason Hill, web-site with php scripts for error correcting codes
--                http://www.ai-studio.com/jason/mathematics/linear_codes.php
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
-- 0.1      SSTL     30 Dec 1999 Delivery to ESA of quasi-cyclic 8 bit codec
-- 0.2      ESA      15 Jun 2000 Modification by ESA to its own requirements
-- 0.3      ESA      10 Jul 2000 Separated encoder from decoder
-- 0.4      ESA       1 Dec 2000 Added 4/16/24/32/40/48/64 bit codecs
-- 0.5      SH       15 Mar 2002 64 bit decoder check bit generation corrected
-- 0.6      RW (ESA) 19 Aug 2005 Added (64,57) EDAC with single error correction
--                               Split package declaration and body into different files
-- 0.7      RW (ESA) 15 Jan 2015 No change - new version, changes in other files
--------------------------------------------------------------------------------

library IEEE;
use IEEE.Std_Logic_1164.all;
use ieee.std_logic_unsigned.all;

package EDAC is
   -----------------------------------------------------------------------------
   -- Generic data types, leftmost bit, number 0, is the most significant
   -----------------------------------------------------------------------------
   subtype Word4          is Std_Logic_Vector(0 to  3);
   subtype Word6          is Std_Logic_Vector(0 to  5);
   subtype Word8          is Std_Logic_Vector(0 to  7);
   subtype Word16         is Std_Logic_Vector(0 to 15);
   subtype Word24         is Std_Logic_Vector(0 to 23);
   subtype Word32         is Std_Logic_Vector(0 to 31);
   subtype Word40         is Std_Logic_Vector(0 to 39);
   subtype Word48         is Std_Logic_Vector(0 to 47);
   subtype Word57         is Std_Logic_Vector(0 to 56);
   subtype Word64         is Std_Logic_Vector(0 to 63);

   -----------------------------------------------------------------------------
   -- {for comments, see package body}
   -----------------------------------------------------------------------------
   procedure EDAC4Hamming(
      signal   DataOut:       in    Word4;               -- Output data bits
      signal   CheckOut:      out   Word4;               -- Output check bits

      signal   DataIn:        in    Word4;               -- Input data bits
      signal   CheckIn:       in    Word4;               -- Input check bits

      signal   DataCorr:      out   Word4;               -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic);         -- Uncorrectable error

   -----------------------------------------------------------------------------
   -- {for comments, see package body}
   -----------------------------------------------------------------------------
   procedure EDAC8Hamming(
      signal   DataOut:       in    Word8;               -- Output data bits
      signal   CheckOut:      out   Word8;               -- Output check bits

      signal   DataIn:        in    Word8;               -- Input data bits
      signal   CheckIn:       in    Word8;               -- Input check bits

      signal   DataCorr:      out   Word8;               -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic);         -- Uncorrectable error

   -----------------------------------------------------------------------------
   -- {for comments, see package body}
   -----------------------------------------------------------------------------
   procedure EDAC8Cyclic(
      signal   DataOut:       in    Word8;               -- Output data bits
      signal   CheckOut:      out   Word8;               -- Output check bits

      signal   DataIn:        in    Word8;               -- Input data bits
      signal   CheckIn:       in    Word8;               -- Input check bits

      signal   DataCorr:      out   Word8;               -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic);         -- Uncorrectable error

   -----------------------------------------------------------------------------
   -- {for comments, see package body}
   -----------------------------------------------------------------------------
   procedure EDAC16Hamming(
      signal   DataOut:       in    Word16;              -- Output data bits
      signal   CheckOut:      out   Word8;               -- Output check bits

      signal   DataIn:        in    Word16;              -- Input data bits
      signal   CheckIn:       in    Word8;               -- Input check bits

      signal   DataCorr:      out   Word16;              -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic);         -- Uncorrectable error

   -----------------------------------------------------------------------------
   -- {for comments, see package body}
   -----------------------------------------------------------------------------
   procedure EDAC16Strong(
      signal   DataOut:       in    Word16;              -- Output data bits
      signal   CheckOut:      out   Word8;               -- Output check bits

      signal   DataIn:        in    Word16;              -- Input data bits
      signal   CheckIn:       in    Word8;               -- Input check bits

      signal   DataCorr:      out   Word16;              -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic);         -- Uncorrectable error

   -----------------------------------------------------------------------------
   -- {for comments, see package body}
   -----------------------------------------------------------------------------
   procedure EDAC24Hamming(
      signal   DataOut:       in    Word24;              -- Output data bits
      signal   CheckOut:      out   Word8;               -- Output check bits

      signal   DataIn:        in    Word24;              -- Input data bits
      signal   CheckIn:       in    Word8;               -- Input check bits

      signal   DataCorr:      out   Word24;              -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic);         -- Uncorrectable error

   -----------------------------------------------------------------------------
   -- {for comments, see package body}
   -----------------------------------------------------------------------------
   procedure EDAC32Hamming(
      signal   DataOut:       in    Word32;              -- Output data bits
      signal   CheckOut:      out   Word8;               -- Output check bits

      signal   DataIn:        in    Word32;              -- Input data bits
      signal   CheckIn:       in    Word8;               -- Input check bits

      signal   DataCorr:      out   Word32;              -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic);         -- Uncorrectable error

   -----------------------------------------------------------------------------
   -- {for comments, see package body}
   -----------------------------------------------------------------------------
   procedure EDAC32Strong(
      signal   DataOut:       in    Word32;              -- Output data bits
      signal   CheckOut:      out   Word8;               -- Output check bits

      signal   DataIn:        in    Word32;              -- Input data bits
      signal   CheckIn:       in    Word8;               -- Input check bits

      signal   DataCorr:      out   Word32;              -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic);         -- Uncorrectable error

   -----------------------------------------------------------------------------
   -- {for comments, see package body}
   -----------------------------------------------------------------------------
   procedure EDAC40Hamming(
      signal   DataOut:       in    Word40;              -- Output data bits
      signal   CheckOut:      out   Word8;               -- Output check bits

      signal   DataIn:        in    Word40;              -- Input data bits
      signal   CheckIn:       in    Word8;               -- Input check bits

      signal   DataCorr:      out   Word40;              -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic);         -- Uncorrectable error

   -----------------------------------------------------------------------------
   -- {for comments, see package body}
   -----------------------------------------------------------------------------
   procedure EDAC48Hamming(
      signal   DataOut:       in    Word48;              -- Output data bits
      signal   CheckOut:      out   Word8;               -- Output check bits

      signal   DataIn:        in    Word48;              -- Input data bits
      signal   CheckIn:       in    Word8;               -- Input check bits

      signal   DataCorr:      out   Word48;              -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic);         -- Uncorrectable error

   -----------------------------------------------------------------------------
   -- {for comments, see package body}
   -----------------------------------------------------------------------------
   procedure EDAC64Hamming(
      signal   DataOut:       in    Word64;              -- Output data bits
      signal   CheckOut:      out   Word8;               -- Output check bits

      signal   DataIn:        in    Word64;              -- Input data bits
      signal   CheckIn:       in    Word8;               -- Input check bits

      signal   DataCorr:      out   Word64;              -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic);         -- Uncorrectable error

   procedure EDAC57 (
      signal   DataOut:       in    Word57;              -- Data bits to be encoded
      signal   CheckOut:      out   Word6;               -- Encoded check bits

      signal   DataIn:        in    Word57;              -- Data bits to be decoded
      signal   CheckIn:       in    Word6;               -- Check bits to be decoded

      signal   DataCorr:      out   Word57;              -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic           -- Single error flag
      );
end EDAC; --==================================================================--

