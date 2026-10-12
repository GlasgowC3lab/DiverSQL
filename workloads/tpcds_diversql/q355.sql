WITH sampled_sales AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10) -- sample 10% of rows for performance
    ),
    item_attrs AS (
        SELECT i_item_sk,
               ARRAY[i_color, i_size] AS attrs
        FROM item
    )
SELECT
    s.s_store_id,
    s.s_store_name,
    ib.ib_lower_bound AS income_lower,
    ib.ib_upper_bound AS income_upper,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    SUM(ss.ss_net_paid) AS total_sales,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount,
    CASE WHEN r.r_reason_desc LIKE '%size%' THEN 'Size Issue' ELSE 'Other' END AS return_category,
    AVG(i.i_current_price) AS avg_item_price,
    (
        SELECT MAX(p_sub.p_cost)
        FROM promotion p_sub
        WHERE p_sub.p_item_sk = i.i_item_sk
    ) AS max_promo_cost,
    LAG(ss.ss_net_paid, 1) OVER (PARTITION BY s.s_store_id ORDER BY td_sold.t_time) AS prev_sales,
    attr AS item_attribute
FROM sampled_sales ss
JOIN time_dim td_sold
  ON ss.ss_sold_time_sk = td_sold.t_time_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN item_attrs ia
  ON i.i_item_sk = ia.i_item_sk
CROSS JOIN UNNEST(ia.attrs) AS t(attr)
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN promotion p2
  ON p2.p_item_sk = i.i_item_sk -- same promotion table reused under a different alias
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN time_dim td_return
  ON sr.sr_return_time_sk = td_return.t_time_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN time_dim td_web
  ON wr.wr_returned_time_sk = td_web.t_time_sk
LEFT JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND td_sold.t_sub_shift = 'morning'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    r.r_reason_desc,
    i.i_current_price,
    i.i_item_sk,
    attr,
    ss.ss_net_paid,
    td_sold.t_time
ORDER BY total_sales DESC
LIMIT 100
