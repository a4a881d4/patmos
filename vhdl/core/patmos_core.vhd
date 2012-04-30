library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.patmos_type_package.all;

entity patmos_core is 
  port
  (
    clk                   : in std_logic;
    rst                   : in std_logic;
    led         		  : out std_logic
   -- txd  			      : out std_logic
  --    rxd     : in  std_logic;
  );
end entity patmos_core;

architecture arch of patmos_core is 

signal pc                              : unsigned(32 - 1 downto 0);
signal pc_next                         : unsigned(32 - 1 downto 0);
signal pc_offset                       : unsigned(32 - 1 downto 0);
signal mux_branch                      : unsigned(32 - 1 downto 0);
signal branch                          : std_logic := '0';
signal fetch_din                       : fetch_in_type;
signal fetch_dout                      : fetch_out_type;
signal decode_din                      : decode_in_type;
signal decode_dout                     : decode_out_type;
signal alu_din                         : alu_in_type;
signal alu_dout                        : alu_out_type;
signal execute_din                     : execution_in_type;
signal execute_dout                    : execution_out_type;
signal mem_din                         : mem_in_type;
signal mem_dout                        : mem_out_type;
signal mux_mem_reg                  	  : unsigned(31 downto 0); 
signal mux_alu_src                     : unsigned(31 downto 0); 
signal alu_src1                        : unsigned(31 downto 0);
signal alu_src2                        : unsigned(31 downto 0);
signal fw_ctrl_rs1                     : forwarding_type;
signal fw_ctrl_rs2                     : forwarding_type;
signal br_src1                         : unsigned(31 downto 0);
signal br_src2                         : unsigned(31 downto 0);
signal fw_ctrl_br1                     : forwarding_type;
signal fw_ctrl_br2                     : forwarding_type;
signal mem_data_out           	        : unsigned(31 downto 0); 
signal branch_taken                    : std_logic; 
signal is_beq                          : std_logic; 
signal beq_imm                         : unsigned(31 downto 0);  

------------------------------------------------------- uart signals

--    component sc_uart                     --  Declaration of uart driver
--    generic (addr_bits : integer := 2;
--             clk_freq  : integer := 50000000;
--             baud_rate : integer := 115200;
--             txf_depth : integer := 16; txf_thres : integer := 8;
--             rxf_depth : integer := 16; rxf_thres : integer := 8);
--    port(
--      clk   : in std_logic;
--      reset : in std_logic;
--
--      address : in  std_logic_vector(1 downto 0);
--      wr_data : in  std_logic_vector(31 downto 0);
--      rd, wr  : in  std_logic;
--      rd_data : out std_logic_vector(31 downto 0);
--      rdy_cnt : out unsigned(1 downto 0);
--      txd     : out std_logic;
--      rxd     : in  std_logic;
--      ncts    : in  std_logic;
--      nrts    : out std_logic
--      );
--  end component;
  signal address : std_logic_vector(1 downto 0)  := (others => '0');
  signal wr_data : std_logic_vector(31 downto 0) := (others => '0');
  signal rd, wr  : std_logic                     := '0';
  signal rd_data : std_logic_vector(31 downto 0);
  signal rdy_cnt : unsigned(1 downto 0);

 -- signal led : std_logic;
  signal toggle : std_logic := '0';
                               
  signal cnt : unsigned(31 downto 0) := (others => '0'); 
                                     
                                     constant CLK_FREQ : integer := 200000000;
  constant BLINK_FREQ : integer := 1;
  constant CNT_MAX    : integer := CLK_FREQ/BLINK_FREQ/2-1;

  signal blink : std_logic := '0';
  --signal txd     : std_logic;
  signal rxd     : std_logic;


begin -- architecture begin
------------------------------------------------------- fetch	
		  
  is_beq <= '1' when fetch_dout.instruction(26 downto 22) = "11111" else '0';
  branch <= branch_taken and is_beq;
  beq_imm <= "0000000000000000000000000" & fetch_dout.instruction(6 downto 0);
  
  led <= mem_dout.write_back_reg_out(0);
  fetch_din.pc <= pc_next;
  
  fet: entity work.patmos_fetch(arch)
	port map(clk, rst, fetch_din, fetch_dout);

  pc_adder: entity work.patmos_adder(arch)
  port map(pc, "00000000000000000000000000000100", pc_next);
  
  mux_pc: entity work.patmos_mux_32(arch)
  port map(pc_next, pc_offset, branch, mux_branch);
  
  pc_gen: entity work.patmos_pc_generator(arch)
  port map(clk, rst, mux_branch, pc);

  inst_mem: entity work.patmos_rom(arch)
  port map(pc, fetch_din.instruction);
-------------------------------------------------------- decode
  pc_offset_adder: entity work.patmos_adder(arch) -- for branch instruction
  port map(fetch_dout.pc, beq_imm, pc_offset);

  reg_file: entity work.patmos_register_file(arch)
	port map(clk, rst, fetch_dout.instruction(16 downto 12), fetch_dout.instruction(11 downto 7),
	         mem_dout.write_back_reg_out, decode_din.rs1_data_in, decode_din.rs2_data_in,
	          mux_mem_reg, mem_dout.reg_write_out);
	 
  decode_din.operation <= fetch_dout.instruction;
	dec: entity work.patmos_decode(arch)
	port map(clk, rst, decode_din, decode_dout);

  mux_br1: entity work.patmos_forward_value(arch)
  port map(execute_dout.alu_result_out, mux_mem_reg, decode_din.rs1_data_in, br_src1, fw_ctrl_br1);
                                                         
  mux_br2: entity work.patmos_forward_value(arch)
  port map(execute_dout.alu_result_out, mux_mem_reg, decode_din.rs2_data_in, br_src2, fw_ctrl_br2);
  
  forward_br: entity work.patmos_forward(arch)
  port map(fetch_dout.instruction(16 downto 12), fetch_dout.instruction(11 downto 7), execute_dout.reg_write_out, mem_dout.reg_write_out, 
           execute_dout.write_back_reg_out, mem_dout.write_back_reg_out, fw_ctrl_br1, fw_ctrl_br2);
  
  equal_check: entity work.patmos_equal_check(arch)
  port map(br_src1, br_src2, branch_taken);

  ------------------------------------------------------ execute
  mux_imm: entity work.patmos_mux_32(arch) -- immediate or rt
  port map(decode_dout.rs2_data_out, decode_dout.ALUi_immediate_out, 
           decode_dout.alu_src_out, mux_alu_src);

  mux_rs1: entity work.patmos_forward_value(arch)
  port map(execute_dout.alu_result_out, mux_mem_reg, decode_dout.rs1_data_out, alu_src1, fw_ctrl_rs1);
                                                         
  mux_rs2: entity work.patmos_forward_value(arch)
  port map(execute_dout.alu_result_out, mux_mem_reg, decode_dout.rs2_data_out, alu_src2, fw_ctrl_rs2);
  
  forward: entity work.patmos_forward(arch)
  port map(decode_dout.rs1_out, decode_dout.rs2_out, execute_dout.reg_write_out, mem_dout.reg_write_out, 
           execute_dout.write_back_reg_out, mem_dout.write_back_reg_out, fw_ctrl_rs1, fw_ctrl_rs2);
  
  
  
  
  alu_din.rs1 <= alu_src1;
  alu_din.rs2 <= mux_alu_src;
  alu_din.inst_type <= decode_dout.inst_type_out;
  alu_din.ALU_function_type <= decode_dout.ALU_function_type_out;
  
  
  alu: entity work.patmos_alu(arch)
  port map(clk, rst, alu_din, alu_dout);
  
  -----------------------
  execute_din.reg_write_in <= decode_dout.reg_write_out;
  execute_din.mem_read_in <= decode_dout.mem_read_out;
  execute_din.mem_write_in <= decode_dout.mem_write_out;
  execute_din.mem_to_reg_in <= decode_dout.mem_to_reg_out;
  execute_din.alu_result_in <= alu_dout.rd;
  execute_din.write_back_reg_in <= decode_dout.rd_out;
  execute_din.mem_write_data_in <= alu_src2;
  execute: entity work.patmos_execute(arch)
  port map(clk, rst, execute_din, execute_dout);
  

  ------------------------------------------------------- memory
  -- memory access
  memory: entity work.patmos_data_memory(arch)
  port map(clk, rst, execute_dout.alu_result_out, 
            execute_dout.mem_write_data_out,
            mem_data_out, 
            execute_dout.mem_read_out, execute_dout.mem_write_out);
  --clk, rst, add, data_in(store), data_out(load), read_en, write_en

  --------------------------
  mem_din.reg_write_in <= execute_dout.reg_write_out;
  mem_din.mem_to_reg_in <= execute_dout.mem_to_reg_out;
  mem_din.alu_result_in <= execute_dout.alu_result_out;
  mem_din.write_back_reg_in <= execute_dout.write_back_reg_out;
  mem_din.mem_data_in <= mem_data_out;
  mem_din.mem_write_data_in <= execute_dout.mem_write_data_out;
  memory_stage: entity work.patmos_mem_stage(arch)
  port map(clk, rst, mem_din, mem_dout);

  ------------------------------------------------------- write back
  
--  write_back: entity work.patmos_mux_32(arch)
--  port map(mem_dout.alu_result_out, mem_dout.mem_data_out, mem_dout.mem_to_reg_out, mux_mem_reg);
  
  

  write_back: process(mem_dout.alu_result_out, mem_dout.mem_data_out, mem_dout.mem_to_reg_out)
	begin
		if(mem_dout.mem_to_reg_out = '0') then
			mux_mem_reg <= mem_dout.alu_result_out;
		elsif(mem_dout.mem_to_reg_out = '1') then
			mux_mem_reg <= mem_dout.mem_data_out;
		else mux_mem_reg <= mem_dout.alu_result_out;
			end if;
	end process;

  
  ------------------------------------------------------ uart
  
  
--    sc_uart_inst : sc_uart port map       -- Maps internal signals to ports
--    (
--      address => address,
--      wr_data => wr_data,
--      rd      => rd,
--      wr      => wr,
--      rd_data => rd_data,
--      rdy_cnt => rdy_cnt,
--      clk     => clk,
--      reset   => rst,
--      txd     => txd,
--      rxd     => rxd,
--      ncts    => '0',
--      nrts    => open
--      );
--  
--
--  process(clk, rst)                        -- blink the led
--    begin
--    
--    if rst = '1' then
--      cnt <= (others => '0');
--      wr  <= '0'; 
--    elsif rising_edge(clk) then
--                    if cnt = 5 then
--                      cnt   <= (others => '0');
--                      blink <= not blink;
--                      wr    <= '1'; 
--                    else
--                      cnt <= cnt + 1; 
--                       wr <= '0';
--                    end if;
--  end if;
--  end process;
--
--led <= blink;
--address(0) <= '1';
--
--process(blink)                          -- write to uart
--begin
--     if blink = '1' then
--       wr_data <= std_logic_vector(to_unsigned(50, 32));
--     else
--       wr_data <= std_logic_vector(decode_din.rs1_data_in);
--     end if;
--end process;

end architecture arch;


