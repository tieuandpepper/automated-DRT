# import OS
import os
import sys
import pandas as pd
from galvani import BioLogic

list_files = []
arg_len = len(sys.argv)
###################################################################
# USE THIS PART AS INPUT. DON'T CHANGE OTHER PARTS IF NOT NECESSARY
input_file = "input_data"
output_file = "output_data"
columns_to_convert = ["freq/Hz", "Re(Z)/Ohm", "Im(Z)/Ohm"]
file_type = "txt"
keeping_header = False
using_index = False
separator = " "
###################################################################
output_file = output_file + "/"
start_data_path = sys.argv[1] if arg_len > 1 else input_file
final_path = (sys.argv[2] + "/") if arg_len > 2 else output_file
if (os.path.exists(start_data_path) == False):
    os.makedirs(start_data_path)

if (os.path.exists(final_path) == False):
    os.makedirs(final_path)

for x in os.listdir(start_data_path):
    if x.endswith(".mpr"):
        list_files.append(x)
        file = BioLogic.MPRfile(start_data_path + "/" + x)
        df = pd.DataFrame(file.data)
        df = df.rename(columns={"-Im(Z)/Ohm":"Im(Z)/Ohm"})
        df["Im(Z)/Ohm"] = df["Im(Z)/Ohm"] * (-1)
        filename = final_path + x[:-3] + file_type
        if len(columns_to_convert) == 0:
            df.to_csv(filename,index=using_index, header=keeping_header, sep= separator)
        else:
            df[columns_to_convert].to_csv(filename,index=using_index, header=keeping_header, sep= separator)