/*
Goal: Compare store performance by computing total sales versus total returns across all sales channels, rank stores by net profit, and provide subtotals per manager and a grand total using GROUP BY ROLLUP.
*/
WITH joined_data AS (
    SELECT
        s.s_manager,
        s.s_store_name,
        sr.sr_return_amt,
        cr.cr_return_amt_inc_tax,
        cs.cs_ext_sales_price,
        ws.ws_ext_sales_price,
        t.t_hour,
        cr.cr_refunded_cash,
        s.s_rec_start_date
    FROM store_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_time_sk = t.t_time_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_order_number = cs.cs_order_number
        AND cr.cr_returned_time_sk = t.t_time_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    WHERE s.s_manager IN ('Jerry Brooks', 'Alva Abner')
      AND s.s_rec_start_date >= DATE '1999-01-01'
      AND s.s_rec_start_date <= DATE '2002-12-31'
      AND t.t_hour BETWEEN 9 AND 17
      AND cr.cr_refunded_cash > 100.00
),
agg AS (
    SELECT
        s_manager,
        s_store_name,
        SUM(sr_return_amt) + SUM(cr_return_amt_inc_tax) AS total_return_amount,
        SUM(cs_ext_sales_price) + SUM(ws_ext_sales_price) AS total_sales_amount,
        (SUM(cs_ext_sales_price) + SUM(ws_ext_sales_price)) - (SUM(sr_return_amt) + SUM(cr_return_amt_inc_tax)) AS net_total
    FROM joined_data
    GROUP BY ROLLUP(s_manager, s_store_name)
)
SELECT
    s_manager,
    s_store_name,
    total_return_amount,
    total_sales_amount,
    net_total,
    CASE
        WHEN s_manager IS NOT NULL AND s_store_name IS NOT NULL THEN
            RANK() OVER (ORDER BY net_total DESC)
        ELSE NULL
    END AS sales_rank
FROM agg
ORDER BY
    CASE WHEN s_manager IS NULL THEN 1 ELSE 0 END, -- put grand total last
    s_manager,
    net_total DESC
