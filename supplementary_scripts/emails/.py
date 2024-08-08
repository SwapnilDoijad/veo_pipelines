import os
import argparse  # Import the argparse library
import smtplib
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
message['Subject'] = 'veo_pipeline: run finished!!!'

# Add the email body
body = """ 
Hi User,

The pipeline 0024_QC_combine_fastq_QC_by_mulitQC is finished. 

For the results, please decompress the attached .gz files and double clik the .html file

Best, 
The VEO Group

for any issues, contact: swapnil.doijad@gmail.com
"""
message.attach(MIMEText(body, 'plain'))

# Attach the first attachment if it exists
file = 'results/0024_QC_combine_fastq_QC_by_mulitQC/0022_QC_by_fastqc.zip'
if os.path.exists(file):
    with open(file, 'rb') as attachment1:
        part1 = MIMEBase('application', 'octet-stream')
        part1.set_payload(attachment1.read())
    encoders.encode_base64(part1)
    part1.add_header('Content-Disposition', f'attachment; filename= {file}')
    message.attach(part1)

# Connect to the SMTP server and send the email
try:
    server = smtplib.SMTP(smtp_server, smtp_port)
    server.starttls()
    server.login(username, password)
    server.sendmail(sender_email, [receiver_email, bcc_email], message.as_string())
    print('Email with attachments sent successfully!')
except Exception as e:
    print('Error sending email:', e)
finally:
    server.quit()