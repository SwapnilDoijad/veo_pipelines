import argparse
from ftplib import FTP
import os

def upload_file_to_ftp(file_name, folder_path):
    # FTP connection details
    ftp_server = 'ftp-private.ncbi.nlm.nih.gov'
    ftp_username = 'subftp'
    ftp_password = 'iodrac9octOckEpp'

    # Connect to FTP server
    ftp = FTP(ftp_server)
    ftp.login(user=ftp_username, passwd=ftp_password)

    # Navigate to your account folder
    ftp.cwd('uploads/swapnil.doijad_uni-jena.de_G7lYuXdb')

    # Create and navigate to a new subfolder
    folder_name = 'new_folder'  # Replace with your desired folder name
    ftp.mkd(folder_name)
    ftp.cwd(folder_name)

    # Build the full file path
    file_path = os.path.join(folder_path, file_name)

    if os.path.isfile(file_path):  # Check if the specified file exists
        print(f'Uploading {file_name}...')
        with open(file_path, 'rb') as file:
            ftp.storbinary(f'STOR {file_name}', file)
    else:
        print(f"Error: The file '{file_path}' does not exist or is not a file.")

    # List files in the target directory
    print('Uploaded files:')
    ftp.retrlines('LIST')

    # Close the connection
    ftp.quit()


if __name__ == "__main__":
    # Set up argument parser
    parser = argparse.ArgumentParser(description="Upload a file to an FTP server.")
    parser.add_argument('-i', '--input', required=True, help="The name of the file to upload.")
    parser.add_argument('-p', '--path', required=True, help="The local path where the file is located.")

    # Parse arguments
    args = parser.parse_args()

    # Upload the file
    upload_file_to_ftp(args.input, args.path)
