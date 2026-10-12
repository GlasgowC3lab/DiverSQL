WITH
    -- First branch: store sales aggregated
    store_sales_agg AS (
        SELECT
            s.s_store_id AS store_id,
            d_sold.d_year AS year,
            SUM(ss.ss_net_paid) AS net_amount
        FROM store_sales ss
        JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d_sold
            ON ss.ss_sold_date_sk = d_sold.d_date_sk
        JOIN time_dim t_sold
            ON ss.ss_sold_time_sk = t_sold.t_time_sk
        JOIN customer_address ca_ss
            ON ss.ss_addr_sk = ca_ss.ca_address_sk
        -- Bring in catalog_sales to satisfy joining all tables
        JOIN catalog_sales cs
            ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN date_dim d_cs_ship
            ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
        JOIN time_dim t_cs
            ON cs.cs_sold_time_sk = t_cs.t_time_sk
        JOIN customer_address ca_bill
            ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_address ca_ship
            ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
        -- Bring in web_returns to satisfy joining all tables
        JOIN web_returns wr
            ON wr.wr_returned_date_sk = d_sold.d_date_sk
        JOIN date_dim d_wr
            ON wr.wr_returned_date_sk = d_wr.d_date_sk
        JOIN time_dim t_wr
            ON wr.wr_returned_time_sk = t_wr.t_time_sk
        JOIN customer_address ca_refund
            ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
        JOIN customer_address ca_returning
            ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
        -- Join store closed date dimension
        JOIN date_dim d_closed
            ON s.s_closed_date_sk = d_closed.d_date_sk
        GROUP BY s.s_store_id, d_sold.d_year
    ),
    -- Second branch: catalog sales aggregated (store_id set to NULL because no direct store link)
    catalog_sales_agg AS (
        SELECT
            CAST(NULL AS varchar) AS store_id,
            d_cs_sold.d_year AS year,
            SUM(cs.cs_net_paid) AS net_amount
        FROM catalog_sales cs
        JOIN date_dim d_cs_sold
            ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
        JOIN time_dim t_cs
            ON cs.cs_sold_time_sk = t_cs.t_time_sk
        JOIN date_dim d_cs_ship
            ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
        JOIN customer_address ca_bill
            ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_address ca_ship
            ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
        -- Join web_returns to keep the table in the query
        JOIN web_returns wr
            ON wr.wr_returned_date_sk = d_cs_sold.d_date_sk
        JOIN date_dim d_wr
            ON wr.wr_returned_date_sk = d_wr.d_date_sk
        JOIN time_dim t_wr
            ON wr.wr_returned_time_sk = t_wr.t_time_sk
        JOIN customer_address ca_refund
            ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
        JOIN customer_address ca_returning
            ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
        -- Join store through its closed date (no store_key relationship)
        JOIN store s
            ON s.s_closed_date_sk = d_cs_sold.d_date_sk
        -- Join store_sales just to involve the table
        JOIN store_sales ss
            ON ss.ss_sold_date_sk = d_cs_sold.d_date_sk
        GROUP BY d_cs_sold.d_year
    ),
    -- Third branch: web returns aggregated (to be subtracted)
    returns_agg AS (
        SELECT
            s.s_store_id AS store_id,
            d_wr.d_year AS year,
            SUM(wr.wr_net_loss) AS net_amount
        FROM web_returns wr
        JOIN date_dim d_wr
            ON wr.wr_returned_date_sk = d_wr.d_date_sk
        JOIN time_dim t_wr
            ON wr.wr_returned_time_sk = t_wr.t_time_sk
        JOIN customer_address ca_refund
            ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
        JOIN customer_address ca_returning
            ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
        -- Pull in store via closed date (no direct FK)
        JOIN store s
            ON s.s_closed_date_sk = d_wr.d_date_sk
        -- Pull in other tables to satisfy join count
        JOIN catalog_sales cs
            ON cs.cs_sold_date_sk = d_wr.d_date_sk
        JOIN date_dim d_cs_ship
            ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
        JOIN time_dim t_cs
            ON cs.cs_sold_time_sk = t_cs.t_time_sk
        JOIN customer_address ca_bill
            ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_address ca_ship
            ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
        JOIN store_sales ss
            ON ss.ss_sold_date_sk = d_wr.d_date_sk
        JOIN date_dim d_ss_sold
            ON ss.ss_sold_date_sk = d_ss_sold.d_date_sk
        JOIN time_dim t_ss
            ON ss.ss_sold_time_sk = t_ss.t_time_sk
        JOIN customer_address ca_ss
            ON ss.ss_addr_sk = ca_ss.ca_address_sk
        GROUP BY s.s_store_id, d_wr.d_year
    )
SELECT store_id, year, net_amount
FROM (
    SELECT store_id, year, net_amount FROM store_sales_agg
    UNION DISTINCT
    SELECT store_id, year, net_amount FROM catalog_sales_agg
) AS union_set
EXCEPT
SELECT store_id, year, net_amount FROM returns_agg
ORDER BY net_amount DESC
LIMIT 100
