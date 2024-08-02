--============================================================================--
-- Design unit  : EDAC (package body)
--
-- File name    : edac-body.vhd
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
-- 0.7      RW (ESA) 15 Jan 2015 Bugfix in EDAC16Hamming (reported by D. Fiore TAS-I)
--                               Some improvements of coding style
--------------------------------------------------------------------------------

library IEEE;
use IEEE.Std_Logic_1164.all;
use ieee.std_logic_unsigned.all;


package body EDAC is
   -----------------------------------------------------------------------------
   -- This functional block provides the EDAC logic to correct up
   -- to one bit error and to detect up to two bit errors in an
   -- 4-bit input data word. The codewords are 8-bit long.
   -- It is a modified Hamming (8, 4, 4) code featuring
   -- Single Error Correction (SEC) and Double Error Detection (DED).
   --
   -- Two parity bits have been inversed to avoid an all-zero code word.
   -----------------------------------------------------------------------------
   procedure EDAC4Hamming(
      signal   DataOut:       in    Word4;               -- Output data bits
      signal   CheckOut:      out   Word4;               -- Output check bits

      signal   DataIn:        in    Word4;               -- Input data bits
      signal   CheckIn:       in    Word4;               -- Input check bits

      signal   DataCorr:      out   Word4;               -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic) is       -- Uncorrectable error

      variable PgenL:         Std_Logic_Vector(0 to 3);  -- Generated parity
      variable SyndL:         Std_Logic_Vector(0 to 3);  -- Syndrome
      variable FlipL:         Std_Logic_Vector(0 to 3);  -- Bits to invert
      variable ChipL:         Std_Logic_Vector(0 to 3);  -- Errors in parity
   begin
      -- Check bit generator
      PgenL(0) := not (DataIn(0) xor DataIn(1) xor DataIn(2));
      PgenL(1) :=      DataIn(0) xor DataIn(1) xor DataIn(3);
      PgenL(2) := not (DataIn(0) xor DataIn(2) xor DataIn(3));
      PgenL(3) :=      DataIn(1) xor DataIn(2) xor DataIn(3);

      -- Syndrome bit generator
      SyndL(0) := PgenL(0) xor not CheckIn(0);
      SyndL(1) := PgenL(1) xor not CheckIn(1);
      SyndL(2) := PgenL(2) xor     CheckIn(2);
      SyndL(3) := PgenL(3) xor     CheckIn(3);

      -- Bit corrector
      FlipL := (others => '0');
      if SyndL="1110" then
         FlipL(0) := '1';
      end if;
      if SyndL="1101" then
         FlipL(1) := '1';
      end if;
      if SyndL="1011" then
         FlipL(2) := '1';
      end if;
      if SyndL="0111" then
         FlipL(3) := '1';
      end if;

      -- Single error in check bits
      ChipL := (others => '0');
      if SyndL="0001" then
         ChipL(0) := '1';
      end if;
      if SyndL="0010" then
         ChipL(1) := '1';
      end if;
      if SyndL="0100" then
         ChipL(2) := '1';
      end if;
      if SyndL="1000" then
         ChipL(3) := '1';
      end if;

      -- Corrected data
      DataCorr(0) <= DataIn(0) xor FlipL(0);
      DataCorr(1) <= DataIn(1) xor FlipL(1);
      DataCorr(2) <= DataIn(2) xor FlipL(2);
      DataCorr(3) <= DataIn(3) xor FlipL(3);

      -- Check bits
      CheckOut(0) <= not (not (DataOut(0) xor DataOut(1) xor DataOut(2)));
      CheckOut(1) <= not (     DataOut(0) xor DataOut(1) xor DataOut(3));
      CheckOut(2) <=     (not (DataOut(0) xor DataOut(2) xor DataOut(3)));
      CheckOut(3) <=     (     DataOut(1) xor DataOut(2) xor DataOut(3));

      -- Single correctable error flag
      SingleErr   <= (FlipL(0) or FlipL(1) or FlipL(2) or FlipL(3)) xor
                     (ChipL(0) or ChipL(1) or ChipL(2) or ChipL(3));

      -- double correctable error flag
      DoubleErr   <= '0';

      -- Uncorrectable error flag
      if SyndL="0011" or SyndL="0101" or
         SyndL="0110" or SyndL="1001" or
         SyndL="1010" or SyndL="1100" or
         SyndL="1111" then
         MultipleErr    <= '1';
      else
         MultipleErr    <= '0';
      end if;
   end EDAC4Hamming;

   -----------------------------------------------------------------------------
   -- This functional block provides a cyclic EDAC coded to correct up to two
   -- bit errors in a code word. The codewords are 16 bit long, 8 bit data and
   -- 8 check bits. The codec has Double error Correction (DEC) capability.
   -- Two parity bits have been inversed to avoid an all-zero code word.
   -----------------------------------------------------------------------------
   procedure EDAC8Cyclic(
      signal   DataOut:       in    Word8;               -- Output data bits
      signal   CheckOut:      out   Word8;               -- Output check bits

      signal   DataIn:        in    Word8;               -- Input data bits
      signal   CheckIn:       in    Word8;               -- Input check bits

      signal   DataCorr:      out   Word8;               -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic) is       -- Uncorrectable error

      variable Parity:        Word8;                     -- parity
      variable Syndrome:      Word8;                     -- syndrome
      variable Correct:       Std_Logic_Vector(0 to 10); -- correction
   begin
      -- parity generation
      Parity(0)   := DataIn(7) xor DataIn(5) xor DataIn(2) xor DataIn(0);
      Parity(1)   := DataIn(6) xor DataIn(5) xor DataIn(4) xor
                     DataIn(2) xor DataIn(1) xor DataIn(0);
      Parity(2)   := DataIn(4) xor DataIn(3) xor DataIn(2) xor DataIn(1);
      Parity(3)   := DataIn(7) xor DataIn(3) xor DataIn(2) xor
                     DataIn(1) xor DataIn(0);
      Parity(4)   := DataIn(7) xor DataIn(6) xor DataIn(5) xor DataIn(1);
      Parity(5)   := DataIn(7) xor DataIn(6) xor DataIn(5) xor
                     DataIn(4) xor DataIn(0);
      Parity(6)   := DataIn(7) xor DataIn(6) xor DataIn(4) xor
                     DataIn(3) xor DataIn(2) xor DataIn(0);
      Parity(7)   := DataIn(6) xor DataIn(3) xor DataIn(1) xor DataIn(0);

      -- syndrome generation
      Syndrome(0) := Parity(0)  xor not CheckIn(0);
      Syndrome(1) := Parity(1)  xor not CheckIn(1);
      Syndrome(2) := Parity(2)  xor     CheckIn(2);
      Syndrome(3) := Parity(3)  xor     CheckIn(3);
      Syndrome(4) := Parity(4)  xor     CheckIn(4);
      Syndrome(5) := Parity(5)  xor     CheckIn(5);
      Syndrome(6) := Parity(6)  xor     CheckIn(6);
      Syndrome(7) := Parity(7)  xor     CheckIn(7);

      -- correction table (three rightmost bits carry error type information)
      case Syndrome is
         when "00000000" => Correct := "00000000000";    -- no error

         when "10011110" => Correct := "00000001001";    -- single data error
         when "01001111" => Correct := "00000010001";
         when "11001100" => Correct := "00000100001";
         when "01100110" => Correct := "00001000001";
         when "00110011" => Correct := "00010000001";
         when "11110010" => Correct := "00100000001";
         when "01111001" => Correct := "01000000001";
         when "11010111" => Correct := "10000000001";

         when "11010001" => Correct := "00000011010";    -- double data error
         when "01010010" => Correct := "00000101010";
         when "10000011" => Correct := "00000110010";
         when "11111000" => Correct := "00001001010";
         when "00101001" => Correct := "00001010010";
         when "10101010" => Correct := "00001100010";
         when "10101101" => Correct := "00010001010";
         when "01111100" => Correct := "00010010010";
         when "11111111" => Correct := "00010100010";
         when "01010101" => Correct := "00011000010";
         when "01101100" => Correct := "00100001010";
         when "10111101" => Correct := "00100010010";
         when "00111110" => Correct := "00100100010";
         when "10010100" => Correct := "00101000010";
         when "11000001" => Correct := "00110000010";
         when "11100111" => Correct := "01000001010";
         when "00110110" => Correct := "01000010010";
         when "10110101" => Correct := "01000100010";
         when "00011111" => Correct := "01001000010";
         when "01001010" => Correct := "01010000010";
         when "10001011" => Correct := "01100000010";
         when "01001001" => Correct := "10000001010";
         when "10011000" => Correct := "10000010010";
         when "00011011" => Correct := "10000100010";
         when "10110001" => Correct := "10001000010";
         when "11100100" => Correct := "10010000010";
         when "00100101" => Correct := "10100000010";
         when "10101110" => Correct := "11000000010";

         when "10011100" => Correct := "00000001100";    -- single data and
         when "10011010" => Correct := "00000001100";    -- single check error
         when "11011110" => Correct := "00000001100";
         when "10010110" => Correct := "00000001100";
         when "10001110" => Correct := "00000001100";
         when "00011110" => Correct := "00000001100";
         when "10111110" => Correct := "00000001100";
         when "10011111" => Correct := "00000001100";
         when "01001110" => Correct := "00000010100";
         when "01001101" => Correct := "00000010100";
         when "01001011" => Correct := "00000010100";
         when "01000111" => Correct := "00000010100";
         when "00001111" => Correct := "00000010100";
         when "11001111" => Correct := "00000010100";
         when "01101111" => Correct := "00000010100";
         when "01011111" => Correct := "00000010100";
         when "11001000" => Correct := "00000100100";
         when "11000100" => Correct := "00000100100";
         when "10001100" => Correct := "00000100100";
         when "01001100" => Correct := "00000100100";
         when "11101100" => Correct := "00000100100";
         when "11011100" => Correct := "00000100100";
         when "11001110" => Correct := "00000100100";
         when "11001101" => Correct := "00000100100";
         when "01100100" => Correct := "00001000100";
         when "01100010" => Correct := "00001000100";
         when "01000110" => Correct := "00001000100";
         when "00100110" => Correct := "00001000100";
         when "11100110" => Correct := "00001000100";
         when "01110110" => Correct := "00001000100";
         when "01101110" => Correct := "00001000100";
         when "01100111" => Correct := "00001000100";
         when "00110010" => Correct := "00010000100";
         when "00110001" => Correct := "00010000100";
         when "00100011" => Correct := "00010000100";
         when "00010011" => Correct := "00010000100";
         when "10110011" => Correct := "00010000100";
         when "01110011" => Correct := "00010000100";
         when "00111011" => Correct := "00010000100";
         when "00110111" => Correct := "00010000100";
         when "11110000" => Correct := "00100000100";
         when "11100010" => Correct := "00100000100";
         when "11010010" => Correct := "00100000100";
         when "10110010" => Correct := "00100000100";
         when "01110010" => Correct := "00100000100";
         when "11111010" => Correct := "00100000100";
         when "11110110" => Correct := "00100000100";
         when "11110011" => Correct := "00100000100";
         when "01111000" => Correct := "01000000100";
         when "01110001" => Correct := "01000000100";
         when "01101001" => Correct := "01000000100";
         when "01011001" => Correct := "01000000100";
         when "00111001" => Correct := "01000000100";
         when "11111001" => Correct := "01000000100";
         when "01111101" => Correct := "01000000100";
         when "01111011" => Correct := "01000000100";
         when "11010110" => Correct := "10000000100";
         when "11010101" => Correct := "10000000100";
         when "11010011" => Correct := "10000000100";
         when "11000111" => Correct := "10000000100";
         when "10010111" => Correct := "10000000100";
         when "01010111" => Correct := "10000000100";
         when "11110111" => Correct := "10000000100";
         when "11011111" => Correct := "10000000100";

         when "00000001" => Correct := "00000000101";    -- single check error
         when "00000010" => Correct := "00000000101";
         when "00000100" => Correct := "00000000101";
         when "00001000" => Correct := "00000000101";
         when "00010000" => Correct := "00000000101";
         when "00100000" => Correct := "00000000101";
         when "01000000" => Correct := "00000000101";
         when "10000000" => Correct := "00000000101";

         when "00000011" => Correct := "00000000110";    -- double check error
         when "00000101" => Correct := "00000000110";
         when "00000110" => Correct := "00000000110";
         when "00001001" => Correct := "00000000110";
         when "00001010" => Correct := "00000000110";
         when "00001100" => Correct := "00000000110";
         when "00010001" => Correct := "00000000110";
         when "00010010" => Correct := "00000000110";
         when "00010100" => Correct := "00000000110";
         when "00011000" => Correct := "00000000110";
         when "00100001" => Correct := "00000000110";
         when "00100010" => Correct := "00000000110";
         when "00100100" => Correct := "00000000110";
         when "00101000" => Correct := "00000000110";
         when "00110000" => Correct := "00000000110";
         when "01000001" => Correct := "00000000110";
         when "01000010" => Correct := "00000000110";
         when "01000100" => Correct := "00000000110";
         when "01001000" => Correct := "00000000110";
         when "01010000" => Correct := "00000000110";
         when "01100000" => Correct := "00000000110";
         when "10000001" => Correct := "00000000110";
         when "10000010" => Correct := "00000000110";
         when "10000100" => Correct := "00000000110";
         when "10001000" => Correct := "00000000110";
         when "10010000" => Correct := "00000000110";
         when "10100000" => Correct := "00000000110";
         when "11000000" => Correct := "00000000110";

         when others     => Correct := "00000000111";    -- uncorrectable error
      end case;

      -- output parity
      CheckOut(0) <= not (DataOut(7) xor DataOut(5) xor DataOut(2) xor
                          DataOut(0));
      CheckOut(1) <= not (DataOut(6) xor DataOut(5) xor DataOut(4) xor
                          DataOut(2) xor DataOut(1) xor DataOut(0));
      CheckOut(2) <= DataOut(4) xor DataOut(3) xor DataOut(2) xor DataOut(1);
      CheckOut(3) <= DataOut(7) xor DataOut(3) xor DataOut(2) xor
                     DataOut(1) xor DataOut(0);
      CheckOut(4) <= DataOut(7) xor DataOut(6) xor DataOut(5) xor DataOut(1);
      CheckOut(5) <= DataOut(7) xor DataOut(6) xor DataOut(5) xor
                     DataOut(4) xor DataOut(0);
      CheckOut(6) <= DataOut(7) xor DataOut(6) xor DataOut(4) xor
                     DataOut(3) xor DataOut(2) xor DataOut(0);
      CheckOut(7) <= DataOut(6) xor DataOut(3) xor DataOut(1) xor DataOut(0);

      -- corrected data output and flags
      DataCorr       <= DataIn xor Correct(0 to 7);      -- corrected data

      if Correct(8 to 10)="001" or                       -- single data error
         Correct(8 to 10)="101" then                     -- single check error
         SingleErr   <= '1';
      else
         SingleErr   <= '0';
      end if;

      if Correct(8 to 10)="010" or                       -- double data error
         Correct(8 to 10)="110" or                       -- dobule check error
         Correct(8 to 10)="100" then                     -- single data and
         DoubleErr   <= '1';                             -- single check error
      else
         DoubleErr   <= '0';
      end if;

      if Correct(8 to 10)="111" then                     -- uncorrectable error
         MultipleErr <= '1';
      else
         MultipleErr <= '0';
      end if;

   end EDAC8Cyclic;

   -----------------------------------------------------------------------------
   -- This functional block provides the EDAC logic to correct up
   -- to two bit errors and to detect up to four bit errors in an
   -- 8-bit input data word. The codewords are 16-bit long.
   -- The 8-bit input Word32 is split into two 4-bit data nibbles.
   -- To each 4-bit nibble it is applied a modified Hamming (8, 4, 4)
   -- coding featuring a Single Error Correction (SEC) and Double
   -- Error Detection (DED).
   --
   -- The first Hamming(8,4,4) encoder/decoder is applied to the low index
   -- order nibbles in the data/parity in/out 8-bit Word32s while the
   -- second is applied to the high index order nibbles.
   --
   -- Signal referring to the first encoder/decoder have an L suffix
   -- while the second uses names with an H suffix.
   --
   -- Four parity bits have been inversed to avoid an all-zero code word.
   --
   -- Double bit errors over the 8 + 8 bit codeword may be reported as
   -- double errors (= correctable) if they are in two different nibbles
   -- or as mulitple errors (= uncorrectable) if they are in the same nibble 
   -----------------------------------------------------------------------------
   procedure EDAC8Hamming(
      signal   DataOut:       in    Word8;               -- Output data bits
      signal   CheckOut:      out   Word8;               -- Output check bits

      signal   DataIn:        in    Word8;               -- Input data bits
      signal   CheckIn:       in    Word8;               -- Input check bits

      signal   DataCorr:      out   Word8;               -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic) is       -- Uncorrectable error

      variable PgenL,  PgenH: Std_Logic_Vector(0 to 3);  -- Generated parity
      variable SyndL,  SyndH: Std_Logic_Vector(0 to 3);  -- Syndrome
      variable FlipL,  FlipH: Std_Logic_Vector(0 to 3);  -- Bits to invert
      variable ChipL,  ChipH: Std_Logic_Vector(0 to 3);  -- Errors in parity
   begin
      -- Check bit generator
      PgenL(0) := not (DataIn(0) xor DataIn(1) xor DataIn(2));
      PgenL(1) :=      DataIn(0) xor DataIn(1) xor DataIn(3);
      PgenL(2) := not (DataIn(0) xor DataIn(2) xor DataIn(3));
      PgenL(3) :=      DataIn(1) xor DataIn(2) xor DataIn(3);

      PgenH(0) := not (DataIn(4) xor DataIn(5) xor DataIn(6));
      PgenH(1) :=      DataIn(4) xor DataIn(5) xor DataIn(7);
      PgenH(2) := not (DataIn(4) xor DataIn(6) xor DataIn(7));
      PgenH(3) :=      DataIn(5) xor DataIn(6) xor DataIn(7);

      -- Syndrome bit generator
      SyndL(0) := PgenL(0) xor not CheckIn(0);
      SyndL(1) := PgenL(1) xor not CheckIn(1);
      SyndL(2) := PgenL(2) xor     CheckIn(2);
      SyndL(3) := PgenL(3) xor     CheckIn(3);

      SyndH(0) := PgenH(0) xor not CheckIn(4);
      SyndH(1) := PgenH(1) xor not CheckIn(5);
      SyndH(2) := PgenH(2) xor     CheckIn(6);
      SyndH(3) := PgenH(3) xor     CheckIn(7);

      -- Bit corrector
      FlipL := (others => '0');
      if SyndL="1110" then
         FlipL(0) := '1';
      end if;
      if SyndL="1101" then
         FlipL(1) := '1';
      end if;
      if SyndL="1011" then
         FlipL(2) := '1';
      end if;
      if SyndL="0111" then
         FlipL(3) := '1';
      end if;

      FlipH := (others => '0');
      if SyndH="1110" then
         FlipH(0) := '1';
      end if;
      if SyndH="1101" then
         FlipH(1) := '1';
      end if;
      if SyndH="1011" then
         FlipH(2) := '1';
      end if;
      if SyndH="0111" then
         FlipH(3) := '1';
      end if;

      -- Single error in check bits
      ChipL := (others => '0');
      if SyndL="0001" then
         ChipL(0) := '1';
      end if;
      if SyndL="0010" then
         ChipL(1) := '1';
      end if;
      if SyndL="0100" then
         ChipL(2) := '1';
      end if;
      if SyndL="1000" then
         ChipL(3) := '1';
      end if;

      ChipH := (others => '0');
      if SyndH="0001" then
         ChipH(0) := '1';
      end if;
      if SyndH="0010" then
         ChipH(1) := '1';
      end if;
      if SyndH="0100" then
         ChipH(2) := '1';
      end if;
      if SyndH="1000" then
         ChipH(3) := '1';
      end if;

      -- Corrected data
      DataCorr(0) <= DataIn(0) xor FlipL(0);
      DataCorr(1) <= DataIn(1) xor FlipL(1);
      DataCorr(2) <= DataIn(2) xor FlipL(2);
      DataCorr(3) <= DataIn(3) xor FlipL(3);

      DataCorr(4) <= DataIn(4) xor FlipH(0);
      DataCorr(5) <= DataIn(5) xor FlipH(1);
      DataCorr(6) <= DataIn(6) xor FlipH(2);
      DataCorr(7) <= DataIn(7) xor FlipH(3);

      -- Check bits
      CheckOut(0) <= not (not (DataOut(0) xor DataOut(1) xor DataOut(2)));
      CheckOut(1) <= not (     DataOut(0) xor DataOut(1) xor DataOut(3));
      CheckOut(2) <=     (not (DataOut(0) xor DataOut(2) xor DataOut(3)));
      CheckOut(3) <=     (     DataOut(1) xor DataOut(2) xor DataOut(3));

      CheckOut(4) <= not (not (DataOut(4) xor DataOut(5) xor DataOut(6)));
      CheckOut(5) <= not (     DataOut(4) xor DataOut(5) xor DataOut(7));
      CheckOut(6) <=     (not (DataOut(4) xor DataOut(6) xor DataOut(7)));
      CheckOut(7) <=     (     DataOut(5) xor DataOut(6) xor DataOut(7));

      -- Single correctable error flag
      SingleErr   <= (FlipL(0) or FlipL(1) or FlipL(2) or FlipL(3)) xor
                     (FlipH(0) or FlipH(1) or FlipH(2) or FlipH(3)) xor
                     (ChipL(0) or ChipL(1) or ChipL(2) or ChipL(3)) xor
                     (ChipH(0) or ChipH(1) or ChipH(2) or ChipH(3));

      -- double correctable error flag
      DoubleErr   <= ((FlipL(0) or FlipL(1) or FlipL(2) or FlipL(3)) or
                      (ChipL(0) or ChipL(1) or ChipL(2) or ChipL(3))) and

                     ((FlipH(0) or FlipH(1) or FlipH(2) or FlipH(3)) or
                      (ChipH(0) or ChipH(1) or ChipH(2) or ChipH(3)));

      -- Uncorrectable error flag
      if SyndL="0011" or SyndL="0101" or
         SyndL="0110" or SyndL="1001" or
         SyndL="1010" or SyndL="1100" or
         SyndL="1111" or
         SyndH="0011" or SyndH="0101" or
         SyndH="0110" or SyndH="1001" or
         SyndH="1010" or SyndH="1100" or
         SyndH="1111" then
         MultipleErr    <= '1';
      else
         MultipleErr    <= '0';
      end if;
   end EDAC8Hamming;

   -----------------------------------------------------------------------------
   -- This functional block provides the EDAC logic to correct
   -- one bit error and to detect up to two bit errors in an
   -- 16-bit input data word. The codewords are 22-bit long.
   -- Check bit 6 and 7 are not used.
   --
   -- Two parity bits have been inversed to avoid an all-zero code word.
   -- 
   -- Generator Matrix: 
   --     D0  D1  D2  D3  D4  D5  D6  D7  D8  D9  D10 D11 D12 D13 D14 D15
   -- P0   1   1   0   1   1   0   0   0   1   1   1   0   0   1   0   0
   -- P1   1   0   1   1   0   1   1   0   1   0   0   1   0   0   1   0
   -- P2   0   1   1   0   1   1   0   1   0   1   0   0   1   0   0   1
   -- P3   1   1   1   0   0   0   1   1   0   0   1   1   1   0   0   0
   -- P4   0   0   0   1   1   1   1   1   0   0   0   0   0   1   1   1
   -- P5   0   0   0   0   0   0   0   0   1   1   1   1   1   1   1   1
   -----------------------------------------------------------------------------
   procedure EDAC16Hamming(
      signal   DataOut:       in    Word16;              -- Output data bits
      signal   CheckOut:      out   Word8;               -- Output check bits

      signal   DataIn:        in    Word16;              -- Input data bits
      signal   CheckIn:       in    Word8;               -- Input check bits

      signal   DataCorr:      out   Word16;              -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic) is       -- Uncorrectable error

      variable Parity:        Std_Logic_Vector(0 to 5);  -- Generated parity
      variable Syndrome:      Std_Logic_Vector(0 to 5);  -- Syndrome
   begin
      -- Check bit generator
      Parity(0)   := DataIn(0)  xor DataIn(1)  xor
                     DataIn(3)  xor DataIn(4)  xor
                     DataIn(8)  xor DataIn(9)  xor
                     DataIn(10) xor DataIn(13);

      Parity(1)   := DataIn(0)  xor DataIn(2)  xor
                     DataIn(3)  xor DataIn(5)  xor
                     DataIn(6)  xor DataIn(8)  xor
                     DataIn(11) xor DataIn(14);

      Parity(2)   := DataIn(1)  xor DataIn(2)  xor
                     DataIn(4)  xor DataIn(5)  xor
                     DataIn(7)  xor DataIn(9)  xor
                     DataIn(12) xor DataIn(15);

      Parity(3)   := DataIn(0)  xor DataIn(1)  xor
                     DataIn(2)  xor DataIn(6)  xor
                     DataIn(7)  xor DataIn(10) xor
                     DataIn(11) xor DataIn(12);

      Parity(4)   := DataIn(3)  xor DataIn(4)  xor
                     DataIn(5)  xor DataIn(6)  xor
                     DataIn(7)  xor DataIn(13) xor
                     DataIn(14) xor DataIn(15);

      Parity(5)   := DataIn(8)  xor DataIn(9)  xor
                     DataIn(10) xor DataIn(11) xor
                     DataIn(12) xor DataIn(13) xor
                     DataIn(14) xor DataIn(15);

      -- Syndrome bit generator
      Syndrome(0) := not Parity(0) xor CheckIn(0);
      Syndrome(1) := not Parity(1) xor CheckIn(1);
      Syndrome(2) :=     Parity(2) xor CheckIn(2);
      Syndrome(3) :=     Parity(3) xor CheckIn(3);
      Syndrome(4) :=     Parity(4) xor CheckIn(4);
      Syndrome(5) :=     Parity(5) xor CheckIn(5);

      -- Bit corrector
      DataCorr             <= DataIn;                    -- uncorrected default

      -- Default
      SingleErr      <= '0';                       -- single correctable
      DoubleErr      <= '0';                       -- double correctable
      MultipleErr    <= '0';                       -- uncorrectable error

      case Syndrome is                                   -- bit error correction
         when "001011" =>                                -- single data error
            DataCorr(15)    <= not DataIn(15);
            SingleErr      <= '1';                       -- single correctable
         when "010011" =>                                -- single data error
            DataCorr(14)    <= not DataIn(14);
            SingleErr      <= '1';                       -- single correctable
         when "100011" =>                                -- single data error
            DataCorr(13)    <= not DataIn(13);
            SingleErr      <= '1';                       -- single correctable
         when "001101" =>                                -- single data error
            DataCorr(12)    <= not DataIn(12);
            SingleErr      <= '1';                       -- single correctable
         when "010101" =>                                -- single data error
            DataCorr(11)    <= not DataIn(11);
            SingleErr      <= '1';                       -- single correctable
         when "100101" =>                                -- single data error
            DataCorr(10)    <= not DataIn(10);
            SingleErr      <= '1';                       -- single correctable
         when "101001" =>                                -- single data error
            DataCorr(9)    <= not DataIn(9);
            SingleErr      <= '1';                       -- single correctable
         when "110001" =>                                -- single data error
            DataCorr(8)    <= not DataIn(8);
            SingleErr      <= '1';                       -- single correctable
         when "001110" =>                                -- single data error
            DataCorr(7)    <= not DataIn(7);
            SingleErr      <= '1';                       -- single correctable
         when "010110" =>                                -- single data error
            DataCorr(6)    <= not DataIn(6);
            SingleErr      <= '1';                       -- single correctable
         when "011010" =>                                -- single data error
            DataCorr(5)   <= not DataIn(5);
            SingleErr      <= '1';                       -- single correctable
         when "101010" =>                                -- single data error
            DataCorr(4)   <= not DataIn(4);
            SingleErr      <= '1';                       -- single correctable
         when "110010" =>                                -- single data error
            DataCorr(3)   <= not DataIn(3);
            SingleErr      <= '1';                       -- single correctable
         when "011100" =>                                -- single data error
            DataCorr(2)   <= not DataIn(2);
            SingleErr      <= '1';                       -- single correctable
         when "101100" =>                                -- single data error
            DataCorr(1)   <= not DataIn(1);
            SingleErr      <= '1';                       -- single correctable
         when "110100" =>                                -- single data error
            DataCorr(0)   <= not DataIn(0);
            SingleErr      <= '1';                       -- single correctable

         when "100000" | "010000" | "001000" |
              "000100" | "000010" | "000001" =>          -- single parity error
            SingleErr      <= '1';                       -- single correctable

         when "000000" =>                                -- no errors

         when others   =>                                -- multiple errors
            MultipleErr    <= '1';                       -- uncorrectable error
      end case;

      -- Check bit generator output
      CheckOut(0) <= not  (DataOut(0)  xor DataOut(1)  xor
                           DataOut(3)  xor DataOut(4)  xor
                           DataOut(8)  xor DataOut(9)  xor
                           DataOut(10) xor DataOut(13));
      CheckOut(1) <= not  (DataOut(0)  xor DataOut(2)  xor
                           DataOut(3)  xor DataOut(5)  xor
                           DataOut(6)  xor DataOut(8)  xor
                           DataOut(11) xor DataOut(14));
      CheckOut(2) <=       DataOut(1)  xor DataOut(2)  xor
                           DataOut(4)  xor DataOut(5)  xor
                           DataOut(7)  xor DataOut(9)  xor
                           DataOut(12) xor DataOut(15);
      CheckOut(3) <=       DataOut(0)  xor DataOut(1)  xor
                           DataOut(2)  xor DataOut(6)  xor
                           DataOut(7)  xor DataOut(10) xor
                           DataOut(11) xor DataOut(12);
      CheckOut(4) <=       DataOut(3)  xor DataOut(4)  xor
                           DataOut(5)  xor DataOut(6)  xor
                           DataOut(7)  xor DataOut(13) xor
                           DataOut(14) xor DataOut(15);
      CheckOut(5) <=       DataOut(8)  xor DataOut(9)  xor
                           DataOut(10) xor DataOut(11) xor
                           DataOut(12) xor DataOut(13) xor
                           DataOut(14) xor DataOut(15);
      CheckOut(6 to 7) <=  "--";
   end EDAC16Hamming;


   -----------------------------------------------------------------------------
   -- This functional block provides the EDAC logic to correct
   -- one bit error and to detect up to 8 bit errors in an
   -- 16-bit input data word. The codewords are 24-bit long.
   --
   -- Three parity bits have been inversed to avoid an all-zero code word.
   -----------------------------------------------------------------------------
   procedure EDAC16Strong(
      signal   DataOut:       in    Word16;              -- Output data bits
      signal   CheckOut:      out   Word8;               -- Output check bits

      signal   DataIn:        in    Word16;              -- Input data bits
      signal   CheckIn:       in    Word8;               -- Input check bits

      signal   DataCorr:      out   Word16;              -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic) is       -- Uncorrectable error

      variable Parity:        Std_Logic_Vector(0 to 7);  -- Generated parity
      variable Syndrome:      Std_Logic_Vector(0 to 7);  -- Syndrome
   begin
      -- Check bit generator
      Parity(0)   :=      DataIn(0)  xor DataIn(4)  xor
                          DataIn(5)  xor DataIn(6)  xor
                          DataIn(7)  xor DataIn(8)  xor
                          DataIn(12) xor DataIn(13);
      Parity(1)   :=      DataIn(1)  xor DataIn(4)  xor
                          DataIn(6)  xor DataIn(8)  xor
                          DataIn(9)  xor DataIn(10) xor
                          DataIn(11) xor DataIn(14);
      Parity(2)   := not (DataIn(0)  xor DataIn(1)  xor
                          DataIn(2)  xor DataIn(3)  xor
                          DataIn(5)  xor DataIn(9)  xor
                          DataIn(12) xor DataIn(15));
      Parity(3)   := not (DataIn(0)  xor DataIn(1)  xor
                          DataIn(2)  xor DataIn(3)  xor
                          DataIn(4)  xor DataIn(10) xor
                          DataIn(13) xor DataIn(14));
      Parity(4)   :=      DataIn(2)  xor DataIn(5)  xor
                          DataIn(7)  xor DataIn(8)  xor
                          DataIn(9)  xor DataIn(10) xor
                          DataIn(11) xor DataIn(15);
      Parity(5)   :=      DataIn(3)  xor DataIn(6)  xor
                          DataIn(7)  xor DataIn(11) xor
                          DataIn(12) xor DataIn(13) xor
                          DataIn(14) xor DataIn(15);
      Parity(6)   :=      DataIn(1)  xor DataIn(2)  xor
                          DataIn(4)  xor DataIn(5)  xor
                          DataIn(7)  xor DataIn(8)  xor
                          DataIn(11) xor DataIn(13);
      Parity(7)   := not (DataIn(1)  xor DataIn(2)  xor
                          DataIn(3)  xor DataIn(5)  xor
                          DataIn(11) xor DataIn(12) xor
                          DataIn(13) xor DataIn(15));

      -- Syndrome bit generator
      Syndrome(0) :=      Parity(0) xor CheckIn(0);
      Syndrome(1) :=      Parity(1) xor CheckIn(1);
      Syndrome(2) :=      Parity(2) xor CheckIn(2);
      Syndrome(3) :=      Parity(3) xor CheckIn(3);
      Syndrome(4) :=      Parity(4) xor CheckIn(4);
      Syndrome(5) :=      Parity(5) xor CheckIn(5);
      Syndrome(6) :=      Parity(6) xor CheckIn(6);
      Syndrome(7) :=      Parity(7) xor CheckIn(7);

      -- Bit corrector
      DataCorr             <= DataIn;                    -- uncorrected default

      -- Default
      SingleErr      <= '0';                       -- single correctable
      DoubleErr      <= '0';                       -- double correctable
      MultipleErr    <= '0';                       -- uncorrectable error

      case Syndrome is                                   -- bit error correction
         when "10110000" =>                              -- single data error
            DataCorr(0)    <= not DataIn(0);
            SingleErr      <= '1';                       -- single correctable
         when "01110011" =>                              -- single data error
            DataCorr(1)    <= not DataIn(1);
            SingleErr      <= '1';                       -- single correctable
         when "00111011" =>                              -- single data error
            DataCorr(2)    <= not DataIn(2);
            SingleErr      <= '1';                       -- single correctable
         when "00110101" =>                              -- single data error
            DataCorr(3)    <= not DataIn(3);
            SingleErr      <= '1';                       -- single correctable
         when "11010010" =>                              -- single data error
            DataCorr(4)    <= not DataIn(4);
            SingleErr      <= '1';                       -- single correctable
         when "10101011" =>                              -- single data error
            DataCorr(5)    <= not DataIn(5);
            SingleErr      <= '1';                       -- single correctable
         when "11000100" =>                              -- single data error
            DataCorr(6)    <= not DataIn(6);
            SingleErr      <= '1';                       -- single correctable
         when "10001110" =>                              -- single data error
            DataCorr(7)    <= not DataIn(7);
            SingleErr      <= '1';                       -- single correctable
         when "11001010" =>                              -- single data error
            DataCorr(8)    <= not DataIn(8);
            SingleErr      <= '1';                       -- single correctable
         when "01101000" =>                              -- single data error
            DataCorr(9)    <= not DataIn(9);
            SingleErr      <= '1';                       -- single correctable
         when "01011000" =>                              -- single data error
            DataCorr(10)   <= not DataIn(10);
            SingleErr      <= '1';                       -- single correctable
         when "01001111" =>                              -- single data error
            DataCorr(11)   <= not DataIn(11);
            SingleErr      <= '1';                       -- single correctable
         when "10100101" =>                              -- single data error
            DataCorr(12)   <= not DataIn(12);
            SingleErr      <= '1';                       -- single correctable
         when "10010111" =>                              -- single data error
            DataCorr(13)   <= not DataIn(13);
            SingleErr      <= '1';                       -- single correctable
         when "01010100" =>                              -- single data error
            DataCorr(14)   <= not DataIn(14);
            SingleErr      <= '1';                       -- single correctable
         when "00101101" =>                              -- single data error
            DataCorr(15)   <= not DataIn(15);
            SingleErr      <= '1';                       -- single correctable

         when "10000000" | "01000000" | "00100000" |
              "00010000" | "00001000" | "00000100" |
              "00000010" | "00000001" =>                 -- single parity error
            SingleErr      <= '1';                       -- single correctable

         when "00000000" =>                              -- no errors

         when others   =>                                -- multiple errors
            MultipleErr    <= '1';                       -- uncorrectable error
      end case;

      -- Check bit generator output
      CheckOut(0) <=      DataOut(0)  xor DataOut(4)  xor
                          DataOut(5)  xor DataOut(6)  xor
                          DataOut(7)  xor DataOut(8)  xor
                          DataOut(12) xor DataOut(13);
      CheckOut(1) <=      DataOut(1)  xor DataOut(4)  xor
                          DataOut(6)  xor DataOut(8)  xor
                          DataOut(9)  xor DataOut(10) xor
                          DataOut(11) xor DataOut(14);
      CheckOut(2) <= not (DataOut(0)  xor DataOut(1)  xor
                          DataOut(2)  xor DataOut(3)  xor
                          DataOut(5)  xor DataOut(9)  xor
                          DataOut(12) xor DataOut(15));
      CheckOut(3) <= not (DataOut(0)  xor DataOut(1)  xor
                          DataOut(2)  xor DataOut(3)  xor
                          DataOut(4)  xor DataOut(10) xor
                          DataOut(13) xor DataOut(14));
      CheckOut(4) <=      DataOut(2)  xor DataOut(5)  xor
                          DataOut(7)  xor DataOut(8)  xor
                          DataOut(9)  xor DataOut(10) xor
                          DataOut(11) xor DataOut(15);
      CheckOut(5) <=      DataOut(3)  xor DataOut(6)  xor
                          DataOut(7)  xor DataOut(11) xor
                          DataOut(12) xor DataOut(13) xor
                          DataOut(14) xor DataOut(15);
      CheckOut(6) <=      DataOut(1)  xor DataOut(2)  xor
                          DataOut(4)  xor DataOut(5)  xor
                          DataOut(7)  xor DataOut(8)  xor
                          DataOut(11) xor DataOut(13);
      CheckOut(7) <= not (DataOut(1)  xor DataOut(2)  xor
                          DataOut(3)  xor DataOut(5)  xor
                          DataOut(11) xor DataOut(12) xor
                          DataOut(13) xor DataOut(15));
   end EDAC16Strong;

   -----------------------------------------------------------------------------
   -- This functional block provides the EDAC logic to correct
   -- one bit error and to detect up to two bit errors in an
   -- 24-bit input data word. The codewords are 31-bit long.
   -- Check bit 7 is not used.
   --
   -- Three parity bits have been inversed to avoid an all-zero code word.
   -----------------------------------------------------------------------------
   procedure EDAC24Hamming(
      signal   DataOut:       in    Word24;              -- Output data bits
      signal   CheckOut:      out   Word8;               -- Output check bits

      signal   DataIn:        in    Word24;              -- Input data bits
      signal   CheckIn:       in    Word8;               -- Input check bits

      signal   DataCorr:      out   Word24;              -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic) is       -- Uncorrectable error

      variable Parity:        Std_Logic_Vector(0 to 6);  -- Generated parity
      variable Syndrome:      Std_Logic_Vector(0 to 6);  -- Syndrome
   begin
      -- Check bit generator
      Parity(0) := not (DataIn(21) xor DataIn(19) xor DataIn(18) xor
                        DataIn(17) xor DataIn(14) xor DataIn(11) xor
                        DataIn(9)  xor DataIn(8)  xor DataIn(7)  xor
                        DataIn(6)  xor DataIn(4)  xor DataIn(0));
      Parity(1) := not (DataIn(22) xor DataIn(20) xor DataIn(18) xor
                        DataIn(17) xor DataIn(16) xor DataIn(12) xor
                        DataIn(10) xor DataIn(8)  xor DataIn(6)  xor
                        DataIn(4)  xor DataIn(1)  xor DataIn(0)  xor
                        DataIn(2));
      Parity(2) := not (DataIn(23) xor DataIn(20) xor DataIn(19) xor
                        DataIn(16) xor DataIn(15) xor DataIn(13) xor
                        DataIn(10) xor DataIn(9)  xor DataIn(7)  xor
                        DataIn(4)  xor DataIn(3)  xor DataIn(0));
      Parity(3) :=      DataIn(23) xor DataIn(22) xor DataIn(21) xor
                        DataIn(17) xor DataIn(16) xor DataIn(13) xor
                        DataIn(12) xor DataIn(11) xor DataIn(7)  xor
                        DataIn(6)  xor DataIn(5)  xor DataIn(1)  xor
                        DataIn(0);
      Parity(4) :=      DataIn(23) xor DataIn(22) xor DataIn(21) xor
                        DataIn(20) xor DataIn(19) xor DataIn(18) xor
                        DataIn(15) xor DataIn(14) xor DataIn(7)  xor
                        DataIn(6)  xor DataIn(5)  xor DataIn(4)  xor
                        DataIn(3)  xor DataIn(2);
      Parity(5) :=      DataIn(15) xor DataIn(14) xor DataIn(13) xor
                        DataIn(12) xor DataIn(11) xor DataIn(10) xor
                        DataIn(9)  xor DataIn(8);
      Parity(6) :=      DataIn(7)  xor DataIn(6)  xor DataIn(5)  xor
                        DataIn(4)  xor DataIn(3)  xor DataIn(2)  xor
                        DataIn(1)  xor DataIn(0);

      -- Syndrome bit generator
      Syndrome(0) :=    Parity(0) xor CheckIn(0);
      Syndrome(1) :=    Parity(1) xor CheckIn(1);
      Syndrome(2) :=    Parity(2) xor CheckIn(2);
      Syndrome(3) :=    Parity(3) xor CheckIn(3);
      Syndrome(4) :=    Parity(4) xor CheckIn(4);
      Syndrome(5) :=    Parity(5) xor CheckIn(5);
      Syndrome(6) :=    Parity(6) xor CheckIn(6);

      -- Bit corrector
      DataCorr             <= DataIn;                    -- uncorrected default

      -- Default
      SingleErr      <= '0';                       -- single correctable
      DoubleErr      <= '0';                       -- double correctable
      MultipleErr    <= '0';                       -- uncorrectable error

      case Syndrome is                                   -- bit error correction
         when "1111001" =>                               -- single data error
            DataCorr(0)    <= not DataIn(0);
            SingleErr      <= '1';                       -- single correctable
         when "0101001" =>                               -- single data error
            DataCorr(1)    <= not DataIn(1);
            SingleErr      <= '1';                       -- single correctable
         when "0100101" =>                               -- single data error
            DataCorr(2)    <= not DataIn(2);
            SingleErr      <= '1';                       -- single correctable
         when "0010101" =>                               -- single data error
            DataCorr(3)    <= not DataIn(3);
            SingleErr      <= '1';                       -- single correctable
         when "1110101" =>                               -- single data error
            DataCorr(4)    <= not DataIn(4);
            SingleErr      <= '1';                       -- single correctable
         when "0001101" =>                               -- single data error
            DataCorr(5)    <= not DataIn(5);
            SingleErr      <= '1';                       -- single correctable
         when "1101101" =>                               -- single data error
            DataCorr(6)    <= not DataIn(6);
            SingleErr      <= '1';                       -- single correctable
         when "1011101" =>                               -- single data error
            DataCorr(7)    <= not DataIn(7);
            SingleErr      <= '1';                       -- single correctable
         when "1100010" =>                               -- single data error
            DataCorr(8)    <= not DataIn(8);
            SingleErr      <= '1';                       -- single correctable
         when "1010010" =>                               -- single data error
            DataCorr(9)    <= not DataIn(9);
            SingleErr      <= '1';                       -- single correctable
         when "0110010" =>                               -- single data error
            DataCorr(10)   <= not DataIn(10);
            SingleErr      <= '1';                       -- single correctable
         when "1001010" =>                               -- single data error
            DataCorr(11)   <= not DataIn(11);
            SingleErr      <= '1';                       -- single correctable
         when "0101010" =>                               -- single data error
            DataCorr(12)   <= not DataIn(12);
            SingleErr      <= '1';                       -- single correctable
         when "0011010" =>                               -- single data error
            DataCorr(13)   <= not DataIn(13);
            SingleErr      <= '1';                       -- single correctable
         when "1000110" =>                               -- single data error
            DataCorr(14)   <= not DataIn(14);
            SingleErr      <= '1';                       -- single correctable
         when "0010110" =>                               -- single data error
            DataCorr(15)   <= not DataIn(15);
            SingleErr      <= '1';                       -- single correctable
         when "0111000" =>                               -- single data error
            DataCorr(16)   <= not DataIn(16);
            SingleErr      <= '1';                       -- single correctable
         when "1101000" =>                               -- single data error
            DataCorr(17)   <= not DataIn(17);
            SingleErr      <= '1';                       -- single correctable
         when "1100100" =>                               -- single data error
            DataCorr(18)   <= not DataIn(18);
            SingleErr      <= '1';                       -- single correctable
         when "1010100" =>                               -- single data error
            DataCorr(19)   <= not DataIn(19);
            SingleErr      <= '1';                       -- single correctable
         when "0110100" =>                               -- single data error
            DataCorr(20)   <= not DataIn(20);
            SingleErr      <= '1';                       -- single correctable
         when "1001100" =>                               -- single data error
            DataCorr(21)   <= not DataIn(21);
            SingleErr      <= '1';                       -- single correctable
         when "0101100" =>                               -- single data error
            DataCorr(22)   <= not DataIn(22);
            SingleErr      <= '1';                       -- single correctable
         when "0011100" =>                               -- single data error
            DataCorr(23)    <= not DataIn(23);
            SingleErr      <= '1';                       -- single correctable


         when "1000000" | "0100000" | "0010000" |
              "0001000" | "0000100" | "0000010" |
              "0000001"  =>                              -- single parity error
            SingleErr      <= '1';                       -- single correctable

         when "0000000" =>                               -- no errors

         when others   =>                                -- multiple errors
            MultipleErr    <= '1';                       -- uncorrectable error
      end case;

      -- Check bit generator output
      CheckOut(0) <= not (DataOut(21) xor DataOut(19) xor DataOut(18) xor
                          DataOut(17) xor DataOut(14) xor DataOut(11) xor
                          DataOut(9)  xor DataOut(8)  xor DataOut(7)  xor
                          DataOut(6)  xor DataOut(4)  xor DataOut(0));
      CheckOut(1) <= not (DataOut(22) xor DataOut(20) xor DataOut(18) xor
                          DataOut(17) xor DataOut(16) xor DataOut(12) xor
                          DataOut(10) xor DataOut(8)  xor DataOut(6)  xor
                          DataOut(4)  xor DataOut(1)  xor DataOut(0)  xor
                          DataOut(2));
      CheckOut(2) <= not (DataOut(23) xor DataOut(20) xor DataOut(19) xor
                          DataOut(16) xor DataOut(15) xor DataOut(13) xor
                          DataOut(10) xor DataOut(9)  xor DataOut(7)  xor
                          DataOut(4)  xor DataOut(3)  xor DataOut(0));
      CheckOut(3) <=      DataOut(23) xor DataOut(22) xor DataOut(21) xor
                          DataOut(17) xor DataOut(16) xor DataOut(13) xor
                          DataOut(12) xor DataOut(11) xor DataOut(7)  xor
                          DataOut(6)  xor DataOut(5)  xor DataOut(1)  xor
                          DataOut(0);
      CheckOut(4) <=      DataOut(23) xor DataOut(22) xor DataOut(21) xor
                          DataOut(20) xor DataOut(19) xor DataOut(18) xor
                          DataOut(15) xor DataOut(14) xor DataOut(7)  xor
                          DataOut(6)  xor DataOut(5)  xor DataOut(4)  xor
                          DataOut(3)  xor DataOut(2);
      CheckOut(5) <=      DataOut(15) xor DataOut(14) xor DataOut(13) xor
                          DataOut(12) xor DataOut(11) xor DataOut(10) xor
                          DataOut(9)  xor DataOut(8);
      CheckOut(6) <=      DataOut(7)  xor DataOut(6)  xor DataOut(5)  xor
                          DataOut(4)  xor DataOut(3)  xor DataOut(2)  xor
                          DataOut(1)  xor DataOut(0);
      CheckOut(7) <=      '-';
   end EDAC24Hamming;

   -----------------------------------------------------------------------------
   -- This functional block provides the EDAC logic to correct
   -- one bit error and to detect up to two bit errors in an
   -- 32-bit input data word. The codewords are 39-bit long.
   -- Check bit 7 is not used.
   --
   -- Two parity bits have been inversed to avoid an all-zero code word.
   -----------------------------------------------------------------------------
   procedure EDAC32Hamming(
      signal   DataOut:       in    Word32;              -- Output data bits
      signal   CheckOut:      out   Word8;               -- Output check bits

      signal   DataIn:        in    Word32;              -- Input data bits
      signal   CheckIn:       in    Word8;               -- Input check bits

      signal   DataCorr:      out   Word32;              -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic) is       -- Uncorrectable error

      variable Parity:        Std_Logic_Vector(0 to 6);  -- Generated parity
      variable Syndrome:      Std_Logic_Vector(0 to 6);
      -- Syndrome
   begin
      -- Check bit generator
      Parity(0) :=      DataIn(31) xor DataIn(30) xor DataIn(29) xor
                        DataIn(28) xor DataIn(24) xor DataIn(21) xor
                        DataIn(20) xor DataIn(19) xor DataIn(15) xor
                        DataIn(11) xor DataIn(10) xor DataIn(9)  xor
                        DataIn(8)  xor DataIn(5)  xor DataIn(4)  xor
                        DataIn(1);
      Parity(1) :=      DataIn(30) xor DataIn(28) xor DataIn(25) xor
                        DataIn(24) xor DataIn(20) xor DataIn(17) xor
                        DataIn(16) xor DataIn(15) xor DataIn(13) xor
                        DataIn(12) xor DataIn(9)  xor DataIn(8)  xor
                        DataIn(7)  xor DataIn(6)  xor DataIn(4)  xor
                        DataIn(3);
      Parity(2) := not (DataIn(31) xor DataIn(26) xor DataIn(22) xor
                        DataIn(19) xor DataIn(18) xor DataIn(16) xor
                        DataIn(15) xor DataIn(14) xor DataIn(10) xor
                        DataIn(8)  xor DataIn(6)  xor DataIn(5)  xor
                        DataIn(4)  xor DataIn(3)  xor DataIn(2)  xor
                        DataIn(1));
      Parity(3) := not (DataIn(31) xor DataIn(30) xor DataIn(27) xor
                        DataIn(23) xor DataIn(22) xor DataIn(19) xor
                        DataIn(15) xor DataIn(14) xor DataIn(13) xor
                        DataIn(12) xor DataIn(10) xor DataIn(9)  xor
                        DataIn(8)  xor DataIn(7)  xor DataIn(4)  xor
                        DataIn(0));
      Parity(4) :=      DataIn(30) xor DataIn(29) xor DataIn(27) xor
                        DataIn(26) xor DataIn(25) xor DataIn(24) xor
                        DataIn(21) xor DataIn(19) xor DataIn(17) xor
                        DataIn(12) xor DataIn(10) xor DataIn(9)  xor
                        DataIn(4)  xor DataIn(3)  xor DataIn(2)  xor
                        DataIn(0);
      Parity(5) :=      DataIn(31) xor DataIn(26) xor DataIn(25) xor
                        DataIn(23) xor DataIn(21) xor DataIn(20) xor
                        DataIn(18) xor DataIn(14) xor DataIn(13) xor
                        DataIn(11) xor DataIn(10) xor DataIn(9)  xor
                        DataIn(8)  xor DataIn(6)  xor DataIn(5)  xor
                        DataIn(0);
      Parity(6) :=      DataIn(31) xor DataIn(30) xor DataIn(29) xor
                        DataIn(28) xor DataIn(27) xor DataIn(23) xor
                        DataIn(22) xor DataIn(19) xor DataIn(18) xor
                        DataIn(17) xor DataIn(16) xor DataIn(15) xor
                        DataIn(11) xor DataIn(7)  xor DataIn(2)  xor
                        DataIn(1);

      -- Syndrome bit generator
      Syndrome(0) :=    Parity(0) xor CheckIn(0);
      Syndrome(1) :=    Parity(1) xor CheckIn(1);
      Syndrome(2) :=    Parity(2) xor CheckIn(2);
      Syndrome(3) :=    Parity(3) xor CheckIn(3);
      Syndrome(4) :=    Parity(4) xor CheckIn(4);
      Syndrome(5) :=    Parity(5) xor CheckIn(5);
      Syndrome(6) :=    Parity(6) xor CheckIn(6);

      -- Bit corrector
      DataCorr             <= DataIn;                    -- uncorrected default

      -- Default
      SingleErr      <= '0';                       -- single correctable
      DoubleErr      <= '0';                       -- double correctable
      MultipleErr    <= '0';                       -- uncorrectable error

      case Syndrome is                                   -- bit error correction
         when "0001110" =>                               -- single data error
            DataCorr(0)    <= not DataIn(0);
            SingleErr      <= '1';                       -- single correctable
         when "1010001" =>                               -- single data error
            DataCorr(1)    <= not DataIn(1);
            SingleErr      <= '1';                       -- single correctable
         when "0010101" =>                               -- single data error
            DataCorr(2)    <= not DataIn(2);
            SingleErr      <= '1';                       -- single correctable
         when "0110100" =>                               -- single data error
            DataCorr(3)    <= not DataIn(3);
            SingleErr      <= '1';                       -- single correctable
         when "1111100" =>                               -- single data error
            DataCorr(4)    <= not DataIn(4);
            SingleErr      <= '1';                       -- single correctable
         when "1010010" =>                               -- single data error
            DataCorr(5)    <= not DataIn(5);
            SingleErr      <= '1';                       -- single correctable
         when "0110010" =>                               -- single data error
            DataCorr(6)    <= not DataIn(6);
            SingleErr      <= '1';                       -- single correctable
         when "0101001" =>                               -- single data error
            DataCorr(7)    <= not DataIn(7);
            SingleErr      <= '1';                       -- single correctable
         when "1111010" =>                               -- single data error
            DataCorr(8)    <= not DataIn(8);
            SingleErr      <= '1';                       -- single correctable
         when "1101110" =>                               -- single data error
            DataCorr(9)    <= not DataIn(9);
            SingleErr      <= '1';                       -- single correctable
         when "1011110" =>                               -- single data error
            DataCorr(10)   <= not DataIn(10);
            SingleErr      <= '1';                       -- single correctable
         when "1000011" =>                               -- single data error
            DataCorr(11)   <= not DataIn(11);
            SingleErr      <= '1';                       -- single correctable
         when "0101100" =>                               -- single data error
            DataCorr(12)   <= not DataIn(12);
            SingleErr      <= '1';                       -- single correctable
         when "0101010" =>                               -- single data error
            DataCorr(13)   <= not DataIn(13);
            SingleErr      <= '1';                       -- single correctable
         when "0011010" =>                               -- single data error
            DataCorr(14)   <= not DataIn(14);
            SingleErr      <= '1';                       -- single correctable
         when "1111001" =>                               -- single data error
            DataCorr(15)   <= not DataIn(15);
            SingleErr      <= '1';                       -- single correctable
         when "0110001" =>                               -- single data error
            DataCorr(16)   <= not DataIn(16);
            SingleErr      <= '1';                       -- single correctable
         when "0100101" =>                               -- single data error
            DataCorr(17)   <= not DataIn(17);
            SingleErr      <= '1';                       -- single correctable
         when "0010011" =>                               -- single data error
            DataCorr(18)   <= not DataIn(18);
            SingleErr      <= '1';                       -- single correctable
         when "1011101" =>                               -- single data error
            DataCorr(19)   <= not DataIn(19);
            SingleErr      <= '1';                       -- single correctable
         when "1100010" =>                               -- single data error
            DataCorr(20)   <= not DataIn(20);
            SingleErr      <= '1';                       -- single correctable
         when "1000110" =>                               -- single data error
            DataCorr(21)   <= not DataIn(21);
            SingleErr      <= '1';                       -- single correctable
         when "0011001" =>                               -- single data error
            DataCorr(22)   <= not DataIn(22);
            SingleErr      <= '1';                       -- single correctable
         when "0001011" =>                               -- single data error
            DataCorr(23)    <= not DataIn(23);
            SingleErr      <= '1';                       -- single correctable
         when "1100100" =>                               -- single data error
            DataCorr(24)    <= not DataIn(24);
            SingleErr      <= '1';                       -- single correctable
         when "0100110" =>                               -- single data error
            DataCorr(25)   <= not DataIn(25);
            SingleErr      <= '1';                       -- single correctable
         when "0010110" =>                               -- single data error
            DataCorr(26)   <= not DataIn(26);
            SingleErr      <= '1';                       -- single correctable
         when "0001101" =>                               -- single data error
            DataCorr(27)   <= not DataIn(27);
            SingleErr      <= '1';                       -- single correctable
         when "1100001" =>                               -- single data error
            DataCorr(28)   <= not DataIn(28);
            SingleErr      <= '1';                       -- single correctable
         when "1000101" =>                               -- single data error
            DataCorr(29)   <= not DataIn(29);
            SingleErr      <= '1';                       -- single correctable
         when "1101101" =>                               -- single data error
            DataCorr(30)   <= not DataIn(30);
            SingleErr      <= '1';                       -- single correctable
         when "1011011" =>                               -- single data error
            DataCorr(31)   <= not DataIn(31);
            SingleErr      <= '1';                       -- single correctable

         when "1000000" | "0100000" | "0010000" |
              "0001000" | "0000100" | "0000010" |
              "0000001" =>                               -- single parity error
            SingleErr      <= '1';                       -- single correctable

         when "0000000" =>                               -- no errors

         when others   =>                                -- multiple errors
            MultipleErr    <= '1';                       -- uncorrectable error
      end case;

      -- Check bit generator output
      CheckOut(0) <=      DataOut(31) xor DataOut(30) xor DataOut(29) xor
                          DataOut(28) xor DataOut(24) xor DataOut(21) xor
                          DataOut(20) xor DataOut(19) xor DataOut(15) xor
                          DataOut(11) xor DataOut(10) xor DataOut(9)  xor
                          DataOut(8)  xor DataOut(5)  xor DataOut(4)  xor
                          DataOut(1);
      CheckOut(1) <=      DataOut(30) xor DataOut(28) xor DataOut(25) xor
                          DataOut(24) xor DataOut(20) xor DataOut(17) xor
                          DataOut(16) xor DataOut(15) xor DataOut(13) xor
                          DataOut(12) xor DataOut(9)  xor DataOut(8)  xor
                          DataOut(7)  xor DataOut(6)  xor DataOut(4)  xor
                          DataOut(3);
      CheckOut(2) <= not (DataOut(31) xor DataOut(26) xor DataOut(22) xor
                          DataOut(19) xor DataOut(18) xor DataOut(16) xor
                          DataOut(15) xor DataOut(14) xor DataOut(10) xor
                          DataOut(8)  xor DataOut(6)  xor DataOut(5)  xor
                          DataOut(4)  xor DataOut(3)  xor DataOut(2)  xor
                          DataOut(1));
      CheckOut(3) <= not (DataOut(31) xor DataOut(30) xor DataOut(27) xor
                          DataOut(23) xor DataOut(22) xor DataOut(19) xor
                          DataOut(15) xor DataOut(14) xor DataOut(13) xor
                          DataOut(12) xor DataOut(10) xor DataOut(9)  xor
                          DataOut(8)  xor DataOut(7)  xor DataOut(4)  xor
                          DataOut(0));
      CheckOut(4) <=      DataOut(30) xor DataOut(29) xor DataOut(27) xor
                          DataOut(26) xor DataOut(25) xor DataOut(24) xor
                          DataOut(21) xor DataOut(19) xor DataOut(17) xor
                          DataOut(12) xor DataOut(10) xor DataOut(9)  xor
                          DataOut(4)  xor DataOut(3)  xor DataOut(2)  xor
                          DataOut(0);
      CheckOut(5) <=      DataOut(31) xor DataOut(26) xor DataOut(25) xor
                          DataOut(23) xor DataOut(21) xor DataOut(20) xor
                          DataOut(18) xor DataOut(14) xor DataOut(13) xor
                          DataOut(11) xor DataOut(10) xor DataOut(9)  xor
                          DataOut(8)  xor DataOut(6)  xor DataOut(5)  xor
                          DataOut(0);
      CheckOut(6) <=      DataOut(31) xor DataOut(30) xor DataOut(29) xor
                          DataOut(28) xor DataOut(27) xor DataOut(23) xor
                          DataOut(22) xor DataOut(19) xor DataOut(18) xor
                          DataOut(17) xor DataOut(16) xor DataOut(15) xor
                          DataOut(11) xor DataOut(7)  xor DataOut(2)  xor
                          DataOut(1);
      CheckOut(7) <=      '-';
   end EDAC32Hamming;

   -----------------------------------------------------------------------------
   -- This functional block provides the EDAC logic to correct
   -- one bit error and to detect up to eight bit errors in an
   -- 32-bit input data word. The codewords are 40-bit long.
   --
   -- Three parity bits have been inversed to avoid an all-zero code word.
   -----------------------------------------------------------------------------
   procedure EDAC32Strong(
      signal   DataOut:       in    Word32;              -- Output data bits
      signal   CheckOut:      out   Word8;               -- Output check bits

      signal   DataIn:        in    Word32;              -- Input data bits
      signal   CheckIn:       in    Word8;               -- Input check bits

      signal   DataCorr:      out   Word32;              -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic) is       -- Uncorrectable error

      variable Parity:              Word8;               -- Generated parity
      variable Syndrome:            Word8;               -- Syndrome
   begin
      -- Check bit generator
      Parity(0) :=      DataIn(31) xor DataIn(30) xor DataIn(29) xor
                        DataIn(28) xor DataIn(24) xor DataIn(21) xor
                        DataIn(20) xor DataIn(19) xor DataIn(15) xor
                        DataIn(11) xor DataIn(10) xor DataIn(9)  xor
                        DataIn(8)  xor DataIn(5)  xor DataIn(4)  xor
                        DataIn(1);
      Parity(1) :=      DataIn(30) xor DataIn(28) xor DataIn(25) xor
                        DataIn(24) xor DataIn(20) xor DataIn(17) xor
                        DataIn(16) xor DataIn(15) xor DataIn(13) xor
                        DataIn(12) xor DataIn(9)  xor DataIn(8)  xor
                        DataIn(7)  xor DataIn(6)  xor DataIn(4)  xor
                        DataIn(3);
      Parity(2) := not (DataIn(31) xor DataIn(26) xor DataIn(22) xor
                        DataIn(19) xor DataIn(18) xor DataIn(16) xor
                        DataIn(15) xor DataIn(14) xor DataIn(10) xor
                        DataIn(8)  xor DataIn(6)  xor DataIn(5)  xor
                        DataIn(4)  xor DataIn(3)  xor DataIn(2)  xor
                        DataIn(1));
      Parity(3) := not (DataIn(31) xor DataIn(30) xor DataIn(27) xor
                        DataIn(23) xor DataIn(22) xor DataIn(19) xor
                        DataIn(15) xor DataIn(14) xor DataIn(13) xor
                        DataIn(12) xor DataIn(10) xor DataIn(9)  xor
                        DataIn(8)  xor DataIn(7)  xor DataIn(4)  xor
                        DataIn(0));
      Parity(4) :=      DataIn(30) xor DataIn(29) xor DataIn(27) xor
                        DataIn(26) xor DataIn(25) xor DataIn(24) xor
                        DataIn(21) xor DataIn(19) xor DataIn(17) xor
                        DataIn(12) xor DataIn(10) xor DataIn(9)  xor
                        DataIn(4)  xor DataIn(3)  xor DataIn(2)  xor
                        DataIn(0);
      Parity(5) :=      DataIn(31) xor DataIn(26) xor DataIn(25) xor
                        DataIn(23) xor DataIn(21) xor DataIn(20) xor
                        DataIn(18) xor DataIn(14) xor DataIn(13) xor
                        DataIn(11) xor DataIn(10) xor DataIn(9)  xor
                        DataIn(8)  xor DataIn(6)  xor DataIn(5)  xor
                        DataIn(0);
      Parity(6) :=      DataIn(31) xor DataIn(30) xor DataIn(29) xor
                        DataIn(28) xor DataIn(27) xor DataIn(23) xor
                        DataIn(22) xor DataIn(19) xor DataIn(18) xor
                        DataIn(17) xor DataIn(16) xor DataIn(15) xor
                        DataIn(11) xor DataIn(7)  xor DataIn(2)  xor
                        DataIn(1);
      Parity(7) := not (DataIn(27) xor DataIn(26) xor DataIn(25) xor
                        DataIn(24) xor DataIn(22) xor DataIn(21) xor
                        DataIn(17) xor DataIn(16) xor DataIn(14) xor
                        DataIn(12) xor DataIn(11) xor DataIn(7)  xor
                        DataIn(6)  xor DataIn(2)  xor DataIn(1)  xor
                        DataIn(0));

      -- Syndrome bit generator
      Syndrome(0) :=    Parity(0) xor CheckIn(0);
      Syndrome(1) :=    Parity(1) xor CheckIn(1);
      Syndrome(2) :=    Parity(2) xor CheckIn(2);
      Syndrome(3) :=    Parity(3) xor CheckIn(3);
      Syndrome(4) :=    Parity(4) xor CheckIn(4);
      Syndrome(5) :=    Parity(5) xor CheckIn(5);
      Syndrome(6) :=    Parity(6) xor CheckIn(6);
      Syndrome(7) :=    Parity(7) xor CheckIn(7);

      -- Bit corrector
      DataCorr             <= DataIn;                    -- uncorrected default

      -- Default
      SingleErr      <= '0';                       -- single correctable
      DoubleErr      <= '0';                       -- double correctable
      MultipleErr    <= '0';                       -- uncorrectable error

      case Syndrome is                                   -- bit error correction
         when "00011101" =>                              -- single data error
            DataCorr(0)    <= not DataIn(0);
            SingleErr      <= '1';                       -- single correctable
         when "10100011" =>                              -- single data error
            DataCorr(1)    <= not DataIn(1);
            SingleErr      <= '1';                       -- single correctable
         when "00101011" =>                              -- single data error
            DataCorr(2)    <= not DataIn(2);
            SingleErr      <= '1';                       -- single correctable
         when "01101000" =>                              -- single data error
            DataCorr(3)    <= not DataIn(3);
            SingleErr      <= '1';                       -- single correctable
         when "11111000" =>                              -- single data error
            DataCorr(4)    <= not DataIn(4);
            SingleErr      <= '1';                       -- single correctable
         when "10100100" =>                              -- single data error
            DataCorr(5)    <= not DataIn(5);
            SingleErr      <= '1';                       -- single correctable
         when "01100101" =>                              -- single data error
            DataCorr(6)    <= not DataIn(6);
            SingleErr      <= '1';                       -- single correctable
         when "01010011" =>                              -- single data error
            DataCorr(7)    <= not DataIn(7);
            SingleErr      <= '1';                       -- single correctable
         when "11110100" =>                              -- single data error
            DataCorr(8)    <= not DataIn(8);
            SingleErr      <= '1';                       -- single correctable
         when "11011100" =>                              -- single data error
            DataCorr(9)    <= not DataIn(9);
            SingleErr      <= '1';                       -- single correctable
         when "10111100" =>                              -- single data error
            DataCorr(10)   <= not DataIn(10);
            SingleErr      <= '1';                       -- single correctable
         when "10000111" =>                              -- single data error
            DataCorr(11)   <= not DataIn(11);
            SingleErr      <= '1';                       -- single correctable
         when "01011001" =>                              -- single data error
            DataCorr(12)   <= not DataIn(12);
            SingleErr      <= '1';                       -- single correctable
         when "01010100" =>                              -- single data error
            DataCorr(13)   <= not DataIn(13);
            SingleErr      <= '1';                       -- single correctable
         when "00110101" =>                              -- single data error
            DataCorr(14)   <= not DataIn(14);
            SingleErr      <= '1';                       -- single correctable
         when "11110010" =>                              -- single data error
            DataCorr(15)   <= not DataIn(15);
            SingleErr      <= '1';                       -- single correctable
         when "01100011" =>                              -- single data error
            DataCorr(16)   <= not DataIn(16);
            SingleErr      <= '1';                       -- single correctable
         when "01001011" =>                              -- single data error
            DataCorr(17)   <= not DataIn(17);
            SingleErr      <= '1';                       -- single correctable
         when "00100110" =>                              -- single data error
            DataCorr(18)   <= not DataIn(18);
            SingleErr      <= '1';                       -- single correctable
         when "10111010" =>                              -- single data error
            DataCorr(19)   <= not DataIn(19);
            SingleErr      <= '1';                       -- single correctable
         when "11000100" =>                              -- single data error
            DataCorr(20)   <= not DataIn(20);
            SingleErr      <= '1';                       -- single correctable
         when "10001101" =>                              -- single data error
            DataCorr(21)   <= not DataIn(21);
            SingleErr      <= '1';                       -- single correctable
         when "00110011" =>                              -- single data error
            DataCorr(22)   <= not DataIn(22);
            SingleErr      <= '1';                       -- single correctable
         when "00010110" =>                              -- single data error
            DataCorr(23)    <= not DataIn(23);
            SingleErr      <= '1';                       -- single correctable
         when "11001001" =>                              -- single data error
            DataCorr(24)    <= not DataIn(24);
            SingleErr      <= '1';                       -- single correctable
         when "01001101" =>                              -- single data error
            DataCorr(25)   <= not DataIn(25);
            SingleErr      <= '1';                       -- single correctable
         when "00101101" =>                              -- single data error
            DataCorr(26)   <= not DataIn(26);
            SingleErr      <= '1';                       -- single correctable
         when "00011011" =>                              -- single data error
            DataCorr(27)   <= not DataIn(27);
            SingleErr      <= '1';                       -- single correctable
         when "11000010" =>                              -- single data error
            DataCorr(28)   <= not DataIn(28);
            SingleErr      <= '1';                       -- single correctable
         when "10001010" =>                              -- single data error
            DataCorr(29)   <= not DataIn(29);
            SingleErr      <= '1';                       -- single correctable
         when "11011010" =>                              -- single data error
            DataCorr(30)   <= not DataIn(30);
            SingleErr      <= '1';                       -- single correctable
         when "10110110" =>                              -- single data error
            DataCorr(31)   <= not DataIn(31);
            SingleErr      <= '1';                       -- single correctable

         when "10000000" | "01000000" | "00100000" |
              "00010000" | "00001000" | "00000100" |
              "00000010" | "00000001"  =>                -- single parity error
            SingleErr      <= '1';                       -- single correctable

         when "00000000" =>                              -- no errors

         when others   =>                                -- multiple errors
            MultipleErr    <= '1';                       -- uncorrectable error
      end case;

      -- Check bit generator output
      CheckOut(0) <=      DataOut(31) xor DataOut(30) xor DataOut(29) xor
                          DataOut(28) xor DataOut(24) xor DataOut(21) xor
                          DataOut(20) xor DataOut(19) xor DataOut(15) xor
                          DataOut(11) xor DataOut(10) xor DataOut(9)  xor
                          DataOut(8)  xor DataOut(5)  xor DataOut(4)  xor
                          DataOut(1);
      CheckOut(1) <=      DataOut(30) xor DataOut(28) xor DataOut(25) xor
                          DataOut(24) xor DataOut(20) xor DataOut(17) xor
                          DataOut(16) xor DataOut(15) xor DataOut(13) xor
                          DataOut(12) xor DataOut(9)  xor DataOut(8)  xor
                          DataOut(7)  xor DataOut(6)  xor DataOut(4)  xor
                          DataOut(3);
      CheckOut(2) <= not (DataOut(31) xor DataOut(26) xor DataOut(22) xor
                          DataOut(19) xor DataOut(18) xor DataOut(16) xor
                          DataOut(15) xor DataOut(14) xor DataOut(10) xor
                          DataOut(8)  xor DataOut(6)  xor DataOut(5)  xor
                          DataOut(4)  xor DataOut(3)  xor DataOut(2)  xor
                          DataOut(1));
      CheckOut(3) <= not (DataOut(31) xor DataOut(30) xor DataOut(27) xor
                          DataOut(23) xor DataOut(22) xor DataOut(19) xor
                          DataOut(15) xor DataOut(14) xor DataOut(13) xor
                          DataOut(12) xor DataOut(10) xor DataOut(9)  xor
                          DataOut(8)  xor DataOut(7)  xor DataOut(4)  xor
                          DataOut(0));
      CheckOut(4) <=      DataOut(30) xor DataOut(29) xor DataOut(27) xor
                          DataOut(26) xor DataOut(25) xor DataOut(24) xor
                          DataOut(21) xor DataOut(19) xor DataOut(17) xor
                          DataOut(12) xor DataOut(10) xor DataOut(9)  xor
                          DataOut(4)  xor DataOut(3)  xor DataOut(2)  xor
                          DataOut(0);
      CheckOut(5) <=      DataOut(31) xor DataOut(26) xor DataOut(25) xor
                          DataOut(23) xor DataOut(21) xor DataOut(20) xor
                          DataOut(18) xor DataOut(14) xor DataOut(13) xor
                          DataOut(11) xor DataOut(10) xor DataOut(9)  xor
                          DataOut(8)  xor DataOut(6)  xor DataOut(5)  xor
                          DataOut(0);
      CheckOut(6) <=      DataOut(31) xor DataOut(30) xor DataOut(29) xor
                          DataOut(28) xor DataOut(27) xor DataOut(23) xor
                          DataOut(22) xor DataOut(19) xor DataOut(18) xor
                          DataOut(17) xor DataOut(16) xor DataOut(15) xor
                          DataOut(11) xor DataOut(7)  xor DataOut(2)  xor
                          DataOut(1);
      CheckOut(7) <= not (DataOut(27) xor DataOut(26) xor DataOut(25) xor
                          DataOut(24) xor DataOut(22) xor DataOut(21) xor
                          DataOut(17) xor DataOut(16) xor DataOut(14) xor
                          DataOut(12) xor DataOut(11) xor DataOut(7)  xor
                          DataOut(6)  xor DataOut(2)  xor DataOut(1)  xor
                          DataOut(0));
   end EDAC32Strong;

   -----------------------------------------------------------------------------
   -- This functional block provides the EDAC logic to correct
   -- one bit error and to detect up to two bit errors in an
   -- 40-bit input data word. The codewords are 47-bit long.
   -- Check bit 7 is not used.
   --
   -- Two parity bits have been inversed to avoid an all-zero code word.
   -----------------------------------------------------------------------------
   procedure EDAC40Hamming(
      signal   DataOut:       in    Word40;              -- Output data bits
      signal   CheckOut:      out   Word8;               -- Output check bits

      signal   DataIn:        in    Word40;              -- Input data bits
      signal   CheckIn:       in    Word8;               -- Input check bits

      signal   DataCorr:      out   Word40;              -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic) is       -- Uncorrectable error

      variable Parity:        Std_Logic_Vector(0 to 6);  -- Generated parity
      variable Syndrome:      Std_Logic_Vector(0 to 6);  -- Syndrome
   begin
      -- Check bit generator
      Parity(0)    :=    not (DataIn(0)  xor DataIn(1)  xor DataIn(3)  xor
                              DataIn(4)  xor DataIn(6)  xor DataIn(8)  xor
                              DataIn(10) xor DataIn(12) xor DataIn(14) xor
                              DataIn(16) xor DataIn(18) xor DataIn(20) xor
                              DataIn(22) xor DataIn(24) xor DataIn(26) xor
                              DataIn(28) xor DataIn(31) xor DataIn(33) xor
                              DataIn(35) xor DataIn(37) xor DataIn(39));
      Parity(1)    :=    not (DataIn(0)  xor DataIn(1)  xor DataIn(2)  xor
                              DataIn(4)  xor DataIn(5)  xor DataIn(7)  xor
                              DataIn(10) xor DataIn(11) xor DataIn(13) xor
                              DataIn(16) xor DataIn(17) xor DataIn(20) xor
                              DataIn(22) xor DataIn(23) xor DataIn(24) xor
                              DataIn(25) xor DataIn(27) xor DataIn(30) xor
                              DataIn(33) xor DataIn(35) xor DataIn(36) xor
                              DataIn(38));
      Parity(2)    :=         DataIn(1)  xor DataIn(2)  xor DataIn(3)  xor
                              DataIn(5)  xor DataIn(6)  xor DataIn(9)  xor
                              DataIn(11) xor DataIn(12) xor DataIn(15) xor
                              DataIn(16) xor DataIn(19) xor DataIn(20) xor
                              DataIn(23) xor DataIn(25) xor DataIn(26) xor
                              DataIn(29) xor DataIn(32) xor DataIn(33) xor
                              DataIn(36) xor DataIn(37);
      Parity(3)    :=         DataIn(0)  xor DataIn(2)  xor DataIn(3)  xor
                              DataIn(7)  xor DataIn(8)  xor DataIn(9)  xor
                              DataIn(13) xor DataIn(14) xor DataIn(15) xor
                              DataIn(16) xor DataIn(21) xor DataIn(22) xor
                              DataIn(23) xor DataIn(27) xor DataIn(28) xor
                              DataIn(29) xor DataIn(34) xor DataIn(35) xor
                              DataIn(36) xor DataIn(37);
      Parity(4)    :=         DataIn(4)  xor DataIn(5)  xor DataIn(6)  xor
                              DataIn(7)  xor DataIn(8)  xor DataIn(9)  xor
                              DataIn(17) xor DataIn(18) xor DataIn(19) xor
                              DataIn(20) xor DataIn(21) xor DataIn(22) xor
                              DataIn(23) xor DataIn(30) xor DataIn(31) xor
                              DataIn(32) xor DataIn(33) xor DataIn(34) xor
                              DataIn(35) xor DataIn(36) xor DataIn(37);
      Parity(5)    :=         DataIn(24) xor DataIn(25) xor DataIn(26) xor
                              DataIn(27) xor DataIn(28) xor DataIn(29) xor
                              DataIn(30) xor DataIn(31) xor DataIn(32) xor
                              DataIn(33) xor DataIn(34) xor DataIn(35) xor
                              DataIn(36) xor DataIn(37) xor DataIn(38) xor
                              DataIn(39);
      Parity(6)    :=         DataIn(10) xor DataIn(11) xor DataIn(12) xor
                              DataIn(13) xor DataIn(14) xor DataIn(15) xor
                              DataIn(16) xor DataIn(17) xor DataIn(18) xor
                              DataIn(19) xor DataIn(20) xor DataIn(21) xor
                              DataIn(22) xor DataIn(23) xor DataIn(38) xor
                              DataIn(39);

      -- Syndrome bit generator
      Syndrome(0) :=    Parity(0) xor CheckIn(0);
      Syndrome(1) :=    Parity(1) xor CheckIn(1);
      Syndrome(2) :=    Parity(2) xor CheckIn(2);
      Syndrome(3) :=    Parity(3) xor CheckIn(3);
      Syndrome(4) :=    Parity(4) xor CheckIn(4);
      Syndrome(5) :=    Parity(5) xor CheckIn(5);
      Syndrome(6) :=    Parity(6) xor CheckIn(6);

      -- Bit corrector
      DataCorr             <= DataIn;                    -- uncorrected default

      -- Default
      SingleErr      <= '0';                       -- single correctable
      DoubleErr      <= '0';                       -- double correctable
      MultipleErr    <= '0';                       -- uncorrectable error

      case Syndrome is                                   -- bit error correction
         when "1101000" =>                               -- single data error
            DataCorr( 0)   <= not DataIn( 0);
            SingleErr      <= '1';                       -- single correctable
         when "1110000" =>                               -- single data error
            DataCorr( 1)   <= not DataIn( 1);
            SingleErr      <= '1';                       -- single correctable
         when "0111000" =>                               -- single data error
            DataCorr( 2)   <= not DataIn( 2);
            SingleErr      <= '1';                       -- single correctable
         when "1011000" =>                               -- single data error
            DataCorr( 3)   <= not DataIn( 3);
            SingleErr      <= '1';                       -- single correctable
         when "1100100" =>                               -- single data error
            DataCorr( 4)   <= not DataIn( 4);
            SingleErr      <= '1';                       -- single correctable
         when "0110100" =>                               -- single data error
            DataCorr( 5)   <= not DataIn( 5);
            SingleErr      <= '1';                       -- single correctable
         when "1010100" =>                               -- single data error
            DataCorr( 6)   <= not DataIn( 6);
            SingleErr      <= '1';                       -- single correctable
         when "0101100" =>                               -- single data error
            DataCorr( 7)   <= not DataIn( 7);
            SingleErr      <= '1';                       -- single correctable
         when "1001100" =>                               -- single data error
            DataCorr( 8)   <= not DataIn( 8);
            SingleErr      <= '1';                       -- single correctable
         when "0011100" =>                               -- single data error
            DataCorr( 9)   <= not DataIn( 9);
            SingleErr      <= '1';                       -- single correctable
         when "1100001" =>                               -- single data error
            DataCorr(10)   <= not DataIn(10);
            SingleErr      <= '1';                       -- single correctable
         when "0110001" =>                               -- single data error
            DataCorr(11)   <= not DataIn(11);
            SingleErr      <= '1';                       -- single correctable
         when "1010001" =>                               -- single data error
            DataCorr(12)   <= not DataIn(12);
            SingleErr      <= '1';                       -- single correctable
         when "0101001" =>                               -- single data error
            DataCorr(13)   <= not DataIn(13);
            SingleErr      <= '1';                       -- single correctable
         when "1001001" =>                               -- single data error
            DataCorr(14)   <= not DataIn(14);
            SingleErr      <= '1';                       -- single correctable
         when "0011001" =>                               -- single data error
            DataCorr(15)   <= not DataIn(15);
            SingleErr      <= '1';                       -- single correctable
         when "1111001" =>                               -- single data error
            DataCorr(16)   <= not DataIn(16);
            SingleErr      <= '1';                       -- single correctable
         when "0100101" =>                               -- single data error
            DataCorr(17)   <= not DataIn(17);
            SingleErr      <= '1';                       -- single correctable
         when "1000101" =>                               -- single data error
            DataCorr(18)   <= not DataIn(18);
            SingleErr      <= '1';                       -- single correctable
         when "0010101" =>                               -- single data error
            DataCorr(19)   <= not DataIn(19);
            SingleErr      <= '1';                       -- single correctable
         when "1110101" =>                               -- single data error
            DataCorr(20)   <= not DataIn(20);
            SingleErr      <= '1';                       -- single correctable
         when "0001101" =>                               -- single data error
            DataCorr(21)   <= not DataIn(21);
            SingleErr      <= '1';                       -- single correctable
         when "1101101" =>                               -- single data error
            DataCorr(22)   <= not DataIn(22);
            SingleErr      <= '1';                       -- single correctable
         when "0111101" =>                               -- single data error
            DataCorr(23)   <= not DataIn(23);
            SingleErr      <= '1';                       -- single correctable
         when "1100010" =>                               -- single data error
            DataCorr(24)   <= not DataIn(24);
            SingleErr      <= '1';                       -- single correctable
         when "0110010" =>                               -- single data error
            DataCorr(25)   <= not DataIn(25);
            SingleErr      <= '1';                       -- single correctable
         when "1010010" =>                               -- single data error
            DataCorr(26)   <= not DataIn(26);
            SingleErr      <= '1';                       -- single correctable
         when "0101010" =>                               -- single data error
            DataCorr(27)   <= not DataIn(27);
            SingleErr      <= '1';                       -- single correctable
         when "1001010" =>                               -- single data error
            DataCorr(28)   <= not DataIn(28);
            SingleErr      <= '1';                       -- single correctable
         when "0011010" =>                               -- single data error
            DataCorr(29)   <= not DataIn(29);
            SingleErr      <= '1';                       -- single correctable
         when "0100110" =>                               -- single data error
            DataCorr(30)   <= not DataIn(30);
            SingleErr      <= '1';                       -- single correctable
         when "1000110" =>                               -- single data error
            DataCorr(31)   <= not DataIn(31);
            SingleErr      <= '1';                       -- single correctable
         when "0010110" =>                               -- single data error
            DataCorr(32)   <= not DataIn(32);
            SingleErr      <= '1';                       -- single correctable
         when "1110110" =>                               -- single data error
            DataCorr(33)   <= not DataIn(33);
            SingleErr      <= '1';                       -- single correctable
         when "0001110" =>                               -- single data error
            DataCorr(34)   <= not DataIn(34);
            SingleErr      <= '1';                       -- single correctable
         when "1101110" =>                               -- single data error
            DataCorr(35)   <= not DataIn(35);
            SingleErr      <= '1';                       -- single correctable
         when "0111110" =>                               -- single data error
            DataCorr(36)   <= not DataIn(36);
            SingleErr      <= '1';                       -- single correctable
         when "1011110" =>                               -- single data error
            DataCorr(37)   <= not DataIn(37);
            SingleErr      <= '1';                       -- single correctable
         when "0100011" =>                               -- single data error
            DataCorr(38)   <= not DataIn(38);
            SingleErr      <= '1';                       -- single correctable
         when "1000011" =>                               -- single data error
            DataCorr(39)   <= not DataIn(39);
            SingleErr      <= '1';                       -- single correctable

         when "1000000" | "0100000" | "0010000" |
              "0001000" | "0000100" | "0000010" |
              "0000001" =>                               -- single parity error
            SingleErr      <= '1';                       -- single correctable

         when "0000000" =>                               -- no errors

         when others    =>                               -- multiple errors
            MultipleErr    <= '1';                       -- uncorrectable error
      end case;

      -- Check bit generator output
      CheckOut(0)    <=  not (DataOut(0)  xor DataOut(1)  xor DataOut(3)  xor
                              DataOut(4)  xor DataOut(6)  xor DataOut(8)  xor
                              DataOut(10) xor DataOut(12) xor DataOut(14) xor
                              DataOut(16) xor DataOut(18) xor DataOut(20) xor
                              DataOut(22) xor DataOut(24) xor DataOut(26) xor
                              DataOut(28) xor DataOut(31) xor DataOut(33) xor
                              DataOut(35) xor DataOut(37) xor DataOut(39));
      CheckOut(1)    <=  not (DataOut(0)  xor DataOut(1)  xor DataOut(2)  xor
                              DataOut(4)  xor DataOut(5)  xor DataOut(7)  xor
                              DataOut(10) xor DataOut(11) xor DataOut(13) xor
                              DataOut(16) xor DataOut(17) xor DataOut(20) xor
                              DataOut(22) xor DataOut(23) xor DataOut(24) xor
                              DataOut(25) xor DataOut(27) xor DataOut(30) xor
                              DataOut(33) xor DataOut(35) xor DataOut(36) xor
                              DataOut(38));
      CheckOut(2)    <=       DataOut(1)  xor DataOut(2)  xor DataOut(3)  xor
                              DataOut(5)  xor DataOut(6)  xor DataOut(9)  xor
                              DataOut(11) xor DataOut(12) xor DataOut(15) xor
                              DataOut(16) xor DataOut(19) xor DataOut(20) xor
                              DataOut(23) xor DataOut(25) xor DataOut(26) xor
                              DataOut(29) xor DataOut(32) xor DataOut(33) xor
                              DataOut(36) xor DataOut(37);
      CheckOut(3)    <=       DataOut(0)  xor DataOut(2)  xor DataOut(3)  xor
                              DataOut(7)  xor DataOut(8)  xor DataOut(9)  xor
                              DataOut(13) xor DataOut(14) xor DataOut(15) xor
                              DataOut(16) xor DataOut(21) xor DataOut(22) xor
                              DataOut(23) xor DataOut(27) xor DataOut(28) xor
                              DataOut(29) xor DataOut(34) xor DataOut(35) xor
                              DataOut(36) xor DataOut(37);
      CheckOut(4)    <=       DataOut(4)  xor DataOut(5)  xor DataOut(6)  xor
                              DataOut(7)  xor DataOut(8)  xor DataOut(9)  xor
                              DataOut(17) xor DataOut(18) xor DataOut(19) xor
                              DataOut(20) xor DataOut(21) xor DataOut(22) xor
                              DataOut(23) xor DataOut(30) xor DataOut(31) xor
                              DataOut(32) xor DataOut(33) xor DataOut(34) xor
                              DataOut(35) xor DataOut(36) xor DataOut(37);
      CheckOut(5)    <=       DataOut(24) xor DataOut(25) xor DataOut(26) xor
                              DataOut(27) xor DataOut(28) xor DataOut(29) xor
                              DataOut(30) xor DataOut(31) xor DataOut(32) xor
                              DataOut(33) xor DataOut(34) xor DataOut(35) xor
                              DataOut(36) xor DataOut(37) xor DataOut(38) xor
                              DataOut(39);
      CheckOut(6)    <=       DataOut(10) xor DataOut(11) xor DataOut(12) xor
                              DataOut(13) xor DataOut(14) xor DataOut(15) xor
                              DataOut(16) xor DataOut(17) xor DataOut(18) xor
                              DataOut(19) xor DataOut(20) xor DataOut(21) xor
                              DataOut(22) xor DataOut(23) xor DataOut(38) xor
                              DataOut(39);
      CheckOut(7) <=       '-';
   end EDAC40Hamming;

   -----------------------------------------------------------------------------
   -- This functional block provides the EDAC logic to correct
   -- one bit error and to detect up to two bit errors in an
   -- 48-bit input data word. The codewords are 55-bit long.
   -- Check bit 7 is not used.
   --
   -- Two parity bits have been inversed to avoid an all-zero code word.
   -----------------------------------------------------------------------------
   procedure EDAC48Hamming(
      signal   DataOut:       in    Word48;              -- Output data bits
      signal   CheckOut:      out   Word8;               -- Output check bits

      signal   DataIn:        in    Word48;              -- Input data bits
      signal   CheckIn:       in    Word8;               -- Input check bits

      signal   DataCorr:      out   Word48;              -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic) is       -- Uncorrectable error

      variable Parity:        Std_Logic_Vector(0 to 6);  -- Generated parity
      variable Syndrome:      Std_Logic_Vector(0 to 6);  -- Syndrome
   begin
      -- Check bit generator
      Parity(0) := not (DataIn(0)  xor DataIn(1)  xor DataIn(3)  xor
                        DataIn(4)  xor DataIn(6)  xor DataIn(8)  xor
                        DataIn(10) xor DataIn(12) xor DataIn(14) xor
                        DataIn(16) xor DataIn(18) xor DataIn(20) xor
                        DataIn(22) xor DataIn(24) xor DataIn(26) xor
                        DataIn(28) xor DataIn(31) xor DataIn(33) xor
                        DataIn(35) xor DataIn(37) xor DataIn(39) xor
                        DataIn(43) xor DataIn(46) xor DataIn(47));
      Parity(1) := not (DataIn(0)  xor DataIn(1)  xor DataIn(2)  xor
                        DataIn(4)  xor DataIn(5)  xor DataIn(7)  xor
                        DataIn(10) xor DataIn(11) xor DataIn(13) xor
                        DataIn(16) xor DataIn(17) xor DataIn(20) xor
                        DataIn(22) xor DataIn(23) xor DataIn(24) xor
                        DataIn(25) xor DataIn(27) xor DataIn(30) xor
                        DataIn(33) xor DataIn(35) xor DataIn(36) xor
                        DataIn(38) xor DataIn(42) xor DataIn(45));
      Parity(2) :=      DataIn(1)  xor DataIn(2)  xor DataIn(3)  xor
                        DataIn(5)  xor DataIn(6)  xor DataIn(9)  xor
                        DataIn(11) xor DataIn(12) xor DataIn(15) xor
                        DataIn(16) xor DataIn(19) xor DataIn(20) xor
                        DataIn(23) xor DataIn(25) xor DataIn(26) xor
                        DataIn(29) xor DataIn(32) xor DataIn(33) xor
                        DataIn(36) xor DataIn(37) xor DataIn(40) xor
                        DataIn(42) xor DataIn(43) xor DataIn(45) xor
                        DataIn(46);
      Parity(3) :=      DataIn(0)  xor DataIn(2)  xor DataIn(3)  xor
                        DataIn(7)  xor DataIn(8)  xor DataIn(9)  xor
                        DataIn(13) xor DataIn(14) xor DataIn(15) xor
                        DataIn(16) xor DataIn(21) xor DataIn(22) xor
                        DataIn(23) xor DataIn(27) xor DataIn(28) xor
                        DataIn(29) xor DataIn(34) xor DataIn(35) xor
                        DataIn(36) xor DataIn(37) xor DataIn(41) xor
                        DataIn(42) xor DataIn(43) xor DataIn(47);
      Parity(4) :=      DataIn(4)  xor DataIn(5)  xor DataIn(6)  xor
                        DataIn(7)  xor DataIn(8)  xor DataIn(9)  xor
                        DataIn(17) xor DataIn(18) xor DataIn(19) xor
                        DataIn(20) xor DataIn(21) xor DataIn(22) xor
                        DataIn(23) xor DataIn(30) xor DataIn(31) xor
                        DataIn(32) xor DataIn(33) xor DataIn(34) xor
                        DataIn(35) xor DataIn(36) xor DataIn(37) xor
                        DataIn(44) xor DataIn(45) xor DataIn(46) xor
                        DataIn(47);
      Parity(5) :=      DataIn(24) xor DataIn(25) xor DataIn(26) xor
                        DataIn(27) xor DataIn(28) xor DataIn(29) xor
                        DataIn(30) xor DataIn(31) xor DataIn(32) xor
                        DataIn(33) xor DataIn(34) xor DataIn(35) xor
                        DataIn(36) xor DataIn(37) xor DataIn(38) xor
                        DataIn(39) xor DataIn(40) xor DataIn(41) xor
                        DataIn(42) xor DataIn(43) xor DataIn(44) xor
                        DataIn(45) xor DataIn(46) xor DataIn(47);
      Parity(6) :=      DataIn(10) xor DataIn(11) xor DataIn(12) xor
                        DataIn(13) xor DataIn(14) xor DataIn(15) xor
                        DataIn(16) xor DataIn(17) xor DataIn(18) xor
                        DataIn(19) xor DataIn(20) xor DataIn(21) xor
                        DataIn(22) xor DataIn(23) xor DataIn(38) xor
                        DataIn(39) xor DataIn(40) xor DataIn(41) xor
                        DataIn(42) xor DataIn(43) xor DataIn(44) xor
                        DataIn(45) xor DataIn(46) xor DataIn(47);

      -- Syndrome bit generator
      Syndrome(0) :=    Parity(0) xor CheckIn(0);
      Syndrome(1) :=    Parity(1) xor CheckIn(1);
      Syndrome(2) :=    Parity(2) xor CheckIn(2);
      Syndrome(3) :=    Parity(3) xor CheckIn(3);
      Syndrome(4) :=    Parity(4) xor CheckIn(4);
      Syndrome(5) :=    Parity(5) xor CheckIn(5);
      Syndrome(6) :=    Parity(6) xor CheckIn(6);

      -- Bit corrector
      DataCorr             <= DataIn;                    -- uncorrected default

      -- Default
      SingleErr      <= '0';                       -- single correctable
      DoubleErr      <= '0';                       -- double correctable
      MultipleErr    <= '0';                       -- uncorrectable error

      case Syndrome is                                   -- bit error correction
         when "1101000" =>                               -- single data error
            DataCorr(0)    <= not DataIn(0);
            SingleErr      <= '1';                       -- single correctable
         when "1110000" =>                               -- single data error
            DataCorr(1)    <= not DataIn(1);
            SingleErr      <= '1';                       -- single correctable
         when "0111000" =>                               -- single data error
            DataCorr(2)    <= not DataIn(2);
            SingleErr      <= '1';                       -- single correctable
         when "1011000" =>                               -- single data error
            DataCorr(3)    <= not DataIn(3);
            SingleErr      <= '1';                       -- single correctable
         when "1100100" =>                               -- single data error
            DataCorr(4)    <= not DataIn(4);
            SingleErr      <= '1';                       -- single correctable
         when "0110100" =>                               -- single data error
            DataCorr(5)    <= not DataIn(5);
            SingleErr      <= '1';                       -- single correctable
         when "1010100" =>                               -- single data error
            DataCorr(6)    <= not DataIn(6);
            SingleErr      <= '1';                       -- single correctable
         when "0101100" =>                               -- single data error
            DataCorr(7)    <= not DataIn(7);
            SingleErr      <= '1';                       -- single correctable
         when "1001100" =>                               -- single data error
            DataCorr(8)    <= not DataIn(8);
            SingleErr      <= '1';                       -- single correctable
         when "0011100" =>                               -- single data error
            DataCorr(9)    <= not DataIn(9);
            SingleErr      <= '1';                       -- single correctable
         when "1100001" =>                               -- single data error
            DataCorr(10)   <= not DataIn(10);
            SingleErr      <= '1';                       -- single correctable
         when "0110001" =>                               -- single data error
            DataCorr(11)   <= not DataIn(11);
            SingleErr      <= '1';                       -- single correctable
         when "1010001" =>                               -- single data error
            DataCorr(12)   <= not DataIn(12);
            SingleErr      <= '1';                       -- single correctable
         when "0101001" =>                               -- single data error
            DataCorr(13)   <= not DataIn(13);
            SingleErr      <= '1';                       -- single correctable
         when "1001001" =>                               -- single data error
            DataCorr(14)   <= not DataIn(14);
            SingleErr      <= '1';                       -- single correctable
         when "0011001" =>                               -- single data error
            DataCorr(15)   <= not DataIn(15);
            SingleErr      <= '1';                       -- single correctable
         when "1111001" =>                               -- single data error
            DataCorr(16)   <= not DataIn(16);
            SingleErr      <= '1';                       -- single correctable
         when "0100101" =>                               -- single data error
            DataCorr(17)   <= not DataIn(17);
            SingleErr      <= '1';                       -- single correctable
         when "1000101" =>                               -- single data error
            DataCorr(18)   <= not DataIn(18);
            SingleErr      <= '1';                       -- single correctable
         when "0010101" =>                               -- single data error
            DataCorr(19)   <= not DataIn(19);
            SingleErr      <= '1';                       -- single correctable
         when "1110101" =>                               -- single data error
            DataCorr(20)   <= not DataIn(20);
            SingleErr      <= '1';                       -- single correctable
         when "0001101" =>                               -- single data error
            DataCorr(21)   <= not DataIn(21);
            SingleErr      <= '1';                       -- single correctable
         when "1101101" =>                               -- single data error
            DataCorr(22)   <= not DataIn(22);
            SingleErr      <= '1';                       -- single correctable
         when "0111101" =>                               -- single data error
            DataCorr(23)   <= not DataIn(23);
            SingleErr      <= '1';                       -- single correctable
         when "1100010" =>                               -- single data error
            DataCorr(24)   <= not DataIn(24);
            SingleErr      <= '1';                       -- single correctable
         when "0110010" =>                               -- single data error
            DataCorr(25)   <= not DataIn(25);
            SingleErr      <= '1';                       -- single correctable
         when "1010010" =>                               -- single data error
            DataCorr(26)   <= not DataIn(26);
            SingleErr      <= '1';                       -- single correctable
         when "0101010" =>                               -- single data error
            DataCorr(27)   <= not DataIn(27);
            SingleErr      <= '1';                       -- single correctable
         when "1001010" =>                               -- single data error
            DataCorr(28)   <= not DataIn(28);
            SingleErr      <= '1';                       -- single correctable
         when "0011010" =>                               -- single data error
            DataCorr(29)   <= not DataIn(29);
            SingleErr      <= '1';                       -- single correctable
         when "0100110" =>                               -- single data error
            DataCorr(30)   <= not DataIn(30);
            SingleErr      <= '1';                       -- single correctable
         when "1000110" =>                               -- single data error
            DataCorr(31)   <= not DataIn(31);
            SingleErr      <= '1';                       -- single correctable
         when "0010110" =>                               -- single data error
            DataCorr(32)   <= not DataIn(32);
            SingleErr      <= '1';                       -- single correctable
         when "1110110" =>                               -- single data error
            DataCorr(33)   <= not DataIn(33);
            SingleErr      <= '1';                       -- single correctable
         when "0001110" =>                               -- single data error
            DataCorr(34)   <= not DataIn(34);
            SingleErr      <= '1';                       -- single correctable
         when "1101110" =>                               -- single data error
            DataCorr(35)   <= not DataIn(35);
            SingleErr      <= '1';                       -- single correctable
         when "0111110" =>                               -- single data error
            DataCorr(36)   <= not DataIn(36);
            SingleErr      <= '1';                       -- single correctable
         when "1011110" =>                               -- single data error
            DataCorr(37)   <= not DataIn(37);
            SingleErr      <= '1';                       -- single correctable
         when "0100011" =>                               -- single data error
            DataCorr(38)   <= not DataIn(38);
            SingleErr      <= '1';                       -- single correctable
         when "1000011" =>                               -- single data error
            DataCorr(39)   <= not DataIn(39);
            SingleErr      <= '1';                       -- single correctable
         when "0010011" =>                               -- single data error
            DataCorr(40)   <= not DataIn(40);
            SingleErr      <= '1';                       -- single correctable
         when "0001011" =>                               -- single data error
            DataCorr(41)   <= not DataIn(41);
            SingleErr      <= '1';                       -- single correctable
         when "0111011" =>                               -- single data error
            DataCorr(42)   <= not DataIn(42);
            SingleErr      <= '1';                       -- single correctable
         when "1011011" =>                               -- single data error
            DataCorr(43)   <= not DataIn(43);
            SingleErr      <= '1';                       -- single correctable
         when "0000111" =>                               -- single data error
            DataCorr(44)   <= not DataIn(44);
            SingleErr      <= '1';                       -- single correctable
         when "0110111" =>                               -- single data error
            DataCorr(45)   <= not DataIn(45);
            SingleErr      <= '1';                       -- single correctable
         when "1010111" =>                               -- single data error
            DataCorr(46)   <= not DataIn(46);
            SingleErr      <= '1';                       -- single correctable
         when "1001111" =>                               -- single data error
            DataCorr(47)   <= not DataIn(47);
            SingleErr      <= '1';                       -- single correctable

         when "1000000" | "0100000" | "0010000" |
              "0001000" | "0000100" | "0000010" |
              "0000001" =>                               -- single parity error
            SingleErr      <= '1';                       -- single correctable

         when "0000000" =>                               -- no errors

         when others    =>                               -- multiple errors
            MultipleErr    <= '1';                       -- uncorrectable error
      end case;

      -- Check bit generator output

      CheckOut(0) <=  not (DataOut(0)  xor DataOut(1)  xor DataOut(3)  xor
                           DataOut(4)  xor DataOut(6)  xor DataOut(8)  xor
                           DataOut(10) xor DataOut(12) xor DataOut(14) xor
                           DataOut(16) xor DataOut(18) xor DataOut(20) xor
                           DataOut(22) xor DataOut(24) xor DataOut(26) xor
                           DataOut(28) xor DataOut(31) xor DataOut(33) xor
                           DataOut(35) xor DataOut(37) xor DataOut(39) xor
                           DataOut(43) xor DataOut(46) xor DataOut(47));
      CheckOut(1) <=  not (DataOut(0)  xor DataOut(1)  xor DataOut(2)  xor
                           DataOut(4)  xor DataOut(5)  xor DataOut(7)  xor
                           DataOut(10) xor DataOut(11) xor DataOut(13) xor
                           DataOut(16) xor DataOut(17) xor DataOut(20) xor
                           DataOut(22) xor DataOut(23) xor DataOut(24) xor
                           DataOut(25) xor DataOut(27) xor DataOut(30) xor
                           DataOut(33) xor DataOut(35) xor DataOut(36) xor
                           DataOut(38) xor DataOut(42) xor DataOut(45));
      CheckOut(2) <=       DataOut(1)  xor DataOut(2)  xor DataOut(3)  xor
                           DataOut(5)  xor DataOut(6)  xor DataOut(9)  xor
                           DataOut(11) xor DataOut(12) xor DataOut(15) xor
                           DataOut(16) xor DataOut(19) xor DataOut(20) xor
                           DataOut(23) xor DataOut(25) xor DataOut(26) xor
                           DataOut(29) xor DataOut(32) xor DataOut(33) xor
                           DataOut(36) xor DataOut(37) xor DataOut(40) xor
                           DataOut(42) xor DataOut(43) xor DataOut(45) xor
                           DataOut(46);
      CheckOut(3) <=       DataOut(0)  xor DataOut(2)  xor DataOut(3)  xor
                           DataOut(7)  xor DataOut(8)  xor DataOut(9)  xor
                           DataOut(13) xor DataOut(14) xor DataOut(15) xor
                           DataOut(16) xor DataOut(21) xor DataOut(22) xor
                           DataOut(23) xor DataOut(27) xor DataOut(28) xor
                           DataOut(29) xor DataOut(34) xor DataOut(35) xor
                           DataOut(36) xor DataOut(37) xor DataOut(41) xor
                           DataOut(42) xor DataOut(43) xor DataOut(47);
      CheckOut(4) <=       DataOut(4)  xor DataOut(5)  xor DataOut(6)  xor
                           DataOut(7)  xor DataOut(8)  xor DataOut(9)  xor
                           DataOut(17) xor DataOut(18) xor DataOut(19) xor
                           DataOut(20) xor DataOut(21) xor DataOut(22) xor
                           DataOut(23) xor DataOut(30) xor DataOut(31) xor
                           DataOut(32) xor DataOut(33) xor DataOut(34) xor
                           DataOut(35) xor DataOut(36) xor DataOut(37) xor
                           DataOut(44) xor DataOut(45) xor DataOut(46) xor
                           DataOut(47);
      CheckOut(5) <=       DataOut(24) xor DataOut(25) xor DataOut(26) xor
                           DataOut(27) xor DataOut(28) xor DataOut(29) xor
                           DataOut(30) xor DataOut(31) xor DataOut(32) xor
                           DataOut(33) xor DataOut(34) xor DataOut(35) xor
                           DataOut(36) xor DataOut(37) xor DataOut(38) xor
                           DataOut(39) xor DataOut(40) xor DataOut(41) xor
                           DataOut(42) xor DataOut(43) xor DataOut(44) xor
                           DataOut(45) xor DataOut(46) xor DataOut(47);
      CheckOut(6) <=       DataOut(10) xor DataOut(11) xor DataOut(12) xor
                           DataOut(13) xor DataOut(14) xor DataOut(15) xor
                           DataOut(16) xor DataOut(17) xor DataOut(18) xor
                           DataOut(19) xor DataOut(20) xor DataOut(21) xor
                           DataOut(22) xor DataOut(23) xor DataOut(38) xor
                           DataOut(39) xor DataOut(40) xor DataOut(41) xor
                           DataOut(42) xor DataOut(43) xor DataOut(44) xor
                           DataOut(45) xor DataOut(46) xor DataOut(47);
      CheckOut(7) <=       '-';
   end EDAC48Hamming;

   -----------------------------------------------------------------------------
   -- This functional block provides the EDAC logic to correct
   -- one bit error and to detect up to two bit errors in an
   -- 64-bit input data word. The codewords are 72-bit long.
   --
   -- Two parity bits have been inversed to avoid an all-zero code word.
   -----------------------------------------------------------------------------
   procedure EDAC64Hamming(
      signal   DataOut:       in    Word64;              -- Output data bits
      signal   CheckOut:      out   Word8;               -- Output check bits

      signal   DataIn:        in    Word64;              -- Input data bits
      signal   CheckIn:       in    Word8;               -- Input check bits

      signal   DataCorr:      out   Word64;              -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic;          -- Single error
      signal   DoubleErr:     out   Std_ULogic;          -- Double error
      signal   MultipleErr:   out   Std_ULogic) is       -- Uncorrectable error

      variable Parity:        Std_Logic_Vector(0 to 7);  -- Generated parity
      variable Syndrome:      Std_Logic_Vector(0 to 7);  -- Syndrome
   begin
      -- Check bit generator
      Parity(0)   :=       DataIn(1)  xor DataIn(2)  xor DataIn(3)  xor
                           DataIn(5)  xor DataIn(8)  xor DataIn(9)  xor
                           DataIn(11) xor DataIn(14) xor DataIn(17) xor
                           DataIn(18) xor DataIn(19) xor DataIn(21) xor
                           DataIn(24) xor DataIn(25) xor DataIn(27) xor
                           DataIn(30) xor DataIn(32) xor DataIn(36) xor
                           DataIn(38) xor DataIn(39) xor DataIn(42) xor
                           DataIn(44) xor DataIn(45) xor DataIn(47) xor
                           DataIn(48) xor DataIn(52) xor DataIn(54) xor
                           DataIn(55) xor DataIn(58) xor DataIn(60) xor
                           DataIn(61) xor DataIn(63);
      Parity(1)   :=       DataIn(0)  xor DataIn(1)  xor DataIn(2)  xor
                           DataIn(4)  xor DataIn(6)  xor DataIn(8)  xor
                           DataIn(10) xor DataIn(12) xor DataIn(16) xor
                           DataIn(17) xor DataIn(18) xor DataIn(20) xor
                           DataIn(22) xor DataIn(24) xor DataIn(26) xor
                           DataIn(28) xor DataIn(32) xor DataIn(33) xor
                           DataIn(34) xor DataIn(36) xor DataIn(38) xor
                           DataIn(40) xor DataIn(42) xor DataIn(44) xor
                           DataIn(48) xor DataIn(49) xor DataIn(50) xor
                           DataIn(52) xor DataIn(54) xor DataIn(56) xor
                           DataIn(58) xor DataIn(60);
      Parity(2)   :=  not (DataIn(0)  xor DataIn(3)  xor DataIn(4)  xor
                           DataIn(7)  xor DataIn(9)  xor DataIn(10) xor
                           DataIn(13) xor DataIn(15) xor DataIn(16) xor
                           DataIn(19) xor DataIn(20) xor DataIn(23) xor
                           DataIn(25) xor DataIn(26) xor DataIn(29) xor
                           DataIn(31) xor DataIn(32) xor DataIn(35) xor
                           DataIn(36) xor DataIn(39) xor DataIn(41) xor
                           DataIn(42) xor DataIn(45) xor DataIn(47) xor
                           DataIn(48) xor DataIn(51) xor DataIn(52) xor
                           DataIn(55) xor DataIn(57) xor DataIn(58) xor
                           DataIn(61) xor DataIn(63));
      Parity(3)   :=  not (DataIn(0)  xor DataIn(1)  xor DataIn(5)  xor
                           DataIn(6)  xor DataIn(7)  xor DataIn(11) xor
                           DataIn(12) xor DataIn(13) xor DataIn(16) xor
                           DataIn(17) xor DataIn(21) xor DataIn(22) xor
                           DataIn(23) xor DataIn(27) xor DataIn(28) xor
                           DataIn(29) xor DataIn(32) xor DataIn(33) xor
                           DataIn(37) xor DataIn(38) xor DataIn(39) xor
                           DataIn(43) xor DataIn(44) xor DataIn(45) xor
                           DataIn(48) xor DataIn(49) xor DataIn(53) xor
                           DataIn(54) xor DataIn(55) xor DataIn(59) xor
                           DataIn(60) xor DataIn(61));
      Parity(4)   :=       DataIn(2)  xor DataIn(3)  xor DataIn(4)  xor
                           DataIn(5)  xor DataIn(6)  xor DataIn(7)  xor
                           DataIn(14) xor DataIn(15) xor DataIn(18) xor
                           DataIn(19) xor DataIn(20) xor DataIn(21) xor
                           DataIn(22) xor DataIn(23) xor DataIn(30) xor
                           DataIn(31) xor DataIn(34) xor DataIn(35) xor
                           DataIn(36) xor DataIn(37) xor DataIn(38) xor
                           DataIn(39) xor DataIn(46) xor DataIn(47) xor
                           DataIn(50) xor DataIn(51) xor DataIn(52) xor
                           DataIn(53) xor DataIn(54) xor DataIn(55) xor
                           DataIn(62) xor DataIn(63);
      Parity(5)   :=       DataIn(8)  xor DataIn(9)  xor DataIn(10) xor
                           DataIn(11) xor DataIn(12) xor DataIn(13) xor
                           DataIn(14) xor DataIn(15) xor DataIn(24) xor
                           DataIn(25) xor DataIn(26) xor DataIn(27) xor
                           DataIn(28) xor DataIn(29) xor DataIn(30) xor
                           DataIn(31) xor DataIn(40) xor DataIn(41) xor
                           DataIn(42) xor DataIn(43) xor DataIn(44) xor
                           DataIn(45) xor DataIn(46) xor DataIn(47) xor
                           DataIn(56) xor DataIn(57) xor DataIn(58) xor
                           DataIn(59) xor DataIn(60) xor DataIn(61) xor
                           DataIn(62) xor DataIn(63);
      Parity(6)   :=       DataIn(0)  xor DataIn(1)  xor DataIn(2)  xor
                           DataIn(3)  xor DataIn(4)  xor DataIn(5)  xor
                           DataIn(6)  xor DataIn(7)  xor DataIn(24) xor
                           DataIn(25) xor DataIn(26) xor DataIn(27) xor
                           DataIn(28) xor DataIn(29) xor DataIn(30) xor
                           DataIn(31) xor DataIn(32) xor DataIn(33) xor
                           DataIn(34) xor DataIn(35) xor DataIn(36) xor
                           DataIn(37) xor DataIn(38) xor DataIn(39) xor
                           DataIn(56) xor DataIn(57) xor DataIn(58) xor
                           DataIn(59) xor DataIn(60) xor DataIn(61) xor
                           DataIn(62) xor DataIn(63);
      Parity(7)   :=       DataIn(0)  xor DataIn(1)  xor DataIn(2)  xor
                           DataIn(3)  xor DataIn(4)  xor DataIn(5)  xor
                           DataIn(6)  xor DataIn(7)  xor DataIn(24) xor
                           DataIn(25) xor DataIn(26) xor DataIn(27) xor
                           DataIn(28) xor DataIn(29) xor DataIn(30) xor
                           DataIn(31) xor DataIn(40) xor DataIn(41) xor
                           DataIn(42) xor DataIn(43) xor DataIn(44) xor
                           DataIn(45) xor DataIn(46) xor DataIn(47) xor
                           DataIn(48) xor DataIn(49) xor DataIn(50) xor
                           DataIn(51) xor DataIn(52) xor DataIn(53) xor
                           DataIn(54) xor DataIn(55);

      -- Syndrome bit generator
      Syndrome(0) :=    Parity(0) xor CheckIn(0);
      Syndrome(1) :=    Parity(1) xor CheckIn(1);
      Syndrome(2) :=    Parity(2) xor CheckIn(2);
      Syndrome(3) :=    Parity(3) xor CheckIn(3);
      Syndrome(4) :=    Parity(4) xor CheckIn(4);
      Syndrome(5) :=    Parity(5) xor CheckIn(5);
      Syndrome(6) :=    Parity(6) xor CheckIn(6);
      Syndrome(7) :=    Parity(7) xor CheckIn(7);

      -- Bit corrector
      DataCorr             <= DataIn;                    -- uncorrected default

      -- Default
      SingleErr      <= '0';                       -- single correctable
      DoubleErr      <= '0';                       -- double correctable
      MultipleErr    <= '0';                       -- uncorrectable error

      case Syndrome is                                   -- bit error correction
         when "01110011" =>                              -- single data error
            DataCorr( 0)   <= not DataIn( 0);
            SingleErr      <= '1';                       -- single correctable
         when "11010011" =>                              -- single data error
            DataCorr( 1)   <= not DataIn( 1);
            SingleErr      <= '1';                       -- single correctable
         when "11001011" =>                              -- single data error
            DataCorr( 2)   <= not DataIn( 2);
            SingleErr      <= '1';                       -- single correctable
         when "10101011" =>                              -- single data error
            DataCorr( 3)   <= not DataIn( 3);
            SingleErr      <= '1';                       -- single correctable
         when "01101011" =>                              -- single data error
            DataCorr( 4)   <= not DataIn( 4);
            SingleErr      <= '1';                       -- single correctable
         when "10011011" =>                              -- single data error
            DataCorr( 5)   <= not DataIn( 5);
            SingleErr      <= '1';                       -- single correctable
         when "01011011" =>                              -- single data error
            DataCorr( 6)   <= not DataIn( 6);
            SingleErr      <= '1';                       -- single correctable
         when "00111011" =>                              -- single data error
            DataCorr( 7)   <= not DataIn( 7);
            SingleErr      <= '1';                       -- single correctable
         when "11000100" =>                              -- single data error
            DataCorr( 8)   <= not DataIn( 8);
            SingleErr      <= '1';                       -- single correctable
         when "10100100" =>                              -- single data error
            DataCorr( 9)   <= not DataIn( 9);
            SingleErr      <= '1';                       -- single correctable
         when "01100100" =>                              -- single data error
            DataCorr(10)   <= not DataIn(10);
            SingleErr      <= '1';                       -- single correctable
         when "10010100" =>                              -- single data error
            DataCorr(11)   <= not DataIn(11);
            SingleErr      <= '1';                       -- single correctable
         when "01010100" =>                              -- single data error
            DataCorr(12)   <= not DataIn(12);
            SingleErr      <= '1';                       -- single correctable
         when "00110100" =>                              -- single data error
            DataCorr(13)   <= not DataIn(13);
            SingleErr      <= '1';                       -- single correctable
         when "10001100" =>                              -- single data error
            DataCorr(14)   <= not DataIn(14);
            SingleErr      <= '1';                       -- single correctable
         when "00101100" =>                              -- single data error
            DataCorr(15)   <= not DataIn(15);
            SingleErr      <= '1';                       -- single correctable
         when "01110000" =>                              -- single data error
            DataCorr(16)   <= not DataIn(16);
            SingleErr      <= '1';                       -- single correctable
         when "11010000" =>                              -- single data error
            DataCorr(17)   <= not DataIn(17);
            SingleErr      <= '1';                       -- single correctable
         when "11001000" =>                              -- single data error
            DataCorr(18)   <= not DataIn(18);
            SingleErr      <= '1';                       -- single correctable
         when "10101000" =>                              -- single data error
            DataCorr(19)   <= not DataIn(19);
            SingleErr      <= '1';                       -- single correctable
         when "01101000" =>                              -- single data error
            DataCorr(20)   <= not DataIn(20);
            SingleErr      <= '1';                       -- single correctable
         when "10011000" =>                              -- single data error
            DataCorr(21)   <= not DataIn(21);
            SingleErr      <= '1';                       -- single correctable
         when "01011000" =>                              -- single data error
            DataCorr(22)   <= not DataIn(22);
            SingleErr      <= '1';                       -- single correctable
         when "00111000" =>                              -- single data error
            DataCorr(23)   <= not DataIn(23);
            SingleErr      <= '1';                       -- single correctable
         when "11000111" =>                              -- single data error
            DataCorr(24)   <= not DataIn(24);
            SingleErr      <= '1';                       -- single correctable
         when "10100111" =>                              -- single data error
            DataCorr(25)   <= not DataIn(25);
            SingleErr      <= '1';                       -- single correctable
         when "01100111" =>                              -- single data error
            DataCorr(26)   <= not DataIn(26);
            SingleErr      <= '1';                       -- single correctable
         when "10010111" =>                              -- single data error
            DataCorr(27)   <= not DataIn(27);
            SingleErr      <= '1';                       -- single correctable
         when "01010111" =>                              -- single data error
            DataCorr(28)   <= not DataIn(28);
            SingleErr      <= '1';                       -- single correctable
         when "00110111" =>                              -- single data error
            DataCorr(29)   <= not DataIn(29);
            SingleErr      <= '1';                       -- single correctable
         when "10001111" =>                              -- single data error
            DataCorr(30)   <= not DataIn(30);
            SingleErr      <= '1';                       -- single correctable
         when "00101111" =>                              -- single data error
            DataCorr(31)   <= not DataIn(31);
            SingleErr      <= '1';                       -- single correctable
         when "11110010" =>                              -- single data error
            DataCorr(32)   <= not DataIn(32);
            SingleErr      <= '1';                       -- single correctable
         when "01010010" =>                              -- single data error
            DataCorr(33)   <= not DataIn(33);
            SingleErr      <= '1';                       -- single correctable
         when "01001010" =>                              -- single data error
            DataCorr(34)   <= not DataIn(34);
            SingleErr      <= '1';                       -- single correctable
         when "00101010" =>                              -- single data error
            DataCorr(35)   <= not DataIn(35);
            SingleErr      <= '1';                       -- single correctable
         when "11101010" =>                              -- single data error
            DataCorr(36)   <= not DataIn(36);
            SingleErr      <= '1';                       -- single correctable
         when "00011010" =>                              -- single data error
            DataCorr(37)   <= not DataIn(37);
            SingleErr      <= '1';                       -- single correctable
         when "11011010" =>                              -- single data error
            DataCorr(38)   <= not DataIn(38);
            SingleErr      <= '1';                       -- single correctable
         when "10111010" =>                              -- single data error
            DataCorr(39)   <= not DataIn(39);
            SingleErr      <= '1';                       -- single correctable
         when "01000101" =>                              -- single data error
            DataCorr(40)   <= not DataIn(40);
            SingleErr      <= '1';                       -- single correctable
         when "00100101" =>                              -- single data error
            DataCorr(41)   <= not DataIn(41);
            SingleErr      <= '1';                       -- single correctable
         when "11100101" =>                              -- single data error
            DataCorr(42)   <= not DataIn(42);
            SingleErr      <= '1';                       -- single correctable
         when "00010101" =>                              -- single data error
            DataCorr(43)   <= not DataIn(43);
            SingleErr      <= '1';                       -- single correctable
         when "11010101" =>                              -- single data error
            DataCorr(44)   <= not DataIn(44);
            SingleErr      <= '1';                       -- single correctable
         when "10110101" =>                              -- single data error
            DataCorr(45)   <= not DataIn(45);
            SingleErr      <= '1';                       -- single correctable
         when "00001101" =>                              -- single data error
            DataCorr(46)   <= not DataIn(46);
            SingleErr      <= '1';                       -- single correctable
         when "10101101" =>                              -- single data error
            DataCorr(47)   <= not DataIn(47);
            SingleErr      <= '1';                       -- single correctable
         when "11110001" =>                              -- single data error
            DataCorr(48)   <= not DataIn(48);
            SingleErr      <= '1';                       -- single correctable
         when "01010001" =>                              -- single data error
            DataCorr(49)   <= not DataIn(49);
            SingleErr      <= '1';                       -- single correctable
         when "01001001" =>                              -- single data error
            DataCorr(50)   <= not DataIn(50);
            SingleErr      <= '1';                       -- single correctable
         when "00101001" =>                              -- single data error
            DataCorr(51)   <= not DataIn(51);
            SingleErr      <= '1';                       -- single correctable
         when "11101001" =>                              -- single data error
            DataCorr(52)   <= not DataIn(52);
            SingleErr      <= '1';                       -- single correctable
         when "00011001" =>                              -- single data error
            DataCorr(53)   <= not DataIn(53);
            SingleErr      <= '1';                       -- single correctable
         when "11011001" =>                              -- single data error
            DataCorr(54)   <= not DataIn(54);
            SingleErr      <= '1';                       -- single correctable
         when "10111001" =>                              -- single data error
            DataCorr(55)   <= not DataIn(55);
            SingleErr      <= '1';                       -- single correctable
         when "01000110" =>                              -- single data error
            DataCorr(56)   <= not DataIn(56);
            SingleErr      <= '1';                       -- single correctable
         when "00100110" =>                              -- single data error
            DataCorr(57)   <= not DataIn(57);
            SingleErr      <= '1';                       -- single correctable
         when "11100110" =>                              -- single data error
            DataCorr(58)   <= not DataIn(58);
            SingleErr      <= '1';                       -- single correctable
         when "00010110" =>                              -- single data error
            DataCorr(59)   <= not DataIn(59);
            SingleErr      <= '1';                       -- single correctable
         when "11010110" =>                              -- single data error
            DataCorr(60)   <= not DataIn(60);
            SingleErr      <= '1';                       -- single correctable
         when "10110110" =>                              -- single data error
            DataCorr(61)   <= not DataIn(61);
            SingleErr      <= '1';                       -- single correctable
         when "00001110" =>                              -- single data error
            DataCorr(62)   <= not DataIn(62);
            SingleErr      <= '1';                       -- single correctable
         when "10101110" =>                              -- single data error
            DataCorr(63)   <= not DataIn(63);
            SingleErr      <= '1';                       -- single correctable

         when "10000000" | "01000000" | "00100000" |
              "00010000" | "00001000" | "00000100" |
              "00000010" | "00000001"=>                  -- single parity error
            SingleErr      <= '1';                       -- single correctable

         when "00000000" =>                              -- no errors

         when others    =>                               -- multiple errors
            MultipleErr    <= '1';                       -- uncorrectable error
      end case;

      -- Check bit generator output
      CheckOut(0)   <=       DataOut(1)  xor DataOut(2)  xor DataOut(3)  xor
                             DataOut(5)  xor DataOut(8)  xor DataOut(9)  xor
                             DataOut(11) xor DataOut(14) xor DataOut(17) xor
                             DataOut(18) xor DataOut(19) xor DataOut(21) xor
                             DataOut(24) xor DataOut(25) xor DataOut(27) xor
                             DataOut(30) xor DataOut(32) xor DataOut(36) xor
                             DataOut(38) xor DataOut(39) xor DataOut(42) xor
                             DataOut(44) xor DataOut(45) xor DataOut(47) xor
                             DataOut(48) xor DataOut(52) xor DataOut(54) xor
                             DataOut(55) xor DataOut(58) xor DataOut(60) xor
                             DataOut(61) xor DataOut(63);
      CheckOut(1)   <=       DataOut(0)  xor DataOut(1)  xor DataOut(2)  xor
                             DataOut(4)  xor DataOut(6)  xor DataOut(8)  xor
                             DataOut(10) xor DataOut(12) xor DataOut(16) xor
                             DataOut(17) xor DataOut(18) xor DataOut(20) xor
                             DataOut(22) xor DataOut(24) xor DataOut(26) xor
                             DataOut(28) xor DataOut(32) xor DataOut(33) xor
                             DataOut(34) xor DataOut(36) xor DataOut(38) xor
                             DataOut(40) xor DataOut(42) xor DataOut(44) xor
                             DataOut(48) xor DataOut(49) xor DataOut(50) xor
                             DataOut(52) xor DataOut(54) xor DataOut(56) xor
                             DataOut(58) xor DataOut(60);
      CheckOut(2)   <=  not (DataOut(0)  xor DataOut(3)  xor DataOut(4)  xor
                             DataOut(7)  xor DataOut(9)  xor DataOut(10) xor
                             DataOut(13) xor DataOut(15) xor DataOut(16) xor
                             DataOut(19) xor DataOut(20) xor DataOut(23) xor
                             DataOut(25) xor DataOut(26) xor DataOut(29) xor
                             DataOut(31) xor DataOut(32) xor DataOut(35) xor
                             DataOut(36) xor DataOut(39) xor DataOut(41) xor
                             DataOut(42) xor DataOut(45) xor DataOut(47) xor
                             DataOut(48) xor DataOut(51) xor DataOut(52) xor
                             DataOut(55) xor DataOut(57) xor DataOut(58) xor
                             DataOut(61) xor DataOut(63));
      CheckOut(3)   <=  not (DataOut(0)  xor DataOut(1)  xor DataOut(5)  xor
                             DataOut(6)  xor DataOut(7)  xor DataOut(11) xor
                             DataOut(12) xor DataOut(13) xor DataOut(16) xor
                             DataOut(17) xor DataOut(21) xor DataOut(22) xor
                             DataOut(23) xor DataOut(27) xor DataOut(28) xor
                             DataOut(29) xor DataOut(32) xor DataOut(33) xor
                             DataOut(37) xor DataOut(38) xor DataOut(39) xor
                             DataOut(43) xor DataOut(44) xor DataOut(45) xor
                             DataOut(48) xor DataOut(49) xor DataOut(53) xor
                             DataOut(54) xor DataOut(55) xor DataOut(59) xor
                             DataOut(60) xor DataOut(61));
      CheckOut(4)   <=       DataOut(2)  xor DataOut(3)  xor DataOut(4)  xor
                             DataOut(5)  xor DataOut(6)  xor DataOut(7)  xor
                             DataOut(14) xor DataOut(15) xor DataOut(18) xor
                             DataOut(19) xor DataOut(20) xor DataOut(21) xor
                             DataOut(22) xor DataOut(23) xor DataOut(30) xor
                             DataOut(31) xor DataOut(34) xor DataOut(35) xor
                             DataOut(36) xor DataOut(37) xor DataOut(38) xor
                             DataOut(39) xor DataOut(46) xor DataOut(47) xor
                             DataOut(50) xor DataOut(51) xor DataOut(52) xor
                             DataOut(53) xor DataOut(54) xor DataOut(55) xor
                             DataOut(62) xor DataOut(63);
      CheckOut(5)   <=       DataOut(8)  xor DataOut(9)  xor DataOut(10) xor
                             DataOut(11) xor DataOut(12) xor DataOut(13) xor
                             DataOut(14) xor DataOut(15) xor DataOut(24) xor
                             DataOut(25) xor DataOut(26) xor DataOut(27) xor
                             DataOut(28) xor DataOut(29) xor DataOut(30) xor
                             DataOut(31) xor DataOut(40) xor DataOut(41) xor
                             DataOut(42) xor DataOut(43) xor DataOut(44) xor
                             DataOut(45) xor DataOut(46) xor DataOut(47) xor
                             DataOut(56) xor DataOut(57) xor DataOut(58) xor
                             DataOut(59) xor DataOut(60) xor DataOut(61) xor
                             DataOut(62) xor DataOut(63);
      CheckOut(6)   <=       DataOut(0)  xor DataOut(1)  xor DataOut(2)  xor
                             DataOut(3)  xor DataOut(4)  xor DataOut(5)  xor
                             DataOut(6)  xor DataOut(7)  xor DataOut(24) xor
                             DataOut(25) xor DataOut(26) xor DataOut(27) xor
                             DataOut(28) xor DataOut(29) xor DataOut(30) xor
                             DataOut(31) xor DataOut(32) xor DataOut(33) xor
                             DataOut(34) xor DataOut(35) xor DataOut(36) xor
                             DataOut(37) xor DataOut(38) xor DataOut(39) xor
                             DataOut(56) xor DataOut(57) xor DataOut(58) xor
                             DataOut(59) xor DataOut(60) xor DataOut(61) xor
                             DataOut(62) xor DataOut(63);
      CheckOut(7)   <=       DataOut(0)  xor DataOut(1)  xor DataOut(2)  xor
                             DataOut(3)  xor DataOut(4)  xor DataOut(5)  xor
                             DataOut(6)  xor DataOut(7)  xor DataOut(24) xor
                             DataOut(25) xor DataOut(26) xor DataOut(27) xor
                             DataOut(28) xor DataOut(29) xor DataOut(30) xor
                             DataOut(31) xor DataOut(40) xor DataOut(41) xor
                             DataOut(42) xor DataOut(43) xor DataOut(44) xor
                             DataOut(45) xor DataOut(46) xor DataOut(47) xor
                             DataOut(48) xor DataOut(49) xor DataOut(50) xor
                             DataOut(51) xor DataOut(52) xor DataOut(53) xor
                             DataOut(54) xor DataOut(55);
   end EDAC64Hamming;

   -------------------------------------------------------------------------------------------------
   -- This EDAC uses regular (63,57) Hamming code with distance = 3, thus providing only single
   -- error detection and correction capability. Double errors lead to wrong 'corrected' data words
   -- and multiple errors can lead to no error being seen at all.
   -- The coding style is essentially different from the previous EDACs but the principle is the
   -- same, XOR-tree generator matrix for parity calculation, XOR with received parity to get
   -- syndrome, LUT to map syndrome to the 'bit to be corrected'.  
   -------------------------------------------------------------------------------------------------
   procedure EDAC57 (
      signal   DataOut:       in    Word57;              -- Data bits to be encoded
      signal   CheckOut:      out   Word6;               -- Encoded check bits

      signal   DataIn:        in    Word57;              -- Data bits to be decoded
      signal   CheckIn:       in    Word6;               -- Check bits to be decoded

      signal   DataCorr:      out   Word57;              -- Corrected data bits
      signal   SingleErr:     out   Std_ULogic           -- Single error flag
      ) is

     variable parity, syndrome : Word6;
     variable synint : integer;         -- syndrome converted to integer
     type gtype is array (0 to 56) of Word6;  -- generator matrix type
     type ltype is array (1 to 63) of integer;  -- LUT type
     constant G : gtype := (   -- Generator Matrix
       ( '1', '1', '1', '1', '1', '1' ), ( '1', '1', '1', '1', '1', '0' ), ( '1', '1', '1', '1', '0', '1' ),
       ( '1', '1', '1', '0', '1', '1' ), ( '1', '1', '1', '1', '0', '0' ), ( '1', '1', '1', '0', '1', '0' ),
       ( '1', '1', '1', '0', '0', '1' ), ( '1', '1', '0', '1', '1', '1' ), ( '1', '1', '0', '1', '1', '0' ),
       ( '1', '1', '0', '1', '0', '1' ), ( '1', '1', '0', '0', '1', '1' ), ( '1', '1', '1', '0', '0', '0' ),
       ( '1', '1', '0', '1', '0', '0' ), ( '1', '1', '0', '0', '1', '0' ), ( '1', '1', '0', '0', '0', '1' ),
       ( '1', '0', '1', '1', '1', '1' ), ( '1', '0', '1', '1', '1', '0' ), ( '1', '0', '1', '1', '0', '1' ),
       ( '1', '0', '1', '0', '1', '1' ), ( '1', '0', '1', '1', '0', '0' ), ( '1', '0', '1', '0', '1', '0' ),
       ( '1', '0', '1', '0', '0', '1' ), ( '1', '0', '0', '1', '1', '1' ), ( '1', '0', '0', '1', '1', '0' ),
       ( '1', '0', '0', '1', '0', '1' ), ( '1', '0', '0', '0', '1', '1' ), ( '1', '1', '0', '0', '0', '0' ),
       ( '1', '0', '1', '0', '0', '0' ), ( '1', '0', '0', '1', '0', '0' ), ( '1', '0', '0', '0', '1', '0' ),
       ( '1', '0', '0', '0', '0', '1' ), ( '0', '1', '1', '1', '1', '1' ), ( '0', '1', '1', '1', '1', '0' ),
       ( '0', '1', '1', '1', '0', '1' ), ( '0', '1', '1', '0', '1', '1' ), ( '0', '1', '1', '1', '0', '0' ),
       ( '0', '1', '1', '0', '1', '0' ), ( '0', '1', '1', '0', '0', '1' ), ( '0', '1', '0', '1', '1', '1' ),
       ( '0', '1', '0', '1', '1', '0' ), ( '0', '1', '0', '1', '0', '1' ), ( '0', '1', '0', '0', '1', '1' ),
       ( '0', '1', '1', '0', '0', '0' ), ( '0', '1', '0', '1', '0', '0' ), ( '0', '1', '0', '0', '1', '0' ),
       ( '0', '1', '0', '0', '0', '1' ), ( '0', '0', '1', '1', '1', '1' ), ( '0', '0', '1', '1', '1', '0' ),
       ( '0', '0', '1', '1', '0', '1' ), ( '0', '0', '1', '0', '1', '1' ), ( '0', '0', '1', '1', '0', '0' ),
       ( '0', '0', '1', '0', '1', '0' ), ( '0', '0', '1', '0', '0', '1' ), ( '0', '0', '0', '1', '1', '1' ),
       ( '0', '0', '0', '1', '1', '0' ), ( '0', '0', '0', '1', '0', '1' ), ( '0', '0', '0', '0', '1', '1' )
       );

     -- The LUT is the generator matrix, converted to decimal (left bit = MSB) and de-referenced
     -- i.e. G(0) = 111111 = 63 =>  LUT(63)=0, G(1) = 111110 = 62 => LUT(62) = 1   etc. etc.
     constant LUT : ltype := (
       62, 61, 56, 60, 55, 54, 53, 59, 52, 51, 49, 50, 48, 47, 46, 58, 45, 44, 41, 43, 40,
       39, 38, 42, 37, 36, 34, 35, 33, 32, 31, 57, 30, 29, 25, 28, 24, 23, 22, 27, 21, 20,
       18, 19, 17, 16, 15, 26, 14, 13, 10, 12,  9,  8,  7, 11,  6,  5,  3,  4,  2,  1,  0
       );
       
   begin
     -- calculate parity and syndrome of data to be decoded
     for i in 0 to 5 loop
       parity(i) := '0';
       for j in 0 to 56 loop
         if G(j)(i) = '1' then
           parity(i) := parity(i) xor DataIn(j);
         end if;
       end loop;  -- j
       syndrome(i) := parity(i) xor CheckIn(i);
     end loop;  -- i
     synint := conv_integer(syndrome);  -- converts left-to-right, so syndrome(0) is the MSB

     -- Correct data
     DataCorr <= DataIn;                -- default uncorrected value
     if synint /= 0 then
       if LUT(synint) < 57 then         -- correcting only data errors
         DataCorr(LUT(synint)) <= not DataIn(LUT(synint));
       end if;
       SingleErr <= '1';
     else
       SingleErr <= '0';
     end if;

     -- calculate parity of data to be encoded
     for i in 0 to 5 loop
       parity(i) := '0';
       for j in 0 to 56 loop
         if G(j)(i) = '1' then
           parity(i) := parity(i) xor DataOut(j);
         end if;
       end loop;  -- j
       CheckOut(i) <= parity(i);
     end loop;  -- i
     
   end EDAC57;

     
   
end EDAC; --==================================================================--
