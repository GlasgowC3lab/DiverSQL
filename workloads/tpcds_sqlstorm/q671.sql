WITH sales_agg AS (
    SELECT ss.ss_store_sk AS store_sk,
           d.d_year AS year,
           i.i_category AS category,
           sum(ss.ss_net_paid) AS total_net_paid,
           sum(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
    GROUP BY ss.ss_store_sk, d.d_year, i.i_category
),
returns_agg AS (
    SELECT sr.sr_store_sk AS store_sk,
           d.d_year AS year,
           i.i_category AS category,
           sum(sr.sr_return_amt_inc_tax) AS total_return_amt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
    GROUP BY sr.sr_store_sk, d.d_year, i.i_category
)
SELECT s.year,
       st.s_store_name,
       s.category,
       s.total_net_paid - coalesce(r.total_return_amt, 0) AS net_revenue,
       s.total_net_profit
FROM sales_agg s
JOIN store st ON s.store_sk = st.s_store_sk
LEFT JOIN returns_agg r ON s.store_sk = r.store_sk AND s.year = r.year AND s.category = r.category
ORDER BY s.year, st.s_store_name, s.category
