WITH
  catalog_cte AS (
    SELECT
      cs.cs_order_number               AS order_number,
      cs.cs_quantity                    AS quantity,
      cs.cs_net_paid                    AS net_paid,
      cr.cr_return_amount               AS return_amount,
      d.d_year                          AS year,
      p.p_promo_name                    AS promo_name,
      sm.sm_type                        AS ship_type,
      w.w_warehouse_name                AS warehouse_name,
      cd.cd_gender                      AS gender,
      CAST(NULL AS VARCHAR)            AS url_part
    FROM catalog_sales cs
    JOIN catalog_returns cr        ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d                ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p               ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm              ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w               ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN reason r                  ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c                ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'CA'
  ),
  web_cte AS (
    SELECT
      ws.ws_order_number               AS order_number,
      ws.ws_quantity                    AS quantity,
      ws.ws_net_paid                    AS net_paid,
      CAST(NULL AS DECIMAL(7,2))       AS return_amount,
      d2.d_year                         AS year,
      p2.p_promo_name                   AS promo_name,
      sm2.sm_type                       AS ship_type,
      w2.w_warehouse_name               AS warehouse_name,
      cd2.cd_gender                     AS gender,
      url_part
    FROM web_sales ws
    JOIN web_page wp                  ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN UNNEST(split(wp.wp_url, '/')) AS t(url_part) ON TRUE
    JOIN date_dim d2                  ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN promotion p2                 ON ws.ws_promo_sk = p2.p_promo_sk
    JOIN ship_mode sm2                ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN warehouse w2                 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    JOIN customer c2                 ON ws.ws_bill_customer_sk = c2.c_customer_sk
    JOIN customer_demographics cd2   ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    JOIN web_returns wr               ON wr.wr_order_number = ws.ws_order_number
    JOIN reason rwr                   ON wr.wr_reason_sk = rwr.r_reason_sk
    WHERE d2.d_year = 2001
      AND p2.p_discount_active = 'Y'
      AND sm2.sm_type = 'AIR'
      AND w2.w_state = 'CA'
      AND wr.wr_fee > 5.0
  ),
  union_all AS (
    SELECT * FROM catalog_cte
    UNION DISTINCT
    SELECT * FROM web_cte
  ),
  store_part AS (
    SELECT
      sr.sr_ticket_number   AS ticket,
      sr.sr_return_quantity AS return_quantity,
      sr.sr_return_amt      AS return_amt,
      d3.d_year             AS year,
      r3.r_reason_desc      AS reason_desc
    FROM store_returns sr
    JOIN date_dim d3        ON sr.sr_returned_date_sk = d3.d_date_sk
    JOIN reason r3          ON sr.sr_reason_sk = r3.r_reason_sk
    WHERE d3.d_year = 2001
  )
SELECT
  u.year,
  sp.reason_desc,
  COUNT(DISTINCT u.order_number)            AS distinct_orders,
  SUM(u.quantity)                           AS total_quantity,
  AVG(u.net_paid)                           AS avg_net_paid,
  SUM(COALESCE(u.return_amount, 0))         AS total_return_amount,
  MIN(sp.return_quantity)                   AS min_store_return_qty,
  MAX(sp.return_amt)                        AS max_store_return_amt,
  COUNT(DISTINCT sp.ticket)                 AS distinct_store_tickets,
  SUM(CASE WHEN u.url_part IS NOT NULL THEN 1 ELSE 0 END) AS url_part_rows
FROM union_all u
FULL OUTER JOIN store_part sp
  ON u.year = sp.year
WHERE u.quantity > (
        SELECT MAX(sr_return_quantity)
        FROM store_returns
        WHERE sr_returned_date_sk = 2450000
      )
GROUP BY u.year, sp.reason_desc
ORDER BY u.year DESC, distinct_orders DESC
