WITH detailed AS (
  SELECT
    ws.ws_order_number,
    ws.ws_item_sk,
    ws.ws_warehouse_sk,
    ws.ws_promo_sk,
    ws.ws_web_page_sk,
    ws.ws_bill_cdemo_sk,
    ws.ws_ship_cdemo_sk,
    ws.ws_net_profit,
    cr.cr_net_loss,
    wr.wr_net_loss,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    w.w_warehouse_name,
    cd_bill.cd_gender AS bill_gender,
    cd_ship.cd_gender AS ship_gender,
    cd_ref.cd_gender AS refund_gender
  FROM tpcds.web_sales ws
  JOIN tpcds.item i
    ON ws.ws_item_sk = i.i_item_sk
  JOIN tpcds.promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  JOIN tpcds.warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN tpcds.web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
  JOIN tpcds.catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
  JOIN tpcds.customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN tpcds.customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN tpcds.customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
)
SELECT
  i_category,
  i_brand,
  p_promo_name,
  w_warehouse_name,
  SUM(total_catalog_return_loss) AS catalog_return_loss,
  SUM(total_web_return_loss) AS web_return_loss,
  SUM(total_net_profit) AS net_profit,
  COUNT(DISTINCT ws_order_number) AS distinct_orders,
  ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY SUM(total_net_profit) DESC) AS category_rank,
  seg.segment
FROM (
  SELECT
    i_category,
    i_brand,
    p_promo_name,
    w_warehouse_name,
    ws_order_number,
    cr_net_loss AS total_catalog_return_loss,
    wr_net_loss AS total_web_return_loss,
    ws_net_profit AS total_net_profit
  FROM detailed
) sub
CROSS JOIN (SELECT 'ALL' AS segment) AS seg
GROUP BY
  i_category,
  i_brand,
  p_promo_name,
  w_warehouse_name,
  seg.segment
ORDER BY net_profit DESC
LIMIT 100
