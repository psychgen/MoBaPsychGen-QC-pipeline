import argparse
import sys
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.widgets import Button, TextBox, CheckButtons
import matplotlib.patches as patches
from matplotlib.transforms import Bbox


def parse_args(args):
    parser = argparse.ArgumentParser(description="Select sampels based on PC1 and PC2.")
    parser.add_argument("eigenvec_file", help="eigenvec file created by plink1.9.")
    parser.add_argument("--title", default=None, help="Figure title.")
    parser.add_argument("--out", default=None, help="Output file prefix.")
    return process_args(parser.parse_args(args))

def process_args(args):
    if args.out is None:
        args.out = args.eigenvec_file
    return args


class PCPlot(object):

    color_default = (255,0,0) # (0.81, 0.81, 0.81, 1.) # sky_blue "#56b4e9" (0.3372549, 0.70588235, 0.91372549, 1.)
    color_default = [c/255 for c in color_default]
    color_select = (139,0,0) # (0., 0., 0., 1.) # blue "#0072b2" (0.,0.44705882, 0.69803922, 1.)
    color_select = [c/255 for c in color_select]
    color_ellipse = (139, 0, 0) # (0., 0., 0., 1.) # vermilion "#d55e00" (0.83529412, 0.36862745, 0., 1.)
    color_ellipse = [c/255 for c in color_ellipse]
    pop_1kg = ("ASW", "CEU", "CHB", "CHS", "CLM",
               "FIN", "GBR", "IBS", "JPT", "LWK",
               "MXL", "PUR", "TSI", "YRI")
    colors_1kg = [(0,0,0), (173,216,230), (0,0,255), (127,255,212), (255,255,0),
                  (0,255,0), (160,32,240), (255,165,0), (190,190,190), (85,107,47),
                  (255,0,255), (0,0,139), (218,121,214), (0,205,205)]
    colors_1kg = [[c/255 for c in cc] for cc in colors_1kg]
    # colors_1kg = ['#000000', '#add8e6', '#0000ff', '#7fffd4', '#ffff00',
    #               '#00ff00', '#a020f0', '#ffa500', '#bebebe', '#556b2f',
    #               '#ff00ff', '#00008b', '#da79d6', '#00cdcd'] # list(cmap(np.linspace(0, 1.0, len(pop_1kg))))

    def __init__(self, pc_df, out_file):
        self.pc_df = pc_df.copy()
        min_x, max_x = pc_df.PC1.min(), pc_df.PC1.max()
        min_y, max_y = pc_df.PC2.min(), pc_df.PC2.max()
        i_1kg = self.pc_df.IID.isin(self.pop_1kg)
        self.pc_1kg_df = self.pc_df.loc[i_1kg,:]
        self.pc_df = self.pc_df.loc[~i_1kg,:]
        
        self.pc_df["SELECTED"] = False
        self.pc_1kg_df["SELECTED"] = False
        self.out_file = out_file

        self.fig, self.ax = plt.subplots(figsize=(8,5))
        self.fig.subplots_adjust(right=0.74)
        self._add_widgets()

        self.ax.set_xlabel("PC1")
        self.ax.set_ylabel("PC2")
        
        legend_labels = [f"MoBa, {pc_df.shape[0]}"]
        self.pc_points = self.ax.scatter(self.pc_df.PC1, self.pc_df.PC2, s=6, marker='o',
            linewidths=0, color=self.color_default)
        
        
        self.pop_1kg_points = {}
        for p,c in zip(self.pop_1kg, self.colors_1kg):
            df = self.pc_1kg_df.loc[self.pc_1kg_df.IID == p,:]
            legend_labels.append(f"{p}, {df.shape[0]}")
            self.pop_1kg_points[p] = self.ax.scatter(df.PC1, df.PC2, s=6, marker='o', linewidths=0, color=c)
            
        self.pc_points_above = self.ax.scatter(self.pc_df.PC1, self.pc_df.PC2, s=6, marker='o',
            linewidths=0, color=self.color_default)
        self.pc_points_above.set_visible(False)
        
        offset_x = 0.05*(max_x - min_x)
        offset_y = 0.05*(max_y - min_y)
        min_x -= offset_x
        max_x += offset_x
        min_y -= offset_y
        max_y += offset_y
        self.ax.set_xlim(min_x, max_x)
        self.ax.set_ylim(min_y, max_y)

        self.ellipse = None
        if args.title:
            self.ax.set_title(args.title)
        self.legend = None
        self._update_legend()

        plt.show()


    def _add_widgets(self):
        self.ax_x = plt.axes([0.77, 0.81, 0.1, 0.07])
        self.ax_y = plt.axes([0.77, 0.71, 0.1, 0.07])
        self.ax_width = plt.axes([0.77, 0.61, 0.1, 0.07])
        self.ax_height = plt.axes([0.77, 0.51, 0.1, 0.07])
        self.ax_angle = plt.axes([0.77, 0.41, 0.1, 0.07])
        self.ax_draw = plt.axes([0.77, 0.31, 0.1, 0.07])
        self.ax_clear = plt.axes([0.77, 0.21, 0.1, 0.07])
        self.ax_select = plt.axes([0.77, 0.11, 0.1, 0.07])
        self.ax_check = plt.axes([0.88, 0.11, 0.11, 0.77])

        self.tb_x = TextBox(self.ax_x, 'X ', initial="0.0")
        self.tb_y = TextBox(self.ax_y, 'Y ', initial="0.0")
        self.tb_width = TextBox(self.ax_width, 'W ', initial="0.01")
        self.tb_height = TextBox(self.ax_height, 'H ', initial="0.01")
        self.tb_angle = TextBox(self.ax_angle, 'A ', initial="0.0")

        self.b_draw = Button(self.ax_draw, 'Draw')
        self.b_draw.on_clicked(self._press_draw)
        self.b_clear = Button(self.ax_clear, 'Clear')
        self.b_clear.on_clicked(self._press_clear)
        self.b_select = Button(self.ax_select, 'Select')
        self.b_select.on_clicked(self._press_select)
        self.cb_labels = ["MoBa^", "MoBa_"] + list(self.pop_1kg)
        self.cb_actives = [False] + [True]*len(self.cb_labels)
        self.cb_check = CheckButtons(self.ax_check, labels=self.cb_labels, actives=self.cb_actives)
        self.cb_check.on_clicked(self._check_pop)
        for i, c in enumerate([self.color_default, self.color_default] + self.colors_1kg):
            self.cb_check.labels[i].set_color(c)

    def _update_legend(self):
        if not self.legend is None:
            self.legend.remove()
        legend_labels = [f"MoBa, {self.pc_df.SELECTED.sum()}"]
        tkg_counts = self.pc_1kg_df.IID.loc[self.pc_1kg_df.SELECTED].value_counts()
        tkg_counts = tkg_counts.to_dict()
        legend_labels += [f'{p}, {tkg_counts.get(p,0)}' for p in self.pop_1kg]
        legends_handles = []
        for color, label in zip([self.color_default] + self.colors_1kg, legend_labels):
            patch = patches.Patch(color=color, label=label)
            legends_handles.append(patch)
        self.legend = self.ax.legend(handles=legends_handles, loc='best', fontsize=7)


    def _press_draw(self, event):
        valid_coords = False
        try:
            x = float(self.tb_x.text)
            y = float(self.tb_y.text)
            width = float(self.tb_width.text)
            height = float(self.tb_height.text)
            angle = float(self.tb_angle.text)
            valid_coords = True
        except ValueError as ve:
            print(str(ve))

        if valid_coords:
            if not self.ellipse is None:
                self.ellipse.set_visible(False)
                self.ellipse = None
                
            self.ellipse = patches.Ellipse((x,y), width, height, angle, fc='none',
                ec=self.color_ellipse, alpha=1.0)
            self.ax.add_patch(self.ellipse)

            colors = np.tile(self.color_default, (len(self.pc_df),1))
            # get indices inside ellipse for moba samples
            selected_i = self._select_points_inside_ellipse(self.pc_df)
            print(f"{selected_i.sum()} MoBa samples selected")
            self.pc_df["SELECTED"] = selected_i
            colors[selected_i] = self.color_select
            self.pc_points.set_facecolors(colors)
            self.pc_points_above.set_facecolors(colors)
            
            selected_i = self._select_points_inside_ellipse(self.pc_1kg_df)
            self.pc_1kg_df["SELECTED"] = selected_i
            self._update_legend()
            self.ax.figure.canvas.draw_idle()

            
    def _select_points_inside_ellipse(self, df):
        x,y = self.ellipse.center
        xc = df.PC1 - x
        yc = df.PC2 - y

        cos_angle = np.cos(np.radians(180.-self.ellipse.angle))
        sin_angle = np.sin(np.radians(180.-self.ellipse.angle))

        xct = xc * cos_angle - yc * sin_angle
        yct = xc * sin_angle + yc * cos_angle 

        rad_cc = (xct**2/(self.ellipse.width/2.)**2) + (yct**2/(self.ellipse.height/2.)**2)
        # rad_cc <=1 - point in ellipse
        selected_i = rad_cc<=1
        return selected_i



    def _press_clear(self, event):
        if not self.ellipse is None:
            self.ellipse.set_visible(False)
            self.ellipse = None
            self.pc_df["SELECTED"] = False
            self.pc_points.set_facecolors([self.color_default]*len(self.pc_df))
            self.pc_points_above.set_facecolors([self.color_default]*len(self.pc_df))
            self._update_legend()
            self.ax.figure.canvas.draw_idle()


    def _press_select(self, event):
        if not self.ellipse is None:
            outf = f"{self.out_file}.selected_samples.csv"
            self.pc_df.loc[self.pc_df.SELECTED,["FID","IID"]].to_csv(outf,
                sep="\t", index=False, header=False)
            print(f"Selected sample ids saved to {outf}")
            
            outf = f"{self.out_file}.selected_samples_1kg.csv"
            self.pc_1kg_df.loc[self.pc_1kg_df.SELECTED,["FID","IID"]].to_csv(outf,
                sep="\t", index=False, header=False)
            print(f"Selected 1kg ids saved to {outf}")

            outf = f"{self.out_file}.selected_samples.png"
            # on how to save only some region from the axes see:
            # https://stackoverflow.com/questions/4325733/save-a-subplot-in-matplotlib
            pad = 0.005
            self.ax.figure.canvas.draw_idle()
            items = self.ax.get_xticklabels() + self.ax.get_yticklabels() 
            items += [self.ax, self.ax.xaxis.label, self.ax.yaxis.label, self.ax.title] 
            bbox = Bbox.union([item.get_window_extent() for item in items])
            extent = bbox.expanded(1.0 + pad, 1.0 + pad).transformed(self.fig.dpi_scale_trans.inverted())
            plt.savefig(outf, bbox_inches=extent)
            print(f"Selection figure saved to {outf}")

            center = self.ellipse.center
            ellipse_str = f"X:{center[0]}\nY:{center[1]}\nW:{self.ellipse.width}\nH:{self.ellipse.height}\nA:{self.ellipse.angle}\n"
            outf = f"{self.out_file}.selected_samples.ellipse"
            with open(outf, 'w') as out:
                out.write(ellipse_str)
            print(f"Ellipse coordinates saved to {outf}")
        else:
            print("Nothing is selected.")
            
    def _check_pop(self, label):
        if label == "MoBa_":
            visible = False if self.pc_points.get_visible() else True
            self.pc_points.set_visible(visible)
        elif label == "MoBa^":
            visible = False if self.pc_points_above.get_visible() else True
            self.pc_points_above.set_visible(visible)
        else:
            visible = False if self.pop_1kg_points[label].get_visible() else True
            self.pop_1kg_points[label].set_visible(visible)
        self.ax.figure.canvas.draw_idle()



def main(args):
    df = pd.read_csv(args.eigenvec_file, delim_whitespace=True, header=None,
        names=["FID","IID","PC1","PC2"], usecols=[0,1,2,3])
    print(f"{df.shape[0]} samples found in {args.eigenvec_file}")

    pcp = PCPlot(df, args.out)



if __name__ == '__main__':
    args = parse_args(sys.argv[1:])
    main(args)


