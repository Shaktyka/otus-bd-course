# Транзакции

## Описать пример транзакции из своего проекта 

C изменением данных в нескольких таблицах. Реализовать в виде хранимой процедуры.

CREATE procedure insert_clients_data()
 
BEGIN
 
   DECLARE income INT;
   SET income = 50;

 
END;

## Загрузить данные из приложенных в материалах csv.

### Реализация через LOAD DATA

Возьмём файл с данными по велосипедам:
https://github.com/levinmejia/Shopify-Product-CSVs-and-Images/blob/master/CSVs/Bicycles.csv

Создадим таблицу для загрузки данных:

```
CREATE TABLE data_table (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    Handle TEXT,
    Body TEXT,
    Vendor TEXT,
    Type TEXT,
    Tags TEXT,
    Published BOOLEAN,
    Option1_Text TEXT,
    Option1_Value TEXT,
    Option2_Name TEXT,
    Option2_Value TEXT,
    Option3_Name TEXT,
    Option3_Value TEXT,
    Variant_SKU	TEXT,
    Variant_Grams INT,
    Variant_Inventory_Tracker TEXT,
    Variant_Inventory_Qty int,
    Variant_Inventory_Policy TEXT,
    Variant_Fulfillment_Service TEXT,
    Variant_Price DECIMAL,
    Compare_At_Price DECIMAL,
    Variant_Requires_Shipping BOOLEAN,
    Variant_Taxable	BOOLEAN,
    Variant_Barcode	TEXT,
    Image_Src TEXT,
    Image_Alt_Text TEXT,
    Gift_Card BOOLEAN,	
    SEO_Title TEXT,
    SEO_Description TEXT,	
    Google_Product_Category TEXT,
    Gender TEXT,
    Age_Group TEXT,	
    MPN TEXT,
    AdWords_Grouping TEXT,	
    AdWords_Labels TEXT,	
    `Condition` TEXT,
    Custom_Product BOOLEAN,
    Custom_Label_0 TEXT,	
    Custom_Label_1 TEXT,	
    Custom_Label_2 TEXT,	
    Custom_Label_3 TEXT,
    Custom_Label_4 TEXT,
    Variant_Image TEXT,	
    Variant_Weight_Unit TEXT
);
```

Установим разрешение на загрузку файлов:

`SET GLOBAL local_infile = true;`

Откуда можно загружать файлы:

`SHOW VARIABLES LIKE "secure_file_priv";`

Загрузим файл на сервер:

`scp /Users/elena/Downloads/data_25/bycicles.csv root@more-mysql:/var/lib/mysql-files/`

Команда для загрузки:

```
LOAD DATA INFILE '/var/lib/mysql-files/bycicles.csv' 
INTO TABLE data_table 
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
```

После загрузки:

(скрин)

### Реализация через mysqlimport



## Реализация загрузки через fifo
Задание повышенной сложности*

