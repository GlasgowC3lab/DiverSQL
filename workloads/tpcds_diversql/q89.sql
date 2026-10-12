WITH base AS (
    SELECT
        d.d_date AS sale_date,
        s.s_store_id AS s_store_id,
        i.i_item_id AS i_item_id,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        p.p_promo_name AS p_promo_name,
        CASE WHEN ss.ss_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS order_type,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_paid DESC) AS sales_rank
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_sold_time_sk = t.t_time_sk
        AND cs.cs_item_sk = i.i_item_sk
        AND cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year IN (2001, 2002)
      AND s.s_state = 'CA'
      AND i.i_category = 'decor'
      AND ss.ss_quantity > 2
      AND p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1 FROM store_returns sr2
          WHERE sr2.sr_ticket_number = ss.ss_ticket_number
            AND sr2.sr_return_amt > 0
      )
)
SELECT sale_date, s_store_id, i_item_id, quantity, net_paid, p_promo_name, order_type, sales_rank
FROM base
WHERE sales_rank <= 10
UNION DISTINCT
SELECT sale_date, s_store_id, i_item_id, quantity, net_paid, p_promo_name, order_type, sales_rank
FROM base
WHERE sales_rank > 10 AND sales_rank <= 20
ORDER BY sale_date DESC, s_store_id, sales_rank
LIMIT 100
