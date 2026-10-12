WITH valid_keys AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT sr_ticket_number
    FROM store_returns
),
base AS (
    SELECT
        cs.cs_order_number,
        d_sold.d_year,
        d_sold.d_month_seq,
        cc.cc_name,
        cc.cc_division,
        cp.cp_catalog_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        sr.sr_return_amt_inc_tax,
        sr.sr_return_tax
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN store_returns sr ON cs.cs_order_number = sr.sr_ticket_number
    JOIN valid_keys vk ON cs.cs_order_number = vk.cs_order_number
    WHERE cc.cc_division = 6
      AND cp.cp_catalog_number = 20
      AND d_sold.d_year = 2001
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_item_sk = cs.cs_item_sk
            AND sr2.sr_returned_date_sk = cs.cs_sold_date_sk
      )
)
SELECT
    row_number() OVER (ORDER BY d_year, d_month_seq) AS row_num,
    cc_name,
    cc_division,
    cp_catalog_number,
    d_year,
    d_month_seq,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(cs_quantity) AS total_quantity,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_net_profit) AS avg_profit,
    SUM(COALESCE(sr_return_amt_inc_tax, 0)) AS total_return_amt_inc_tax,
    SUM(COALESCE(sr_return_tax, 0)) AS total_return_tax
FROM base
GROUP BY
    cc_name,
    cc_division,
    cp_catalog_number,
    d_year,
    d_month_seq
ORDER BY d_year, d_month_seq
LIMIT 100
