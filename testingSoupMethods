




'''

text = 'CS Theory Course'
 
# Search by text with the help of lambda function
gfg = soup.find_all(lambda tag: tag.name == "strong" and text in tag.text)

'''
import re

from bs4 import BeautifulSoup

# Example HTML content
html_content = '''
<html>
    <body class="ENTIRE BODY">
        <table class="table 1">
            <caption>Table 1: General Information</caption>
            <tr>
                <th>Name</th>
                <td>John Doe</td>
            </tr>
            <tr>
                <th>Age</th>
                <td>30</td>
            </tr>
        </table>

        <table class="table 1">
            <caption>Model</caption>
            <tr>
                <th>Manager</th>
                <td>Philip Boss</td>
            </tr>
            <tr>
                <th>"Employee" <!-- --> </th>
                <td>Jane Smith</td>
            </tr>
            <tr>
                <th>Position</th>
                <td>Computer Analyst</td>
            </tr>
        </table>
    </body>
</html>
'''

# Parse the HTML content using BeautifulSoup
soup = BeautifulSoup(html_content, 'html.parser')

# Find the specific <table> with a specific <caption>
caption_text = 'Model'
table_with_caption = (
    soup.find('table', class_='table 1')
    .find_next_sibling('table')
    .find(lambda tag: tag.name == "th" and 'Employee' in tag.text).find_next_sibling().text
    
    
    )

# If we found the table, print the table and its contents
if table_with_caption:
    print(table_with_caption)  # Print the table's HTML in a readable format
else:
    print("Table with the specified caption not found.")
    
    
    
    
    
    
