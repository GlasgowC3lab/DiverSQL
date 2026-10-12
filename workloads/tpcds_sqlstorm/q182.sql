WITH sales AS (
    SELECT d.d_year,
           i.i_category,
           st.s_state,
           SUM(ss.ss_net_profit) AS total_profit,
           SUM(ss.ss_quantity) AS total_quantity,
           SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    GROUP BY d.d_year, i.i_category, st.s_state
),
returns AS (
    SELECT d.d_year,
           i.i_category,
           st.s_state,
           SUM(sr.sr_net_loss) AS total_return_loss,
           SUM(sr.sr_return_quantity) AS total_return_quantity,
           SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    GROUP BY d.d_year, i.i_category, st.s_state
)
SELECT
    COALESCE(s.d_year, r.d_year) AS year,
    COALESCE(s.i_category, r.i_category) AS category,
    COALESCE(s.s_state, r.s_state) AS state,
    s.total_profit,
    s.total_quantity,
    s.total_sales,
    r.total_return_loss,
    r.total_return_quantity,
    r.total_return_amount,
    COALESCE(s.total_profit, 0) - COALESCE(r.total_return_loss, 0) AS net_profit_adj
FROM sales s
FULL OUTER JOIN returns r
    ON s.d_year = r.d_year
    AND s.i_category = r.i_category
    AND s.s_state = r.s_state
ORDER BY year, category, state
