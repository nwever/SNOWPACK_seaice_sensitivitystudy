import netCDF4 as nc
import pandas as pd
import os as os
import numpy as np
import argparse

def read_files(directory):
    data = []
    for filename in os.listdir(directory):
        if filename.endswith(".nc"):
            file_path = os.path.join(directory, filename)

            with nc.Dataset(file_path, 'r') as ds:
                time_var = ds.variables['time']
                date = [t.strftime("%Y-%m-%dT%H:%M:%S") for t in nc.num2date(time_var[:], time_var.units)]
                if 'temp' in ds.variables:
                        ta = list(ds.variables['temp'][:]+273.15)
                else:
                        ta = list(ds.variables['temp_2m'][:]+273.15)
                if 'rh' in ds.variables:
                        rh = list(ds.variables['rh'][:]/100.)
                else:
                        rh = list(ds.variables['rh_2m'][:]/100.)
                tss = list(ds.variables['skin_temp_surface'][:]+273.15)
                if 'wspd_u_mean' in ds.variables:
                        u = list(ds.variables['wspd_u_mean'][:])
                else:
                        u = list(ds.variables['wspd_u_mean_10m'][:])
                if 'wspd_v_mean' in ds.variables:
                        v = list(ds.variables['wspd_v_mean'][:])
                else:
                        v = list(ds.variables['wspd_v_mean_10m'][:])
                ilwr = list(ds.variables['down_long_hemisp'][:])
                iswr = list(ds.variables['down_short_hemisp'][:])
                data_s = {'Date': date, 'ta': ta, 'rh': rh, 'tss': tss, 'u': u, 'v': v, 'ilwr': ilwr, 'iswr': iswr}
            data = pd.concat([pd.DataFrame(data), pd.DataFrame(data_s)])
    return data

parser = argparse.ArgumentParser(description='This script processes a bunch of netcdf files.')
parser.add_argument('dir', help='provide a path containing the netcdf files.')
args = parser.parse_args()

dir = args.dir
outfile = '/dev/stdout'

dataframe = read_files(dir)
dataframe.sort_values(by='Date').to_csv(outfile, sep=' ', index=False)
