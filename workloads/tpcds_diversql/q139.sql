WITH filtered AS (
  SELECT
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_returned_date_sk,
    cr.cr_refunded_hdemo_sk,
    ws.ws_ext_sales_price,
    ws.ws_quantity,
    ws.ws_item_sk,
    ws.ws_sold_date_sk,
    ws.ws_ship_date_sk,
    ws.ws_promo_sk,
    ws.ws_web_page_sk,
    ws.ws_bill_hdemo_sk,
    ws.ws_ship_hdemo_sk,
    ws.ws_order_number,
    ws.ws_net_profit,
    p.p_promo_id,
    p.p_cost,
    p.p_discount_active,
    p.p_start_date_sk,
    p.p_end_date_sk,
    s.s_store_id,
    s.s_state,
    s.s_tax_percentage,
    d.d_year,
    d.d_date_sk
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_item_sk = ws.ws_item_sk
  WHERE d.d_year = 2001
    AND p.p_discount_active = 'N'
    AND p.p_start_date_sk >= 2450324
    AND p.p_end_date_sk <= 2450400
    AND s.s_state = 'CA'
    AND ws.ws_quantity >= 2
    AND cr.cr_return_quantity > 0
    AND ws.ws_ext_sales_price > (SELECT MAX(p2.p_cost) FROM promotion p2)
),
agg AS (
  SELECT
    s_store_id,
    p_promo_id,
    d_year,
    d_date_sk,
    ws_item_sk,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(ws_net_profit) AS avg_profit,
    COUNT(DISTINCT ws_order_number) AS order_cnt
  FROM filtered
  GROUP BY s_store_id, p_promo_id, d_year, d_date_sk, ws_item_sk
)
SELECT
  a.s_store_id,
  a.p_promo_id,
  a.d_year,
  a.total_return_amount,
  a.total_sales,
  a.avg_profit,
  a.order_cnt,
  (
    SELECT SUM(inv3.inv_quantity_on_hand)
    FROM inventory inv3
    WHERE inv3.inv_date_sk = a.d_date_sk
      AND inv3.inv_item_sk = a.ws_item_sk
  ) AS inventory_on_date,
  LAG(a.total_sales) OVER (PARTITION BY a.s_store_id ORDER BY a.d_date_sk) AS lag_total_sales
FROM agg a
ORDER BY a.s_store_id, a.d_year, a.p_promo_id
