|-lab2-2_2016K8009908007/                                Ŀ¼lab2-2��Ʒ
|   |--lab2-2_2016K8009908007.pdf/                     ʵ�鱨��
|   |--mycpu_verify/                                             Ŀ¼����ʵ�� CPU ����֤����
|   |   |--rtl/                                                          Ŀ¼�� SoC_lite ��Դ�롣
|   |   |   |--soc_lite_top.v                                       SoC_lite �Ķ��㡣
|   |   |   |--myCPU/                                              Ŀ¼����ʵ�� CPU Դ�롣
|   |   |   |--CONFREG/                                          Ŀ¼��confreg ģ��
|   |   |   |--BRIDGE/                                              Ŀ¼��bridge_1x2 ģ ��
|   |   |   |--xilinx_ip/                                              Ŀ¼��Xilinx IP������ clk_pll��inst_ram��data_ram��
|   |   |--testbench/                                               Ŀ¼�������ļ���
|   |   |   |--mycpu_tb.v                                          ���涥��
|   |   |--run_vivado/                                             Ŀ¼������ Vivado ���̡�
|   |   |   |--soc_lite.xdc                                          Vivado ������Ƶ�Լ���ļ�
|   |   |   |--mycpu/                                               Ŀ¼��Vivado ������ Vivado ����
|   |   |   |   |--mycpu.xpr                                       �����ű�
|   |   |   |   |--mycpu.bit                                        bit �ļ�