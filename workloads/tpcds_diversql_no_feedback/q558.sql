WITH base_join AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        i.i_item_id,
        i.i_category,
        cs.cs_net_paid               AS catalog_net_paid,
        ws.ws_net_paid               AS web_net_paid,
        sr.sr_return_amt             AS store_return_amount,
        cr.cr_return_amount          AS catalog_return_amount,
        td_cs.t_hour                 AS sold_hour,
        wsit.web_market_manager,
        hd.hd_vehicle_count,
        ib.ib_lower_bound            AS income_lower,
        sm.sm_type                    AS ship_mode_type
    FROM catalog_sales cs
    JOIN catalog_page cp               ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td_cs                ON cs.cs_sold_time_sk = td_cs.t_time_sk
    JOIN customer c                    ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca           ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib                ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm                  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p                   ON cs.cs_promo_sk = p.p_promo_sk
    JOIN item i                        ON cs.cs_item_sk = i.i_item_sk
    JOIN web_sales ws                  ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td_ws                ON ws.ws_sold_time_sk = td_ws.t_time_sk
    JOIN web_site wsit                 ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN store_returns sr              ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim td_sr                ON sr.sr_return_time_sk = td_sr.t_time_sk
    JOIN reason r_sr                   ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN catalog_returns cr            ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim td_cr                ON cr.cr_returned_time_sk = td_cr.t_time_sk
    JOIN reason r_cr                   ON cr.cr_reason_sk = r_cr.r_reason_sk
    WHERE wsit.web_market_manager = 'Keith Frazier'
      AND hd.hd_vehicle_count > 1
      AND td_cs.t_hour BETWEEN 9 AND 17
),
agg AS (
    SELECT
        i_item_id,
        i_category,
        SUM(catalog_net_paid)          AS total_catalog_net_paid,
        SUM(web_net_paid)              AS total_web_net_paid,
        SUM(store_return_amount)       AS total_store_return,
        SUM(catalog_return_amount)     AS total_catalog_return,
        COUNT(DISTINCT cs_order_number) AS order_count,
        MAX(cs_order_number)           AS max_order_number,
        AVG(income_lower)              AS avg_income_lower
    FROM base_join
    GROUP BY i_item_id, i_category
)
SELECT
    a.i_item_id,
    a.i_category,
    a.total_catalog_net_paid,
    a.total_web_net_paid,
    a.total_store_return,
    a.order_count,
    a.avg_income_lower
FROM agg a
WHERE a.total_catalog_net_paid > 10000
  AND a.total_web_net_paid > 5000
  AND a.order_count >= 10
  AND a.total_catalog_net_paid > (SELECT AVG(total_catalog_net_paid) FROM agg)
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = a.max_order_number
          AND cr2.cr_return_amount > 0
    )
ORDER BY a.total_catalog_net_paid DESC
LIMIT 100
