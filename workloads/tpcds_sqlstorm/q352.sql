WITH sales AS (
    SELECT 'store' AS channel,
           ss_sold_date_sk AS sold_date_sk,
           ss_item_sk AS item_sk,
           ss_quantity AS quantity,
           ss_net_profit AS net_profit,
           ss_net_paid AS net_paid,
           ss_ext_discount_amt AS discount_amt
    FROM store_sales
    UNION ALL
    SELECT 'catalog' AS channel,
           cs_sold_date_sk AS sold_date_sk,
           cs_item_sk AS item_sk,
           cs_quantity AS quantity,
           cs_net_profit AS net_profit,
           cs_net_paid AS net_paid,
           cs_ext_discount_amt AS discount_amt
    FROM catalog_sales
    UNION ALL
    SELECT 'web' AS channel,
           ws_sold_date_sk AS sold_date_sk,
           ws_item_sk AS item_sk,
           ws_quantity AS quantity,
           ws_net_profit AS net_profit,
           ws_net_paid AS net_paid,
           ws_ext_discount_amt AS discount_amt
    FROM web_sales
),
returns AS (
    SELECT 'store' AS channel,
           sr_returned_date_sk AS returned_date_sk,
           sr_item_sk AS item_sk,
           sr_return_quantity AS quantity,
           sr_net_loss AS net_loss,
           sr_return_amt AS return_amount
    FROM store_returns
    UNION ALL
    SELECT 'catalog' AS channel,
           cr_returned_date_sk AS returned_date_sk,
           cr_item_sk AS item_sk,
           cr_return_quantity AS quantity,
           cr_net_loss AS net_loss,
           cr_return_amount AS return_amount
    FROM catalog_returns
    UNION ALL
    SELECT 'web' AS channel,
           wr_returned_date_sk AS returned_date_sk,
           wr_item_sk AS item_sk,
           wr_return_quantity AS quantity,
           wr_net_loss AS net_loss,
           wr_return_amt AS return_amount
    FROM web_returns
),
date_sales AS (
    SELECT s.channel,
           d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_brand,
           SUM(s.net_profit) AS total_net_profit,
           SUM(s.net_paid) AS total_net_paid,
           SUM(s.discount_amt) AS total_discount,
           COUNT(*) AS sales_cnt
    FROM sales s
    JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    GROUP BY ROLLUP (s.channel, d.d_year, d.d_month_seq, i.i_category, i.i_brand)
),
date_returns AS (
    SELECT r.channel,
           d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_brand,
           SUM(r.net_loss) AS total_net_loss,
           SUM(r.return_amount) AS total_return_amount,
           COUNT(*) AS returns_cnt
    FROM returns r
    JOIN date_dim d ON r.returned_date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    GROUP BY ROLLUP (r.channel, d.d_year, d.d_month_seq, i.i_category, i.i_brand)
),
combined AS (
    SELECT
        COALESCE(s.channel, r.channel) AS channel,
        COALESCE(s.d_year, r.d_year) AS year,
        COALESCE(s.d_month_seq, r.d_month_seq) AS month_seq,
        COALESCE(s.i_category, r.i_category) AS category,
        COALESCE(s.i_brand, r.i_brand) AS brand,
        s.total_net_profit,
        s.total_net_paid,
        s.total_discount,
        s.sales_cnt,
        r.total_net_loss,
        r.total_return_amount,
        r.returns_cnt
    FROM date_sales s
    FULL OUTER JOIN date_returns r
      ON s.channel = r.channel
     AND s.d_year = r.d_year
     AND s.d_month_seq = r.d_month_seq
     AND s.i_category = r.i_category
     AND s.i_brand = r.i_brand
)
SELECT
    channel,
    year,
    month_seq,
    category,
    brand,
    total_net_profit,
    total_net_loss,
    (total_net_profit - total_net_loss) AS net_profit_after_loss,
    total_net_paid,
    total_discount,
    sales_cnt,
    returns_cnt,
    CASE WHEN total_net_profit IS NULL THEN 0 ELSE total_net_profit END /
    CASE WHEN total_net_loss = 0 THEN NULL ELSE total_net_loss END AS profit_loss_ratio,
    ROW_NUMBER() OVER (PARTITION BY channel ORDER BY (total_net_profit - total_net_loss) DESC) AS profit_rank
FROM combined
WHERE year = 2000
ORDER BY channel, profit_rank
LIMIT 100
