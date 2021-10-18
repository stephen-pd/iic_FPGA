# iic_FPGA
首先是EEPROM通过IIC读出，EEPROM其实就是一块掉电不缺失的存储体，为什么需要这个东西呢？
一般是用来传递参数信息，比如在FPGA传出视频流给显示屏时，显示屏需要先从FPGA读取视频流的参数，比如分辨率，帧率等等，这些信息则储存在EEPROM中需要通过iic读取

iic协议相信大家都知道，主设备master通过iic协议传递传递信息给slaver，整个读取过程包括：start--写从机地址--读数据--stop；
其中SCL一般由主机提供即一段时钟，从机地址一般是七位

start信号在SCL高时SDA下降；
写从机地址这个过程则是主机发送数据给从机，I2C规定当SCL为高时，SDA处于传输状态不允许改变；SCL为低时允许改变；除此之外还要加一位读写位1代表主机读数据0代表写数据
stop信号在SCL高时SDA上升实现

# 以下是FPGA实现
本次slaveaddress是七位地址1010000
以下为DATABYTE_SHREG进程用来输出dataByte，dataByte是八位寄存器用来存储进来的数据
DATABYTE_SHREG: process (SampleClk) 
	begin
		if Rising_Edge(SampleClk) then
			if ((latchData = '1' and fSCLFalling = '1') or state = stIdle or fStart = '1') then
				dataByte <= D_I; --latch data
				bitCount <= 7;
			elsif (shiftBitOut = '1' and fSCLFalling = '1') then
				dataByte <= dataByte(dataByte'high-1 downto 0) & dSDA;
				bitCount <= bitCount - 1;
			elsif (shiftBitIn = '1' and fSCLRising = '1') then
				dataByte <= dataByte(dataByte'high-1 downto 0) & dSDA;
				bitCount <= bitCount - 1;
			end if;
		end if;
	end process;
