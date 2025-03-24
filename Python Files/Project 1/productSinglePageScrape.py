'''



scrapes specific website for data

'''


import csv
import requests
from bs4 import BeautifulSoup

def csv_table_OverWrite(filename, data):
    """
    Creates a CSV file with the given filename, headers, and data.

    Args:
        filename (str): The name of the CSV file to create.
        headers (list): A list of strings representing the column headers.
        data (list of lists): A list of lists, where each inner list represents a row of data.
    """
    with open(filename, 'w', newline='') as csvfile:
        fieldnames = ['Description', 'Brand', 'CurrentPrice', 'PreviousPrice', 'Availability', 'Reviews', 'URL']
        writer = csv.DictWriter(csvfile, delimiter='|', fieldnames=fieldnames)
        
        writer.writeheader()
        writer.writerows(data)

#this loop iterates through the each page of the website
url1 = 'insertWebsiteURL'

pageNumber = 1

maxPageNumber = 3

#writing object headers to csv filename
filename = 'webscrapingGPUData'
headers = ['Description', 'Brand', 'CurrentPrice', 'PreviousPrice', 'Availability', 'Reviews', 'URL']
itemDictionary = [ {'Description': '', 'Brand': '', 'CurrentPrice':'', 'PreviousPrice':'', 'Availability': '', 'Reviews': '', 'URL':'' } ]

while pageNumber <= maxPageNumber:
    
    
    GrabProductsPageNum = 0
    while GrabProductsPageNum < 5:
        searchPage = requests.get(url1)
        searchPageSoup = BeautifulSoup(searchPage.content, 'html.parser')
        itemObjects = searchPageSoup.find_all('div', class_='item-cell')
        
        if len(itemObjects) > 3:
            print('successful scrape on page: ' + str(pageNumber) + ' URL: ' + url1)
            break
        
        if GrabProductsPageNum >= 4:
            print('Unable to parse page: ' + str(pageNumber) + ' URL: ' + url1)
            
        GrabProductsPageNum+=1

    for itemObject in itemObjects:
        
        
        #checks the product description
        try:
            Description = itemObject.find('a', class_='item-title').text
        except:
            Description = ''
            
        #checks if product is in stock
        try:
            Availability = itemObject.find('p', class_='item-promo').text
            if Availability != 'OUT OF STOCK':
                Availability = 'IN STOCK'
        except:
            Availability = 'IN STOCK'
        
        #checks the brand of product
        try:
            brandImage = itemObject.find('a', class_='item-brand').find('img')
            Brand = brandImage['alt']
        except:
            Brand = ''
        
        #checks the current product price       
        try:
            CurrentPrice = itemObject.find('li', class_='price-current').find('strong').text
        except:
            CurrentPrice = ''
            
        #checks the preivous product price
        try:
            PreviousPrice = itemObject.find('span', class_='price-was-data').text
        except:
            PreviousPrice = ''

        #checks amount of ratings product has   
        try:
            Reviews = itemObject.find('span', class_='item-rating-num').text
        except:
            Reviews = '0'
            
        #grabs the product page URL for the product  
        try:
            URL = itemObject.find('a', class_='item-title').get('href')
        except:
            URL = ''

            
            
        itemDictionary.append( {'Description': Description, 'Brand': Brand, 'CurrentPrice':CurrentPrice, 'PreviousPrice':PreviousPrice, 'Availability': Availability, 'Reviews': Reviews, 'URL':URL } )
    
    
    #changes url to get the next page
    StringPageNumberPrev = 'page=' + str(pageNumber)
    pageNumber+=1
    StringPageNumberNext = 'page=' + str(pageNumber)   
    url1 = url1.replace(StringPageNumberPrev, StringPageNumberNext)


csv_table_OverWrite(filename, itemDictionary)
