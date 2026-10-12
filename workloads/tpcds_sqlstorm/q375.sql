WITH sales_union AS (
    SELECT ss.ss_sold_date_sk AS sold_date_sk,
           ss.ss_net_profit AS net_profit,
           ss.ss_net_paid AS net_paid,
           ss.ss_quantity AS quantity,
           'Store' AS channel,
           ss.ss_item_sk AS item_sk,
           ss.ss_promo_sk AS promo_sk,
           CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END AS promo_flag
    FROM store_sales ss
    LEFT JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
         AND ss.ss_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk

    UNION ALL

    SELECT ws.ws_sold_date_sk,
           ws.ws_net_profit,
           ws.ws_net_paid,
           ws.ws_quantity,
           'Web',
           ws.ws_item_sk,
           ws.ws_promo_sk,
           CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END
    FROM web_sales ws
    LEFT JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
         AND ws.ws_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk

    UNION ALL

    SELECT cs.cs_sold_date_sk,
           cs.cs_net_profit,
           cs.cs_net_paid,
           cs.cs_quantity,
           'Catalog',
           cs.cs_item_sk,
           cs.cs_promo_sk,
           CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END
    FROM catalog_sales cs
    LEFT JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
         AND cs.cs_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
),
sales_agg AS (
    SELECT su.sold_date_sk,
           su.channel,
           SUM(su.net_profit) AS total_net_profit,
           SUM(su.net_paid) AS total_net_paid,
           SUM(su.quantity) AS total_quantity,
           SUM(su.promo_flag) AS promo_count
    FROM sales_union su
    GROUP BY su.sold_date_sk, su.channel
),
returns_agg AS (
    SELECT ru.returned_date_sk,
           ru.channel,
           SUM(ru.net_loss) AS total_return_net_loss,
           SUM(ru.return_quantity) AS total_return_quantity
    FROM (
        SELECT sr_returned_date_sk AS returned_date_sk,
               'Store' AS channel,
               sr_net_loss AS net_loss,
               sr_return_quantity AS return_quantity
        FROM store_returns
        UNION ALL
        SELECT wr_returned_date_sk,
               'Web',
               wr_net_loss,
               wr_return_quantity
        FROM web_returns
        UNION ALL
        SELECT cr_returned_date_sk,
               'Catalog',
               cr_net_loss,
               cr_return_quantity
        FROM catalog_returns
    ) ru
    GROUP BY ru.returned_date_sk, ru.channel
),
item_daily AS (
    SELECT su.sold_date_sk,
           su.channel,
           su.item_sk,
           SUM(su.net_profit) AS item_net_profit,
           SUM(su.quantity) AS item_quantity
    FROM sales_union su
    GROUP BY su.sold_date_sk, su.channel, su.item_sk
),
item_ranked AS (
    SELECT id.sold_date_sk,
           id.channel,
           id.item_sk,
           i.i_item_id,
           i.i_product_name,
           i.i_category,
           id.item_net_profit,
           ROW_NUMBER() OVER (PARTITION BY id.sold_date_sk, id.channel ORDER BY id.item_net_profit DESC) AS rn
    FROM item_daily id
    LEFT JOIN item i ON id.item_sk = i.i_item_sk
),
top_item AS (
    SELECT ir.sold_date_sk,
           ir.channel,
           ir.i_item_id AS top_item_id,
           CONCAT(ir.i_category, '-', ir.i_product_name) AS top_item_category
    FROM item_ranked ir
    WHERE ir.rn = 1
)
SELECT
    d.d_date AS sale_date,
    s.channel,
    s.total_net_profit,
    s.total_net_paid,
    s.total_quantity,
    s.promo_count,
    COALESCE(r.total_return_net_loss, 0) AS total_return_net_loss,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    SUM(s.total_net_profit) OVER (PARTITION BY s.channel ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_profit,
    (SELECT MAX(s2.total_net_profit)
     FROM sales_agg s2
     WHERE s2.sold_date_sk < s.sold_date_sk
       AND s2.channel = s.channel) AS prior_day_max_net_profit,
    CASE WHEN s.total_net_profit < 0 THEN 0 ELSE s.total_net_profit END AS adjusted_net_profit,
    COALESCE(ti.top_item_id, 'UNKNOWN') AS top_item_id,
    COALESCE(ti.top_item_category, 'UNKNOWN') AS top_item_category,
    CONCAT(s.channel, '_', CAST(d.d_date AS VARCHAR)) AS channel_date_key,
    CASE WHEN s.total_net_paid = 0 THEN NULL ELSE (s.total_net_profit - COALESCE(r.total_return_net_loss, 0)) / s.total_net_paid END AS profit_margin,
    s.total_net_profit - COALESCE(r.total_return_net_loss, 0) AS net_profit_minus_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.sold_date_sk = r.returned_date_sk
   AND s.channel = r.channel
LEFT JOIN date_dim d
    ON s.sold_date_sk = d.d_date_sk
LEFT JOIN top_item ti
    ON s.sold_date_sk = ti.sold_date_sk
   AND s.channel = ti.channel
WHERE d.d_year BETWEEN 1999 AND 2002
ORDER BY s.channel, d.d_date
