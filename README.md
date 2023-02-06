
# Cyboard for the Amstrad CPC
Cyboard is a [Symbiface II](https://www.cpcwiki.eu/index.php/SYMBiFACE_II) clone with Ethernet for the [Amstrad CPC](https://www.cpcwiki.eu/index.php/CPC) range of computers.</br>
![Cyboard v1.1](https://github.com/salafek/cyboard-for-cpc/blob/main/pictures/cyboard-v1.1.png)
## Interface main components and functions
- Compact Flash Card mass storage device
- PS/2 compatible USB Mouse controller
- Real Time Clock
- Ethernet controller with embedded TCP/IP stack
- Reset button

Unlike Symbiface II, Cyboard doesn't integrate RAM or ROM expansion for the CPC.

All the integrated devices are fully compatible with the original Symbiface II thus using the same [I/O port addresses](https://www.cpcwiki.eu/index.php/SYMBiFACE_II:I/O_Map_Summary).</br>
The interface uses a full 16-bit address decoding. A dual 4-input AND gate 74HCT21 and a GAL20V8 PLD is used for this purpose. All the GALs outputs are programmed as combinational outputs.</br>
The interface has a [Mother X4](https://cpcrulez.fr/hardware-interface-mother_x4.htm) compatible connector.</br> 
The CF card works in memory mode so it can be directly addressed as an 8-bit device and has no need for initialization via software.</br>
The mouse controller is a [Microchip PIC16F84A](https://www.microchip.com/en-us/product/PIC16F84A) programmed in assembly and it is clocked by the CPCs 4MHz clock. It supports mice with 5 buttons and scroll wheel.</br>
The RTC module is the famous [DS12887](https://www.analog.com/en/products/ds12887.html#product-overview) which is also used in the original Symbiface II.(variants DS12887A, DS12C887, DS12C887A can also be used)</br>
The network module is based on the [WIZnet's W5100S](https://www.wiznet.io/product-item/w5100s/) embedded ethernet controller and works in indirect parallel bus mode.</br>
In this mode it needs 4 I/O ports:
- #FD20: MR - Common Register MR
- #FD21: IDM_ARH - Upper 8 bits Offset Address Register
- #FD22: IDM_ARL - Lower 8 bits Offset Address Register
- #FD23: IDM_DR - 8 Bits Data Register

[The module](https://www.aliexpress.com/w/wholesale-%22W5100S-Network-Module%22-parallel.html?catId=0&initiative_id=SB_20230206005326&SearchText=%22W5100S%20Network%20Module%22%20parallel&spm=a2g0o.productlist.1000002.0) that's been used in this implementation is one with an integrated 3.3V regulator but also the original WIZnet's [W5100S](https://github.com/Wiznet/Hardware-Files-of-WIZnet/tree/master/05_Network_Module/WIZ810SMJ) and [W6100](https://github.com/Wiznet/Hardware-Files-of-WIZnet/tree/master/05_Network_Module/WIZ610MJ) modules can be used instead, with small changes in the design.</br>

![W5100S module](https://github.com/salafek/cyboard-for-cpc/blob/main/pictures/w5100s-module.png)

## Build info
The schematic and layout were generated with Autodesk EAGLE 9.6.2 free edition</br>
The GAL20V8B files were generated with Atmel WinCupl 5.30.4</br>
The PIC16F84A files were generated with Microchip MPLAB IDE 8.83</br>

## License
Copyright (C) 2023 Dimitris Kefalas

This program is free software: you can redistribute them and/or modify them under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
