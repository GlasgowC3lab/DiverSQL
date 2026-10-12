WITH agg AS (
    SELECT
        d.d_year,
        i_item.i_category,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(wr.wr_return_amt) AS web_returns,
        SUM(inv.inv_quantity_on_hand) AS inventory_on_hand,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i_item
        ON ss.ss_item_sk = i_item.i_item_sk
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_item_sk = i_item.i_item_sk
    LEFT JOIN tpcds.call_center cc
        ON cc.cc_open_date_sk = d.d_date_sk
    LEFT JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i_item.i_item_sk
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i_item.i_item_sk
    LEFT JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i_item.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i_item.i_category = 'Electronics'
      AND ss.ss_quantity > 5
      AND cs.cs_net_profit > 0
      AND inv.inv_quantity_on_hand < 200
    GROUP BY d.d_year, i_item.i_category
),
base AS (
    SELECT
        d_year,
        i_category,
        store_sales,
        catalog_sales,
        web_sales,
        web_returns,
        inventory_on_hand,
        CASE WHEN total_net_profit > 1000 THEN 'high' ELSE 'low' END AS profit_category
    FROM agg
),
union_data AS (
    SELECT d_year, i_category, store_sales, catalog_sales, web_sales, web_returns, inventory_on_hand, profit_category
    FROM base
    UNION DISTINCT
    SELECT d_year, i_category, store_sales * 1.05, catalog_sales * 0.95, web_sales * 1.10, web_returns * 0.90, inventory_on_hand, profit_category
    FROM base
    WHERE profit_category = 'high'
)
SELECT
    d_year,
    i_category,
    SUM(store_sales) AS total_store_sales,
    SUM(catalog_sales) AS total_catalog_sales,
    SUM(web_sales) AS total_web_sales,
    SUM(web_returns) AS total_web_returns,
    SUM(inventory_on_hand) AS total_inventory,
    profit_category,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(store_sales) DESC) AS sales_rank
FROM union_data
GROUP BY d_year, i_category, profit_category
ORDER BY total_store_sales DESC
LIMIT 100
