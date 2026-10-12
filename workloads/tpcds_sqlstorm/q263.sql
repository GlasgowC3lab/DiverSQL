WITH combined_sales AS (
    SELECT ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           ss_customer_sk AS cust_sk,
           ss_quantity AS quantity,
           ss_net_paid AS net_paid,
           ss_net_profit AS net_profit,
           'store' AS channel,
           s.s_state AS state
    FROM store_sales ss
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk

    UNION ALL

    SELECT cs_sold_date_sk AS date_sk,
           cs_item_sk AS item_sk,
           cs_bill_customer_sk AS cust_sk,
           cs_quantity AS quantity,
           cs_net_paid AS net_paid,
           cs_net_profit AS net_profit,
           'catalog' AS channel,
           cc.cc_state AS state
    FROM catalog_sales cs
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk

    UNION ALL

    SELECT ws_sold_date_sk AS date_sk,
           ws_item_sk AS item_sk,
           ws_bill_customer_sk AS cust_sk,
           ws_quantity AS quantity,
           ws_net_paid AS net_paid,
           ws_net_profit AS net_profit,
           'web' AS channel,
           ws2.web_state AS state
    FROM web_sales ws
    LEFT JOIN web_site ws2 ON ws.ws_web_site_sk = ws2.web_site_sk
),
combined_returns AS (
    SELECT sr_returned_date_sk AS date_sk,
           sr_item_sk AS item_sk,
           sr_customer_sk AS cust_sk,
           sr_return_quantity AS quantity,
           sr_return_amt AS return_amount,
           sr_net_loss AS net_loss,
           'store' AS channel,
           s.s_state AS state
    FROM store_returns sr
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk

    UNION ALL

    SELECT cr_returned_date_sk AS date_sk,
           cr_item_sk AS item_sk,
           cr_refunded_customer_sk AS cust_sk,
           cr_return_quantity AS quantity,
           cr_return_amount AS return_amount,
           cr_net_loss AS net_loss,
           'catalog' AS channel,
           cc.cc_state AS state
    FROM catalog_returns cr
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk

    UNION ALL

    SELECT wr_returned_date_sk AS date_sk,
           wr_item_sk AS item_sk,
           wr_refunded_customer_sk AS cust_sk,
           wr_return_quantity AS quantity,
           wr_return_amt AS return_amount,
           wr_net_loss AS net_loss,
           'web' AS channel,
           CAST(NULL AS varchar) AS state
    FROM web_returns wr
),
sales_agg AS (
    SELECT d.d_year AS year,
           d.d_quarter_seq AS quarter_seq,
           d.d_quarter_name AS quarter,
           i.i_category AS category,
           i.i_class AS class,
           cs.channel,
           cs.state,
           SUM(cs.quantity) AS total_qty,
           SUM(cs.net_paid) AS total_sales_amount,
           SUM(cs.net_profit) AS total_sales_profit
    FROM combined_sales cs
    JOIN date_dim d ON cs.date_sk = d.d_date_sk
    JOIN item i ON cs.item_sk = i.i_item_sk
    GROUP BY d.d_year,
             d.d_quarter_seq,
             d.d_quarter_name,
             i.i_category,
             i.i_class,
             cs.channel,
             cs.state
),
returns_agg AS (
    SELECT d.d_year AS year,
           d.d_quarter_seq AS quarter_seq,
           d.d_quarter_name AS quarter,
           i.i_category AS category,
           i.i_class AS class,
           cr.channel,
           cr.state,
           SUM(cr.quantity) AS total_ret_qty,
           SUM(cr.return_amount) AS total_return_amount,
           SUM(cr.net_loss) AS total_return_loss
    FROM combined_returns cr
    JOIN date_dim d ON cr.date_sk = d.d_date_sk
    JOIN item i ON cr.item_sk = i.i_item_sk
    GROUP BY d.d_year,
             d.d_quarter_seq,
             d.d_quarter_name,
             i.i_category,
             i.i_class,
             cr.channel,
             cr.state
),
final AS (
    SELECT sa.year,
           sa.quarter_seq,
           sa.quarter,
           sa.category,
           sa.class,
           sa.channel,
           COALESCE(sa.state, ra.state) AS state,
           sa.total_qty,
           sa.total_sales_amount,
           sa.total_sales_profit,
           COALESCE(ra.total_ret_qty, 0) AS total_ret_qty,
           COALESCE(ra.total_return_amount, 0) AS total_return_amount,
           COALESCE(ra.total_return_loss, 0) AS total_return_loss,
           sa.total_sales_amount - COALESCE(ra.total_return_amount, 0) AS net_sales_amount,
           sa.total_sales_profit - COALESCE(ra.total_return_loss, 0) AS net_profit
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON sa.year = ra.year
        AND sa.quarter_seq = ra.quarter_seq
        AND sa.category = ra.category
        AND sa.class = ra.class
        AND sa.channel = ra.channel
        AND (sa.state = ra.state OR (sa.state IS NULL AND ra.state IS NULL))
)
SELECT year,
       quarter,
       category,
       class,
       channel,
       state,
       total_qty,
       total_sales_amount,
       total_sales_profit,
       total_ret_qty,
       total_return_amount,
       total_return_loss,
       net_sales_amount,
       net_profit,
       LAG(net_sales_amount) OVER (PARTITION BY quarter_seq, category, class, channel, state ORDER BY year) AS prev_year_net_sales,
       CASE
           WHEN LAG(net_sales_amount) OVER (PARTITION BY quarter_seq, category, class, channel, state ORDER BY year) = 0 THEN NULL
           ELSE (net_sales_amount - LAG(net_sales_amount) OVER (PARTITION BY quarter_seq, category, class, channel, state ORDER BY year)) /
                LAG(net_sales_amount) OVER (PARTITION BY quarter_seq, category, class, channel, state ORDER BY year) * 100
       END AS yoy_growth_percent,
       SUM(net_sales_amount) OVER (PARTITION BY channel, state ORDER BY year, quarter_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_by_channel_state
FROM final
ORDER BY year DESC, quarter_seq, channel, state
