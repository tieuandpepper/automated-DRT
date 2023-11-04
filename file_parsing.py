# from galvani import BioLogic
# import pandas as pd
# import matplotlib.pyplot as plt

# mpr_file = BioLogic.MPRfile('LZ019NMC(5.5)(5-16in)SC3UA80_14MPa_cell2_14_PEIS_C02.mpr')
# df = pd.DataFrame(mpr_file.data)
# print(df.describe())
# # print(df["Re(Z)/Ohm"])
# print(df["-Im(Z)/Ohm"])
# fig,ax = plt.subplots()
# ax.scatter(df["Re(Z)/Ohm"],df["-Im(Z)/Ohm"])
# plt.show()

# import OS
import os
import pandas as pd
from galvani import BioLogic

list_files = []
for x in os.listdir():
    if x.endswith("jdb11-1_c3_gcpl_5cycles_2V-3p8V_C-24_data_C09.mpr"):
        list_files.append(x)
        file = BioLogic.MPRfile(x)
        df = pd.DataFrame(file.data)
        df.to_csv(x[:-3] + 'csv')