/* Goal: Compare total catalog sales net amount with store and web channel net paid amounts for the year 2001, broken down by channel with subtotals and a grand total. The query joins all 11 TPC‑DS tables, pre‑aggregates catalog_sales, applies six filter predicates, uses an EXISTS sub‑query, and combines store and web results with UNION before a final ROLLUP aggregation. */
WITH agg_cs AS (
    SELECT
        cs_order_number,
        cs_warehouse_sk,
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_sold_date_sk,
        SUM(cs_net_paid)        AS total_cs_net_paid,
        SUM(cs_quantity)        AS total_cs_quantity
    FROM catalog_sales
    GROUP BY cs_order_number, cs_warehouse_sk, cs_call_center_sk, cs_catalog_page_sk, cs_sold_date_sk
)
,
store_side AS (
    SELECT
        d_cs.d_year                                      AS year,
        'Store'                                          AS channel,
        agg_cs.total_cs_net_paid,
        store_sales.ss_net_paid                         AS total_store_net_paid,
        store_sales.ss_quantity                         AS total_store_quantity,
        CAST(NULL AS decimal(7,2))                     AS total_web_net_paid,
        CAST(NULL AS integer)                          AS total_web_quantity
    FROM agg_cs
    JOIN catalog_returns
        ON agg_cs.cs_order_number = catalog_returns.cr_order_number
    JOIN call_center
        ON agg_cs.cs_call_center_sk = call_center.cc_call_center_sk
    JOIN catalog_page
        ON agg_cs.cs_catalog_page_sk = catalog_page.cp_catalog_page_sk
    JOIN warehouse
        ON agg_cs.cs_warehouse_sk = warehouse.w_warehouse_sk
    JOIN date_dim d_cs
        ON agg_cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN store_sales
        ON store_sales.ss_sold_date_sk = d_cs.d_date_sk
    JOIN customer_demographics
        ON store_sales.ss_cdemo_sk = customer_demographics.cd_demo_sk
    JOIN household_demographics
        ON store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
    JOIN income_band
        ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
    WHERE d_cs.d_year = 2001
      AND warehouse.w_country = 'United States'
      AND income_band.ib_lower_bound >= 60000
      AND call_center.cc_market_manager IS NOT NULL
      AND catalog_page.cp_type = 'Electronics'
      AND customer_demographics.cd_gender = 'F'
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_order_number = agg_cs.cs_order_number
            AND cr2.cr_return_amount > 100
      )
),
web_side AS (
    SELECT
        d_cs.d_year                                      AS year,
        'Web'                                            AS channel,
        agg_cs.total_cs_net_paid,
        CAST(NULL AS decimal(7,2))                     AS total_store_net_paid,
        CAST(NULL AS integer)                          AS total_store_quantity,
        web_sales.ws_net_paid                           AS total_web_net_paid,
        web_sales.ws_quantity                           AS total_web_quantity
    FROM agg_cs
    JOIN catalog_returns
        ON agg_cs.cs_order_number = catalog_returns.cr_order_number
    JOIN call_center
        ON agg_cs.cs_call_center_sk = call_center.cc_call_center_sk
    JOIN catalog_page
        ON agg_cs.cs_catalog_page_sk = catalog_page.cp_catalog_page_sk
    JOIN warehouse
        ON agg_cs.cs_warehouse_sk = warehouse.w_warehouse_sk
    JOIN date_dim d_cs
        ON agg_cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN web_sales
        ON web_sales.ws_sold_date_sk = d_cs.d_date_sk
    JOIN customer_demographics
        ON web_sales.ws_bill_cdemo_sk = customer_demographics.cd_demo_sk
    JOIN household_demographics
        ON web_sales.ws_bill_hdemo_sk = household_demographics.hd_demo_sk
    JOIN income_band
        ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
    WHERE d_cs.d_year = 2001
      AND warehouse.w_country = 'United States'
      AND income_band.ib_lower_bound >= 60000
      AND call_center.cc_market_manager IS NOT NULL
      AND catalog_page.cp_type = 'Electronics'
      AND customer_demographics.cd_gender = 'F'
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_order_number = agg_cs.cs_order_number
            AND cr2.cr_return_amount > 100
      )
)
SELECT
    year,
    channel,
    SUM(total_cs_net_paid)      AS sum_cs_net_paid,
    SUM(total_store_net_paid)   AS sum_store_net_paid,
    SUM(total_store_quantity)   AS sum_store_quantity,
    SUM(total_web_net_paid)     AS sum_web_net_paid,
    SUM(total_web_quantity)     AS sum_web_quantity
FROM (
    SELECT * FROM store_side
    UNION
    SELECT * FROM web_side
) AS combined
GROUP BY ROLLUP (year, channel)
ORDER BY year, channel
