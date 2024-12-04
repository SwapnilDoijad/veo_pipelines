import smtplib
from email.mime.text import MIMEText
from email.header import Header

# Same email setup as before...

smtp_host = "smtp.gmail.com"
smtp_port = 465  # Use SSL with port 465 for Gmail
smtp_username = "swapnil.doijad@gmail.com"
smtp_password = "vtjrhbqwnofztetu"

try:
    server = smtplib.SMTP_SSL(smtp_host, smtp_port)
    server.login(smtp_username, smtp_password)
    server.sendmail(smtp_username, ["swapnil.doijad@outlook.com"], msg.as_string())
    print("Email sent successfully!")
except Exception as e:
    print("An error occurred:", e)
finally:
    if "server" in locals():
        server.quit()
