|-lab2-2_2016K8009908007/                                目录lab2-2作品
|   |--lab2-2_2016K8009908007.pdf/                     实验报告
|   |--mycpu_verify/                                             目录，自实现 CPU 的验证环境
|   |   |--rtl/                                                          目录， SoC_lite 的源码。
|   |   |   |--soc_lite_top.v                                       SoC_lite 的顶层。
|   |   |   |--myCPU/                                              目录，自实现 CPU 源码。
|   |   |   |--CONFREG/                                          目录，confreg 模块
|   |   |   |--BRIDGE/                                              目录，bridge_1x2 模 块
|   |   |   |--xilinx_ip/                                              目录，Xilinx IP，包含 clk_pll、inst_ram、data_ram。
|   |   |--testbench/                                               目录，仿真文件。
|   |   |   |--mycpu_tb.v                                          仿真顶层
|   |   |--run_vivado/                                             目录，运行 Vivado 工程。
|   |   |   |--soc_lite.xdc                                          Vivado 工程设计的约束文件
|   |   |   |--mycpu/                                               目录，Vivado 创建的 Vivado 工程
|   |   |   |   |--mycpu.xpr                                       工作脚本
|   |   |   |   |--mycpu.bit                                        bit 文件