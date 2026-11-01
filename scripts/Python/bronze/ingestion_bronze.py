import pandas as pd
import urllib.parse
from sqlalchemy import create_engine, text
from pathlib import Path
import logging
import time

# Setup Logger
logger = logging.getLogger(__name__)

def configure_logging():
    log_dir = Path(__file__).resolve().parents[3] / "logs"
    log_dir.mkdir(exist_ok = True)

    logging.basicConfig(
        level = logging.INFO,
        format = "%(asctime)s:%(levelname)-8s:%(name)s:%(message)-3s",
        handlers = [
            logging.FileHandler(log_dir / "bronze.log", encoding = "utf-8"),
            logging.StreamHandler()
        ]
    )

    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)

def main():
    configure_logging()

    #Connect to Database
    obdc = (
        "DRIVER={ODBC DRIVER 17 for SQL Server};"
        "SERVER=localhost\\SQLEXPRESS;"
        "DATABASE=DataWareHouse;"
        "Trusted_Connection=yes;"
    )

    engine = create_engine(
        "mssql+pyodbc:///?odbc_connect=" + urllib.parse.quote_plus(obdc)
    )

    # Prepare Files Ptry:
    data_dir = Path(__file__).resolve().parents[3]/"datasets"
    files = {
        "crm_cust_info": "source_crm/cust_info.csv",
        "crm_prd_info": "source_crm/prd_info.csv",
        "crm_sales_details": "source_crm/sales_details.csv",
        "erp_cust_az12": "source_erp/CUST_AZ12.csv",
        "erp_loc_a101": "source_erp/LOC_A101.csv",
        "erp_px_cat_g1v2": "source_erp/PX_CAT_G1V2.csv"
    }

    logger.info(
        "\nBronze Load started database = %s files = %d \n",
        "DataWareHouse",
        len(files)
    )

    logger.info("=" * 60)

    # Start load files into database
    failed = 0
    for table, path in files.items():
        csv_path = data_dir / path
        started = time.perf_counter()
        logger.info("\nLoading bronze.%s from %s \n", table, csv_path.name)
        try:
            df = pd.read_csv(csv_path)
            if df.empty:
                logger.warning(
                    "\nEmpty file %s. bronze.%s will be trucated \n",
                    csv_path.name,
                    table
                )
            with engine.begin() as conn:
                conn.execute(text(f"TRUNCATE TABLE bronze.{table}"))
            df.to_sql(
                table,
                schema = "bronze",
                con = engine,
                if_exists = 'append',
                index = False
            )
        except Exception:
            failed += 1
            logger.exception(
                "\nFailed loading bronze.%s from %s. \nthat table may be empty \n",
                table,
                csv_path
            )
            raise
        eclapsed = time.perf_counter() - started
        logger.info(
            "\nLoaded bronze.%s \nrows = %d cols = %d file = %s \nsecond = %.2f \n",
            table,
            len(df),
            df.shape[1],
            csv_path.name,
            eclapsed
        )
        logger.info("=" * 60)
    
    logger.info("\nBronze load finished \nfailed = %d", failed)


if __name__ == "__main__":
    main()