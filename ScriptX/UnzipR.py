import os
import zipfile
import sys

# Get the file name from the command line argument
file_name = sys.argv[1]

# Define a function to extract zip files recursively
def extract_zip(file):
    # Open the zip file
    with zipfile.ZipFile(file) as zip_file:
        print("Extracting " + file)
        # Loop through the members of the zip file
        for member in zip_file.namelist():
            # Get the full path of the member
            member_path = zip_file.extract(member, os.path.dirname(file))
            # Check if the member is another zip file
            if zipfile.is_zipfile(member_path):
                # Extract the inner zip file recursively
                extract_zip(member_path)
                # Delete the inner zip file
                os.remove(member_path)
extract_zip(file_name)