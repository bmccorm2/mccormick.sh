'''get and save yields from the previous business day'''
import os
import datetime
import xml.etree.ElementTree as et
import requests
from gql import Client
from gql.transport.requests import RequestsHTTPTransport
import queries
from dotenv import load_dotenv

temp_data_file = 'yields.xml'
XML_DATE_FORMAT = '%d-%b-%y'
API_DATE_FORMAT = '%Y-%m-%d'


def get_previous_day(d: datetime):
    '''get the previous day'''
    t = d - datetime.timedelta(days=1)
    return get_business_day(t)


def get_business_day(d: datetime):
    '''get corresponding business day: saturday/sunday = friday'''
    day = d.weekday()
    if (day == 5):
        # saturday
        d = d - datetime.timedelta(days=1)
    elif (day == 6):
        # sunday
        d = d - datetime.timedelta(days=2)
    return d.date().strftime(XML_DATE_FORMAT).upper()


def get_current_rates():
    '''get rates for the previous business day'''
    base_url = "https://home.treasury.gov/sites/default/files/interest-rates/yield.xml"
    response = requests.get(base_url)
    with open(temp_data_file, 'wb+') as file:
        file.write(response.content)
    print('wrote the file')


def process_current_day():
    '''find the correct item to parse in the XML tree'''
    target_date = get_previous_day(datetime.datetime.now())
    print(f'in process_current_day for date: {target_date}')
    tree = et.parse(temp_data_file)
    root = tree.getroot().find('LIST_G_WEEK_OF_MONTH')
    for week_of_month in root.findall('G_WEEK_OF_MONTH'):
        dates = week_of_month.find('LIST_G_NEW_DATE').findall('G_NEW_DATE')
        for date in dates:
            if date.find('BID_CURVE_DATE').text == target_date:
                properties = date.find('LIST_G_BC_CAT').find('G_BC_CAT')
                process(properties, target_date)
                break


def process(element, effective_date):
    '''Process XML element and save to DB'''
    effective_date = datetime.datetime.strptime(
        effective_date, XML_DATE_FORMAT)
    effective_date = effective_date.strftime(API_DATE_FORMAT)
    print(effective_date)
    one_month = float(element.find('BC_1MONTH').text)
    two_month = float(element.find('BC_2MONTH').text)
    three_month = float(element.find('BC_3MONTH').text)
    six_month = float(element.find('BC_6MONTH').text)
    one_year = float(element.find('BC_1YEAR').text)
    two_year = float(element.find('BC_2YEAR').text)
    three_year = float(element.find('BC_3YEAR').text)
    five_year = float(element.find('BC_5YEAR').text)
    seven_year = float(element.find('BC_7YEAR').text)
    ten_year = float(element.find('BC_10YEAR').text)
    twenty_year = float(element.find('BC_20YEAR').text)
    thirty_year = float(element.find('BC_30YEAR').text)

    variables = {
        'oneMonth': one_month,
        'twoMonth': two_month,
        'threeMonth': three_month,
        'sixMonth': six_month,
        'oneYear': one_year,
        'twoYear': two_year,
        'threeYear': three_year,
        'fiveYear': five_year,
        'sevenYear': seven_year,
        'tenYear': ten_year,
        'twentyYear': twenty_year,
        'thirtyYear': thirty_year,
        'effectiveDate': effective_date
    }

    transport = RequestsHTTPTransport(
        url=os.environ.get('GRAPHQL_URI'), verify=True, retries=2)
    client = Client(transport=transport, fetch_schema_from_transport=False)
    client.execute(queries.CREATE_YIELD, variable_values=variables)
    print(f"Added object for date: {effective_date}")


if __name__ == "__main__":
    try:
        load_dotenv()
        get_current_rates()
        process_current_day()
    except Exception as ex:
        print(ex)
        with open('log/yield.txt', 'a+', encoding='UTF-8') as file:
            file.write(f"{datetime.datetime.now()}-Yields: {ex}\n")
