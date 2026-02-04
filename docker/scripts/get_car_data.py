'''Get daily data from cars.com'''
import os
import datetime
import requests
from dotenv import load_dotenv
from bs4 import BeautifulSoup
from gql import Client
from gql.transport.requests import RequestsHTTPTransport
import queries

BASE = "https://www.car.com"


def get_current_car(search_url):
    '''Returns web response for the current URL'''
    print(f"Search URL: {search_url}")
    headers = {'accept': '*/*',
               'accept-encoding': 'gzip, deflate, br',
               'accept-language': 'en-US,en;q=0.9',
               'origin': 'https://www.cars.com',
               'referer': 'https://www.cars.com/shopping/results/?stock_type=used&makes[]=mazda&models[]=mazda-mx_5_miata&list_price_max=&maximum_distance=20&zip=80208',
               'user-agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.101 Safari/537.36 OPR/77.0.4054.90'}
    return requests.get(search_url, headers=headers)
    # with open('data.html', 'wb') as file:
    #     file.write(response.content)


def process_entries(car_id, client, response):
    '''Process each car and save'''
    soup = BeautifulSoup(response.content, 'html.parser')

    # # This is temporary CODE!!
    # with open('data.html', 'r', encoding='UTF-8') as read_file:
    #     data = read_file.read().replace('\n', '')
    # soup = BeautifulSoup(data, 'html.parser')

    for car in soup.find_all('div', class_="vehicle-card-main"):
        try:
            # If for whatever reason there is an exception (i.e., no price given),
            # skip and go to next
            car_type = car.find('p', class_="stock-type").getText()

            detail_url = BASE + \
                car.find('a', class_="vehicle-card-link").get('href')
            display_name = car.find(
                'a', class_='vehicle-card-link').find('h2').getText()
            year = int(str.split(display_name, ' ')[0])

            miles = 0 if car_type == 'New' else int(
                str.split(car.find('div', class_='mileage').getText().replace(',', ''), ' ')[0])
            price = int(car.find(
                'span', class_='primary-price').getText().replace('$', '').replace(',', ''))
            distance = 0 if car.find('div', class_='online-seller') else int(
                str.split(car.find('div', class_='miles-from').getText().replace(',', '').replace('\n','').lstrip(), ' ')[0])

            variables = {
                'carId': car_id,
                'url': detail_url,
                'year': year,
                'miles': miles,
                'price': price,
                'distance': distance,
                'displayName': display_name,
                'effectiveDate': datetime.datetime.now().strftime("%Y-%m-%d")
            }
            client.execute(queries.CREATE_CAR_DETAIL,
                           variable_values=variables)
            print(f"Saved car {display_name}")
        except Exception as ex:
            print(f"Skipped car {display_name} - {ex}")
            continue


if __name__ == "__main__":
    try:
        load_dotenv()
        transport = RequestsHTTPTransport(
            url=os.environ.get('GRAPHQL_URI'), verify=True, retries=2)
        client = Client(transport=transport, fetch_schema_from_transport=False)
        cars = client.execute(queries.GET_CAR_DETAILS)['cars']
        for car in cars:
            search_url = car['searchUrl']
            response = get_current_car(search_url)
            process_entries(car['id'], client, response)
    except BaseException as ex:
        print(ex)
        with open('./log/cars.log', 'a+', encoding='UTF-8') as file:
            file.write(f"{datetime.datetime.now()}: {ex}\n")
