# sql-data-warehouse
    Medallion (Bronze → Silver → Gold) SQL data warehouse project for Data Engineer

---

## General Priciple
    - Use snake_case (with lowercase letters and underscore to separate words) for all objects.
    - Language: English for all name.

---

### Table Naming Convention

#### Bronze Layer Rules
- **sourcesystem_entity**
    - **sourcesystem**: Name of source system (e.g. crm, erp).
    - **entity**: Exact table name from source system.
    - **Example**: crm_customer_info ---> Customer information from the CRM system.
    
#### Silver Layer Rules
As same as a bronze layer

#### Gold Layer Rules
All names must use meaningful, business-aligned name for tables, start with category prefix.
- **category_entity**
    - **category**: Describe the role of the table such as dim (Dimension which is store a attributes of data like what, where, when, why and who)
    , fact (which is store a number, metrics, transactions like revenue or quantity sold)
    - **entity**: Descriptive name of the table, aligned with with business domain (e.g. customers, products, sales).
    - **Example**: dim_customer ---> Dimension table for customer data, fact_sales ---> Fact table containing sales data.

---

### Column Naming Convention

#### Surrogate Keys
All primary keys in dimension tables must use the suffix _key.
- **<table_name>_key**
    - **table_name**: Refers to the name of table or entity the key belong to.
    - **_key**: Suffix indicating that this column is a surrogate key.
    - **Example**: customer_key ---> Surrogate key in the dim_customers table.

#### Technical Columns
All technical column must start with dwh_, followed by a descriptive name indicating the column's purpose.
- **dwh_<column_name>**
    - **dwh**: Prefix exclusively for system-generated metadata.
    - **column_name**: Descriptive name indicating the column purpose.
    - **Example**: dwh_load_date ---> System-generated column used to store the date when the record was loaded.

#### Store Procedure 
All stored procedures used for loading data must follow the naming pattern:
- **load_<layer>**
    - **layer**: Represents the layer being loaded, such as bronze, silver or gold.
    - **Example**: load_bronze ---> Stored procedure used to load data into the bronze layer.
