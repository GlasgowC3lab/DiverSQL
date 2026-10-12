WITH unified_sales AS (
    SELECT cs.cs_item_sk AS item_sk,
           cs.cs_order_number AS order_number,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_quantity AS quantity,
           cs.cs_ext_sales_price AS ext_sales_price,
           cs.cs_ext_discount_amt AS ext_discount_amt,
           cs.cs_ext_tax AS ext_tax,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           'catalog' AS channel,
           cs.cs_coupon_amt AS coupon_amt,
           cs.cs_promo_sk AS promo_sk,
           cs.cs_call_center_sk AS call_center_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_item_sk AS item_sk,
           ss.ss_ticket_number AS order_number,
           ss.ss_sold_date_sk AS date_sk,
           ss.ss_quantity AS quantity,
           ss.ss_ext_sales_price AS ext_sales_price,
           ss.ss_ext_discount_amt AS ext_discount_amt,
           ss.ss_ext_tax AS ext_tax,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           'store' AS channel,
           ss.ss_coupon_amt AS coupon_amt,
           ss.ss_promo_sk AS promo_sk,
           NULL AS call_center_sk
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_sk AS item_sk,
           ws.ws_order_number AS order_number,
           ws.ws_sold_date_sk AS date_sk,
           ws.ws_quantity AS quantity,
           ws.ws_ext_sales_price AS ext_sales_price,
           ws.ws_ext_discount_amt AS ext_discount_amt,
           ws.ws_ext_tax AS ext_tax,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit,
           'web' AS channel,
           ws.ws_coupon_amt AS coupon_amt,
           ws.ws_promo_sk AS promo_sk,
           NULL AS call_center_sk
    FROM web_sales ws
),
unified_returns AS (
    SELECT cr.cr_item_sk AS item_sk,
           cr.cr_order_number AS order_number,
           cr.cr_returned_date_sk AS date_sk,
           cr.cr_return_quantity AS quantity,
           cr.cr_return_amount AS return_amount,
           cr.cr_return_tax AS return_tax,
           cr.cr_net_loss AS net_loss,
           'catalog' AS channel,
           cr.cr_refunded_cash AS refunded_cash,
           cr.cr_fee AS fee
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_item_sk AS item_sk,
           sr.sr_ticket_number AS order_number,
           sr.sr_returned_date_sk AS date_sk,
           sr.sr_return_quantity AS quantity,
           sr.sr_return_amt AS return_amount,
           sr.sr_return_tax AS return_tax,
           sr.sr_net_loss AS net_loss,
           'store' AS channel,
           sr.sr_refunded_cash AS refunded_cash,
           sr.sr_fee AS fee
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_item_sk AS item_sk,
           wr.wr_order_number AS order_number,
           wr.wr_returned_date_sk AS date_sk,
           wr.wr_return_quantity AS quantity,
           wr.wr_return_amt AS return_amount,
           wr.wr_return_tax AS return_tax,
           wr.wr_net_loss AS net_loss,
           'web' AS channel,
           wr.wr_refunded_cash AS refunded_cash,
           wr.wr_fee AS fee
    FROM web_returns wr
),
item_promo AS (
    SELECT p.p_item_sk AS item_sk,
           p.p_promo_sk AS promo_sk,
           p.p_discount_active,
           COALESCE(p.p_channel_dmail, '') || COALESCE(p.p_channel_email, '') || COALESCE(p.p_channel_catalog, '') ||
           COALESCE(p.p_channel_tv, '') || COALESCE(p.p_channel_radio, '') || COALESCE(p.p_channel_press, '') ||
           COALESCE(p.p_channel_event, '') AS all_channels,
           p.p_cost
    FROM promotion p
),
sales_with_promos AS (
    SELECT s.*,
           ip.p_discount_active,
           ip.all_channels,
           ip.p_cost,
           CASE WHEN s.quantity <> 0 THEN s.ext_discount_amt / NULLIF(s.quantity, 0) ELSE NULL END AS avg_discount_per_unit,
           CASE WHEN ip.p_discount_active = 'Y' THEN 1 ELSE 0 END AS discount_flag
    FROM unified_sales s
    LEFT JOIN item_promo ip
        ON s.promo_sk = ip.promo_sk
        AND s.item_sk = ip.item_sk
),
ranked_sales AS (
    SELECT swp.item_sk,
           i.i_product_name,
           swp.channel,
           d.d_date,
           d.d_year,
           d.d_month_seq,
           swp.quantity,
           swp.ext_sales_price,
           swp.net_profit,
           swp.discount_flag,
           swp.all_channels,
           ROW_NUMBER() OVER (PARTITION BY swp.item_sk ORDER BY d.d_date DESC) AS rn,
           SUM(swp.net_profit) OVER (PARTITION BY swp.item_sk ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
    FROM sales_with_promos swp
    LEFT JOIN date_dim d ON swp.date_sk = d.d_date_sk
    LEFT JOIN item i ON swp.item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND swp.channel IN ('store', 'web')
),
final AS (
    SELECT rs.item_sk,
           rs.i_product_name,
           rs.channel,
           rs.d_year,
           rs.d_month_seq,
           rs.quantity,
           rs.ext_sales_price,
           rs.net_profit,
           rs.cumulative_profit,
           rs.rn,
           CASE
               WHEN rs.cumulative_profit > 0 AND rs.rn <= 5 THEN 'Top Performer'
               ELSE 'Regular'
           END AS performance_category,
           COALESCE(NULLIF(REGEXP_REPLACE(rs.all_channels, '[^A-Z]', ''), ''), 'NONE') AS promo_channels_clean,
           (SELECT SUM(sr.sr_return_quantity) FROM store_returns sr WHERE sr.sr_item_sk = rs.item_sk) AS total_store_returns_qty,
           CASE
               WHEN REGEXP_LIKE(rs.all_channels, '(TV|Radio)') THEN TRUE
               ELSE FALSE
           END AS has_tv_radio_promo,
           CONCAT_WS('_', rs.channel, CAST(rs.item_sk AS VARCHAR), CAST(rs.d_year AS VARCHAR)) AS composite_key,
           LENGTH(COALESCE(i.i_item_desc, '')) AS item_desc_len
    FROM ranked_sales rs
    LEFT JOIN item i ON rs.item_sk = i.i_item_sk
    LEFT JOIN (
        SELECT DISTINCT item_sk FROM item_promo WHERE p_discount_active = 'Y'
    ) ip_active ON rs.item_sk = ip_active.item_sk
    WHERE (rs.rn = 1 OR rs.rn = 10)
      AND ip_active.item_sk IS NOT NULL
)
SELECT *
FROM (
    SELECT *
    FROM final
    WHERE (performance_category = 'Top Performer' AND promo_channels_clean <> 'NONE')
       OR (has_tv_radio_promo AND composite_key IS NOT NULL)
    UNION ALL
    SELECT NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'No Data', NULL, NULL, NULL, NULL, NULL
    WHERE NOT EXISTS (SELECT 1 FROM final WHERE performance_category = 'Top Performer')
) q
ORDER BY cumulative_profit DESC
FETCH FIRST 100 ROWS ONLY
