WITH unified_sales AS (
    SELECT cs_sold_date_sk AS sold_date_sk,
           cs_item_sk AS item_sk,
           cs_quantity AS quantity,
           cs_ext_sales_price AS sales_amount,
           cs_net_paid AS net_paid,
           cs_promo_sk AS promo_sk,
           'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk,
           ss_item_sk,
           ss_quantity,
           ss_ext_sales_price,
           ss_net_paid,
           ss_promo_sk,
           'store'
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_quantity,
           ws_ext_sales_price,
           ws_net_paid,
           ws_promo_sk,
           'web'
    FROM web_sales
),
unified_returns AS (
    SELECT cr_returned_date_sk AS returned_date_sk,
           cr_item_sk AS item_sk,
           cr_return_quantity AS return_quantity,
           cr_return_amount AS return_amount,
           cr_net_loss AS net_loss,
           'catalog' AS channel
    FROM catalog_returns
    UNION ALL
    SELECT sr_returned_date_sk,
           sr_item_sk,
           sr_return_quantity,
           sr_return_amt,
           sr_net_loss,
           'store'
    FROM store_returns
    UNION ALL
    SELECT wr_returned_date_sk,
           wr_item_sk,
           wr_return_quantity,
           wr_return_amt,
           wr_net_loss,
           'web'
    FROM web_returns
),
sales_agg AS (
    SELECT s.channel,
           d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_brand,
           s.promo_sk,
           SUM(s.sales_amount) AS sales_amount,
           SUM(s.net_paid) AS net_paid,
           SUM(s.quantity) AS quantity
    FROM unified_sales s
    JOIN date_dim d ON d.d_date_sk = s.sold_date_sk
    JOIN item i ON i.i_item_sk = s.item_sk
    GROUP BY s.channel, d.d_year, d.d_month_seq, i.i_category, i.i_brand, s.promo_sk
),
returns_agg AS (
    SELECT r.channel,
           d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_brand,
           SUM(r.return_amount) AS return_amount,
           SUM(r.net_loss) AS net_loss,
           SUM(r.return_quantity) AS return_quantity
    FROM unified_returns r
    JOIN date_dim d ON d.d_date_sk = r.returned_date_sk
    JOIN item i ON i.i_item_sk = r.item_sk
    GROUP BY r.channel, d.d_year, d.d_month_seq, i.i_category, i.i_brand
),
final_agg AS (
    SELECT sa.d_year,
           sa.d_month_seq,
           sa.channel,
           sa.i_category AS category,
           sa.i_brand AS brand,
           COALESCE(p.p_promo_name, 'No Promo') AS promo_name,
           SUM(sa.sales_amount) AS total_sales_amount,
           SUM(sa.net_paid) AS total_net_paid,
           SUM(sa.quantity) AS total_quantity,
           COALESCE(SUM(ra.return_amount), 0) AS total_return_amount,
           COALESCE(SUM(ra.net_loss), 0) AS total_return_loss,
           COALESCE(SUM(ra.return_quantity), 0) AS total_return_quantity
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON ra.channel = sa.channel
       AND ra.d_year = sa.d_year
       AND ra.d_month_seq = sa.d_month_seq
       AND ra.i_category = sa.i_category
       AND ra.i_brand = sa.i_brand
    LEFT JOIN promotion p ON p.p_promo_sk = sa.promo_sk
    GROUP BY sa.d_year, sa.d_month_seq, sa.channel, sa.i_category, sa.i_brand, COALESCE(p.p_promo_name, 'No Promo')
)
SELECT d_year,
       d_month_seq,
       channel,
       category,
       brand,
       promo_name,
       total_sales_amount,
       total_net_paid,
       total_quantity,
       total_return_amount,
       total_return_loss,
       total_return_quantity,
       RANK() OVER (PARTITION BY d_year, channel ORDER BY total_sales_amount DESC) AS sales_rank
FROM final_agg
WHERE total_sales_amount > 0
ORDER BY d_year DESC, channel, total_sales_amount DESC
LIMIT 200
