import pandas as pd
from shapely.geometry import Point, shape
import json

data_path = '/home/jovyan/work/_core/projects/datasets/talkingdata/'
n_samples = 20000

def get_age_segment(age):
    if age <= 22:
        return '22-'
    elif age <= 26:
        return '23-26'
    elif age <= 28:
        return '27-28'
    elif age <= 32:
        return '29-32'
    elif age <= 38:
        return '33-38'
    else:
        return '39+'

def get_location(longitude, latitude, provinces_json):
    try:
        point = Point(longitude, latitude)

        for record in provinces_json['features']:
            polygon = shape(record['geometry'])
            if polygon.contains(point):
                return record['properties']['name']
        return 'other'
        print("location converted")
    except:
        ("location convert failed")

#initial import of csv files
try:
    with open(data_path + 'china_provinces_en.json') as data_file:    
        provinces_json = json.load(data_file)
    provinces = pd.read_csv(data_path + 'china_provinces_en.csv')
    gen_age_tr = pd.read_csv(data_path + 'gender_age_train.csv')
    ev = pd.read_csv(data_path + 'events.csv')
    ph_br_dev_model = pd.read_csv(data_path + 'phone_brand_device_model.csv')
    print("CSVs imported")
except:
    print("Import failed")

#Get n_samples records
try:    
    df = gen_age_tr.merge(ev, how='left', on='device_id')
    df = df.merge(ph_br_dev_model, how='left', on='device_id')
    df = df[df['longitude'] != 0].sample(n=n_samples)
    top_10_brands_en = {'华为':'Huawei', '小米':'Xiaomi', '三星':'Samsung', 'vivo':'vivo', 'OPPO':'OPPO','魅族':'Meizu', '酷派':'Coolpad', '乐视':'LeEco', '联想':'Lenovo', 'HTC':'HTC'}
    df['phone_brand_en'] = df['phone_brand'].apply(lambda phone_brand: top_10_brands_en[phone_brand] if (phone_brand in top_10_brands_en) else 'Other')
    df['age_segment'] = df['age'].apply(lambda age: get_age_segment(age))
    df['location'] = df.apply(lambda row: get_location(row['longitude'], row['latitude'], provinces_json), axis=1)
    cols_to_keep = ['timestamp', 'longitude', 'latitude', 'phone_brand_en', 'gender', 'age_segment', 'location']
    df_clean = df[cols_to_keep].dropna()
    #store the resulting csv
    df_clean.to_csv(data_path+'talkingdata.csv')
    print("Results successfully exported to "+data_path)
except:
    print("Export failed")

