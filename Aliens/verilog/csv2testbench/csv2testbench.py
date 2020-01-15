# csv2testbench.py
# @RndMnkIII. 15/01/2020
# Description:
# Python script that convert logic analizer csv captured data (with time control signal and signal values)
# into a suitable verilog testbench data with calculated delays, each signal enclosed in initial blocks.
# For the clock signal also the script creates a sysclk clock usually used in FPGA implementation as higher level clock.
# The sysclk_ratio variable control the sysclk/clk ratio and must be a integer value. (in the example is x4 ratio).
# see the example CRAMCS_capture.csv format. Tested with Icarus verilog.

# Usage:
# csv2testbench.py > output.txt
# paste the output.txt in the testbench to test (AliensBusControl_TB_CAPTURED_async.v example included)
# TODO:
# print testbench sentences using specified tab level:
# print('\t' * tab_level, 'string....', .... , sep='') 

import csv
import re
import sys


#------ Start of relevant variables ------
csvfilename = 'CRAMCS_capture.csv'
TO_NANOSECONDS = 1.0e9 #timescale units
time_header_name = 'Time'
clk_name = 'NCLK12'
sysclk_name = 'SYSCLK'
#------ Start of relevant variables ------


time_nf = 2
time_offset = 0.0
abs_time = 0.0
last_time = 0.0
last_signal_value=' '
rel_time = 0.0
acum_time = 0.0

first_clock_capture = 1
sysclk_ratio = 4 #integer ratio
sysclk_value = 1;
first_sysclk_risedge_t = -1.0;
last_sysclk_risedge_t = -1.0;
tc1 = -1.0 #store clk_name first rising edge time 
tc2 = -1.0 #store clk_name second rising edge time 

RFF_clkrisedge=-1 #Row file first clock rising edge (used for discard earlier rows)
RFL_clkrisedge=-1 #Row file last clock rising edge (used for discard earlier rows)

f = open(csvfilename, 'r')

with f:
    #read some bytes and test to find header
    preview = f.read(1024)
    csv_has_header = csv.Sniffer().has_header(preview)
    if (not csv_has_header):
        sys.exit('CSV Header not found, exiting')
    
    f.seek(0) #rewind file to zero offset
    reader = csv.DictReader(f, delimiter=";")
    #next(reader)
    signal_list_names = reader.fieldnames
    #signal_list_names.remove(time_header_name)
    
    #print(signal_list_names)
    
    ###START OF FIND FIRST CLOCK RISING EDGE LINE ROW###
    contador=0
    
    #First located row number with clock signal rising edge 
    #and store value in RFF_clkrisedge
    f.seek(0) #rewind file to zero offset
    reader = csv.DictReader(f, delimiter=";")
        
    last_signal_value=' '
    try:
        for row in reader:
            contador += 1
            if( row[clk_name] != last_signal_value):
                if(row[clk_name] == '1' and last_signal_value == '0' and RFF_clkrisedge == -1):
                    RFF_clkrisedge = contador
                    
                RFL_clkrisedge = contador
            last_signal_value = row[clk_name]
    except csv.Error as e:
        sys.exit('file %s, line %d: %s' % (csvfilename, reader.line_num, e))
        
    if(RFF_clkrisedge == -1):
        sys.exit('No %s clock rising edge detected. Exiting' % (clk_name))
    
    #print('Primer clk risedge en fila:{}', RFF_clkrisedge)
    #print('Ultimo clk risedge en fila:{}', RFL_clkrisedge)
    ###END OF FIND FIRST CLOCK RISING EDGE LINE ROW###
    
    for signal_name in signal_list_names:
        f.seek(0) #rewind file to zero offset
        reader = csv.DictReader(f, delimiter=";")
        
        last_signal_value=' '
        time_offset=0.0
        last_time = 0.0
        contador = 0
        
        
        if(signal_name != time_header_name): #bypass the time signal itself (time_header_name)
            #print("Iteration: {}".format(signal_name))
            print("initial\nbegin")
            try:
                for row in reader:
                    contador += 1
                    
                    if(contador >= RFF_clkrisedge and contador <= RFL_clkrisedge):
                        cadena = re.sub(',', '.', row[time_header_name])
                        
                        abs_time = float(cadena) * TO_NANOSECONDS #Convert to nanoseconds, use as timescale unit
                        #print("* abs_time:{}".format(abs_time))
                        
                        #adjust absolute time for start always from 0 (logic analyzer can start capture before trigger point)
                        if (abs_time < 0.0 and time_offset == 0.0):
                            time_offset = abs_time;
                        abs_time = abs_time - time_offset
                        
                        #print("* offset_abs_time:{}".format(abs_time))
                        rel_time = abs_time - last_time #in verilog testbenches delay time always is relative, not absolute
                        acum_time += rel_time;
                        
                        #print("** rel_time:{}".format(rel_time))
                        #print("** acum_time:{}".format(acum_time))
                        
                        if( row[signal_name] != last_signal_value):
                        
                            ### START signal_name VALUE CHANGE ###    
                            ### START OF SYSCLK PROCESSING ###
                            # clk_name: actually the captured clock signal of the system to be emulated in the verilog testbench
                            # sysclk_name: system wide clock signal used in the destiny system that governs the rest of clocks (clk_name), usually running at
                            # higher clock frequency (sysclk_ratio * clk frequency). In this code is assumed no phase delay between clocks and an integer clock ratio.
                            #
                            #now the sysclk with clk * sysclk_ratio frequency is generated from a clk captured clock period,
                            #because sysclk was not captured but is needed to be generated in sync with clk signal as is (with clk clock uncertainly)
                            if(signal_name == clk_name):
                            
                                if(contador == RFF_clkrisedge):
                                    last_signal_value = '0' #Its assumed that comes from a rising edge the first time
                                    
                                #check first clk rising edge and store absolute time value, sysclk generated with rising edge aligned to clk rising edge.
                                if(row[signal_name] == '1' and last_signal_value == '0'): #is a rising edge, transition from 0 to 1
                                    #print("row[signal_name] == '1'")
                                    if(first_clock_capture == 1): 
                                        #print("first_clock_capture == 1")
                                        #capture the first rising edge of clk
                                        first_clock_capture = 0 #deassert first_clock_capture
                                        first_sysclk_risedge_t = abs_time #captures the time of first rising edge of clk signal
                                        tc2 = abs_time #store time value used for delta time calculation
                                        print("    ", end = '')
                                    else:
                                        #general case capture of rising edge (not first capture)
                                        last_sysclk_risedge_t = abs_time
                                        tc1 = tc2
                                        tc2 = abs_time
                                        delta_t = tc2 - tc1
                                        sysclk_period = delta_t / sysclk_ratio
                                        sysclk_semiperiod = sysclk_period / 2.0
                                        
                                        #print positive value of clk
                                        print("{0} = 1'b1;".format(clk_name)) 
                                        print("    ", end = '')
                                        
                                        for i in range(sysclk_ratio * 2, 0, -1):
                                        
                                            #print negative value of clk
                                            if (i == sysclk_ratio):
                                                print("{0} = 1'b0;".format(clk_name))
                                                print("    ", end = '')
                                                
                                            #print alternating value of sysclk
                                            print("{0} = 1'b{1};".format(sysclk_name, sysclk_value)) 
                                            print("    #{0}; ".format(float("{0:.{time_nf}f}".format( (sysclk_semiperiod), time_nf = time_nf))), end = '')

                                            sysclk_value ^= 1 #toggle sysclk clock
                            ### END OF SYSCLK PROCESSING ###
                            else:
                                ### START OF THE OTHER SIGNALS PROCESSING ###
                                #align testbench input signals with clock rising edge
                                #if(abs_time >= first_sysclk_risedge_t):
                                if (rel_time != 0):
                                    print("    #{0}; ".format(float("{0:.{time_nf}f}".format(acum_time, time_nf = time_nf))), end = '') #round float to 2 decimal positions
                                else:
                                    print("    ", end = '');
                                    
                                #format as 16 bit hexadecimal value or binary 1bit value
                                if(row[signal_name][0].upper() == 'H'):   
                                    print("{0} = 16'{1:s};".format(signal_name, row[signal_name])) 
                                else:    
                                    print("{0} = 1'b{1};".format(signal_name, row[signal_name]))
                                    

                                ### END OF THE OTHER SIGNALS PROCESSING ###
                                
                            #reset acumulated time always after processing a signal value change case
                            acum_time = 0.0    
                        ### END signal_name VALUE CHANGE ###
                        
                        last_signal_value = row[signal_name]
                        last_time = abs_time
            except csv.Error as e:
                sys.exit('file %s, line %d: %s' % (csvfilename, reader.line_num, e))
            print("\nend")        
