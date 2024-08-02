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
-- Design unit  : ccsds_shyloc_tb Testbench for CCSDS-123
--
-- File name    : ccsds_shyloc_tb.vhd
--
-- Purpose      : Takes care of setting off configuration values, provide input samples and control signals received from the the IP core.
--
-- Note         :
--
-- Library      : work
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

--!@file #ccsds_shyloc_tb.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  Takes care of setting off configuration values, provide input samples and control signals received from the the IP core.

--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;

--! Use standard library
library std;
--! Use user input/output
use std.textio.all;
use ieee.std_logic_textio.all;
--! Use finish and stop
use std.env.all;

use work.ccsds_ahbtbp.all;
use work.ahbtbp.all;

--! Use shyloc_123 library

library post_syn_lib;
--! Use testbench 123_parameters
use work.ccsds123_tb_parameters.all;
--! Use shyloc_123 ahb types
library shyloc_123;
use shyloc_123.ccsds_ahb_types.all;
--! Use shyloc_123 configuration package
use shyloc_123.config123_package.all;




--! Use grlib library and elements
library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
use grlib.devices.all;

--! Use shyloc_utils library and elements
library shyloc_utils;
use shyloc_utils.amba.all;
use shyloc_utils.shyloc_functions.all;

--! ccsds_shyloc_tb entity Takes care of setting off configuration values, provide input samples and control signals received from the the IP core.
entity ccsds_shyloc_tb is
end ccsds_shyloc_tb;

--! @brief Architecture of ccsds_shyloc_tb 
architecture arch of ccsds_shyloc_tb is
  
  -- Clock and reset signals
  signal clk, rst_n, clk_ahb, rst_ahb: std_logic;
  
  signal DataIn, s: std_logic_vector (D_G_tb-1 downto 0);
  signal DataIn_NewValid, s_valid: std_logic;
  signal ls_out: std_logic_vector (W_LS_G_tb-1 downto 0);
  signal sign: std_logic;
  signal counter: unsigned(4 downto 0);
  signal counter_samples: unsigned (31 downto 0);
  
  
  signal msto: grlib.amba.ahb_mst_out_vector;
  signal slvo: grlib.amba.ahb_slv_out_vector;

  signal ahbmi: grlib.amba.ahb_mst_in_type;       --testbench
  signal ahbmo: grlib.amba.ahb_mst_out_type;
  
  signal ctrl  : work.ahbtbp.ahbtb_ctrl_type;
  signal ahbsi: grlib.amba.ahb_slv_in_type;
  signal ahbso: grlib.amba.ahb_slv_out_type;
  
  --for configuration
  signal AHBSlave123_In: shyloc_utils.amba.ahb_slv_in_type;
  signal AHBSlave123_Out: shyloc_utils.amba.ahb_slv_out_type;
  
  signal AHBMaster123_In: shyloc_utils.amba.ahb_mst_in_type; --shyloc
  signal AHBMaster123_Out: shyloc_utils.amba.ahb_mst_out_type;
  
  signal config_valid: std_logic; 
  
  -- Control signals connected to the IP
  signal AwaitingConfig: Std_Logic;                 --! The IP core is waiting to receive the configuration.
  signal Ready: Std_Logic;                    --! Configuration has been received and the IP is ready to receive new samples.
  signal FIFO_Full: Std_Logic;                  --! The input FIFO is full.
  signal ForceStop : std_logic;                 --! Stop the compression
  signal ForceStop_i : std_logic;                 --! Stop the compression
  signal EOP: Std_Logic;                      --! Compression of last sample has started.
  signal Finished: Std_Logic;                   --! The IP has finished compressing all samples.
  signal Error_s: Std_Logic;                    --! There has been an error during the compression
  signal DataOut: Std_Logic_Vector (W_BUFFER_G_tb-1 downto 0); 
  signal DataOut_Valid: Std_Logic; 
  signal IsHeaderOut: Std_Logic;                  --! The data in DataOut corresponds to the header when the core is working as a pre-processor.
  signal NbitsOut: Std_Logic_Vector (5 downto 0);         --! Number of valid bits in the DataOut signal

  signal  AwaitingConfig_Ext: Std_Logic;              --! The IP core is waiting to receive the configuration.
  signal  Ready_Ext: Std_Logic;                   --! Configuration has been received and the IP is ready to receive new samples.
  signal  FIFO_Full_Ext: Std_Logic;                 --! The input FIFO is full.
  signal  EOP_Ext: Std_Logic;                   --! Compression of last sample has started.
  signal  Finished_Ext: Std_Logic;                --! The IP has finished compressing all samples.
  signal  Error_Ext: Std_Logic;                   --! There has been an error during the compression  
  
  signal clear: std_logic;
  
  -- File handlers
  type bin_file_type is file of character;
  file stimulus: bin_file_type;
  file reference: bin_file_type;
  file output: bin_file_type;
  type ref_value_byte_type is array (0 to 7) of natural;
  signal ForceStop_reg: std_logic;  
  
  -- FOR 05_test (second files are different) (not global because it is the only one using two different stimulus and reference files)
  constant sec_stim_file: string := "../images/raw/artifacts_h8w7b17_8int_le.bip";
  constant sec_ref_file: string := "../images/reference/comp_20.esa";
  
  signal Nx_conf_test     : integer;
  signal Nz_conf_test     : integer;
  signal D_conf_test      : integer;
  signal ENDIANESS_conf_test  : integer;
  signal config_reg: config_word (0 to N_CONFIG_WORDS-1);
  signal sim_successful: boolean := false;
  
	signal ahb_en : std_logic;		-- Modified by AS: new signal declaration in order to block transactions through AHB bus
	
begin

  
  ---------------------
  --! Clock generation
  ---------------------
  gen_clk: process
  begin
    clk <= '1';
    wait for clk_ip;
    clk <= '0';
    wait for clk_ip;
  end process;
  
  -------------------------
  --! Amba clock generation
  -------------------------
  gen_clk_ahb: process
  begin
    clk_ahb <= '1';
    wait for 50 ns;
    clk_ahb <= '0';
    wait for 50 ns;
  end process;
  
  ---------------------
  --! Reset generation
  ---------------------
  gen_rst: process
  begin
    rst_n <= '0';
    wait for 3000 ns;
    rst_n <= '1';
    wait for 200 ns;
    rst_n <= '1';
    wait;
  end process;
  
  
  ---------------
  --! Assignments
  ---------------
	-- Modified by AS: Ready_Ext generation modified. In test_id 80 this signal is deactivated for several clock cycles
	--Ready_Ext <= '1';
	process
	begin
		Ready_Ext <= '1';
		if (test_id = 80) then
			wait for 50 us;
			Ready_Ext <= '0';
			wait for 10 us;
  Ready_Ext <= '1';
		end if;
		wait;
	end process;
	------------
  sign <= '1';
  rst_ahb <= rst_n;
  
	-- Modified by AS: assignment of new signal ahb_en. This signal is used to block transactions through AHB bus if test_id = 83
	-- The timing of ahb_en depends on the actual architecture
	process
	begin
		ahb_en <= '1';
		if (test_id = 83) then
			if	  (PREDICTION_TYPE_tb = 1) then		-- bip-mem
				wait for 10 us;
				wait until (ahbmi.hgrant(1) = '0');
				ahb_en <= '0';
				wait for 10 us;
				ahb_en <= '1';
				wait for 80 us;
				wait until (ahbmi.hgrant(1) = '0');
				ahb_en <= '0';
				wait for 50 us;
				ahb_en <= '1';
			elsif (PREDICTION_TYPE_tb = 2) then		-- bsq
				wait for 30 us;
				wait until (ahbmi.hgrant(1) = '0');
				ahb_en <= '0';
				wait for 120 us;
				ahb_en <= '1';
				wait for 438000 us;
				wait until (ahbmi.hgrant(1) = '0');
				ahb_en <= '0';
				wait for 100 us;
				ahb_en <= '1';
			elsif (PREDICTION_TYPE_tb = 4) then		-- bil-mem
				wait for 200 us;
				wait until (ahbmi.hgrant(1) = '0');
				ahb_en <= '0';
				wait for 40 us;
				ahb_en <= '1';
				wait for 1140 us;
				wait until (ahbmi.hgrant(1) = '0');
				ahb_en <= '0';
				wait for 60 us;
				ahb_en <= '1';
			end if;
		end if;
		wait;
	end process;
	---------------
	
  ------------------------------------------------------------------------------------------
  --! Process to provide input input samples and control
  --! Read process is perform byte per byte and controlled to obtain the proper input sample
  ------------------------------------------------------------------------------------------
  gen_stim: process (clk, rst_n)
    variable pixel_file: character;
    variable value_high: natural;
    variable value_low: natural;
    variable s_in_var: std_logic_vector (D_G_tb-1 downto 0);    
    variable ini : std_logic := '1';
    variable fin : std_logic := '0';
    variable bound, modul: integer := 0;
    variable send_samples : boolean := false;
  begin
    if (rst_n = '0') then
      s <= (others => '0');
      counter <= (others => '0');
      counter_samples <= (others => '0');
      s_valid <= '0';
      ini := '1';
      ForceStop_reg <= '0';
      fin := '0';
    elsif (clk'event and clk = '1') then
      s_valid <= '0';
      counter <= counter + 1;
      ForceStop_reg <= ForceStop;
      if (Finished = '1' or ForceStop = '1') then
        file_close(stimulus);
        ini := '1';
        counter_samples <= (others => '0');
        fin := '1';
      else
        if (ini = '1') then
          if (test_id = 5 and fin = '1') then
            file_open(stimulus, sec_stim_file, read_mode);
          else
            file_open(stimulus, stim_file, read_mode);
          end if;
          ini := '0';
        else
          if (test_id = 67) then
            if (counter = 0) then
              send_samples := true;
            else
              send_samples := false;
            end if;
          else
            send_samples := true;
          end if;
          bound := Nx_tb*Ny_tb*Nz_tb/16;
          if counter_samples < Nz_conf_test*Nx_conf_test*Ny_tb + 4 then
            if (Ready = '1' and AwaitingConfig = '0' and send_samples = true) then
              if (EN_RUNCFG_G = 0) then
                if (D_G_tb <= 8) then
                  read(stimulus, pixel_file);
                  value_high := character'pos(pixel_file);
                  s_in_var := std_logic_vector(to_unsigned(value_high, D_G_tb)); --16 bits only
                else
                  read(stimulus, pixel_file);
                  value_high := character'pos(pixel_file);
                  read(stimulus, pixel_file); --16 bits only
                  value_low := character'pos(pixel_file); --16 bits only
                  if (ENDIANESS_conf_test = 0) then
                    s_in_var :=  std_logic_vector(to_unsigned(value_high, 8)) & std_logic_vector(to_unsigned(value_low, D_G_tb-8));
                  else
                    s_in_var := std_logic_vector(to_unsigned(value_high, D_G_tb-8)) --16 bits only
                    & std_logic_vector(to_unsigned(value_low, 8)); --16 bits only
                  end if;
                end if;
              else
                if (D_conf_test <= 8) then
                  read(stimulus, pixel_file);
                  value_high := character'pos(pixel_file);
                  if (D_G_tb = 16) then
                    s_in_var := "00000000" & std_logic_vector(to_unsigned(value_high, 8)); --16 bits only
                  else
                    s_in_var := std_logic_vector(to_unsigned(value_low, 8)); --16 bits only
                  end if;
                else
                  read(stimulus, pixel_file);
                  value_high := character'pos(pixel_file);
                  read(stimulus, pixel_file); --16 bits only
                  value_low := character'pos(pixel_file); --16 bits only
                  if (ENDIANESS_conf_test = 0) then
                    s_in_var :=  std_logic_vector(to_unsigned(value_high, 8)) & std_logic_vector(to_unsigned(value_low, D_G_tb-8));
                  else
                    s_in_var := std_logic_vector(to_unsigned(value_high, D_G_tb-8)) --16 bits only
                    & std_logic_vector(to_unsigned(value_low, 8)); --16 bits only
                  end if;
                end if;
              end if;
              counter_samples <= counter_samples+1;
              s <= s_in_var;
              s_valid <= '1';
              modul := modulo(to_integer(counter_samples), bound);
              if modul = 0 then
                assert false report "... "&integer'image(to_integer(counter_samples)) &" samples processed" severity note;
              end if;
            else
              if (test_id = 63 and AwaitingConfig = '0') then --just keep validating samples, for the FIFO to get full
                s_valid <= '1';
              else
                s_valid <= '0';
              end if;
            end if;
          else
            s_valid <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;
  
  process (clk, rst_n)
    variable ini: integer := 0;
		variable fin: integer := 0;
		variable error_f : integer := 1;
		variable probe: std_logic_vector(7 downto 0);
		variable uns: unsigned (7 downto 0);
		variable int: integer;
		variable pixel_file: character;
		variable size: integer;
    variable status: FILE_OPEN_STATUS;
  begin
    if (clk'event and clk = '0') then
			if (rst_n = '0') then
				ini:= 0;
				fin := 0;
	--			sim_successful <= false;
			elsif (ForceStop = '1') then
				assert false report "Comparison not possible because there has been a ForceStop assertion" severity note;
				file_close(output);
				ini:= 0;
				fin := 0;
				error_f := 0;
		--		sim_successful <= false;
			elsif (Error_s = '1') then
				if (error_f = 1) then
					assert false report "Comparison not possible because there has not been compression performed (configuration error)" severity note;
					file_close(output);
					ini:= 0;
					fin := 0;
					error_f := 0;
				end if;
	--			sim_successful <= false;
			else
          if (DataOut_Valid = '1' and (AwaitingConfig = '0')) then 
            if (ini = 0) then
                file_open(output, out_file, write_mode);
                ini:= 1;
                fin := 1;
        
            end if;
  --          sim_successful <= false;
            if (work.ccsds123_tb_parameters.EN_RUNCFG_G = 1) then
                size := work.ccsds123_tb_parameters.W_BUFFER_tb;
            else
                size := work.ccsds123_tb_parameters.W_BUFFER_tb;
            end if;
            for i in 0 to (size/8) -1 loop
                      probe:= DataOut((((size/8) -1-i)+1)*8-1 downto ((size/8) -1-i)*8);
                      uns := unsigned(probe);
                      int := to_integer(uns);
                      pixel_file:= character'val(int);
                      write(output,pixel_file);
               end loop;
         end if;
         if (Finished = '1') then
					if (fin = 1) then
						file_close(output);
						ini:= 0;
						fin := 0;
						error_f := 0;
						
					end if;
				end if;
			end if;
		end if;
	end process;
  -----------------------------------------------------------------------------------------------------------------------------------------
  --! Process to read output words after some control, and to compare output words generated by the IP Core and the reference file provided
  -----------------------------------------------------------------------------------------------------------------------------------------
  gen_reference: process (clk, rst_n)
    variable pixel_file: character;
    variable ref_value_byte: ref_value_byte_type;
    variable value_high: natural;
    variable value_low: natural;
    variable value_high1: natural;
    variable value_low1: natural;
    variable pixel_read: std_logic_vector (W_BUFFER_G_tb-1 downto 0);
    variable ini: integer := 1;
    variable compression_started: integer := 0;
    variable num_bytes: integer := 0;
    
    function ceil (A: integer; B: integer) return integer is
      variable q: integer := 0;
      variable r: integer := 0;
    begin
      q := A/B;
      r := A-q*B;
      if (r > 0) then
        q := q+1;
      end if; 
      return q;
    end function;
  begin
    if (rst_n = '0') then
      if (ini = 1) then
        file_open(reference, ref_file, read_mode);
        ini := 0;
      end if;
    elsif (clk'event and clk = '1') then
      if DataOut_Valid = '1' then
        compression_started := 1;
        if Finished = '1' then
          if (Error_s = '1' or ForceStop = '1') then
            if (Error_s = '1') then
              assert false report "Comparison not possible because there has not been compression performed (configuration error)" severity note;
            else
              assert false report "Comparison not possible because there has been a ForceStop assertion" severity note;
            end if;
            file_close(reference);
            file_open(reference, ref_file, read_mode);
            compression_started := 0;
          else 
            if (compression_started = 1) then
              if (not endfile(reference)) then
                assert false report "Reference file has more samples" severity error;
              else
                assert false report "Comparison was successful!" severity note;
              end if;
              file_close(reference);
              if (test_id = 5) then
                file_open(reference, sec_ref_file, read_mode);
              else
                file_open(reference, ref_file, read_mode);
              end if;
              compression_started := 0;
            end if;
          end if;
        
        end if;
        
        if (EN_RUNCFG_G = 1) then
        -- to consider: note that this will give problems if D_G_tb is not a multiple of 8
          if (ENCODER_SELECTION_tb = 1 and BYPASS_tb = 0) then
            num_bytes := W_BUFFER_tb/8; -- TO CONSIDER: with the configurable or with the generic?!
          else
            if D_conf_test = 8 then
              num_bytes := 2;
            else
              num_bytes := ceil(D_conf_test,8);
            end if;
          end if;
        else
          if (ENCODING_TYPE_G_tb = 1) then
            num_bytes := W_BUFFER_G_tb/8;
          else
            if D_G_tb = 8 then
              num_bytes := 2;
            else
              num_bytes := ceil(D_G_tb,8);
            end if;
          end if;
        end if;
  --      for i in num_bytes - 1 downto 0 loop
  --        if (not endfile(reference)) then
  --          read(reference, pixel_file);
  --          ref_value_byte(i) := character'pos(pixel_file);
  --          pixel_read((i+1)*8-1 downto i*8) := std_logic_vector(to_unsigned(ref_value_byte(i), 8));
  --        else
  --          assert false report "Output file has more samples" severity error;
  --        end if;
  --      end loop;
  --      for i in pixel_read'high downto num_bytes*8 loop
   --       pixel_read(i) := '0';
  --      end loop;
        
  --      pixel_read := std_logic_vector(resize (unsigned(pixel_read), DataOut'length));
  --      if (pixel_read /= DataOut) then 
  --        assert false report "Problems in final stream" severity error;
 --       end if;
      end if;
      if Finished = '1' then
        if (Error_s = '1' or ForceStop_reg = '1') then
          if (Error_s = '1') then
            assert false report "Comparison not possible because there has not been compression performed (configuration error)" severity note;
          else
            assert false report "Comparison not possible because there has been a ForceStop assertion" severity note;
          end if;
          file_close(reference);
          file_open(reference, ref_file, read_mode);
          compression_started := 0;
        else 
          if (compression_started = 1) then
            if (not endfile(reference)) then
              assert false report "Reference file has more samples" severity error;
            else
              assert false report "Comparison was successful!" severity note;
            end if;
          file_close(reference);
          if (test_id = 5) then
            file_open(reference, sec_ref_file, read_mode);
          else
            file_open(reference, ref_file, read_mode);
          end if;
          compression_started := 0;
          end if;
        end if;
      
      end if;
    end if;
  end process;
  
  ---------------------
  --!@brief AMBA master
  ---------------------
  ahbtbm0 : entity work.ahbtbm(rtl)
  generic map(hindex => 0)
  port map(rst_ahb, clk_ahb, ctrl.i, ctrl.o, ahbmi, ahbmo);
  
  ----------------------
  --! AMBA masters vector
  ----------------------
  masters: for i in 2 to NAHBMST-1 generate
    msto(i).hconfig <= (others => (others => '0'));
  end generate;
  
  ---------------------
  --! AMBA slaves vector
  ---------------------
  slaves: for i in 2 to NAHBSLV-1 generate
    slvo(i).hconfig <= (others => (others => '0'));
  end generate;
  
  ----------------
  --! Memory slave
  ----------------
	-- Modified by AS: PREDICTION_TYPE = 4 (BIL-MEM) included
	gen_slave_sim_memory: if ((PREDICTION_TYPE_tb = 1) or (PREDICTION_TYPE_tb = 2) or (PREDICTION_TYPE_tb = 4)) generate --two masters
	-------------------------------
    ahbtbslv0 : entity work.ahbtbs(rtl) --External memory
    generic map(hindex => 0, haddr => ExtMemAddress_G_tb, hmask => 16#f00#, kbytes => 8196) -- AMBA slave index 0
    port map(rst_ahb, clk_ahb, ahbsi, ahbso);
  end generate;
  
  ------------------------------------
  --! Memory slave (small size memory)
  ------------------------------------
  gen_slave_sim_memory_small: if PREDICTION_TYPE_tb = 0 or PREDICTION_TYPE_tb = 3 generate --two masters
    ahbtbslv0 : entity work.ahbtbs(rtl) --External memory
    generic map(hindex => 0, haddr => ExtMemAddress_G_tb, hmask => 16#f00#, kbytes => 512) -- AMBA slave index 0
    port map(rst_ahb, clk_ahb, ahbsi, ahbso);
  end generate;
  
  
  -----------------------------------------------------------------------------------------
  --! AMBA configuration: 2 slaves (memory and shyloc) and 2 masters (testbench and shyloc)
  -----------------------------------------------------------------------------------------
		-- Modified by AS: PREDICTION_TYPE = 4 (BIL-MEM) included
		gen_mst: if ((PREDICTION_TYPE_tb = 1) or (PREDICTION_TYPE_tb = 2) or (PREDICTION_TYPE_tb = 4)) generate 
		-----------------------------
    msto(1).hbusreq <= AHBMaster123_Out.HBUSREQ after 5 ns;
    msto(1).HLOCK <= AHBMaster123_Out.HLOCK after 5 ns;
    msto(1).HTRANS <= AHBMaster123_Out.HTRANS after 5 ns;
    msto(1).HADDR <= AHBMaster123_Out.HADDR after 5 ns;
    msto(1).HWRITE <= AHBMaster123_Out.HWRITE after 5 ns;
    msto(1).HSIZE <= AHBMaster123_Out.HSIZE after 5 ns;
    msto(1).HBURST <= AHBMaster123_Out.HBURST after 5 ns;
    msto(1).HPROT <= AHBMaster123_Out.HPROT after 5 ns;
    msto(1).HWDATA <= AHBMaster123_Out.HWDATA after 5 ns;
    msto(1).hconfig <= (others => (others => '0'));
    msto(1).hindex <= 1;
    
    ----------------
    --! AMBA decoder
    ----------------
    ahbtbctrl : entity work.ahbctrl(rtl)
    generic map (nahbm => 2, nahbs => 2, assertwarn => 1) 
    port map(rst_ahb, clk_ahb, ahbmi, msto, ahbsi, slvo);   
  end generate;
  
  ------------------------------------------------------------------------------
  --! AMBA configuration: 2 slaves (memory and shyloc) and 1 master (testbench)
  ------------------------------------------------------------------------------
  not_gen_mst: if PREDICTION_TYPE_tb = 0 or PREDICTION_TYPE_tb = 3 generate 
    
    msto(1).hconfig <= (others => (others => '0'));
    ----------------
    --! AMBA decoder
    ----------------
    ahbtbctrl : entity work.ahbctrl(rtl)
    generic map (nahbm => 1, nahbs => 2, assertwarn => 1) 
    port map(rst_ahb, clk_ahb, ahbmi, msto, ahbsi, slvo);
    
  end generate;
  
  ---------------
  --! Assignments
  ---------------
  msto(0) <= ahbmo;
  
  slvo(0) <= ahbso;
  
  -- from shyloc to controller
  slvo(1).hready <= AHBSlave123_Out.HREADY; 
  slvo(1).hresp <=  AHBSlave123_Out.HRESP;
  slvo(1).hrdata <=  AHBSlave123_Out.HRDATA;
  slvo(1).hsplit <=  AHBSlave123_Out.HSPLIT;
  enable_slave_shyloc: if EN_RUNCFG_G = 1 generate
    -- The slave is disabled in this case, so we need to drive hconfig to zero
    -- We do it from here because we are not using GRLIB. We can also add this as a port
    slvo(1).hconfig <= (0 => zero32,  4 => ahb_membar(HSCONFIGADDR_tb, '1', '1', HSADDRMASK_tb),  others => zero32);
  end generate enable_slave_shyloc;
  disable_enable_slave_shyloc: if EN_RUNCFG_G = 0 generate
    slvo(1).hconfig <= (others => (others => '0'));
  end generate disable_enable_slave_shyloc;
  
  slvo(1).hindex <= 1;
  
  AHBSlave123_In.HSEL <= ahbsi.hsel(1) after 5 ns;  
  AHBSlave123_In.HADDR <= ahbsi.haddr after 5 ns;   
  AHBSlave123_In.HWRITE <= ahbsi.hwrite after 5 ns;   
  AHBSlave123_In.HTRANS <= ahbsi.htrans after 5 ns;   
  AHBSlave123_In.HSIZE <= ahbsi.hsize after 5 ns;   
  AHBSlave123_In.HBURST <= ahbsi.hburst after 5 ns;   
  AHBSlave123_In.HWDATA <= ahbsi.hwdata after 5 ns;
  AHBSlave123_In.HPROT <= ahbsi.hprot after 5 ns;
  AHBSlave123_In.HREADY <= ahbsi.hready after 5 ns;
  AHBSlave123_In.HMASTER <= ahbsi.hmaster after 5 ns;
  AHBSlave123_In.HMASTLOCK <= ahbsi.hmastlock after 5 ns;
  
  
	AHBMaster123_In.HGRANT <= (ahbmi.hgrant(1) and ahb_en) after 5 ns;  -- Modified by AS: HGRANT can be blocked by ahb_en signal
  AHBMaster123_In.HREADY <= ahbmi.hready after 5 ns;
  AHBMaster123_In.HRESP <= ahbmi.hresp after 5 ns;
  AHBMaster123_In.HRDATA <= ahbmi.hrdata after 5 ns;
  DataIn <= s after 10 ns;
  DataIn_NewValid <= s_valid after 10 ns;
  ForceStop_i <= ForceStop after 10 ns;
  gen_beh: if POST_SYN = 0 generate
  ---------------------------
  --!@brief CCSDS-123 IP Core
  ---------------------------
  shyloc: entity shyloc_123.ccsds123_top(arch)
  port map(
    clk_s => clk, 
    rst_n => rst_n, 
    clk_ahb => clk_ahb, 
    rst_ahb => rst_ahb, 
    DataIn => s, 
    DataIn_NewValid => s_valid, 
    AwaitingConfig => AwaitingConfig, 
    Ready => Ready, 
    FIFO_Full => FIFO_Full, 
    EOP => EOP, 
    Finished => Finished, 
    ForceStop => ForceStop,
    Error => Error_s,
    AHBSlave123_In => AHBSlave123_In, 
    AHBSlave123_Out => AHBSlave123_Out,   
    
    AHBMaster123_In => AHBMaster123_In, 
    AHBMaster123_Out => AHBMaster123_Out,
    DataOut => DataOut,
    DataOut_NewValid => DataOut_Valid, 
    IsHeaderOut => IsHeaderOut, 
    NbitsOut => NbitsOut, 
    AwaitingConfig_Ext => AwaitingConfig_Ext,
    Ready_Ext => Ready_Ext, 
    FIFO_Full_Ext => FIFO_Full_Ext, 
    EOP_Ext => EOP_Ext, 
    Finished_Ext => Finished_Ext, 
    Error_Ext => Error_Ext);
    end generate gen_beh;
    
  gen_syn: if POST_SYN = 1 generate
  ---------------------------
  --!@brief CCSDS-123 IP Core  wrapper for post-synthesis simulations.
  ---------------------------
    shyloc: entity post_syn_lib.ccsds123_top_wrapper
    port map(
      clk_s => clk, 
      rst_n => rst_n, 
      clk_ahb => clk_ahb, 
      rst_ahb => rst_ahb, 
      DataIn => DataIn, 
      DataIn_NewValid => DataIn_NewValid, 
      AwaitingConfig => AwaitingConfig, 
      Ready => Ready, 
      FIFO_Full => FIFO_Full, 
      EOP => EOP, 
      Finished => Finished, 
      ForceStop => ForceStop_i,
      Error => Error_s,

      AHBSlave123_In_HSEL => AHBSlave123_In.HSEL, 
      AHBSlave123_In_HADDR => AHBSlave123_In.HADDR, 
      AHBSlave123_In_HWRITE => AHBSlave123_In.HWRITE, 
      AHBSlave123_In_HTRANS => AHBSlave123_In.HTRANS, 
      AHBSlave123_In_HSIZE => AHBSlave123_In.HSIZE, 
      AHBSlave123_In_HBURST => AHBSlave123_In.HBURST, 
      AHBSlave123_In_HWDATA => AHBSlave123_In.HWDATA, 
      AHBSlave123_In_HPROT => AHBSlave123_In.HPROT, 
      AHBSlave123_In_HREADY => AHBSlave123_In.HREADY, 
      AHBSlave123_In_HMASTER => AHBSlave123_In.HMASTER, 
      AHBSlave123_In_HMASTLOCK => AHBSlave123_In.HMASTLOCK, 

      AHBSlave123_Out_HREADY => AHBSlave123_Out.HREADY, 
      AHBSlave123_Out_HRESP => AHBSlave123_Out.HRESP, 
      AHBSlave123_Out_HRDATA => AHBSlave123_Out.HRDATA, 
      AHBSlave123_Out_HSPLIT => AHBSlave123_Out.HSPLIT, 
      
      AHBMaster123_In_HGRANT => AHBMaster123_In.HGRANT,
      AHBMaster123_In_HREADY => AHBMaster123_In.HREADY,
      AHBMaster123_In_HRESP => AHBMaster123_In.HRESP,
      AHBMaster123_In_HRDATA => AHBMaster123_In.HRDATA,

      AHBMaster123_Out_HBUSREQ => AHBMaster123_Out.HBUSREQ,
      AHBMaster123_Out_HLOCK => AHBMaster123_Out.HLOCK,
      AHBMaster123_Out_HTRANS => AHBMaster123_Out.HTRANS,
      AHBMaster123_Out_HADDR => AHBMaster123_Out.HADDR,
      AHBMaster123_Out_HWRITE => AHBMaster123_Out.HWRITE,
      AHBMaster123_Out_HSIZE => AHBMaster123_Out.HSIZE,
      AHBMaster123_Out_HBURST => AHBMaster123_Out.HBURST,
      AHBMaster123_Out_HPROT => AHBMaster123_Out.HPROT,
      AHBMaster123_Out_HWDATA => AHBMaster123_Out.HWDATA,
      DataOut => DataOut,
      DataOut_NewValid => DataOut_Valid, 
      IsHeaderOut => IsHeaderOut, 
      NbitsOut => NbitsOut, 
      AwaitingConfig_Ext => AwaitingConfig_Ext,
      Ready_Ext => Ready_Ext, 
      FIFO_Full_Ext => FIFO_Full_Ext, 
      EOP_Ext => EOP_Ext, 
      Finished_Ext => Finished_Ext, 
      Error_Ext => Error_Ext);
    end generate gen_syn;
    ------------------------------------------------
    --! Control the test to perform and check signals
    ------------------------------------------------
    configure: process
      variable address: std_logic_vector(31 downto 0);
      --------------------------------------------------------------------------
      --! Regular test (2 consecutive compressions or 1 (depending on the size))
      --------------------------------------------------------------------------
      procedure test0 is
        variable n_words: integer := 0;
      begin
        assert (Finished /= '1') report "Finished started with a high value" severity warning;
        assert (Ready /= '1') report "Ready started with a high value" severity warning;
        assert (AwaitingConfig /= '0') report "AwaitingConfig started with a low value" severity warning;
        if (EN_RUNCFG_G = 1) then
          assert false report "Sending a new configuration..." severity note;
          config_reg <= (others => (others => '0'));
          config_reg(1)(31 downto 0) <= std_logic_vector(to_unsigned(ExtMemAddress_G_tb, 12)) & std_logic_vector(to_unsigned(0, 20));
      
          config_reg(2)(31 downto 16) <= std_logic_vector(to_unsigned(Nx_conf_test,16));
          config_reg(2)(15 downto 11) <= std_logic_vector(to_unsigned(D_conf_test,5));
          config_reg(2)(10 downto 10) <= std_logic_vector(to_unsigned(IS_SIGNED_tb,1));
          config_reg(2)(9 downto 9) <= std_logic_vector(to_unsigned(DISABLE_HEADER_tb,1));
          config_reg(2)(8 downto 7) <= std_logic_vector(to_unsigned(ENCODER_SELECTION_tb,2));
          config_reg(2)(6 downto 3) <= std_logic_vector(to_unsigned(P_tb,4));
          config_reg(2)(2 downto 0) <= (others => '0');     

          config_reg(3)(31 downto 16) <= std_logic_vector(to_unsigned(Ny_tb,16));
          config_reg(3)(15 downto 15) <= std_logic_vector(to_unsigned(PREDICTION_tb,1));
          config_reg(3)(14 downto 14) <= std_logic_vector(to_unsigned(LOCAL_SUM_tb,1));
          config_reg(3)(13 downto 9) <= std_logic_vector(to_unsigned(OMEGA_tb,5));
          config_reg(3)(8 downto 2) <= std_logic_vector(to_unsigned(R_tb,7));
          config_reg(3)(1 downto 0) <= (others => '0');   
      
          config_reg(4)(31 downto 16) <= std_logic_vector(to_unsigned(Nz_conf_test,16));
          config_reg(4)(15 downto 11) <= std_logic_vector(to_signed(VMAX_tb,5));
          config_reg(4)(10 downto 6) <= std_logic_vector(to_signed(VMIN_tb,5));
          config_reg(4)(5 downto 2) <= std_logic_vector(to_unsigned(TINC_tb,4));
          config_reg(4)(1 downto 1) <= std_logic_vector(to_unsigned(WEIGHT_INIT_tb,1));
          config_reg(4)(0 downto 0) <= std_logic_vector(to_unsigned(ENDIANESS_conf_test,1));
          
          config_reg(5)(31 downto 28) <= std_logic_vector(to_unsigned(INIT_COUNT_E_tb,4));
          config_reg(5)(27 downto 27) <= std_logic_vector(to_unsigned(ACC_INIT_TYPE_tb,1));
          config_reg(5)(26 downto 23) <= std_logic_vector(to_unsigned(ACC_INIT_CONST_tb,4));
          config_reg(5)(22 downto 19) <= std_logic_vector(to_unsigned(RESC_COUNT_SIZE_tb,4));
          config_reg(5)(18 downto 13) <= std_logic_vector(to_unsigned(U_MAX_tb,6));
          config_reg(5)(12 downto 6) <= std_logic_vector(to_unsigned(W_BUFFER_tb,7));
					-- Modified by AS: assigning new configuration parameters Q and WR --
					config_reg(5)(5 downto 1) <= std_logic_vector(to_unsigned(Q_tb,5));
					config_reg(5)(0 downto 0) <= std_logic_vector(to_unsigned(WR_tb,1));
					--config_reg(5)(5 downto 0) <= (others => '0');
					---------------------------		
          
          config_reg(0)(0) <= '0';
          address := std_logic_vector(to_unsigned(16#200#, 12)) & std_logic_vector(to_unsigned(0, 20));
          wait until clk'event and clk = '1'; 
          n_words := 6;
          ahbwrite(address, config_reg, "10", n_words, 2, ctrl);
          config_reg(0)(0) <= '1';
          ahbwrite(address, config_reg(0), "10", "10", '1', 2, true , ctrl);
        end if;
        wait until Awaitingconfig = '0';
        assert false report "AwaitingConfig lowered correctly when configuration was received" severity note;
        wait until Ready = '1';
        assert false report "Ready asserted correctly when IP core is ready to receive new samples" severity note;
        while Finished = '0' loop
          if test_id = 63 then
            assert FIFO_Full = '0' report "FIFO is full, as expected" severity note;
            if FIFO_Full = '1' then
              exit;
            end if;
          end if;
          if test_id /= 62 then
            assert Error_s = '0' report "Unexpected IP core error during compression" severity error;
          else
            assert Error_s = '0' report "Expected IP core AHB error during compression" severity note;
          end if;
          wait until clk'event and clk = '1';
        end loop;
        if test_id /= 63 then --Test for FIFO full finishes here.
          assert false report "Finished correctly activated when compression finished" severity note;
          if test_id /= 62 then
              assert Error_s = '0' report "Unexpected IP core error after compression" severity error;
            else
              assert Error_s = '0' report "Expected IP core AHB error during compression" severity note;
            end if;
          wait until AwaitingConfig = '1';
          assert false report "AwaitingConfig correctly activated after compression finished" severity note;
          if (Nx_tb*Ny_tb*Nz_tb < 16000) then -- repeat compression procedure only in shorter tests.
            assert false report "Sending a new configuration..." severity note;
            if (EN_RUNCFG_G = 1) then
              config_reg(0)(0) <= '0';
              address := std_logic_vector(to_unsigned(16#200#, 12)) & std_logic_vector(to_unsigned(0, 20));
              wait until clk'event and clk = '1'; 
              ahbwrite(address, config_reg, "10", n_words, 2, ctrl);
              config_reg(0)(0) <= '1';
              ahbwrite(address, config_reg(0), "10", "10", '1', 2, true , ctrl);
              wait until clk'event and clk = '1';
            end if;
            while Awaitingconfig = '1' loop
              assert Finished = '1' report "Error between sequential compressions, value of Finished shall be kept high" severity error; 
              wait until clk'event and clk = '1';
            end loop;
            assert false report "AwaitingConfig lowered correctly when configuration was received" severity note;
            assert (Ready = '1') report "Ready not asserted correctly when IP core has been configured" severity warning;
            assert false report "Ready asserted correctly when IP core is ready to receive new samples" severity note;
            assert Finished = '0' report "Error for sequential compressions, Finished shall be de-asserted with AwaitingConfig" severity error; 
            while Finished = '0' loop
              --if test_id = 62 then
              if test_id /= 62 then
                assert Error_s = '0' report "Unexpected IP core error during compression" severity error;
              else
                assert Error_s = '0' report "Expected IP core AHB error during compression" severity note;
              end if;
              wait until clk'event and clk = '1';
            end loop;
            assert false report "Finished correctly activated when compression finished" severity note;
            if test_id /= 62 then
              assert Error_s = '0' report "Unexpected IP core error after compression" severity error;
            else
              assert Error_s = '0' report "Expected IP core AHB error during compression" severity note;
            end if;
            wait until AwaitingConfig = '1';
            assert false report "AwaitingConfig correctly activated after compression finished" severity note;
            assert false report "Two sequential compressions test performed" severity note;
          else
            assert false report "One compression test performed" severity note;
          end if;
        end if; 
      end test0;
      
    -----------------------------------------------------------------------------------
    --! Trying to reconfigure test (configuration bypass during an existing compression)
    -----------------------------------------------------------------------------------
    procedure test2 is
          variable n_words: integer := 0;
      begin
        assert (Finished /= '1') report "Finished started with a high value" severity warning;
        assert (Ready /= '1') report "Ready started with a high value" severity warning;
        assert (AwaitingConfig /= '0') report "AwaitingConfig started with a low value" severity warning;
        assert false report "Sending a new configuration..." severity note;
        config_reg <= (others => (others => '0'));
        config_reg(1)(31 downto 0) <= std_logic_vector(to_unsigned(ExtMemAddress_G_tb, 12)) & std_logic_vector(to_unsigned(0, 20));
    
        config_reg(2)(31 downto 16) <= std_logic_vector(to_unsigned(Nx_conf_test,16));
        config_reg(2)(15 downto 11) <= std_logic_vector(to_unsigned(D_conf_test,5));
        config_reg(2)(10 downto 10) <= std_logic_vector(to_unsigned(IS_SIGNED_tb,1));
        config_reg(2)(9 downto 9) <= std_logic_vector(to_unsigned(DISABLE_HEADER_tb,1));
        config_reg(2)(8 downto 7) <= std_logic_vector(to_unsigned(ENCODER_SELECTION_tb,2));
        config_reg(2)(6 downto 3) <= std_logic_vector(to_unsigned(P_tb,4));
        config_reg(2)(2 downto 0) <= (others => '0');     

        config_reg(3)(31 downto 16) <= std_logic_vector(to_unsigned(Ny_tb,16));
        config_reg(3)(15 downto 15) <= std_logic_vector(to_unsigned(PREDICTION_tb,1));
        config_reg(3)(14 downto 14) <= std_logic_vector(to_unsigned(LOCAL_SUM_tb,1));
        config_reg(3)(13 downto 9) <= std_logic_vector(to_unsigned(OMEGA_tb,5));
        config_reg(3)(8 downto 2) <= std_logic_vector(to_unsigned(R_tb,7));
        config_reg(3)(1 downto 0) <= (others => '0');   
    
        config_reg(4)(31 downto 16) <= std_logic_vector(to_unsigned(Nz_conf_test,16));
        config_reg(4)(15 downto 11) <= std_logic_vector(to_signed(VMAX_tb,5));
        config_reg(4)(10 downto 6) <= std_logic_vector(to_signed(VMIN_tb,5));
        config_reg(4)(5 downto 2) <= std_logic_vector(to_unsigned(TINC_tb,4));
        config_reg(4)(1 downto 1) <= std_logic_vector(to_unsigned(WEIGHT_INIT_tb,1));
        config_reg(4)(0 downto 0) <= std_logic_vector(to_unsigned(ENDIANESS_conf_test,1));
        
        config_reg(5)(31 downto 28) <= std_logic_vector(to_unsigned(INIT_COUNT_E_tb,4));
        config_reg(5)(27 downto 27) <= std_logic_vector(to_unsigned(ACC_INIT_TYPE_tb,1));
        config_reg(5)(26 downto 23) <= std_logic_vector(to_unsigned(ACC_INIT_CONST_tb,4));
        config_reg(5)(22 downto 19) <= std_logic_vector(to_unsigned(RESC_COUNT_SIZE_tb,4));
        config_reg(5)(18 downto 13) <= std_logic_vector(to_unsigned(U_MAX_tb,6));
        config_reg(5)(12 downto 6) <= std_logic_vector(to_unsigned(W_BUFFER_tb,7));
				-- Modified by AS: assigning new configuration parameters Q and WR --
				config_reg(5)(5 downto 1) <= std_logic_vector(to_unsigned(Q_tb,5));
				config_reg(5)(0 downto 0) <= std_logic_vector(to_unsigned(WR_tb,1));
				--config_reg(5)(5 downto 0) <= (others => '0');
				---------------------------		

        config_reg(0)(0) <= '0';
        address := std_logic_vector(to_unsigned(16#200#, 12)) & std_logic_vector(to_unsigned(0, 20));
        wait until clk'event and clk = '1'; 
        n_words := 6;
        ahbwrite(address, config_reg, "10", n_words, 2, ctrl);
        config_reg(0)(0) <= '1';
        ahbwrite(address, config_reg(0), "10", "10", '1', 2, true , ctrl);
        
        wait until Awaitingconfig = '0';
        assert false report "AwaitingConfig lowered correctly when configuration was received" severity note;
        wait until Ready = '1';
        assert false report "Ready asserted correctly when IP core is ready to receive new samples" severity note;
        for j in 0 to 20 loop
          wait until clk'event and clk = '1'; 
          ahbwrite(address, config_reg, "10", n_words, 2, ctrl);
        end loop;
        config_reg(0)(0) <= '0';
        ahbwrite(address, config_reg(0), "10", "10", '1', 2, true , ctrl);
        address := x"10000000";
        wait until clk'event and clk = '1'; 
        ahbwrite(x"10000000", config_reg, "10", 4, 2, ctrl);
        config_reg(0)(0) <= '1';
        ahbwrite(address, config_reg(0), "10", "10", '1', 2, true , ctrl);
        while Finished = '0' loop
          assert Error_s = '0' report "Unexpected IP core error during compression" severity error; 
          wait until clk'event and clk = '1';
        end loop;
        assert false report "Finished correctly activated when compression finished" severity note;
        assert (Error_s = '0') report "Unexpected IP core error after compression" severity failure;
        wait until AwaitingConfig = '1';
        assert false report "AwaitingConfig correctly activated after compression finished" severity note;
        assert false report "One compression (attempting to reconfigure) test performed" severity note;
      end test2;
      
    -----------------------------------------------------------------------------------
    --! ForceStop test (ForceStop assertion during a compression)
    -----------------------------------------------------------------------------------
    procedure test4 is
        variable n_words: integer := 0;
        variable n_forcestop: integer := 0;
        variable total_samples: integer := 0;
      begin
        assert (Finished /= '1') report "Finished started with a high value" severity warning;
        assert (Ready /= '1') report "Ready started with a high value" severity warning;
        assert (AwaitingConfig /= '0') report "AwaitingConfig started with a low value" severity warning;
        if (EN_RUNCFG_G = 1) then
          assert false report "Sending a new configuration..." severity note;
          config_reg <= (others => (others => '0'));
          config_reg(1)(31 downto 0) <= std_logic_vector(to_unsigned(ExtMemAddress_G_tb, 12)) & std_logic_vector(to_unsigned(0, 20));
      
          config_reg(2)(31 downto 16) <= std_logic_vector(to_unsigned(Nx_conf_test,16));
          config_reg(2)(15 downto 11) <= std_logic_vector(to_unsigned(D_conf_test,5));
          config_reg(2)(10 downto 10) <= std_logic_vector(to_unsigned(IS_SIGNED_tb,1));
          config_reg(2)(9 downto 9) <= std_logic_vector(to_unsigned(DISABLE_HEADER_tb,1));
          config_reg(2)(8 downto 7) <= std_logic_vector(to_unsigned(ENCODER_SELECTION_tb,2));
          config_reg(2)(6 downto 3) <= std_logic_vector(to_unsigned(P_tb,4));
          config_reg(2)(2 downto 0) <= (others => '0');     

          config_reg(3)(31 downto 16) <= std_logic_vector(to_unsigned(Ny_tb,16));
          config_reg(3)(15 downto 15) <= std_logic_vector(to_unsigned(PREDICTION_tb,1));
          config_reg(3)(14 downto 14) <= std_logic_vector(to_unsigned(LOCAL_SUM_tb,1));
          config_reg(3)(13 downto 9) <= std_logic_vector(to_unsigned(OMEGA_tb,5));
          config_reg(3)(8 downto 2) <= std_logic_vector(to_unsigned(R_tb,7));
          config_reg(3)(1 downto 0) <= (others => '0');   
      
          config_reg(4)(31 downto 16) <= std_logic_vector(to_unsigned(Nz_conf_test,16));
          config_reg(4)(15 downto 11) <= std_logic_vector(to_signed(VMAX_tb,5));
          config_reg(4)(10 downto 6) <= std_logic_vector(to_signed(VMIN_tb,5));
          config_reg(4)(5 downto 2) <= std_logic_vector(to_unsigned(TINC_tb,4));
          config_reg(4)(1 downto 1) <= std_logic_vector(to_unsigned(WEIGHT_INIT_tb,1));
          config_reg(4)(0 downto 0) <= std_logic_vector(to_unsigned(ENDIANESS_conf_test,1));
          
          config_reg(5)(31 downto 28) <= std_logic_vector(to_unsigned(INIT_COUNT_E_tb,4));
          config_reg(5)(27 downto 27) <= std_logic_vector(to_unsigned(ACC_INIT_TYPE_tb,1));
          config_reg(5)(26 downto 23) <= std_logic_vector(to_unsigned(ACC_INIT_CONST_tb,4));
          config_reg(5)(22 downto 19) <= std_logic_vector(to_unsigned(RESC_COUNT_SIZE_tb,4));
          config_reg(5)(18 downto 13) <= std_logic_vector(to_unsigned(U_MAX_tb,6));
          config_reg(5)(12 downto 6) <= std_logic_vector(to_unsigned(W_BUFFER_tb,7));
					-- Modified by AS: assigning new configuration parameters Q and WR --
					config_reg(5)(5 downto 1) <= std_logic_vector(to_unsigned(Q_tb,5));
					config_reg(5)(0 downto 0) <= std_logic_vector(to_unsigned(WR_tb,1));
					--config_reg(5)(5 downto 0) <= (others => '0');
					---------------------------		

          config_reg(0)(0) <= '0';
          address := std_logic_vector(to_unsigned(16#200#, 12)) & std_logic_vector(to_unsigned(0, 20));
          wait until clk'event and clk = '1'; 
          n_words := 6;
          ahbwrite(address, config_reg, "10", n_words, 2, ctrl);
          config_reg(0)(0) <= '1';
          ahbwrite(address, config_reg(0), "10", "10", '1', 2, true , ctrl);
          wait until clk'event and clk = '1';
        end if;
        wait until Awaitingconfig = '0';
        assert false report "AwaitingConfig lowered correctly when configuration was received" severity note;
        wait until Ready = '1';
        assert false report "Ready asserted correctly when IP core is ready to receive new samples" severity note;
        -- Calculate the number of iterations before sending the forcestop
        total_samples := Nx_tb*Ny_tb*Nz_tb;
        n_forcestop := modulo(total_samples, 10);
        for i in 0 to (125 + n_forcestop) loop
          assert Error_s = '0' report "Unexpected IP core error during compression" severity failure; 
          assert Finished = '0' report "Unexpected IP core error during compression" severity failure; 
          wait until clk'event and clk = '1';
        end loop;
        assert false report "ForceStop assertion" severity note;
        ForceStop <= '1';
        wait until clk'event and clk = '1'; 
        ForceStop <= '0';
        while Finished = '0' loop 
          assert Error_s = '0' report "Unexpected IP core error during compression" severity error; 
          wait until clk'event and clk = '1';
        end loop;
        assert false report "Finished correctly activated after ForceStop" severity note;
        assert Error_s = '0' report "Unexpected IP core error after compression" severity error;
        if (PREDICTION_TYPE_tb /= 0 and PREDICTION_TYPE_tb /= 3) then 
          wait until AwaitingConfig = '1';
        end if;
        assert false report "AwaitingConfig asserted correctly after ForceStop" severity note;
        if (EN_RUNCFG_G = 1) then
          assert false report "Sending a new configuration..." severity note;
          config_reg(0)(0) <= '0';
          address := std_logic_vector(to_unsigned(16#200#, 12)) & std_logic_vector(to_unsigned(0, 20));
          wait until clk'event and clk = '1'; 
          ahbwrite(address, config_reg, "10", n_words, 2, ctrl);
          config_reg(0)(0) <= '1';
          ahbwrite(address, config_reg(0), "10", "10", '1', 2, true , ctrl);
          wait until clk'event and clk = '1';
        end if;
        while Awaitingconfig = '1' loop
          assert Finished = '1' report "Error between sequential compressions, value of Finished shall be kept high" severity error; 
          wait until clk'event and clk = '1';
        end loop;
        assert false report "AwaitingConfig lowered correctly when configuration was received" severity note;
        assert (Ready = '1') report "Ready not asserted correctly when IP core has been configured" severity warning;
        assert false report "Ready asserted correctly when IP core is ready to receive new samples" severity note;
        assert Finished = '0' report "Error for sequential compressions, Finished shall be de-asserted with AwaitingConfig" severity error; 
        while Finished = '0' loop
          assert Error_s = '0' report "Unexpected IP core error during compression" severity error; 
          wait until clk'event and clk = '1';
        end loop;
        assert false report "Finished correctly activated when compression finished" severity note;
        assert Error_s = '0' report "Unexpected IP core error after compression" severity error;
        wait until AwaitingConfig = '1';
        assert false report "AwaitingConfig correctly activated after compression finished" severity note;
        assert false report "ForceStop and one compression test performed" severity note;
      end test4;
    
    -----------------------------------------------------------------------------------
    --! 2-compression test (Second compression is performed with different run-time configuration)
    -----------------------------------------------------------------------------------
    procedure test5 is
        variable n_words: integer := 0;
      begin
        assert (Finished /= '1') report "Finished started with a high value" severity warning;
        assert (Ready /= '1') report "Ready started with a high value" severity warning;
        assert (AwaitingConfig /= '0') report "AwaitingConfig started with a low value" severity warning;
        if (EN_RUNCFG_G = 1) then
          assert false report "Sending a new configuration..." severity note;
          config_reg <= (others => (others => '0'));
          config_reg(1)(31 downto 0) <= std_logic_vector(to_unsigned(ExtMemAddress_G_tb, 12)) & std_logic_vector(to_unsigned(0, 20));
      
          config_reg(2)(31 downto 16) <= std_logic_vector(to_unsigned(Nx_conf_test,16));
          config_reg(2)(15 downto 11) <= std_logic_vector(to_unsigned(D_conf_test,5));
          config_reg(2)(10 downto 10) <= std_logic_vector(to_unsigned(IS_SIGNED_tb,1));
          config_reg(2)(9 downto 9) <= std_logic_vector(to_unsigned(DISABLE_HEADER_tb,1));
          config_reg(2)(8 downto 7) <= std_logic_vector(to_unsigned(ENCODER_SELECTION_tb,2));
          config_reg(2)(6 downto 3) <= std_logic_vector(to_unsigned(P_tb,4));
          config_reg(2)(2 downto 0) <= (others => '0');     

          config_reg(3)(31 downto 16) <= std_logic_vector(to_unsigned(Ny_tb,16));
          config_reg(3)(15 downto 15) <= std_logic_vector(to_unsigned(PREDICTION_tb,1));
          config_reg(3)(14 downto 14) <= std_logic_vector(to_unsigned(LOCAL_SUM_tb,1));
          config_reg(3)(13 downto 9) <= std_logic_vector(to_unsigned(OMEGA_tb,5));
          config_reg(3)(8 downto 2) <= std_logic_vector(to_unsigned(R_tb,7));
          config_reg(3)(1 downto 0) <= (others => '0');   
      
          config_reg(4)(31 downto 16) <= std_logic_vector(to_unsigned(Nz_conf_test,16));
          config_reg(4)(15 downto 11) <= std_logic_vector(to_signed(VMAX_tb,5));
          config_reg(4)(10 downto 6) <= std_logic_vector(to_signed(VMIN_tb,5));
          config_reg(4)(5 downto 2) <= std_logic_vector(to_unsigned(TINC_tb,4));
          config_reg(4)(1 downto 1) <= std_logic_vector(to_unsigned(WEIGHT_INIT_tb,1));
          config_reg(4)(0 downto 0) <= std_logic_vector(to_unsigned(ENDIANESS_conf_test,1));
          
          config_reg(5)(31 downto 28) <= std_logic_vector(to_unsigned(INIT_COUNT_E_tb,4));
          config_reg(5)(27 downto 27) <= std_logic_vector(to_unsigned(ACC_INIT_TYPE_tb,1));
          config_reg(5)(26 downto 23) <= std_logic_vector(to_unsigned(ACC_INIT_CONST_tb,4));
          config_reg(5)(22 downto 19) <= std_logic_vector(to_unsigned(RESC_COUNT_SIZE_tb,4));
          config_reg(5)(18 downto 13) <= std_logic_vector(to_unsigned(U_MAX_tb,6));
          config_reg(5)(12 downto 6) <= std_logic_vector(to_unsigned(W_BUFFER_tb,7));
					-- Modified by AS: assigning new configuration parameters Q and WR --
					config_reg(5)(5 downto 1) <= std_logic_vector(to_unsigned(Q_tb,5));
					config_reg(5)(0 downto 0) <= std_logic_vector(to_unsigned(WR_tb,1));
					--config_reg(5)(5 downto 0) <= (others => '0');
					---------------------------			

          
          config_reg(0)(0) <= '0';
          address := std_logic_vector(to_unsigned(16#200#, 12)) & std_logic_vector(to_unsigned(0, 20));
          wait until clk'event and clk = '1'; 
          n_words := 6;
          ahbwrite(address, config_reg, "10", n_words, 2, ctrl);
          config_reg(0)(0) <= '1';
          ahbwrite(address, config_reg(0), "10", "10", '1', 2, true , ctrl);
        end if;
        wait until Awaitingconfig = '0';
        assert false report "AwaitingConfig lowered correctly when configuration was received" severity note;
        wait until Ready = '1';
        assert false report "Ready asserted correctly when IP core is ready to receive new samples" severity note;
        while Finished = '0' loop
          assert Error_s = '0' report "Unexpected IP core error during compression" severity error; 
          wait until clk'event and clk = '1';
        end loop;
        assert false report "Finished correctly activated when compression finished" severity note;
        assert Error_s = '0' report "Unexpected IP core error after compression" severity error;
        wait until AwaitingConfig = '1';
        assert false report "AwaitingConfig correctly activated after compression finished" severity note;
        if (EN_RUNCFG_G = 1) then
          assert false report "Sending a new configuration..." severity note;
          Nx_conf_test <= 320;      
          Nz_conf_test <= 86; 
          D_conf_test <= 12;
          ENDIANESS_conf_test <= 0;
          config_reg <= (others => (others => '0'));
          config_reg(1)(31 downto 0) <= std_logic_vector(to_unsigned(ExtMemAddress_G_tb, 12)) & std_logic_vector(to_unsigned(0, 20));
      
          config_reg(2)(31 downto 16) <= std_logic_vector(to_unsigned(320,16));
          config_reg(2)(15 downto 11) <= std_logic_vector(to_unsigned(12,5));
          config_reg(2)(10 downto 10) <= std_logic_vector(to_unsigned(IS_SIGNED_tb,1));
          config_reg(2)(9 downto 9) <= std_logic_vector(to_unsigned(DISABLE_HEADER_tb,1));
          config_reg(2)(8 downto 7) <= std_logic_vector(to_unsigned(ENCODER_SELECTION_tb,2));
          config_reg(2)(6 downto 3) <= std_logic_vector(to_unsigned(P_tb,4));
          config_reg(2)(2 downto 0) <= (others => '0');     

          config_reg(3)(31 downto 16) <= std_logic_vector(to_unsigned(Ny_tb,16));
          config_reg(3)(15 downto 15) <= std_logic_vector(to_unsigned(PREDICTION_tb,1));
          config_reg(3)(14 downto 14) <= std_logic_vector(to_unsigned(LOCAL_SUM_tb,1));
          config_reg(3)(13 downto 9) <= std_logic_vector(to_unsigned(OMEGA_tb,5));
          config_reg(3)(8 downto 2) <= std_logic_vector(to_unsigned(R_tb,7));
          config_reg(3)(1 downto 0) <= (others => '0');   
      
          config_reg(4)(31 downto 16) <= std_logic_vector(to_unsigned(86,16));
          config_reg(4)(15 downto 11) <= std_logic_vector(to_signed(VMAX_tb,5));
          config_reg(4)(10 downto 6) <= std_logic_vector(to_signed(VMIN_tb,5));
          config_reg(4)(5 downto 2) <= std_logic_vector(to_unsigned(TINC_tb,4));
          config_reg(4)(1 downto 1) <= std_logic_vector(to_unsigned(WEIGHT_INIT_tb,1));
          config_reg(4)(0 downto 0) <= std_logic_vector(to_unsigned(0,1));
          
          config_reg(5)(31 downto 28) <= std_logic_vector(to_unsigned(INIT_COUNT_E_tb,4));
          config_reg(5)(27 downto 27) <= std_logic_vector(to_unsigned(ACC_INIT_TYPE_tb,1));
          config_reg(5)(26 downto 23) <= std_logic_vector(to_unsigned(ACC_INIT_CONST_tb,4));
          config_reg(5)(22 downto 19) <= std_logic_vector(to_unsigned(RESC_COUNT_SIZE_tb,4));
          config_reg(5)(18 downto 13) <= std_logic_vector(to_unsigned(U_MAX_tb,6));
          config_reg(5)(12 downto 6) <= std_logic_vector(to_unsigned(W_BUFFER_tb,7));
					-- Modified by AS: assigning new configuration parameters Q and WR --
					config_reg(5)(5 downto 1) <= std_logic_vector(to_unsigned(Q_tb,5));
					config_reg(5)(0 downto 0) <= std_logic_vector(to_unsigned(WR_tb,1));
					--config_reg(5)(5 downto 0) <= (others => '0');
					---------------------------			

          
          config_reg(0)(0) <= '0';
          address := std_logic_vector(to_unsigned(16#200#, 12)) & std_logic_vector(to_unsigned(0, 20));
          wait until clk'event and clk = '1'; 
          n_words := 6;
          ahbwrite(address, config_reg, "10", n_words, 2, ctrl);
          config_reg(0)(0) <= '1';
          ahbwrite(address, config_reg(0), "10", "10", '1', 2, true , ctrl);
        end if;
        while Awaitingconfig = '1' loop
          assert Finished = '1' report "Error between sequential compressions, value of Finished shall be kept high" severity error; 
          wait until clk'event and clk = '1';
        end loop;
        assert false report "AwaitingConfig lowered correctly when configuration was received" severity note;
        assert (Ready = '1') report "Ready not asserted correctly when IP core has been configured" severity warning;
        assert false report "Ready asserted correctly when IP core is ready to receive new samples" severity note;
        assert Finished = '0' report "Error for sequential compressions, Finished shall be de-asserted with AwaitingConfig" severity error; 
        while Finished = '0' loop
          assert Error_s = '0' report "Unexpected IP core error during compression" severity error; 
          wait until clk'event and clk = '1';
        end loop;
        assert false report "Finished correctly activated when compression finished" severity note;
        assert Error_s = '0' report "Unexpected IP core error after compression" severity error;
        wait until AwaitingConfig = '1';
        assert false report "AwaitingConfig correctly activated after compression finished" severity note;
        assert false report "Two different compressions test performed" severity note;          
      end test5;
      
    ----------------------------------------------------------------------------------------------------------------------------------------------
    --! Error test (Invalid configuration is sent for the first compression, and after the IP responds properly, the configuration value is fixed)
    ----------------------------------------------------------------------------------------------------------------------------------------------
    procedure test9 is
          variable n_words: integer := 0;
      begin
        assert (Finished /= '1') report "Finished started with a high value" severity warning;
        assert (Ready /= '1') report "Ready started with a high value" severity warning;
        assert (AwaitingConfig /= '0') report "AwaitingConfig started with a low value" severity warning;
        if (EN_RUNCFG_G = 1) then 
          assert false report "Sending invalid configuration..." severity note;
          config_reg <= (others => (others => '0'));
          config_reg(1)(31 downto 0) <= std_logic_vector(to_unsigned(ExtMemAddress_G_tb, 12)) & std_logic_vector(to_unsigned(0, 20));
      
          config_reg(2)(31 downto 16) <= std_logic_vector(to_unsigned(65535,16));
          config_reg(2)(15 downto 11) <= std_logic_vector(to_unsigned(D_conf_test,5));
          config_reg(2)(10 downto 10) <= std_logic_vector(to_unsigned(IS_SIGNED_tb,1));
          config_reg(2)(9 downto 9) <= std_logic_vector(to_unsigned(DISABLE_HEADER_tb,1));
          config_reg(2)(8 downto 7) <= std_logic_vector(to_unsigned(ENCODER_SELECTION_tb,2));
          config_reg(2)(6 downto 3) <= std_logic_vector(to_unsigned(P_tb,4));
          config_reg(2)(2 downto 0) <= (others => '0');     

          config_reg(3)(31 downto 16) <= std_logic_vector(to_unsigned(Ny_tb,16));
          config_reg(3)(15 downto 15) <= std_logic_vector(to_unsigned(PREDICTION_tb,1));
          config_reg(3)(14 downto 14) <= std_logic_vector(to_unsigned(LOCAL_SUM_tb,1));
          config_reg(3)(13 downto 9) <= std_logic_vector(to_unsigned(OMEGA_tb,5));
          config_reg(3)(8 downto 2) <= std_logic_vector(to_unsigned(R_tb,7));
          config_reg(3)(1 downto 0) <= (others => '0');   
      
          config_reg(4)(31 downto 16) <= std_logic_vector(to_unsigned(Nz_conf_test,16));
          config_reg(4)(15 downto 11) <= std_logic_vector(to_signed(VMAX_tb,5));
          config_reg(4)(10 downto 6) <= std_logic_vector(to_signed(VMIN_tb,5));
          config_reg(4)(5 downto 2) <= std_logic_vector(to_unsigned(TINC_tb,4));
          config_reg(4)(1 downto 1) <= std_logic_vector(to_unsigned(WEIGHT_INIT_tb,1));
          config_reg(4)(0 downto 0) <= std_logic_vector(to_unsigned(ENDIANESS_conf_test,1));
          
          config_reg(5)(31 downto 28) <= std_logic_vector(to_unsigned(INIT_COUNT_E_tb,4));
          config_reg(5)(27 downto 27) <= std_logic_vector(to_unsigned(ACC_INIT_TYPE_tb,1));
          config_reg(5)(26 downto 23) <= std_logic_vector(to_unsigned(ACC_INIT_CONST_tb,4));
          config_reg(5)(22 downto 19) <= std_logic_vector(to_unsigned(RESC_COUNT_SIZE_tb,4));
          config_reg(5)(18 downto 13) <= std_logic_vector(to_unsigned(U_MAX_tb,6));
          config_reg(5)(12 downto 6) <= std_logic_vector(to_unsigned(W_BUFFER_tb,7));
					-- Modified by AS: assigning new configuration parameters Q and WR --
					config_reg(5)(5 downto 1) <= std_logic_vector(to_unsigned(Q_tb,5));
					config_reg(5)(0 downto 0) <= std_logic_vector(to_unsigned(WR_tb,1));
					--config_reg(5)(5 downto 0) <= (others => '0');
					---------------------------	

          
          config_reg(0)(0) <= '0';
          address := std_logic_vector(to_unsigned(16#200#, 12)) & std_logic_vector(to_unsigned(0, 20));
          wait until clk'event and clk = '1'; 
          n_words := 6;
          ahbwrite(address, config_reg, "10", n_words, 2, ctrl);
          config_reg(0)(0) <= '1';
          ahbwrite(address, config_reg(0), "10", "10", '1', 2, true , ctrl);
          wait until clk'event and clk = '1';
        end if;
        wait until (clk'event and clk = '1') and Awaitingconfig = '0';
        assert false report "AwaitingConfig lowered correctly when configuration was received (even with error)" severity note;
        assert (Error_s /= '1') report "Error has been correctly asserted" severity note;
        assert (Error_s = '1') report "Error has not been correctly asserted when error" severity error;
        assert (Finished /= '1') report "Finished has been correctly asserted after an error" severity note;
        assert (Finished = '1') report "Finished has not been correctly asserted after an error" severity error;
        wait until Awaitingconfig = '1';
        assert false report "AwaitingConfig asserted correctly after an error" severity note;
        if (EN_RUNCFG_G = 1) then
          assert false report "Sending a new configuration..." severity note;
          config_reg(0)(0) <= '0';
          address := std_logic_vector(to_unsigned(16#200#, 12)) & std_logic_vector(to_unsigned(0, 20));
          wait until clk'event and clk = '1'; 
          config_reg(2)(31 downto 16) <= std_logic_vector(to_unsigned(Nx_conf_test,16));
          ahbwrite(address, config_reg, "10", n_words, 2, ctrl);
          config_reg(0)(0) <= '1';
          ahbwrite(address, config_reg(0), "10", "10", '1', 2, true , ctrl);
          wait until clk'event and clk = '1';
        end if;
        while Awaitingconfig = '1' loop
          assert Finished = '1' report "Error between sequential compressions, value of Finished shall be kept high" severity error; 
          wait until clk'event and clk = '1';
        end loop;
        assert false report "AwaitingConfig lowered correctly when configuration was received" severity note;
        assert (Ready = '1') report "Ready not asserted correctly when IP core has been configured" severity warning;
        assert false report "Ready asserted correctly when IP core is ready to receive new samples" severity note;
        assert Finished = '0' report "Error for sequential compressions, Finished shall be de-asserted with AwaitingConfig" severity error; 
        while Finished = '0' loop
          assert Error_s = '0' report "Unexpected IP core error during compression" severity error; 
          wait until clk'event and clk = '1';
        end loop;
        assert false report "Finished correctly activated when compression finished" severity note;
        assert Error_s = '0' report "Unexpected IP core error after compression" severity error;
        wait until AwaitingConfig = '1';
        assert false report "AwaitingConfig correctly activated after compression finished" severity note;
        assert false report "Configuration error and one compression test performed" severity note;
      end test9;
   begin
    print("**********************************************************");
    print("Starting simulation of test: "&test_identifier);
    print("**********************************************************");
    ForceStop <= '0';
    clear <= '0';
    Nx_conf_test <= Nx_tb;      
    Nz_conf_test <= Nz_tb;  
    D_conf_test <= D_tb;
    ENDIANESS_conf_test <= ENDIANESS_tb;
    --need more time here 1000 ns reset is 0, then 3 clk for synchronization
    wait for (3600 ns); 
    assert (AwaitingConfig = '1') report "AwaitingConfig started with a low value" severity failure;
    assert (Finished /= '1') report "Finished started with a high value" severity failure;
    assert (Ready = '0') report "Ready started with a high value" severity failure;
    -- Initialize the control signals
    if (EN_RUNCFG_G = 1 or (EN_RUNCFG_G = 0 and (PREDICTION_TYPE_tb /= 0 and PREDICTION_TYPE_tb /= 3))) then
      ahbtbminit(ctrl);
    end if;
    if (test_id = 4) then
      test4;
    elsif (test_id = 9) then
      test9;
    elsif (test_id = 2) then
      test2;
    elsif (test_id = 5) then
      test5;
		elsif (test_id = 0 or test_id = 62 or test_id = 63 or test_id = 67 or test_id = 80 or test_id = 83) then		-- Modified by AS: new test identifiers 80 and 83 included
      test0;
    elsif (test_id = 10) then
      if (EN_RUNCFG_G = 1) then
        test4;
        test9;
      end if;
      test0;
    end if;
    sim_successful <= true;
    wait until clk'event and clk = '1';
    if (EN_RUNCFG_G = 1 or (EN_RUNCFG_G = 0 and (PREDICTION_TYPE_tb /= 0 and PREDICTION_TYPE_tb /= 3))) then
      ahbtbmdone(1, ctrl);
    end if;
    print("**********************************************************");
    print("         CCSDS123    Testbench Done");
    print("**********************************************************");
    assert false report "**** CCSDS-123 Testbench done ****" severity note; 
    stop(0);
   end process;
   
    
end arch;






