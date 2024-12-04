import os
import argparse  # Import the argparse library
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

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
message['Subject'] = 'veo_pipeline: 0060_metagenome_assembly_QC_by_metaquast run finished!!!'

# Add the email body
body = """ 
Hi User,

The pipeline 0060_metagenome_assembly_QC_by_metaquast is finished. 

Your results are located at results/0060_QC_genome-metagenome_assembly_by_quast/results folder. 

for example results/0060_QC_genome-metagenome_assembly_by_quast/results/metagenome_id/report.html

Best, 
The VEO Group

for any issues, contact: swapnil.doijad@gmail.com
"""
message.attach(MIMEText(body, 'plain'))

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