WITH sales AS (
    SELECT d.d_year,
           d.d_month_seq,
           i.i_item_id,
           i.i_product_name,
           'catalog' AS channel,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           SUM(cs.cs_net_profit) AS total_profit,
           SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_item_id, i.i_product_name
    UNION ALL
    SELECT d.d_year,
           d.d_month_seq,
           i.i_item_id,
           i.i_product_name,
           'store' AS channel,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           SUM(ss.ss_net_profit) AS total_profit,
           SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_item_id, i.i_product_name
    UNION ALL
    SELECT d.d_year,
           d.d_month_seq,
           i.i_item_id,
           i.i_product_name,
           'web' AS channel,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           SUM(ws.ws_net_profit) AS total_profit,
           SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_item_id, i.i_product_name
), returns AS (
    SELECT d.d_year,
           d.d_month_seq,
           i.i_item_id,
           i.i_product_name,
           'catalog' AS channel,
           SUM(cr.cr_return_amount) AS total_return_amount,
           SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_item_id, i.i_product_name
    UNION ALL
    SELECT d.d_year,
           d.d_month_seq,
           i.i_item_id,
           i.i_product_name,
           'store' AS channel,
           SUM(sr.sr_return_amt) AS total_return_amount,
           SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_item_id, i.i_product_name
    UNION ALL
    SELECT d.d_year,
           d.d_month_seq,
           i.i_item_id,
           i.i_product_name,
           'web' AS channel,
           SUM(wr.wr_return_amt) AS total_return_amount,
           SUM(wr.wr_return_quantity) AS total_return_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_item_id, i.i_product_name
), sales_returns_combined AS (
    SELECT
        s.d_year,
        s.d_month_seq,
        s.channel,
        s.i_item_id,
        s.i_product_name,
        s.total_sales,
        s.total_profit,
        s.total_quantity,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
        s.total_profit - COALESCE(r.total_return_amount, 0) AS net_profit_adj,
        SUM(s.total_profit - COALESCE(r.total_return_amount, 0)) OVER (
            PARTITION BY s.channel
            ORDER BY s.d_year, s.d_month_seq
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_profit
    FROM sales s
    LEFT JOIN returns r
        ON s.d_year = r.d_year
        AND s.d_month_seq = r.d_month_seq
        AND s.channel = r.channel
        AND s.i_item_id = r.i_item_id
        AND s.i_product_name = r.i_product_name
), ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq, channel ORDER BY net_profit_adj DESC) AS profit_rank
    FROM sales_returns_combined
    WHERE d_year BETWEEN 1999 AND 2002
)
SELECT
    d_year,
    d_month_seq,
    channel,
    i_item_id,
    i_product_name,
    total_sales,
    total_profit,
    total_quantity,
    total_return_amount,
    total_return_quantity,
    net_profit_adj,
    cumulative_profit,
    profit_rank
FROM ranked
WHERE profit_rank <= 10
ORDER BY d_year, d_month_seq, channel, profit_rank
