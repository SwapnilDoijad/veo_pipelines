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
message['Subject'] = 'veo_pipeline: 0653_phage_clustering_by_mmseq2 run finished!!!'

# Add the email body
body = """ 
Hi User,

The pipeline 0653_phage_clustering_by_mmseq2 is finished. 

For a quick view of the output, please find attached summary.tsv file.

You can find more details at results/0653_phage_clustering_by_mmseq2 directory in your project folder. 

Key Command: mmseqs easy-linclust fasta.gz tmp -c 0.8 --min-seq-id 0.97 --cov-mode 1 --alignment-mode 3 --threads 80

The mmseq2 run with different coverage/sequence-identity cutoffs (80-97, 65-80, 50-65, and 30-50), and each result will be located in directories labeled with respective ids.

More details of the tool and output can be found at https://github.com/soedinglab/mmseqs2/wiki

Cheers, 
The VEO Group

for any issues, contact: swapnil.doijad@gmail.com
"""
message.attach(MIMEText(body, 'plain'))

# Attach the first attachment if it exists
file = 'results/0653_phage_clustering_by_mmseq2/summary.tsv'
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
except Exception as e:
    print('Error sending email:', e)
finally:
    server.quit()