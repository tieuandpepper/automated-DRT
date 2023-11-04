# import OS
import os
import pandas as pd
from galvani import BioLogic

list_files = []

###################################################################
# USE THIS PART AS INPUT. DON'T CHANGE OTHER PARTS IF NOT NECESSARY
start_data_path = "data"
final_path = "data_parsed/"
columns_to_convert = ["freq/Hz", "Re(Z)/Ohm", "-Im(Z)/Ohm"]
file_type = "txt"
keeping_header = False
using_index = False
separator = " "
###################################################################

for x in os.listdir(start_data_path):
    if x.endswith(".mpr"):
        list_files.append(x)
        file = BioLogic.MPRfile(start_data_path + "/" + x)
        df = pd.DataFrame(file.data)
        filename = final_path + x[:-3] + file_type
        if len(columns_to_convert) == 0:
            df.to_csv(filename,index=using_index, header=keeping_header, sep= separator)
        else:
            df[columns_to_convert].to_csv(filename,index=using_index, header=keeping_header, sep= separator)