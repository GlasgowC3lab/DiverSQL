WITH catalog_sales_data AS (
    SELECT cs.cs_sold_date_sk AS date_sk, cs.cs_item_sk AS item_sk, cs.cs_ext_sales_price AS sales, cs.cs_net_profit AS profit
    FROM catalog_sales cs
), store_sales_data AS (
    SELECT ss.ss_sold_date_sk AS date_sk, ss.ss_item_sk AS item_sk, ss.ss_ext_sales_price AS sales, ss.ss_net_profit AS profit
    FROM store_sales ss
), web_sales_data AS (
    SELECT ws.ws_sold_date_sk AS date_sk, ws.ws_item_sk AS item_sk, ws.ws_ext_sales_price AS sales, ws.ws_net_profit AS profit
    FROM web_sales ws
), sales_union AS (
    SELECT * FROM catalog_sales_data
    UNION ALL
    SELECT * FROM store_sales_data
    UNION ALL
    SELECT * FROM web_sales_data
), catalog_returns_data AS (
    SELECT cr.cr_returned_date_sk AS date_sk, cr.cr_item_sk AS item_sk, cr.cr_return_amt_inc_tax AS return_amount
    FROM catalog_returns cr
), store_returns_data AS (
    SELECT sr.sr_returned_date_sk AS date_sk, sr.sr_item_sk AS item_sk, sr.sr_return_amt_inc_tax AS return_amount
    FROM store_returns sr
), web_returns_data AS (
    SELECT wr.wr_returned_date_sk AS date_sk, wr.wr_item_sk AS item_sk, wr.wr_return_amt_inc_tax AS return_amount
    FROM web_returns wr
), returns_union AS (
    SELECT * FROM catalog_returns_data
    UNION ALL
    SELECT * FROM store_returns_data
    UNION ALL
    SELECT * FROM web_returns_data
), sales_enriched AS (
    SELECT su.date_sk,
           d.d_year,
           d.d_month_seq,
           i.i_brand,
           su.sales,
           su.profit
    FROM sales_union su
    JOIN date_dim d ON su.date_sk = d.d_date_sk
    JOIN item i ON su.item_sk = i.i_item_sk
), returns_enriched AS (
    SELECT ru.date_sk,
           d.d_year,
           d.d_month_seq,
           i.i_brand,
           ru.return_amount
    FROM returns_union ru
    JOIN date_dim d ON ru.date_sk = d.d_date_sk
    JOIN item i ON ru.item_sk = i.i_item_sk
), monthly_sales AS (
    SELECT d_year,
           d_month_seq,
           i_brand,
           SUM(sales) AS total_sales,
           SUM(profit) AS total_profit
    FROM sales_enriched
    GROUP BY d_year, d_month_seq, i_brand
), monthly_returns AS (
    SELECT d_year,
           d_month_seq,
           i_brand,
           SUM(return_amount) AS total_returns
    FROM returns_enriched
    GROUP BY d_year, d_month_seq, i_brand
), monthly_agg AS (
    SELECT s.d_year,
           s.d_month_seq,
           s.i_brand,
           s.total_sales,
           s.total_profit,
           COALESCE(r.total_returns, 0) AS total_returns
    FROM monthly_sales s
    LEFT JOIN monthly_returns r
        ON s.d_year = r.d_year
        AND s.d_month_seq = r.d_month_seq
        AND s.i_brand = r.i_brand
), final_calc AS (
    SELECT
        ma.d_year,
        ma.d_month_seq,
        ma.i_brand,
        ma.total_sales,
        ma.total_returns,
        ma.total_sales - ma.total_returns AS net_sales,
        ma.total_profit,
        RANK() OVER (PARTITION BY ma.d_year, ma.d_month_seq ORDER BY ma.total_profit DESC) AS profit_rank,
        LAG(ma.total_profit) OVER (PARTITION BY ma.i_brand ORDER BY ma.d_year, ma.d_month_seq) AS prev_profit,
        CASE
            WHEN LAG(ma.total_profit) OVER (PARTITION BY ma.i_brand ORDER BY ma.d_year, ma.d_month_seq) = 0 THEN NULL
            ELSE (ma.total_profit - LAG(ma.total_profit) OVER (PARTITION BY ma.i_brand ORDER BY ma.d_year, ma.d_month_seq))
                 / LAG(ma.total_profit) OVER (PARTITION BY ma.i_brand ORDER BY ma.d_year, ma.d_month_seq) * 100
        END AS yoy_profit_pct
    FROM monthly_agg ma
)
SELECT
    d_year,
    d_month_seq,
    i_brand,
    total_sales,
    total_returns,
    net_sales,
    total_profit,
    profit_rank,
    yoy_profit_pct
FROM final_calc
WHERE profit_rank <= 10
  AND d_year >= 2000
ORDER BY d_year, d_month_seq, profit_rank
