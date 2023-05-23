import tkinter as tk
from os import system
import re

import tkinter.scrolledtext as scrolledtext
from tkinter.filedialog import askopenfilename


# Window
window = tk.Tk()
window.title("Text Editor")

# suitable window sizes: 800x600, 1024x768, 1280x720, 1280x1024, 1366x768, 1600x900, 1920x1080

window_size = (1600, 900)
frame_padding = 50
frame_size = (window_size[0] - frame_padding, window_size[1] - frame_padding)
window.geometry(f"{window_size[0]}x{window_size[1]}")
window.resizable(False, False)
bg_color = "#3e2e4e"
editor_color = "#2e1e3e"
window.config(bg=bg_color)

# Data
code = ""
quadruples = ""
symbol_table = ""
log = ""

quadruples_or_symbol_table = "quadruples"


# tag dictionary
tag_dict = {
    "separator": ["\(", "\)", "\[", "\]", "\{", "\}", "\;", "\:", "\,", "\."],
    "data_type": ["int", "float", "bool", "string", "char", "double", "long", "short", "signed", "unsigned", "auto", "const", "void"],
    "keyword": ["if", "else", "while", "for", "true", "false", "return", "break", "case", "continue", "default", "do", "enum", "sizeof", "switch", "typedef", "using", "namespace", "cout", "cin", "endl", "std", "main"],
    "operator": ["\+", "-", "\*", "/", "\%", "\+\+", "--", "==", "!=", ">", "<", ">=", "<=", "&&", "\|\|", "!", "\&", "\|", "\^", "\~", "<<", ">>", "\?", "\:", "\=", "\+=", "-=", "\*=", "/=", "\%=", "\&=", "\|=", "\^=", "<<=", ">>="],
    "preprocessor": ["#include", "#define", "#ifdef", "#ifndef", "#endif", "#if", "#else", "#elif", "#undef", "#pragma", "#error", "#line", "#"],
    "comment": ["\/\/", "\/\*", "\*\/"]
}

color_dict = {
    "data_type": "#7799ff",
    "keyword": "#ff88b5",
    "operator": "#dd99ff",
    "separator": "cyan",
    "preprocessor": "grey",
    "comment": "#66ff55",
    "string": "#ff9944", # #ffaa00
    "function": "lightyellow"
}


# Functions

# import button functionality


def read_import(file_path):
    global code
    global text_editor

    # clear all, update code variable and then update text editor
    clear_all()

    # open file
    file = open(file_path, "r")

    # update code variable
    code = file.read()

    # close file
    file.close()

    # update text editor
    text_editor.insert(tk.INSERT, code)

    # highlight code
    highlight_code(code)


def import_file(event):
    global code
    global text_editor

    # clear all, update code variable and then update text editor
    clear_all()

    # open file
    file_path = askopenfilename(
        filetypes=[("C++ Files", "*.cpp"), ("C Files", "*.c"), ("Header Files", "*.h")])

    if file_path:
        read_import(file_path)

def swap_quadruples_symbol_table(choice = 'quadruples'):
    global quadruples_or_symbol_table
    global text_quadruples_symbol_table
    global show_quadruples_button

    quadruples_or_symbol_table = choice

    if quadruples_or_symbol_table == "quadruples":
        show_quadruples_button.config(text = "Show Symbol Table")
        text_quadruples_symbol_table.delete("1.0", tk.END)
        text_quadruples_symbol_table.insert(tk.INSERT, quadruples)
    else:
        show_quadruples_button.config(text = "Show Quadruples")
        text_quadruples_symbol_table.delete("1.0", tk.END)
        text_quadruples_symbol_table.insert(tk.INSERT, symbol_table)

def show_quadruples_symbol_table(event):
    global quadruples_or_symbol_table

    if quadruples_or_symbol_table == "quadruples":
        swap_quadruples_symbol_table(choice = 'symbol_table')
    else:
        swap_quadruples_symbol_table(choice = 'quadruples')

def compile_code(event=None):
    global code
    global quadruples
    global symbol_table
    global log
    global text_editor
    global text_quadruples_symbol_table
    global text_log

    # clear all
    clear_all(None, clear_text_editor = False)

    if code == "":
        text_log.insert(tk.INSERT, "No code to compile")
        return

    # save code to file to be compiled
    file = open("to_compile.cpp", "w")
    file.write(code)
    file.close()

    # TODO: compile code
    # system("python src\\compiler.py")

    file = open("output/symbol_table.txt", "r")
    symbol_table = file.read()
    file.close()

    file = open("output/errors.txt", "r")
    errors = file.read()
    file.close()

    file = open("output/warnings.txt", "r")
    warnings = file.read()
    file.close()

    errors_line_numbers = re.findall(r"Line (\d+)", errors)
    errors_line_numbers = [int(line_number) for line_number in errors_line_numbers]

    warnings_line_numbers = re.findall(r"Line (\d+)", warnings)
    warnings_line_numbers = [int(line_number) for line_number in warnings_line_numbers]

    # for each line in errors, add ERROR prefix to it
    errors = "\n".join([f"ERROR  : {line}" for line in errors.split("\n") if line != ""])

    # for each line in warnings, add WARNING prefix to it
    warnings = "\n".join([f"WARNING: {line}" for line in warnings.split("\n") if line != ""])

    # merge errors and warnings and sort them (based on line number at index 8
    log = "\n".join(sorted([f"{line[8:]}" for line in (errors + "\n" + warnings).split("\n") if line != ""]))

    # log has this format:
    # Line <line_number>: <error_message>
    # if there is no error, log is empty, in which case we read the quadruples

    print(errors_line_numbers)

    if len(errors_line_numbers) == 0:
        file = open("output/quad.asm", "r")
        quadruples = file.read()
        file.close()

        swap_quadruples_symbol_table(choice = 'quadruples')

    else:
        # highlight errors
        for line_number in errors_line_numbers:
            text_editor.tag_add("error", f"{line_number}.0", f"{line_number}.end")

        swap_quadruples_symbol_table(choice = 'symbol_table')

    # highlight warnings
    for line_number in warnings_line_numbers:
        text_editor.tag_add("warning", f"{line_number}.0", f"{line_number}.end")

    # update text boxes
    text_log.insert(tk.INSERT, log)


def clear_all(event=None, clear_text_editor = True):
    global code
    global quadruples
    global symbol_table
    global log
    global text_editor
    global text_quadruples_symbol_table
    global text_log

    # clear all variables
    if clear_text_editor:
        text_editor.delete("1.0", tk.END)
        code = ""

    quadruples = ""
    symbol_table = ""
    log = ""

    text_quadruples_symbol_table.delete("1.0", tk.END)
    text_log.delete("1.0", tk.END)


def highlight_code(code):
    # need to color the code in an c++ ide
    # use regex to find keywords, operators, etc
    # use tags to color them
    global text_editor
    global tag_dict

    text_editor.tag_remove("error", "1.0", tk.END)
    text_editor.tag_remove("warning", "1.0", tk.END)

    # loop through all tag types as keys and their values
    for tag_type, tag_values in tag_dict.items():
        # word boundary regex
        regex = r"(" + "|".join(tag_values) + r")"

        # find all matches
        matches = re.finditer(regex, code, re.MULTILINE)

        text_editor.tag_remove(tag_type, "1.0", tk.END)

        # highlight matches, handle multiple lines
        for matchNum, match in enumerate(matches, start=1):
            start_index = match.start()

            # get the line index by counting \n before the match
            line_index = code[:start_index].count("\n") + 1

            # get the column index by counting characters before the match
            column_index = start_index - code[:start_index].rfind("\n") - 1

            # highlight the match if not a comment, else highlight the whole line
            if tag_type != "comment":
                text_editor.tag_add(
                    tag_type, f"{line_index}.{column_index}", f"{line_index}.{column_index + len(match.group())}")
            else:
                text_editor.tag_add(
                    tag_type, f"{line_index}.0", f"{line_index}.end")

    # highlight strings
    # find all matches of "string"
    matches = re.finditer(r"\".*?\"", code, re.MULTILINE)

    # highlight matches, handle multiple lines
    for matchNum, match in enumerate(matches, start=1):
        start_index = match.start()

        # get the line index by counting \n before the match
        line_index = code[:start_index].count("\n") + 1

        # get the column index by counting characters before the match
        column_index = start_index - code[:start_index].rfind("\n") - 1

        # highlight the match if not a comment, else highlight the whole line
        text_editor.tag_add(
            "string", f"{line_index}.{column_index}", f"{line_index}.{column_index + len(match.group())}")


def on_text_editor_change(event):
    global code
    code = text_editor.get("1.0", tk.END)

    # highlight code
    highlight_code(code)


# Widgets
# root_frame
root_frame = tk.Frame(
    window, width=window_size[0], height=window_size[1], bg=bg_color)
root_frame.pack(pady=30, padx=20)

# divided into a top frame 65% and a bottom frame 35%
top_frame = tk.Frame(
    root_frame, width=frame_size[0], height=frame_size[1] * 0.65, bg=bg_color)
top_frame.pack(pady=10, padx=10)

bottom_frame = tk.Frame(
    root_frame, width=frame_size[0], height=frame_size[1] * 0.35, bg=bg_color)
bottom_frame.pack(pady=10, padx=10, fill=tk.X)

# top frame divided into a left frame 50% and a right frame 50%

left_frame = tk.Frame(
    top_frame, width=frame_size[0] * 0.5, height=frame_size[1] * 0.65, bg=editor_color)
left_frame.pack(side=tk.LEFT, padx=10)

right_frame = tk.Frame(
    top_frame, width=frame_size[0] * 0.5, height=frame_size[1] * 0.65, bg=editor_color)
right_frame.pack(side=tk.RIGHT, padx=10)

# bottom frame divided into a left frame 75% and a right frame 25%

bottom_left_frame = tk.Frame(
    bottom_frame, width=frame_size[0] * 0.80, height=frame_size[1] * 0.35, bg=editor_color)
bottom_left_frame.pack(side=tk.LEFT, padx=10)

# make this take its space
bottom_right_frame = tk.Frame(
    bottom_frame, width=frame_size[0] * 0.20, height=frame_size[1] * 0.35, bg=bg_color)
bottom_right_frame.pack(side=tk.RIGHT, padx=10, fill=tk.BOTH, expand=True)

# left frame consists of a text editor
text_editor = scrolledtext.ScrolledText(left_frame, bg=editor_color, font=(
    "Consolas", 14), fg="white", width=80, height=25)
# color tags
for tag_type, tag_color in color_dict.items():
    text_editor.tag_config(tag_type, foreground=tag_color)

text_editor.tag_config("error", background="#550000", font=(
    "Consolas", 14, "bold"), foreground="#ff0000")

text_editor.tag_config("warning", background="#444400", font=(
    "Consolas", 14, "bold"), foreground="#ffff00")

text_editor.pack()

# right frame consists of 1 text box for quadruples and symbol table, make this scrollable in both directions
text_quadruples_symbol_table = scrolledtext.ScrolledText(right_frame, bg=editor_color, font=(
    "Consolas", 10), fg="white", width=84, height=37)  # state=tk.DISABLED
text_quadruples_symbol_table.pack()

# bottom left frame consists of 1 text box for log
text_log = scrolledtext.ScrolledText(bottom_left_frame, bg=editor_color, font=(
    "Consolas", 14), fg="white", width=120, height=11)   # state=tk.DISABLED
text_log.pack()

# bottom right frame consists of 4 buttons: import, compile, show quadruples, clear, buttons are stacked vertically
import_button = tk.Button(bottom_right_frame, text="Import", width=22,
                          height=2, bg=editor_color, fg="white", font=("Arial", 11, "bold"))
import_button.pack(pady=5)

compile_button = tk.Button(bottom_right_frame, text="Compile", width=22,
                           height=2, bg=editor_color, fg="white", font=("Arial", 11, "bold"))
compile_button.pack(pady=5)

show_quadruples_button = tk.Button(bottom_right_frame, text="Show Quadruples",
                                   width=22, height=2, bg=editor_color, fg="white", font=("Arial", 11, "bold"))
show_quadruples_button.pack(pady=5)

clear_button = tk.Button(bottom_right_frame, text="Clear", width=22,
                         height=2, bg=editor_color, fg="white", font=("Arial", 11, "bold"))
clear_button.pack(pady=5)

# events
# on text_editor text change

text_editor.bind("<KeyPress>", on_text_editor_change)

# on button click
clear_button.bind("<Button-1>", clear_all)

# on button click
import_button.bind("<Button-1>", import_file)

# on button click
compile_button.bind("<Button-1>", compile_code)

# on button click
show_quadruples_button.bind("<Button-1>", show_quadruples_symbol_table)

# show window
window.mainloop()
