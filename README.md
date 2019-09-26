# Konami_arcade

Hello everyone, I created this repository to share it with other people interested in preserving Konami's arcade boards in the form of core for FPGA. All the material I collect as well as my own developments will be uploaded to the repository. I would like the authorship of the material to be recognized if someone considers it useful for their own developments.

## Developments:

### Aliens arcade board
![](/Aliens/Documentation/photos/100_9009.jpg?raw=true "Aliens arcade board")
#### Custom IC's pinout documentation:

I've created this PDF with a description of the IC's as I found on the Aliens arcade board:
https://github.com/RndMnkIII/Konami_arcade/blob/master/Aliens/Documentation/konami_custom_ICs_Aliens.pdf


I have also included photographs of the IC's to facilitate the identification of the pins for pickling these chips. I should be grateful for the help provided to [@furrtek](https://twitter.com/furrtek?s=17) in this regard, as it is collaborating to reverse engineer the operation of these circuits.

#### Konami-2 nano adapter:
![](Aliens/custom_pcbs/Konami-2_DE10Nano_adapter/Konami-2_DE10Nano_adapter.jpg?raw=true "Konami-2 nano adapter")
I have developed a pcb to be able to debug the signals of the konami-2 cpu (052526) using the FPGA DE10-Nano, it is simply an appropriate interface to route the signals from the cpu pins to the GPIO1 connector of the FPGA by a bidirectional conversion of TTL 5v and CMOS 3.3v levels.

All the schematics of the Kicad version 5.1 board are available in the repository for download, as well as the step files with the 3d models that are not in the standard Kicad library that I have used for the footprints of the components.

Schematic:
https://github.com/RndMnkIII/Konami_arcade/blob/master/Aliens/custom_pcbs/Konami-2_DE10Nano_adapter/esquemas/SCHEMATIC.pdf