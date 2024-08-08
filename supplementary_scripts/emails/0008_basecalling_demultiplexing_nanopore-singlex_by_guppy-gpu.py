import os
import argparse  # Import the argparse library
import smtplib
import glob
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders

# Set up command-line argument parsing
parser = argparse.ArgumentParser(description='Send email with attachments')
parser.add_argument('-e', '--receiver_email', default='swapnil.doijad@gmail.com', help='Receiver email address')
args = parser.parse_args()

# Email configuration
sender_email = 'veo.lab@uni-jena.de'
receiver_email = args.receiver_email  # Use the provided receiver_email argument
bcc_email = 'swapnil.doijad@gmail.com'
smtp_server = 'smtp.uni-jena.de'
smtp_port = 587
username = 'veo.lab@uni-jena.de'
password = 'Working2023'

# Create a message object
message = MIMEMultipart()
message['From'] = sender_email
message['To'] = receiver_email
message['Bcc'] = bcc_email  # Add the Bcc recipient's email address
message['Subject'] = 'veo_pipeline:0008_basecalling_demultiplexing_nanopore-singlex_by_guppy-gpu run finished!!!'

# Add the email body
body = """ 
Hi User,

The pipeline 0008_basecalling_demultiplexing_nanopore-singlex_by_guppy-gpu is finished. 

For a quick view of the output, please find attached summary.tsv file.

You can find more details in your project folder...

1. fastq files: data/fastq directory
2. QC files: details at data/fastq_nanoplot in your project folder.
3. pipeline ouptut: results/0008_basecalling_demultiplexing_nanopore-singlex_by_guppy-gpu

For errors (if any) and for details of the pipeline can be examined in slurm files (.out and .err) located at 

1. general : /tmp/slurm/
2. pipeline specific : results/0008_basecalling_demultiplexing_nanopore-singlex_by_guppy-gpu/tmp/slurm/

Cheers, 
The VEO Group

for any issues, contact: swapnil.doijad@gmail.com
"""
message.attach(MIMEText(body, 'plain'))

# Attach the first attachment if it exists
file = 'results/0008_basecalling_demultiplexing_nanopore-singlex_by_guppy-gpu/summary.tsv'
if os.path.exists(file):
    with open(file, 'rb') as attachment1:
        part1 = MIMEBase('application', 'octet-stream')
        part1.set_payload(attachment1.read())
    encoders.encode_base64(part1)
    part1.add_header('Content-Disposition', f'attachment; filename= {file}')
    message.attach(part1)

# Attach the second and third attachments if they exist
file2_pattern = 'tmp/slurm/*.err'
file3_pattern = 'tmp/slurm/*.out'
files2 = glob.glob(file2_pattern)
files3 = glob.glob(file3_pattern)

for file2 in files2:
    if os.path.exists(file2):
        with open(file2, 'rb') as attachment:
            part = MIMEBase('application', 'octet-stream')
            part.set_payload(attachment.read())
        encoders.encode_base64(part)
        part.add_header('Content-Disposition', f'attachment; filename= {os.path.basename(file2)}')
        message.attach(part)

for file3 in files3:
    if os.path.exists(file3):
        with open(file3, 'rb') as attachment:
            part = MIMEBase('application', 'octet-stream')
            part.set_payload(attachment.read())
        encoders.encode_base64(part)
        part.add_header('Content-Disposition', f'attachment; filename= {os.path.basename(file3)}')
        message.attach(part)



# Connect to the SMTP server and send the email
try:
    server = smtplib.SMTP(smtp_server, smtp_port)
    server.starttls()
    server.login(username, password)
    server.sendmail(sender_email, [receiver_email, bcc_email], message.as_string())
except Exception as e:
    print('Error sending email:', e)
finally:
    server.quit()