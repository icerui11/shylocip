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
-- Design unit  : Finished generation
--
-- File name    : header123_gen.vhd
--
-- Purpose      : Generates header for the 123 encoder
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
use ieee.numeric_std.all; 

library shyloc_123; 
--use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all;

library shyloc_utils;    
use shyloc_utils.shyloc_functions.all;
use shyloc_utils.amba.all;


--library grlib;
--use grlib.testlib.all;

--!@file #header123_gen.vhd#
-- File history:
--      v1.0: 16/03/2015: Preliminary black box. 
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Generates header for the 123 encoder

entity header123_gen  is
  generic (
    HEADER_ADDR: integer := 5;            --! Bit width of the image header pointer.
    W_BUFFER_GEN: integer := 32;          --! Bit width of the output buffer. It has to be always greater than the maximum possible bit width of the codewords (U_MAX + DRANGE).
    PREDICTION_TYPE : integer := 0;          --! Prediction architecture (0) BIP (1) BIP-MEM (2) BSQ (3) BIL (4) BIL-MEM.
    W_NBITS_HEAD_GEN: integer := 6;         --! Bit width of the signal which represents the number of bits of each codeword.
    RESET_TYPE: integer := 1;           --! Reset flavour (0) asynchronous (1) synchronous.
    MAX_HEADER_SIZE : integer := 19;        --! Maximum bytes in the header.
    Nz_GEN: integer := 224;             --! Number of bands the core is configured for.
    Q_GEN:  integer := 5;             --! Resolution of custom weigths (functionality not included).
    W_MAX_HEADER_SIZE : integer := 7;       --! Bit width of the value storing the W_MAX_HEADER_SIZE.
    WEIGHT_INIT_GEN : integer := 0;         --! Selection of weight initialitazion type (functionality not included).
    ENCODING_TYPE: integer := 1;          --! Select if sample-adaptive encoder is instantiated.
    ACC_INIT_TYPE_GEN: integer := 0         --! Selection of accumulator initialization table.
    );
  port 
    (
      Clk: in std_logic;            --! Clock
      Rst_N: in std_logic;          --! Reset signal (active low)
      clear: in std_logic;          --! Asynchronous clear
      config_image_in: in config_123_image;     --! Image metadata configuration values
      config_predictor_in: in config_123_predictor; --! Predictor configuration values
      config_sample_in: in config_123_sample;     --! Sample-adaptive configuration values
      config_weight_tab_in: in weight_tab_type;   --! Custom weight initialization table values (functionality not included)
      config_received: in Std_Logic;          --! If High, the configuration has been received.
      dispatcher_ready: in std_logic;         --! Output dispatcher can accept header values.
      header_out: out std_logic_vector(W_BUFFER_GEN-1 downto 0);        --! Header value to be sent to the dispatcher module. Already packed in W_BUFFER_resolved bits.
      header_out_valid: out std_logic;                    --! Validates the data in header_out.
      n_bits: out std_logic_vector (W_NBITS_HEAD_GEN-1 downto 0));      --! Number of bits of the header output.
    
end header123_gen;


library shyloc_123; 
--use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all;

library shyloc_utils;   
use shyloc_utils.shyloc_functions.all;

architecture arch of header123_gen is

  -- Array type to group header in bytes
  type array_type is array (0 to MAX_HEADER_SIZE-1) of std_logic_vector (7 downto 0);     
  signal header: array_type := (others => (others => '0'));
  
  -- Modules of values that need to be stored in the header
  signal Nx_mod, Ny_mod, Nz_mod: std_logic_vector(15 downto 0);
  signal D_mod: std_logic_vector(3 downto 0);
  signal M_mod: std_logic_vector(15 downto 0);
  signal B_mod: std_logic_vector(2 downto 0);
  signal R_mod: std_logic_vector(5 downto 0);
  signal U_mod: std_logic_vector(4 downto 0);
  signal init_count_e_mod: std_logic_vector(2 downto 0);
  
  --signal n_bytes_weight_tab: integer;
  signal counter_local: unsigned (W_MAX_HEADER_SIZE-1 downto 0);
   --remainding byes  to be sent
  signal rem_bytes: unsigned(W_MAX_HEADER_SIZE-1 downto 0);
  --Total number of bytes in the output buffer.
  signal N_BYTES : unsigned(W_MAX_HEADER_SIZE-1 downto 0);
  
  -- max possible number of bytes in the output buffer
  constant MAX_N_BYTES : integer := W_BUFFER_GEN/8; 
  
   --maximum possible number of remainding byes
  constant MAX_REMAINDER: integer := MAX_N_BYTES-1;
  constant MAX_header_weight_table_bytes: integer := ceil((Q_GEN*19),8);
  constant MAX_acc_table_bytes: integer := ceil((Nz_GEN*4),8);
  signal ini: std_logic := '1';
  -- NUMBER OF BITS THE HEADER IS PACKED WITH
  signal W_BUFFER_resolved: std_logic_vector (W_W_BUFFER_GEN-1 downto 0);
begin
  -----------------------------------------------------------------------
  -- Selection of number of valid bits in header output according to configuration
  -----------------------------------------------------------------------
  -- If CCSDS121 entropy coder is to be used (config_image_in.ENCODER_SELECTION = "10") use D (same as residuals)
  -- Otherwise, use the configured W_BUFFER value.
  W_BUFFER_resolved <= std_logic_vector(to_unsigned(8, W_BUFFER_resolved'length))
            when (config_image_in.ENCODER_SELECTION = "10" and  to_integer(unsigned(config_image_in.D)) <= 8 ) else 
            std_logic_vector(to_unsigned(16, W_BUFFER_resolved'length))
            when config_image_in.ENCODER_SELECTION = "10" and  to_integer(unsigned(config_image_in.D)) <= 16 else config_image_in.W_BUFFER;
            
  -----------------------------------------------------------------------
  -- Calculate modulos
  -----------------------------------------------------------------------
  Nx_mod <= std_logic_vector(to_signed(modulo(to_integer(unsigned(config_image_in.Nx)), 2**16), 16));
  Ny_mod <= std_logic_vector(to_signed(modulo(to_integer(unsigned(config_image_in.Ny)), 2**16), 16));
  Nz_mod <= std_logic_vector(to_signed(modulo(to_integer(unsigned(config_image_in.Nz)), 2**16), 16));
  D_mod <= std_logic_vector(to_signed(modulo(to_integer(unsigned(config_image_in.D)), 2**4), 4));
  M_mod <= std_logic_vector(to_unsigned(modulo(to_integer(unsigned(config_image_in.Nz)), 2**16), 16)) when (PREDICTION_TYPE = 0 or PREDICTION_TYPE = 1) else
      -- Modified by AS: PREDICTION_TYPE = 4 (BIL-MEM) included
       std_logic_vector(to_unsigned(modulo(to_integer(to_unsigned(1, 16)), 2**16), 16)) when (PREDICTION_TYPE = 3 or PREDICTION_TYPE = 4) else
      -----------------------------
       std_logic_vector(to_unsigned(modulo(to_integer(to_unsigned(0, 16)), 2**16), 16));
  B_mod <= std_logic_vector(to_signed(modulo(to_integer(unsigned(config_image_in.W_BUFFER)/8), 2**3), 3));
  R_mod <= std_logic_vector(to_signed(modulo(to_integer(unsigned(config_predictor_in.R)), 2**6), 6));
  U_mod <= std_logic_vector(to_signed(modulo(to_integer(unsigned(config_sample_in.U_MAX)), 2**5), 5));
  init_count_e_mod <= std_logic_vector(to_signed(modulo(to_integer(unsigned(config_sample_in.INIT_COUNT_E)), 2**3), 3));

  -----------------------------------------------------------------------         
  -- Combinatorial process to generate the header.
  -----------------------------------------------------------------------
  header_cmb: process(config_image_in, config_predictor_in, config_sample_in, config_received, Nx_mod, Ny_mod, Nz_mod, D_mod, M_mod, B_mod, R_mod, U_mod, init_count_e_mod) 
    variable tab_index: integer := 0;
    variable wb_index: integer := 0;
    variable header_weight_table_bytes : integer := 0;
    variable MAX_header_weight_table_bytes_conf: integer := 0;
    variable max_bits_weight : integer := 0;
    variable MAX_acc_table_bytes_conf: integer := 0;
    variable max_bits_acc : integer := 0;
  begin
    header <= (others => (others => '0'));
    if (config_received = '1') then
    
      MAX_header_weight_table_bytes_conf:= 0;
      MAX_acc_table_bytes_conf:= 0;
      
      -- IMAGE METADATA
      header(0) <= (others => '0');
      
      header(1)(7 downto 0) <= Nx_mod(15 downto 8);
      header(2)(7 downto 0) <= Nx_mod(7 downto 0);
      
      header(3)(7 downto 0) <= Ny_mod(15 downto 8);
      header(4)(7 downto 0) <= Ny_mod(7 downto 0);
      
      header(5)(7 downto 0) <= Nz_mod(15 downto 8);
      header(6)(7 downto 0) <= Nz_mod(7 downto 0);
      
      header(7)(7 downto 7) <= config_image_in.IS_SIGNED(0 downto 0);
      header(7)(6 downto 5) <= "00";
      header(7)(4 downto 1) <= D_mod;
      
      if (PREDICTION_TYPE = 2) then
        header(7)(0) <= '1';
      else
        header(7)(0) <= '0';
      end if;
      
      header(8)(7 downto 0) <= M_mod(15 downto 8);
      header(9)(7 downto 0) <= M_mod(7 downto 0);
      
      header(10)(7 downto 6) <= "00";
      header(10)(5 downto 3) <= B_mod;
      if (unsigned(config_image_in.ENCODER_SELECTION) = 2) then
        header(10)(2 downto 2) <= std_logic_vector(to_unsigned(1, 1));
      else --if (ENCODING_TYPE = 1 and unsigned(config_in.ENCODER_SELECTION) = 1) then
        header(10)(2 downto 2) <= std_logic_vector(to_unsigned(0, 1));
      end if;
      header(10)(1 downto 0) <= "00";
      
      header(11)(7 downto 0) <= (others => '0');
      
      -- PREDICTOR METADATA
      header(12)(7 downto 6) <= "00";
      header(12)(5 downto 2) <= std_logic_vector(resize(unsigned(config_predictor_in.P), 4));
      header(12)(1 downto 1) <= config_predictor_in.PREDICTION;
      header(12)(0) <= '0';
      
      header(13)(7 downto 7) <= config_predictor_in.LOCAL_SUM;
      header(13)(6) <= '0';
      header(13)(5 downto 0) <= R_mod;
      
      header(14)(7 downto 4) <= std_logic_vector(resize((unsigned(config_predictor_in.OMEGA) - 4), 4));
      
      --We give as input the exponent of the TINC, so the log2 is not needed
      header(14)(3 downto 0) <= std_logic_vector(resize(unsigned(config_predictor_in.TINC) -4, 4));
      
      header(15)(7 downto 4) <= std_logic_vector(resize(unsigned(signed(config_predictor_in.VMIN) + to_signed(6, 4)), 4));
      header(15)(3 downto 0) <= std_logic_vector(resize(unsigned(signed(config_predictor_in.VMAX) + to_signed(6, 4)), 4));
      
      header(16)(7) <= '0';
      --Custom weights generatio of header not included yet. Lines left commented for future developments.
  --    if (unsigned(config_predictor_in.WEIGHT_INIT) = 0) then
        header(16)(6 downto 5) <= "00";
        header(16)(4 downto 0) <= (others => '0');
        
  --    else
  --      MAX_header_weight_table_bytes_conf:= ceil((to_integer(unsigned(config_predictor_in.Q))*19),8);
  --      header(16)(6 downto 5) <= "11";
  --      header(16)(4 downto 0) <= std_logic_vector(resize(unsigned(config_predictor_in.Q), 5));
        -- WEIGHT INIT TABLE (depending on... what parameter?)
  --      tab_index:= 0;
  --      wb_index := to_integer(unsigned(config_predictor_in.Q) - 1);
  --      max_bits_weight:= (to_integer(unsigned(config_predictor_in.Q))*19);
  --      for header_index in 1 to MAX_header_weight_table_bytes loop   -- Maximum number of header words fr WEIGHT_TAB
  --        for bit_index in 7 downto 0 loop                -- Size of each header word
  --          if (header_index <= MAX_header_weight_table_bytes_conf) then
  --            if (((header_index-1)*8+(8-bit_index)) <= max_bits_weight) then
  --              header(16 + header_index)(bit_index) <= config_weight_tab_in(tab_index)(wb_index);
  --            else
  --              header(16 + header_index)(bit_index) <= '0';
  --            end if;
  --            if (wb_index = 0) then                  
  --              if (tab_index = 18) then                  -- Weight tab entrance end
  --                -- Weight table ending
  --              else                          
  --                wb_index := to_integer(unsigned(config_predictor_in.Q) - 1);    -- Next weight tab entrance
  --                tab_index := tab_index + 1;
  --              end if;
  --            else
  --              wb_index := wb_index - 1;                 -- Next bit
  --            end if;
  --          end if;
  --        end loop;
  --      end loop;
  --    end if;
      
      -- ENTROPY CODER METADATA
      if (ENCODING_TYPE = 1 and unsigned(config_image_in.ENCODER_SELECTION) = 1) then
        header(16 + MAX_header_weight_table_bytes + 1)(7 downto 3) <= U_mod;
        header(16 + MAX_header_weight_table_bytes + 1)(2 downto 0) <= std_logic_vector(resize(unsigned(config_sample_in.RESC_COUNT_SIZE) - to_unsigned(4, 3), 3));
        
        header(16 + MAX_header_weight_table_bytes + 2)(7 downto 5) <= init_count_e_mod;
        if (unsigned(config_sample_in.ACC_INIT_TYPE) = 0) then
          header(16 + MAX_header_weight_table_bytes + 2)(4 downto 1) <= std_logic_vector(resize(unsigned(config_sample_in.ACC_INIT_CONST), 4));
        else 
          header(16 + MAX_header_weight_table_bytes + 2)(4 downto 1) <= std_logic_vector(to_unsigned(1, 4));
        end if;
        header(16 + MAX_header_weight_table_bytes + 2)(0 downto 0) <= config_sample_in.ACC_INIT_TYPE;
        -- Generation of accumulator table for sample-adaptive in header not included yet. Lines left commented for future developments. 
      --  if (unsigned(config_sample_in.ACC_INIT_TYPE) = 1 and ACC_INIT_TYPE_GEN = 1) then
      --    MAX_acc_table_bytes_conf := ceil((to_integer(unsigned(config_image_in.Nz))*4),8);
      --    tab_index:= 0;
      --    wb_index := 3;
      --    max_bits_acc:= (to_integer(unsigned(config_image_in.Nz))*4);
      --    for header_index in 1 to MAX_acc_table_bytes loop   -- Maximum number of header words for ACC_TAB
      --      for bit_index in 7 downto 0 loop                -- Size of each header word
      --        if (header_index <= MAX_acc_table_bytes_conf) then
      --          if (((header_index-1)*8+(8-bit_index)) <= max_bits_acc) then
      --            header(16 + MAX_header_weight_table_bytes + 2 + header_index)(bit_index) <= ACC_TAB_GEN(tab_index)(wb_index);
      --          else
      --            header(16 + MAX_header_weight_table_bytes + 2 + header_index)(bit_index) <= '0';
      --          end if;
      --          if (wb_index = 0) then                  
      --            if (tab_index = unsigned(config_image_in.Nz)-1) then              -- Weight tab entrance end
            -- Weight table ending
      --            else                          
      --              wb_index := 3;    -- Next acc tab entrance
      --              tab_index := tab_index + 1;
      --            end if;
      --          else
      --            wb_index := wb_index - 1;                 -- Next bit
      ----          end if;
      --        end if;
      --      end loop;
      --    end loop; 
      --  end if;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------
  -- Process to send one valid header value every clk cycle. 
  -----------------------------------------------------------------------
  process(Clk, Rst_N)
    variable pointer_high: integer :=0;
    variable pointer_low: integer := 0;
    variable header_out_tmp: std_logic_vector(W_BUFFER_GEN-1 downto 0) := (others => '0');
    variable shift_bits: unsigned(6 downto 0) := (others => '0');
    variable byte_pointer : unsigned (W_MAX_HEADER_SIZE-1 downto 0) := (others => '0');
    variable header_final_size : unsigned (rem_bytes'high downto 0) := to_unsigned(17, rem_bytes'length);
    variable ACTUAL_HEADER_SIZE : unsigned (rem_bytes'high downto 0); 
    variable MAX_header_weight_table_bytes_conf: integer := 0;
    variable MAX_acc_table_bytes_conf: integer := 0;
    variable data: integer := 0;
    variable data_u: unsigned (W_MAX_HEADER_SIZE-1 downto 0) := (others => '0');
    variable data_i: integer := 0;
    variable curr_counter: unsigned(W_MAX_HEADER_SIZE-1 downto 0) := (others => '0');
  begin
    if (Rst_N = '0'and RESET_TYPE = 0) then
      header_out <= (others => '0');
      header_out_valid <= '0';
      n_bits <= (others => '0');
      counter_local <= (others => '0');
      rem_bytes <= (others => '0');
      N_BYTES <= (others => '0');
      ini <= '1';
    elsif (Clk'Event and Clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE = 1)) then
        header_out <= (others => '0');
        header_out_valid <= '0';
        n_bits <= (others => '0');
        counter_local <= (others => '0');
        rem_bytes <= (others => '0');
        N_BYTES <= (others => '0');
        ini <= '1';
      else
        n_bits <= (others => '0');
        header_out_valid <= '0';
        header_final_size := to_unsigned(17, rem_bytes'length); 
        if (config_received = '1' and ini = '1') then
          -- header size calculation
          if (ENCODING_TYPE = 1 and unsigned(config_image_in.ENCODER_SELECTION) = 1 and unsigned(config_image_in.DISABLE_HEADER) = 0) then
          -- Generation of accumulator table for sample-adaptive in header not included yet. Lines left commented for future developments. 
          --  if (unsigned(config_sample_in.ACC_INIT_TYPE) = 1 and ACC_INIT_TYPE_GEN = 1) then
          --    data := ceil(to_integer(unsigned(config_image_in.Nz)*4), 8);
          --    ACTUAL_HEADER_SIZE := header_final_size + 2 + ceil(to_integer(unsigned(config_image_in.Nz)*4), 8);
          --  else
              ACTUAL_HEADER_SIZE := header_final_size + 2;
          --  end if;
          else
            ACTUAL_HEADER_SIZE := header_final_size;
          end if;
        --Custom weights generatio of header not included yet. Lines left commented for future developments.
        --  if (unsigned(config_predictor_in.WEIGHT_INIT) = 1 and WEIGHT_INIT_GEN = 1) then
        --    data_u := (unsigned(resize(unsigned(config_predictor_in.Q), W_MAX_HEADER_SIZE)));
        --    data_i := to_integer(data_u*19);          
        --    data := ceil(data_i, 8);
        --    ACTUAL_HEADER_SIZE := ACTUAL_HEADER_SIZE + data;
        --  end if;
          ini <= '0';
          rem_bytes <= ACTUAL_HEADER_SIZE;
          N_BYTES <= resize((unsigned(W_BUFFER_resolved(W_W_BUFFER_GEN-1 downto 0)) srl 3), N_BYTES'length);
          -- Encoding of accumulator table for sample-adaptive in header not included yet. Lines left commented for future developments. 
          -- if (unsigned(config_sample_in.ACC_INIT_TYPE) = 1 and ACC_INIT_TYPE_GEN = 1) then
          --  MAX_acc_table_bytes_conf := ceil((to_integer(unsigned(config_image_in.Nz))*4),8);
          -- else 
          --  MAX_acc_table_bytes_conf := 0;
          -- end if;
          MAX_header_weight_table_bytes_conf:= 0;
          -- Encoding of custom weight table not included yet. Lines left commented for future developments. 
          -- if (unsigned(config_predictor_in.WEIGHT_INIT) = 1 and WEIGHT_INIT_GEN = 1) then
          --  MAX_header_weight_table_bytes_conf:= ceil((to_integer(unsigned(config_predictor_in.Q))*19),8);
          -- else 
          --  MAX_header_weight_table_bytes_conf:= 0;
          -- end if;
        elsif (rem_bytes > 0 and unsigned(config_image_in.DISABLE_HEADER) = 0 and dispatcher_ready = '1') then --assumes config has been received
          n_bits <= (others => '0');
          header_out_valid <= '0';
          if (rem_bytes >= N_BYTES) then
            header_out_tmp := (others => '0');
            for i in 0 to MAX_N_BYTES-1 loop
              if (i = 0) then
                curr_counter := counter_local;
              end if;
              if (i = N_BYTES) then   
                exit;
              end if;
              byte_pointer := resize(curr_counter, byte_pointer'length) + to_unsigned(i, byte_pointer'length);
              
              -- Encoding of custom weight table not included yet. Lines left commented for future developments. 
              --if ((to_integer(byte_pointer) >= (16 + MAX_header_weight_table_bytes_conf +1)) and (to_integer(byte_pointer) <= (16 + MAX_header_weight_table_bytes))) then
              --  if (curr_counter = counter_local) then
              --    curr_counter := unsigned(to_signed(MAX_header_weight_table_bytes + 16 + 1, curr_counter'length)) - i;
              --  end if;
              --  byte_pointer := resize(curr_counter, byte_pointer'length) + to_unsigned(i, byte_pointer'length);
              --end if;
              
              header_out_tmp := std_logic_vector(shift_left(unsigned(header_out_tmp),8));
              header_out_tmp (7 downto 0) := header(to_integer(byte_pointer));
            end loop;
            header_out <= std_logic_vector (header_out_tmp);
            header_out_valid <= '1';
            counter_local <= curr_counter + resize(N_BYTES, counter_local'length);
            rem_bytes <= rem_bytes - N_BYTES;
            n_bits <= std_logic_vector(resize(unsigned(W_BUFFER_resolved), W_NBITS_HEAD_GEN));
          else  
            --this is not really needed as long as the n_bits are calculated correctly
            header_out_tmp := (others => '0');
            for i in 0 to MAX_REMAINDER-1 loop
              if (i = 0) then
                curr_counter := counter_local;
              end if;
              if (i = rem_bytes) then
                exit;
              end if;
              byte_pointer := resize(curr_counter, byte_pointer'length) + to_unsigned(i, byte_pointer'length);
              
              if ((to_integer(byte_pointer) >= (16 + MAX_header_weight_table_bytes_conf +1)) and (to_integer(byte_pointer) <= (16 + MAX_header_weight_table_bytes))) then
                if (curr_counter = counter_local) then
                  curr_counter := unsigned(to_signed(MAX_header_weight_table_bytes + 16 + 1, curr_counter'length)) - i;
                end if;
                byte_pointer := resize(curr_counter, byte_pointer'length) + to_unsigned(i, byte_pointer'length);
              end if;
              
              header_out_tmp := std_logic_vector(shift_left(unsigned(header_out_tmp),8));
              header_out_tmp (7 downto 0) := header(to_integer(byte_pointer));
            end loop;
            header_out <= std_logic_vector (header_out_tmp);
            header_out_valid <= '1';
            n_bits <= std_logic_vector(resize(rem_bytes*8, n_bits'length));
            rem_bytes <= (others => '0');
          end if;
        end if;                                         
      end if;
    end if;
  end process;
end arch;
    
    
    
    