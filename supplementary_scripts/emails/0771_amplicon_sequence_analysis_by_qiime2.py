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
message['Subject'] = 'veo_pipeline:0771_amplicon_sequence_analysis_by_qiime2 run finished!!!'

# Add the email body
body = """ 
Hi User,

The pipeline 0771_amplicon_sequence_analysis_by_qiime2 is finished. 

For a quick view of the output, please find attached summary.tsv file.

You can find more details at results/0771_amplicon_sequence_analysis_by_qiime2 directory in your proejct folder.

Cheers, 
The VEO Group

for any issues, contact: swapnil.doijad@gmail.com
"""
message.attach(MIMEText(body, 'plain'))

# Attach the err and out attachments if they exist
file1_pattern = 'results/0771_amplicon_sequence_analysis_by_qiime2/tmp/slurm/*.err'
file2_pattern = 'results/0771_amplicon_sequence_analysis_by_qiime2/tmp/slurm/*.out'
files2 = glob.glob(file1_pattern)
files3 = glob.glob(file2_pattern)

for file1 in files2:
    if os.path.exists(file1):
        with open(file1, 'rb') as attachment:
            part = MIMEBase('application', 'octet-stream')
            part.set_payload(attachment.read())
        encoders.encode_base64(part)
        part.add_header('Content-Disposition', f'attachment; filename= {os.path.basename(file1)}')
        message.attach(part)

for file2 in files3:
    if os.path.exists(file2):
        with open(file2, 'rb') as attachment:
            part = MIMEBase('application', 'octet-stream')
            part.set_payload(attachment.read())
        encoders.encode_base64(part)
        part.add_header('Content-Disposition', f'attachment; filename= {os.path.basename(file2)}')
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