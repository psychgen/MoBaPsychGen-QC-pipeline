# bokeh serve --allow-websocket-origin=p697-submit:5006 ellipseselect.py --args path/to/file.eigenvec
# p697-appn-norment01 can be used instead of p697-submit

import sys
import os
import numpy as np
from functools import partial
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import textwrap
import pandas as pd
pd.options.mode.chained_assignment = None

from bokeh.plotting import figure, ColumnDataSource
from bokeh.models import Select, TextInput, Button, Title
from bokeh.layouts import column, row, gridplot
from bokeh.io import curdoc, export_png


def select_points_inside_ellipse(df, el_x, el_y, el_w, el_h, el_a):
        xc = df.PC1 - el_x
        yc = df.PC2 - el_y

        cos_angle = np.cos(np.radians(180 - el_a))
        sin_angle = np.sin(np.radians(180 - el_a))

        xct = xc * cos_angle - yc * sin_angle
        yct = xc * sin_angle + yc * cos_angle 

        # rad_cc <=1 - point in ellipse
        rad_cc = (xct**2/(el_w/2.)**2) + (yct**2/(el_h/2.)**2)
        selected_i = rad_cc<=1
        return selected_i


def draw_figure():
    # prepare data
    global FILE_PATH, MOBA, TKG
    if FILE_PATH != path_text.value:
        if not os.path.isfile(path_text.value):
            raise FileNotFoundError(f'{path_text.value} file does not exist.')
        FILE_PATH = path_text.value
        print(f'Reading {FILE_PATH}')
        df = read_data(FILE_PATH)
        i_1kg = df.IID.isin(colors_1kg)
        MOBA = df.loc[~i_1kg,:]
        TKG = df.loc[i_1kg,:]
        print(f'    {len(MOBA)} MoBa sampels')
        print(f'    {len(TKG)} 1KG sampels')
    x_range = None if ((AXIS_RANGES['x_start'] is None) or (AXIS_RANGES['x_end'] is None)) else (AXIS_RANGES['x_start'],AXIS_RANGES['x_end'])
    y_range = None if ((AXIS_RANGES['y_start'] is None) or (AXIS_RANGES['y_end'] is None)) else (AXIS_RANGES['y_start'],AXIS_RANGES['y_end'])
    plot1 = figure(tools=TOOLS, plot_height=350, plot_width=350, x_range=x_range, y_range=y_range)
    plot1.x_range.on_change('start', xaxis_range_change)
    plot1.x_range.on_change('end', xaxis_range_change)
    plot1.y_range.on_change('start', yaxis_range_change)
    plot1.y_range.on_change('end', yaxis_range_change)
    plot2 = figure(tools=TOOLS, plot_height=350, plot_width=350,
        x_range=plot1.x_range, y_range=plot1.y_range)

    moba_legend_label = 'MoBa, 0'
    MOBA['SELECTED'] = False
    MOBA['COLOR'] = color_moba
    TKG['SELECTED'] = False
    TKG['LEGEND'] = [f'{iid}, 0' for iid in TKG.IID]

    try:
        el_x, el_y, el_w, el_h, el_a = [float(c.value) for c in ellipse_controls_list]
        plot_ellipse = True
        selected_i = select_points_inside_ellipse(MOBA, el_x, el_y, el_w, el_h, el_a)
        MOBA.COLOR[selected_i] = color_moba_selected
        MOBA.SELECTED[selected_i] = True
        selected_i = select_points_inside_ellipse(TKG, el_x, el_y, el_w, el_h, el_a)
        TKG.SELECTED[selected_i] = True
        for k,v in zip('XYWHA', (el_x, el_y, el_w, el_h, el_a)):
            ELLIPSE_PAR[k] = v
        moba_legend_label = f'MoBa, {MOBA.SELECTED.sum()}'
        tkg_counts = TKG.IID[selected_i].value_counts().to_dict()
        TKG.LEGEND = [f'{iid}, {tkg_counts.get(iid,0)}' for iid in TKG.IID]
        print(f'{MOBA.SELECTED.sum()} MoBa samples selected')
        print(f'{TKG.SELECTED.sum()} 1KG samples selected')
    except ValueError:
        plot_ellipse = False

    moba_source = ColumnDataSource(MOBA)
    tkg_source = ColumnDataSource(TKG)
    plot1.circle('PC1', 'PC2', fill_color='COLOR', size=4, fill_alpha=0.7,
        line_color='COLOR', source=tkg_source)
    plot1.circle('PC1', 'PC2', fill_color='COLOR', size=4, fill_alpha=0.7,
        line_color='COLOR',source=moba_source)
    
    plot2.circle('PC1', 'PC2', fill_color='COLOR', size=4, fill_alpha=0.7,
        line_color='COLOR', legend_label=moba_legend_label, source=moba_source)
    plot2.circle('PC1', 'PC2', fill_color='COLOR', size=4, fill_alpha=0.7,
        line_color='COLOR', legend_group='LEGEND', source=tkg_source)
    
    #plot.circle(x, y, legend_label="sin(x)")

    if plot_ellipse:
        # https://math.stackexchange.com/questions/2645689/what-is-the-parametric-equation-of-a-rotated-ellipse-given-the-angle-of-rotatio
        el_a_rad = np.radians(el_a)
        a =  np.linspace(0, 2*np.pi, 500)
        el_xx = 0.5*el_w*np.cos(a)*np.cos(el_a_rad) - 0.5*el_h*np.sin(a)*np.sin(el_a_rad) + el_x
        el_yy = 0.5*el_w*np.cos(a)*np.sin(el_a_rad) + 0.5*el_h*np.sin(a)*np.cos(el_a_rad) + el_y
        plot1.line(x=el_xx, y=el_yy, line_width=1.5, line_color=color_moba_selected)
        plot2.line(x=el_xx, y=el_yy, line_width=1.5, line_color=color_moba_selected)

    # https://docs.bokeh.org/en/latest/docs/user_guide/styling.html
    title_list = textwrap.wrap(title_text.value, 52)
    for p in (plot1, plot2):
        for line in title_list[::-1]:
            p.add_layout(Title(text=line, text_font_style="normal"), 'above')
        p.title.text_font_style = "normal"
        p.xaxis.axis_label = 'PC1'
        p.xgrid.grid_line_color = None
        p.yaxis.axis_label = 'PC2'
        p.yaxis.major_label_orientation = "vertical"
        p.ygrid.grid_line_color = None
        p.yaxis.axis_label_text_font_style = "normal"
        p.xaxis.axis_label_text_font_style = "normal"
        p.axis.minor_tick_in = 0
        p.axis.major_tick_in = 0
    plot2.legend.label_text_font_size = '6pt'
    plot2.legend.label_standoff = 0
    plot2.legend.spacing = -5
    plot2.legend.padding = 4
    plot2.legend.margin = 0

    grid = gridplot([[plot1, plot2]], toolbar_location='right')
    return grid


def axis_range_change(x_or_y, attr, old, new):
    k = f'{x_or_y}_{attr}'
    AXIS_RANGES[k] = new
    # print(f'{x_or_y} {attr} : {old} > {new}')


def update_plot():
    layout.children[0] = draw_figure()


def save_selection():
    out_prefix = out_path_text.value

    outf = f'{out_prefix}.selected_samples.csv'
    MOBA.loc[MOBA.SELECTED,["FID","IID"]].to_csv(outf, sep='\t', index=False, header=False)

    outf = f'{out_prefix}.selected_samples_1kg.csv'
    TKG.loc[TKG.SELECTED,["FID","IID"]].to_csv(outf, sep='\t', index=False, header=False)

    ellipse_str = '\n'.join([f'{k}:{v}' for k,v in ELLIPSE_PAR.items()])
    outf = f'{out_prefix}.selected_samples.ellipse'
    with open(outf, 'w') as out:
        out.write(ellipse_str)

    # create matplotlib figure and save
    title = '\n'.join(textwrap.wrap(title_text.value, 56))
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11,5))
    ax1.scatter(MOBA.PC1, MOBA.PC2, s=8, marker='o', linewidths=1,
               edgecolor=MOBA.COLOR, color=MOBA.COLOR, alpha=0.7)
    ax1.scatter(TKG.PC1, TKG.PC2, s=8, marker='o', linewidths=1,
               edgecolor=TKG.COLOR, color=TKG.COLOR, alpha=0.7)

    ax2.scatter(TKG.PC1, TKG.PC2, s=8, marker='o', linewidths=1,
               edgecolor=TKG.COLOR, color=TKG.COLOR, alpha=0.7)
    ax2.scatter(MOBA.PC1, MOBA.PC2, s=8, marker='o', linewidths=1,
               edgecolor=MOBA.COLOR, color=MOBA.COLOR, alpha=0.7)

    
    moba_legend_label = f'MoBa, {MOBA.SELECTED.sum()}'
    patch = patches.Patch(color=color_moba, label=moba_legend_label)
    legends_handles = [patch]
    tkg_counts = TKG.IID[TKG.SELECTED].value_counts().to_dict()
    for name in TKG.IID.unique():
        color = colors_1kg[name]
        label = f'{name}, {tkg_counts.get(name,0)}'
        patch = patches.Patch(color=color, label=label)
        legends_handles.append(patch)
    
    el_x, el_y, el_w, el_h, el_a = [ELLIPSE_PAR[k] for k in 'XYWHA']

    for ax in (ax1, ax2):
        ellipse = patches.Ellipse((el_x,el_y), el_w, el_h, el_a, fc='none',
                ec=color_moba_selected, alpha=1.0)
        ax.add_patch(ellipse)
        ax.set_title(title, loc='left', fontsize=10)
        ax.set_xlabel('PC1')
        ax.set_ylabel('PC2')
        ax.set_xlim((AXIS_RANGES['x_start'], AXIS_RANGES['x_end']))
        ax.set_ylim((AXIS_RANGES['y_start'], AXIS_RANGES['y_end']))
        ax.minorticks_on()

    ax2.legend(loc='center left', handles=legends_handles, fontsize=7, bbox_to_anchor=(1.02, 0.5))
    plt.tight_layout()
    outf = f'{out_prefix}.selected_samples.png'
    plt.savefig(outf)


def read_data(file_path):
    ncols = pd.read_csv(file_path, sep=' ', nrows=1).columns.size
    pc_cols = [f'PC{i}' for i in range(1,ncols-1)]
    col_names = ['FID','IID'] + pc_cols
    df = pd.read_csv(file_path, sep=' ', header=None, names=col_names, na_filter=False)
    df['COLOR'] = [colors_1kg.get(iid,color_moba) for i,iid in enumerate(df.IID)]
    return df


# Start script
# global variables

if len(sys.argv) < 2:
    raise ValueError('Provide a path to valid .eigenvec file: --args /path/to/file.eigenvec')
elif not os.path.isfile(sys.argv[1]):
    raise FileNotFoundError(f'{sys.argv[1]} file does not exist.')

color_moba = '#ff0000'
color_moba_selected = '#8b0000'
colors_1kg = {'ASW':'#000000', 'CEU':'#add8e6', 'CHB':'#0000ff', 'CHS':'#7fffd4',
              'CLM':'#ffff00', 'FIN':'#00ff00', 'GBR':'#a020f0', 'IBS':'#ffa500',
              'JPT':'#bebebe', 'LWK':'#556b2f', 'MXL':'#ff00ff', 'PUR':'#00008b',
              'TSI':'#da79d6', 'YRI':'#00cdcd'}

FILE_PATH = None
MOBA = None
TKG = None
ELLIPSE_PAR = dict.fromkeys('XYWHA', 0)

#TOOLS="hover,crosshair,pan,wheel_zoom,zoom_in,zoom_out,box_zoom,undo,
#       redo,reset,tap,save,box_select,poly_select,lasso_select"
TOOLS="crosshair,pan,box_zoom,reset,zoom_in,zoom_out"
#TOOLTIPS = [
#    ('IID', '@IID'),
#    ("x", "$x"),
#    ("y", "$y")
#]
AXIS_RANGES = dict.fromkeys(('x_start', 'x_end', 'y_start', 'y_end'), None)


# Paths and title
path_text = TextInput(title="Path to .eigenvec file", value=sys.argv[1], width=390)
path_text_row = row(path_text, width=400)
out_path_text = TextInput(title="Output prefix", value='', width=390)
out_path_text_row = row(out_path_text, width=400)
title_text = TextInput(title="Title", value='PC1 vs PC2', width=390)
title_text_row = row(title_text, width=400)

# Ellipse controls
center_x = TextInput(title="Center X")
center_y = TextInput(title="Center Y")
width = TextInput(title="Width")
height = TextInput(title="Height")
angle = TextInput(title="Angle")
ellipse_controls_list = [center_x, center_y, width, height, angle]

# Buttons
button_update = Button(label="Update")
button_update.on_click(update_plot)
button_save = Button(label="Save")
button_save.on_click(save_selection)

buttons = row(button_update, button_save, width=400)
ellipse_controls = row(*ellipse_controls_list, width=400) # width=300

xaxis_range_change = partial(axis_range_change, 'x')
yaxis_range_change = partial(axis_range_change, 'y')
grid = draw_figure()

layout = column(grid, path_text_row, out_path_text_row, title_text_row, ellipse_controls, buttons) # sizing_mode='fixed'

# add the layout to curdoc
curdoc().add_root(layout)

