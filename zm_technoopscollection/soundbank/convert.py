import os
import sys
from glob import glob

#dir = "C:/OAT/mods/zm_technoopscollection_test/soundbank"
#new_dir = "C:/OAT/mods/zm_technoopscollection_test/new_soundbank"

dir = sys.argv[1]
new_dir = sys.argv[2]

soundbank_names = [y for x in os.walk(dir) for y in glob(os.path.join(x[0], '*.aliases.csv'))]
new_soundbank_names = [y for x in os.walk(new_dir) for y in glob(os.path.join(x[0], '*.aliases.csv'))]

new_header = ""

with open(new_soundbank_names[0]) as new_soundbank:
    new_header = new_soundbank.readline()

for soundbank_name in soundbank_names:
    converted_lines = [new_header]

    with open(soundbank_name) as soundbank:
        next(soundbank) # skip header line

        for line in soundbank:
            cols = line.split(",")
            alias_name = cols[0]
            file_name = cols[1]
            found_new_line = False

            for new_soundbank_name in new_soundbank_names:
                with open(new_soundbank_name) as new_soundbank:
                    next(new_soundbank) # skip header line

                    for new_line in new_soundbank:
                        new_cols = new_line.split(",")
                        new_alias_name = new_cols[0]
                        new_file_name = os.path.splitext(new_cols[1])[0]

                        if alias_name == new_alias_name and file_name == new_file_name:
                            found_new_line = True
                            converted_lines.append(new_line)
                            break

                if found_new_line:
                    break

            if not found_new_line:
                converted_lines.append(line)

    with open(soundbank_name, "w") as soundbank:
        soundbank.writelines(converted_lines)