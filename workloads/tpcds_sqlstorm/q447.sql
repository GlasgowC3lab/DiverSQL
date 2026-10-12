WITH sales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        i.i_category,
        SUM(ss.ss_net_profit) AS sales_profit,
        SUM(ss.ss_ext_sales_price) AS sales_amount
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, i.i_category
), returns AS (
    SELECT
        s.s_store_sk,
        d.d_year,
        i.i_category,
        SUM(sr.sr_net_loss) AS returns_loss,
        SUM(sr.sr_return_amt_inc_tax) AS returns_amount
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY s.s_store_sk, d.d_year, i.i_category
)
SELECT *
FROM (
    SELECT
        s.s_store_name,
        s.d_year,
        s.i_category,
        s.sales_profit - COALESCE(r.returns_loss, 0) AS net_profit_adj,
        s.sales_amount - COALESCE(r.returns_amount, 0) AS net_sales_adj,
        RANK() OVER (PARTITION BY s.d_year ORDER BY (s.sales_profit - COALESCE(r.returns_loss, 0)) DESC) AS profit_rank
    FROM sales s
    LEFT JOIN returns r
        ON s.s_store_sk = r.s_store_sk
       AND s.d_year = r.d_year
       AND s.i_category = r.i_category
) t
WHERE t.profit_rank <= 5
ORDER BY t.d_year, t.profit_rank
